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
#if !os(watchOS)
import WidgetKit
#endif
import WatchConnectivity

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
    @Published var currentPrayer: Prayer! = .fajr
    @Published var locationName: String = ""
    @Published var qiblaHeading: Double = 0.0
    @Published var currentHeading: Double = 0.0
    @Published var locationPermissionsGranted = false
    @Published var appearance: AppearanceSettings = AppearanceSettings.defaultSetting()
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
    
    var appearanceSettings = AppearanceSettings.shared {
        didSet { appearanceSettingsDidSetHelper() }
    }
    
    var locationPermissionsGranted = false {
        didSet {
            if #available(iOS 13.0.0, *) {
                ObservableAthanManager.shared.locationPermissionsGranted = locationPermissionsGranted
            }
        }
    }
    var captureLocationUpdateClosure: ((LocationSettings?) -> ())?
    
    // MARK: - DidSet Helpers
    func prayerSettingsDidSetHelper() {
        PrayerSettings.shared = prayerSettings
        PrayerSettings.archive()
        
        // if not running on watchOS, update the watch
//        #warning("may have unnecessary updates from widget loading up these objects. not sure since i dont think didset is called on widgets unless locations update")
//        #if !os(watchOS)
//        if WCSession.default.activationState == .activated {
//            WCSession.default.sendMessage([PHONE_MSG_KEY : "prayerSettings"]) { replyDict in
//                print("watchos reply: \(replyDict)")
//            } errorHandler: { error in
//                print("> Error with WCSession send")
//            }
//        }
//        #endif
    }
    
    func notificationSettingsDidSetHelper() {
        NotificationSettings.shared = notificationSettings
        NotificationSettings.archive()
        // no need to send these to the watch
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
        
        #if !os(watchOS)
        if WCSession.default.activationState == .activated {
            do {
                let encoded = try PropertyListEncoder().encode(WatchPackage(locationSettings: locationSettings, prayerSettings: prayerSettings))
                WCSession.default.sendMessageData(encoded) { (respData) in
                    print(">>> got response from sending watch data")
                } errorHandler: { error in
                    print(">>> error from watch in sending data \(error)")
                }
            } catch {
                print(">>> unable to encode location settings response")
            }
        }
        #endif
    }
    
    func appearanceSettingsDidSetHelper() {
        AppearanceSettings.shared = appearanceSettings
        AppearanceSettings.archive()
        if #available(iOS 13.0.0, *) {
            ObservableAthanManager.shared.appearance = appearanceSettings
        }
        // no need to send these over to watchos
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
        
        #if !os(watchOS)
        // register for going into foreground
        NotificationCenter.default.addObserver(self, selector: #selector(movedToForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        #else
        WCSession.default.delegate = WatchSessionDelegate.shared
        WCSession.default.activate()
        #endif
        
        
        // manually call these the first time since didSet not called on init
        prayerSettingsDidSetHelper()
        notificationSettingsDidSetHelper()
        locationSettingsDidSetHelper()
        
        refreshTimes()
        
        // if non-iOS devices, force a refresh since enteredForeground will not be called
        if let bundleID = Bundle.main.bundleIdentifier, bundleID != "com.omaralejel.Athan-Utility" {
            considerRecalculations(force: false)
        }
    }
        
    // MARK: - Prayer Times
    
    func refreshTimes() {
        // swiftui publisher gets updates through didSet
        let tz = locationSettings.timeZone
        if let today = calculateTimes(referenceDate: Date(), customTimeZone: tz), let tomorrow = calculateTimes(referenceDate: Date().addingTimeInterval(86400), customTimeZone: tz) {
            todayTimes = today
            tomorrowTimes = tomorrow
        } else {
            print("DANGER: unable to calculate times. should handle this accordingly for places on the north pole lol")
            // default back to settings defaults
            locationSettings = LocationSettings.defaultSetting()
            todayTimes = calculateTimes(referenceDate: Date(), customTimeZone: locationSettings.timeZone) // guaranteed fallback
            tomorrowTimes = calculateTimes(referenceDate: Date().addingTimeInterval(86400), customTimeZone: locationSettings.timeZone)
        } // should never fail on cupertino time.
         // add 24 hours for next day
        currentPrayer = todayTimes.currentPrayer() ?? .isha
        assert(todayTimes.currentPrayer(at: todayTimes.fajr.addingTimeInterval(-100)) == nil, "failed test on assumption about API nil values")
    }
    
    // NOTE: this function MUST not have SIDE EFFECTS
    func calculateTimes(referenceDate: Date, customCoordinate: CLLocationCoordinate2D? = nil, customTimeZone: TimeZone? = nil) -> PrayerTimes? {
        let coord = locationSettings.locationCoordinate
        
        var cal = Calendar(identifier: Calendar.Identifier.gregorian)
        cal.timeZone = customTimeZone ?? cal.timeZone // if we want to pass a custom time zone not based on the device time zone
        let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
        let coordinates = Coordinates(latitude: customCoordinate?.latitude ?? coord.latitude, longitude: customCoordinate?.longitude ?? coord.longitude)
        
        var params = PrayerSettings.shared.calculationMethod.params
        params.madhab = PrayerSettings.shared.madhab
        
        if let prayers = PrayerTimes(coordinates: coordinates,
                                     date: date,
                                     calculationParameters: params) {
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
        considerRecalculations(force: false)
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
    func considerRecalculations(force: Bool) {
        // reload settings in case we are running widget and app changed them
        if let arch = LocationSettings.checkArchive() { locationSettings = arch }
        if let arch = NotificationSettings.checkArchive() { notificationSettings = arch }
        if let arch = PrayerSettings.checkArchive() { prayerSettings = arch }
        if let arch = AppearanceSettings.checkArchive() { appearanceSettings = arch }
        
        var shouldRecalculate = force // forced for when we have new locations
        if !force {
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
        }
        
        // only make notifications if user has edited from the default location
        if locationSettings.locationName != "Edit Location" {
            #if !os(watchOS) // dont schedule notes in watchos app
            NotificationsManager
                .createNotifications(coordinate: locationSettings.locationCoordinate,
                                     calculationMethod: prayerSettings.calculationMethod,
                                     madhab: prayerSettings.madhab,
                                     noteSettings: notificationSettings,
                                     shortLocationName: locationSettings.locationName)
            resetWidgets()
            #endif
        }
        
        // reset timers to keep data updated if app stays on screen
        resetTimers()
    }
    
    func resetWidgets() {
        if #available(iOS 14.0, *) {
            // refresh widgets only if this is being run in the main app
            if let bundleID = Bundle.main.bundleIdentifier, bundleID == "com.omaralejel.Athan-Utility" {
                DispatchQueue.main.async {
                    #if !os(watchOS)
                        WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }
            }
        }
    }
    
    // called by observer
    @objc func movedToForeground() {
        print("ENTERED FOREROUND \(Date())")
        // 1. refresh times, notifications, widgets, timers,
        // 2. allow location to be updated and repeat step 1
        // first recalculation on existing location settings
        considerRecalculations(force: false)
        
        if locationSettings.useCurrentLocation {
            attemptSingleLocationUpdate() // if new location is read, we will trigger concsiderRecalculations(isNewLocation: true)
        }
    }
}

// location services side of the manager
extension AthanManager {
    
    // NOTE: leave request to use location data for when the user taps on the loc button OR
    //  if the user launches the app from a widget for the first time
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // pass a capture closure to take the location update
    func attemptSingleLocationUpdate(captureClosure: ((LocationSettings?) -> ())? = nil) {
        if let capture = captureClosure {
            self.captureLocationUpdateClosure = capture
        }
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse ||
            status == CLAuthorizationStatus.authorizedAlways {
            #warning("not sure if we should have this automatically called. may want a semaphore")
            locationPermissionsGranted = true
            if locationSettings.useCurrentLocation {
                attemptSingleLocationUpdate()
            }
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
                    
                    if placemark.timeZone == nil { print("!!! BAD: time zone for placemark nil")}
                    let timeZone = placemark.timeZone ?? Calendar.current.timeZone
                    // save our location settings
                    let potentialNewLocationSettings = LocationSettings(locationName: shortname,
                                                                        coord: locations.first!.coordinate, timeZone: timeZone, useCurrentLocation: true)
                    
                    if let captureClosue = self.captureLocationUpdateClosure  {
                        captureClosue(potentialNewLocationSettings)
                        self.captureLocationUpdateClosure = nil
                    } else if self.locationSettings.locationName != potentialNewLocationSettings.locationName { // if not same location, update
                        self.locationSettings = potentialNewLocationSettings
                        self.considerRecalculations(force: true)
                    }
                    
                    return
                }
            }
            
            // user calendar timezone, trusting user is giving coordinates that make sense for their time zone
            let namelessLocationSettings = LocationSettings(locationName: String(format: "%.2f°, %.2f°", locations.first!.coordinate.latitude, locations.first!.coordinate.longitude),
                                                            coord: locations.first!.coordinate, timeZone: Calendar.current.timeZone, useCurrentLocation: true)
            // error case: rely on coordinates and no geocoded name
            if let captureClosue = self.captureLocationUpdateClosure  {
                captureClosue(namelessLocationSettings)
                self.captureLocationUpdateClosure = nil
            } else {
                self.locationSettings = namelessLocationSettings
            }
            
            self.considerRecalculations(force: true)
            if let x = error {
                print("failed to reverse geocode location")
                print(x) // fallback
                self.captureLocationUpdateClosure?(nil)
                self.captureLocationUpdateClosure = nil
            }
        })
    }
}
