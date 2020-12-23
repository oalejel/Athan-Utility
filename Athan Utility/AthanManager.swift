//
//  AthanManager.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/14/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation
import Adhan
import CoreLocation
import UIKit
import WidgetKit

/*
 Athan manager now uses the batoul apps api to calculate prayer times
 Process flow of this manager can roughly be condensed to this list:
 - Current location calculation
    - Use corelocation to find a location name and coordinates
    - Or use manual location input to find coordinates using reversegeocode location
    - Store coordinates on disk, with a flag of whether we want that location to be manual or not
 - Provide accessors to today and tomorrow's prayer times, only recalculating when last calculation day ≠ current day
 - Modify settings for prayer calculation, write changes to user defaults
- No storage of qibla --> user location angle is enough
 */


// In order to preserve backwards compatibility, properties we would have wanted to observe
// in athan manager are stored in this object, and conditionally updated by AthanManager.s
@available(iOS 13.0.0, *)
class ObservableAthanManager: ObservableObject {
    static var shared = ObservableAthanManager()
    
    init() {
        // bootstrap process of initializing the athan manager?
//        let _ = AthanManager.shared
    }
    
    @Published var todayTimes: PrayerTimes!
    @Published var tomorrowTimes: PrayerTimes!
    @Published var currentPrayer: Prayer = .fajr
    @Published var locationName: String = ""
    @Published var qiblaHeading: Double = 0.0
    @Published var currentHeading: Double = 0.0
}

class AthanManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = AthanManager()
    let locationManager = CLLocationManager()
    var heading: Double = 0.0 {
        didSet {
            if #available(iOS 13.0.0, *) {
                ObservableAthanManager.shared.currentHeading = heading
            }
        }
    }
    
    // will default to cupertino times at start of launch
    lazy var todayTimes: PrayerTimes! = nil {
        didSet {
            if #available(iOS 13.0.0, *) {
                ObservableAthanManager.shared.todayTimes = todayTimes
            }
        }
    }
    
    lazy var tomorrowTimes: PrayerTimes! = nil {
        didSet {
            if #available(iOS 13.0.0, *) {
                ObservableAthanManager.shared.tomorrowTimes = tomorrowTimes
            }
        }
    }
    
    // MARK: - Settings to load from storage
    var prayerSettings = PrayerSettings.shared {
        didSet { prayerSettingsDidSetHelper() }
    }
    
    var notificationSettings = NotificationSettings.shared {
        didSet { notificationSettingsDidSetHelper() }
    }
    
    var locationSettings = LocationSettings.shared {
        didSet { locationSettingsDidSetHelper() }
    }
    
    var locationPermissionsGranted = false
    
    // MARK: - DidSet Helpers
    func prayerSettingsDidSetHelper() {
        PrayerSettings.shared = prayerSettings
        PrayerSettings.archive()
    }
    
    func notificationSettingsDidSetHelper() {
        NotificationSettings.shared = notificationSettings
        NotificationSettings.archive()
    }
    
    func locationSettingsDidSetHelper() {
//        assert(false, "just checking that this correctly gets called")
        LocationSettings.shared = locationSettings
        LocationSettings.archive()
        if #available(iOS 13.0.0, *) {
            ObservableAthanManager.shared.locationName = locationSettings.locationName
            ObservableAthanManager.shared.qiblaHeading = Qibla(coordinates:
                                                                Coordinates(latitude: locationSettings.locationCoordinate.latitude,
                                                                            longitude: locationSettings.locationCoordinate.longitude)).direction
        }
    }
    
    // App lifecycle state tracking
    private var dayOfMonth = 0
    private var firstLaunch = true
    var currentPrayer: Prayer? {
        didSet {
            if #available(iOS 13.0.0, *) {
                ObservableAthanManager.shared.currentPrayer = currentPrayer! // should never be nil after didSet
            }
        }
    }
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        
        // register for going into foreground
        NotificationCenter.default.addObserver(self, selector: #selector(movedToForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        // manually call these the first time since didSet not called on init
        prayerSettingsDidSetHelper()
        notificationSettingsDidSetHelper()
        locationSettingsDidSetHelper()
        
        // if non-iOS devices, force a refresh since enteredForeground will not be called
        if let bundleID = Bundle.main.bundleIdentifier, bundleID != "com.omaralejel.Athan-Utility" {
            considerRecalculations(isNewLocation: false)
        }
    }
        
    // MARK: - Prayer Times
    
    func refreshTimes() {
        // swiftui publisher gets updates through didSet
        todayTimes = calculateTimes(referenceDate: Date())
        tomorrowTimes = calculateTimes(referenceDate: Date().addingTimeInterval(86400)) // add 24 hours for next day
        currentPrayer = todayTimes.currentPrayer() ?? .isha
        assert(todayTimes.currentPrayer(at: todayTimes.fajr.addingTimeInterval(-100)) == nil, "failed test on assumption about API nil values")
    }
    
    private func calculateTimes(referenceDate: Date) -> PrayerTimes? {
        let coord = locationSettings.locationCoordinate
        
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
        let coordinates = Coordinates(latitude: coord.latitude, longitude: coord.longitude)
        
        var params = PrayerSettings.shared.calculationMethod.params
        params.madhab = PrayerSettings.shared.madhab
        
        if let prayers = PrayerTimes(coordinates: coordinates,
                                     date: date,
                                     calculationParameters: params) {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.timeZone = TimeZone.current

            print("fajr \(formatter.string(from: prayers.fajr))")
            print("sunrise \(formatter.string(from: prayers.sunrise))")
            print("dhuhr \(formatter.string(from: prayers.dhuhr))")
            print("asr \(formatter.string(from: prayers.asr))")
            print("maghrib \(formatter.string(from: prayers.maghrib))")
            print("isha \(formatter.string(from: prayers.isha))")
            return prayers
        }
        return nil
    }
    
    // MARK: - Timers and timer callbacks
    
    var nextPrayerTimer: Timer?
    var reminderTimer: Timer?
    var newDayTimer: Timer?
    
    func resetTimers() {
        nextPrayerTimer?.invalidate()
        reminderTimer?.invalidate()
        newDayTimer?.invalidate()
        nextPrayerTimer = nil
        reminderTimer = nil
        newDayTimer = nil
        
        let nextPrayerTime = guaranteedNextPrayerTime()
        
        let secondsLeft = nextPrayerTime.timeIntervalSince(Date())
        nextPrayerTimer = Timer.scheduledTimer(timeInterval: secondsLeft,
                             target: self, selector: #selector(newPrayer),
                             userInfo: nil, repeats: false)
        
        // if > 15m and 2 seconds remaining, make a timer
        if secondsLeft > 15 * 60 + 2 {
            reminderTimer = Timer.scheduledTimer(timeInterval: nextPrayerTime.timeIntervalSince(Date()) - 15 * 60,
                                                 target: self, selector: #selector(fifteenMinsLeft),
                                                 userInfo: nil, repeats: false)
        }
        
        // time til next day
        let currentDateComponents = Calendar.current.dateComponents([.hour, .minute, .hour, .second], from: Date())
        let accumulatedSeconds = currentDateComponents.hour! * 60 * 60 + currentDateComponents.minute! * 60 + currentDateComponents.second!
        let remainingSecondsInDay = 86400 - accumulatedSeconds
        print("\(remainingSecondsInDay / 3600) hours left today")
        newDayTimer = Timer.scheduledTimer(timeInterval: TimeInterval(remainingSecondsInDay + 1), // +1 to account for slight error
                                           target: self, selector: #selector(newDay),
                                           userInfo: nil, repeats: false)
    }
    
    private func watchForImminentPrayerUpdate() {
        // enter a background thread loop to wait on a change in case this timer is triggered too early
        let samplePrayer = todayTimes.currentPrayer()
        let nextTime = guaranteedNextPrayerTime()
        let timeUntilChange = nextTime.timeIntervalSince(Date())
        if timeUntilChange < 5 && timeUntilChange > 0 {
            DispatchQueue.global().async {
                // wait on a change
                while (samplePrayer == self.todayTimes.currentPrayer()) {
                    // do nothing
                } // on break, we can update our prayer
                DispatchQueue.main.async {
                    self.currentPrayer = self.todayTimes.currentPrayer() ?? .isha
                }
            }
        } else {
            currentPrayer = todayTimes.currentPrayer() ?? .isha
        }
    }
    
    @objc func newPrayer() {
//        print("new prayer | \(currentPrayer!) -> \(todayTimes.nextPrayer() ?? .fajr)")
//        assert(currentPrayer != (todayTimes.nextPrayer() ?? .fajr))
        watchForImminentPrayerUpdate()
    }
    
    @objc func fifteenMinsLeft() {
        // trigger a didset
//        print("15 mins left | \(currentPrayer!) -> \(todayTimes.nextPrayer() ?? .fajr)")
//        assert(currentPrayer != todayTimes.nextPrayer() ?? .fajr)
//        currentPrayer = todayTimes.currentPrayer() ?? .isha
        watchForImminentPrayerUpdate()
    }
    
    @objc func newDay() {
        // will update dayOfMonth
        considerRecalculations(isNewLocation: false)
    }
    
    // MARK: - Helpers
    
    // calculate next prayer, considering next day's .fajr time in case we are on isha time
    func guaranteedNextPrayerTime() -> Date {
        let currentPrayer = todayTimes.currentPrayer()
        // do not use api nextPrayeras it does not distinguish tomorrow fajr from today fajr nil
//        var nextPrayer: Prayer? = todayTimes.nextPrayer()
        var nextPrayerTime: Date! = nil
        if currentPrayer == .isha { // case for reading from tomorrow fajr times
            nextPrayerTime = tomorrowTimes.fajr
        } else if currentPrayer == nil { // case for reading from today's fajr times
            nextPrayerTime = todayTimes.fajr
        } else { // otherwise, next prayer time is based on today
            nextPrayerTime = todayTimes.time(for: currentPrayer!.next())
        }
        
        return nextPrayerTime
    }
    
    func guaranteedCurrentPrayerTime() -> Date {
        var currentPrayer: Prayer? = todayTimes.currentPrayer()
        var currentPrayerTime: Date! = nil
        if currentPrayer == nil { // case of new day before fajr
            currentPrayer = .isha
            currentPrayerTime = todayTimes.isha.addingTimeInterval(-86400) // shift back today isha approximation by a day
        } else {
            currentPrayerTime = todayTimes.time(for: currentPrayer!)
        }
        return currentPrayerTime
    }
}

// Listen for background events
extension AthanManager {
    
    func considerRecalculations(isNewLocation: Bool) {
        // reload settings in case we are running widget and app changed them
        if let arch = LocationSettings.checkArchive() { locationSettings = arch }
        if let arch = NotificationSettings.checkArchive() { notificationSettings = arch }
        if let arch = PrayerSettings.checkArchive() { prayerSettings = arch }
        
        var shouldRecalculate = isNewLocation // forced for when we have new locations
        if !isNewLocation {
            if firstLaunch { // if app was quit before opening, recalculating for whatever location we have stored
                shouldRecalculate = true
//                let _ = LocationSettings.shared // this is already done when the manager launches
                // ask location settings to lookup user coordinates
            } else if dayOfMonth != Calendar.current.component(.day, from: Date()) { // if new day of month
                shouldRecalculate = true
            } else { // check next athan times to see if we have 15m left or a new prayer
                assert(todayTimes != nil, "todayTimes should not be nil at this point")
                var nextPrayer: Prayer! = todayTimes.nextPrayer()
                var nextPrayerTime: Date! = nil
                if nextPrayer == nil {
                    nextPrayer = .fajr
                    nextPrayerTime = tomorrowTimes.fajr // distinguish from today's fajr time
                } else {
                    nextPrayerTime = todayTimes.time(for: nextPrayer)
                }
                
                // if new prayer,
                if currentPrayer != (todayTimes.currentPrayer() ?? .isha) {
                    print("new prayer on launch")
                    currentPrayer = (todayTimes.currentPrayer() ?? .isha)
                    // notify to change gradient, update highlighting
                    
                } else if nextPrayerTime.timeIntervalSince(Date()) < 15 * 60 { // 15 mins left!
                    // just update highlighting -- maybe let UI
                    print("15m left")
                    currentPrayer = (todayTimes.currentPrayer() ?? .isha)
                }
                
                // otherwise, no new prayer or anything
                // just proceed to refresh timers
            }
        }
        
        // unconditional update of day of month
        dayOfMonth = Calendar.current.component(.day, from: Date())

        // 1. refresh times
        // 2. create notifications (if recalculating)
        // 3. refresh widgets (if recalculating)
        // 4. reset timers
        if shouldRecalculate {
            refreshTimes()
            NotificationsManager
                .createNotifications(coordinate: locationSettings.locationCoordinate,
                                     calculationMethod: prayerSettings.calculationMethod,
                                     madhab: prayerSettings.madhab,
                                     noteSettings: notificationSettings.settings,
                                     shortLocationName: locationSettings.locationName)
            if #available(iOS 14.0, *) {
                // refresh widgets only if this is being run in the main app
                if let bundleID = Bundle.main.bundleIdentifier, bundleID == "com.omaralejel.Athan-Utility" {
                    DispatchQueue.main.async {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
        
        // reset timers to keep data updated if app stays on screen
        resetTimers()
    }
    
    // called by observer
    @objc func movedToForeground() {
        print("ENTERED FOREROUND \(Date())")
        // 1. refresh times, notifications, widgets, timers,
        // 2. allow location to be updated and repeat step 1
        // first recalculation on existing location settings
        considerRecalculations(isNewLocation: false)
        attemptSingleLocationUpdate() // if new location is read, we will trigger concsiderRecalculations(isNewLocation: true)
    }
}

// location services side of the manager
extension AthanManager {
    
    // NOTE: leave request to use location data for when the user taps on the loc button OR
    //  if the user launches the app from a widget for the first time
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func attemptSingleLocationUpdate() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse ||
            status == CLAuthorizationStatus.authorizedAlways {
            #warning("not sure if we should have this automatically called. may want a semaphore")
            locationManager.startUpdatingLocation()
            locationPermissionsGranted = true
        } else {
            locationPermissionsGranted = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = Double(newHeading.trueHeading)
    }
    
    // triggered and disabled after one measurement
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(locations.first!, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) -> Void in
            if error == nil {
                print("successfully reverse geocoded location")
                if let placemark = placemarks?.first {
                    let city = placemark.locality
                    let district = placemark.subAdministrativeArea
                    let state = placemark.administrativeArea
                    let country = placemark.isoCountryCode
                    
                    // current preferred method of prioritizing parts of a placemark's location.
                    #warning("test for localization")
                    var shortname = ""
                    if let city = city, let state = state {
                        shortname = "\(city), \(state)"
                    } else if let district = district {
                        shortname = district
                        if let state = state {
                            shortname += ", " + state
                        } else if let country = country {
                            shortname += ", " + country
                        }
                    } else if let name = placemark.name {
                        shortname = name
                    } else {
                        shortname = String(format: "%.2f°, %.2f°", locations.first!.coordinate.latitude, locations.first!.coordinate.longitude)
                    }
                    
                    // save our location settings
                    let potentialNewLocationSettings = LocationSettings(locationName: shortname,
                                                             coord: locations.first!.coordinate)
                    if self.locationSettings.locationName != potentialNewLocationSettings.locationName {
                        self.locationSettings = potentialNewLocationSettings
                        self.considerRecalculations(isNewLocation: true)
                    }
                    
                    return
                }
            }
            
            // error case: rely on coordinates and no geocoded name
            self.locationSettings = LocationSettings(locationName: String(format: "%.2f°, %.2f°", locations.first!.coordinate.latitude, locations.first!.coordinate.longitude),
                                                     coord: locations.first!.coordinate)
            self.considerRecalculations(isNewLocation: true)
            if let x = error {
                print("failed to reverse geocode location")
                print(x) // fallback
            }
        })
    }
}
