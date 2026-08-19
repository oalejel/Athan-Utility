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
import AVFoundation
#else
import ClockKit
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
class ObservableAthanManager: ObservableObject {
    static var shared = ObservableAthanManager()
        
    @Published var todayTimes: PrayerTimes!
    @Published var tomorrowTimes: PrayerTimes!
    @Published var yesterdayTimes: PrayerTimes!
    @Published var currentPrayer: Prayer! = .fajr
    @Published var locationName: String = ""
    @Published var qiblaHeading: Double = 0.0
    @Published var currentHeading: Double = 0.0
    @Published var locationPermissionsGranted = false
    @Published var appearance: AppearanceSettings = AppearanceSettings.defaultSetting()

    /// Set when the app has *automatically* updated the calculation method for the user's
    /// country (GPS- or locale-derived). Drives the bottom-floating "Updated Calculation
    /// Method" popup in MainSwiftUI, which lets the user Undo or acknowledge (OK). The
    /// change is already applied when this is set — the popup is a notice, not a prompt.
    @Published var methodUpdateNotice: MethodUpdateNotice? = nil
}

/// A record that the calculation method was auto-updated from `oldMethod` to `newMethod`
/// for a given country. Persisted to the app group so a change applied in the background
/// (e.g. during a widget refresh) still surfaces the popup the next time the app opens.
struct MethodUpdateNotice: Equatable, Identifiable, Codable {
    var id = UUID()
    let oldMethod: CalculationMethod
    let newMethod: CalculationMethod
    /// The ISO country code this update was derived from (GPS- or locale-based).
    let countryCode: String
}

// Defined here (rather than CalculationMethod+Extensions.swift) so it is available to
// every target that compiles AthanManager.swift — the extensions file is only in the app target.
extension CalculationMethod {
    /// Best-fit calculation method for a given ISO 3166-1 alpha-2 country code.
    /// Used to auto-suggest a method when the user's location/country is determined.
    /// Falls back to the Muslim World League method for any country not explicitly mapped.
    static func recommended(forISOCountryCode code: String) -> CalculationMethod {
        switch code.uppercased() {
        // Gulf states with their own official authorities
        case "SA": return .ummAlQura          // Umm al-Qura, Saudi Arabia
        case "AE": return .dubai               // UAE
        case "KW": return .kuwait              // Kuwait
        case "QA": return .qatar               // Qatar

        // South / Central Asia (University of Islamic Sciences, Karachi)
        case "PK", "IN", "BD", "AF": return .karachi

        // Iran
        case "IR": return .tehran              // Institute of Geophysics, University of Tehran

        // Turkey
        case "TR": return .turkey              // Diyanet

        // North America (ISNA)
        case "US", "CA", "MX": return .northAmerica

        // Southeast Asia (MUIS Singapore-style angles)
        case "SG", "MY", "BN": return .singapore

        // Egyptian General Authority of Survey (widely followed across N. Africa & Levant)
        case "EG", "SD", "LY", "DZ", "TN", "IQ", "SY", "LB", "JO", "YE":
            return .egyptian

        // Everyone else: Muslim World League
        default: return .muslimWorldLeague
        }
    }
}

class AthanManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = AthanManager()
    let locationManager = CLLocationManager()
    var heading: Double = 0.0 {
        didSet {
            ObservableAthanManager.shared.currentHeading = heading
        }
    }
    
    // will default to cupertino times at start of launch
    lazy var todayTimes: PrayerTimes! = nil {
        didSet {
            ObservableAthanManager.shared.todayTimes = self.todayTimes
        }
    }
    
    lazy var tomorrowTimes: PrayerTimes! = nil {
        didSet {
            ObservableAthanManager.shared.tomorrowTimes = self.tomorrowTimes
        }
    }
    
    lazy var yesterdayTimes: PrayerTimes! = nil {
        didSet {
            ObservableAthanManager.shared.yesterdayTimes = self.yesterdayTimes
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
            ObservableAthanManager.shared.locationPermissionsGranted = self.locationPermissionsGranted
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
        
        let newSettings = LocationSettings.shared.copy() as! LocationSettings // used for reference if we need a comparison for watchOS
        LocationSettings.shared = self.locationSettings
        LocationSettings.archive()
        
        ObservableAthanManager.shared.locationName = self.locationSettings.locationName
        ObservableAthanManager.shared.qiblaHeading = Qibla(coordinates:
                                                            Coordinates(latitude: self.locationSettings.locationCoordinate.latitude,
                                                                        longitude: self.locationSettings.locationCoordinate.longitude)).direction
        #if !os(watchOS)
        if WCSession.default.activationState == .activated && WCSession.default.isReachable {
            do {
                print("*** PHONE SENDING INFO MESSAGE ON LOCATION CHANGE FOR UNREACHABLE WATCH")
                let encoded = try PropertyListEncoder().encode(WatchPackage(locationSettings: self.locationSettings, prayerSettings: self.prayerSettings))
                WCSession.default.sendMessageData(encoded) { (respData) in
                    print(">>> got response from sending watch data")
                } errorHandler: { error in
                    print(">>> error from watch in sending data \(error)")
                }
            } catch {
                print(">>> unable to encode location settings response")
            }
        } else if WCSession.default.activationState == .activated {
            // also a complication update --- TODO: might need to track state for a pending settings change
            // in case we arent activated yet
            
            // read last sent coordinate sent via complication info dict -- dont want very frequent complication updates
            let LAT_KEY = "lastLat"
            let LON_KEY = "lastLon"
            let lastLat = UserDefaults.standard.double(forKey: LAT_KEY)
            let lastLon = UserDefaults.standard.double(forKey: LON_KEY)
            let estimatedLat = Int(lastLat * 100) // compare doubles with precision within 10 degrees
            let estimatedLon = Int(lastLon * 100)
            let comparedLat = Int(newSettings.locationCoordinate.latitude * 100) // must compare against old stored settings
            let comparedLon = Int(newSettings.locationCoordinate.longitude * 100)
            if estimatedLat != comparedLat || estimatedLon != comparedLon {
                // just send something to tell complications to update
                for existingTransfers in WCSession.default.outstandingUserInfoTransfers {
                    existingTransfers.cancel()
                }
                #warning("ensure we dont go over the limit for user info transfers")
                print("*** PHONE SENDING INFO DICT ON LOCATION CHANGE FOR UNREACHABLE WATCH")
                WCSession.default.transferCurrentComplicationUserInfo([
                    "locname" : self.locationSettings.locationName,
                    "latitude" : self.locationSettings.locationCoordinate.latitude,
                    "longitude" : self.locationSettings.locationCoordinate.longitude,
                    "currentloc" : self.locationSettings.useCurrentLocation,
                    "timezoneid" : self.locationSettings.timeZone.identifier
                ])
            }
        } else {
            print(">>>> NOT ACTIVATED")
        }
        #endif
        
        
        // if watchos, we may need to immediately updat ecomplications
        // but we need to be conservative with complication updsates, so confirm that location has changed
        #if os(watchOS)
        let LAT_KEY = "lastLat"
        let LON_KEY = "lastLon"
        let lastLat = UserDefaults.standard.double(forKey: LAT_KEY)
        let lastLon = UserDefaults.standard.double(forKey: LON_KEY)
        let estimatedLat = Int(lastLat * 100) // compare doubles with precision within 10 degrees
        let estimatedLon = Int(lastLon * 100)
        let comparedLat = Int(newSettings.locationCoordinate.latitude * 100) // must compare against old stored settings
        let comparedLon = Int(newSettings.locationCoordinate.longitude * 100)
        // if we have a signficant change in coordinates, save and update all complications
        print("comparing stored and new lats: \(estimatedLat), \(comparedLat)")
        if estimatedLat != comparedLat || estimatedLon != comparedLon {
            refreshTimes()
            
            print(">>> NEW LOCATION \(self.locationSettings.locationName) : update complications!")
            UserDefaults.standard.setValue(Double(self.locationSettings.locationCoordinate.latitude), forKey: LAT_KEY)
            UserDefaults.standard.setValue(Double(self.locationSettings.locationCoordinate.longitude), forKey: LON_KEY)
            
            let complicationServer = CLKComplicationServer.sharedInstance()
            guard let activeComplications = complicationServer.activeComplications else { // watchOS 2.2
                return
            }
            for complication in activeComplications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
        #endif
    }
    
    func appearanceSettingsDidSetHelper() {
        AppearanceSettings.shared = appearanceSettings
        AppearanceSettings.archive()
        ObservableAthanManager.shared.appearance = appearanceSettings
        // no need to send these over to watchos
    }
    
    // App lifecycle state tracking
    private var dayOfMonth = 0
    private var firstLaunch = true
    var currentPrayer: Prayer? {
        didSet {
            DispatchQueue.main.async {
                ObservableAthanManager.shared.currentPrayer = self.currentPrayer! // should never be nil after didSet
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
//        if let bundleID = Bundle.main.bundleIdentifier, bundleID != "com.omaralejel.Athan-Utility" {
//            reloadSettingsAndNotifications()
//        }
    }
    
    // safe way to update multiple settings so that all changes propogate to rest of UI
    // this is to avoid recalculating times for two different settings objects that can both
    // modify the times that we get. perhaps the solution was to not have them split up in the first place...
    //    func batchUpdateSettings(prayerSettings: PrayerSettings, notificationSettings: NotificationSettings, locationSettings: LocationSettings) {
    //        self.prayerSettings = prayerSettings
    //        self.notificationSettings = notificationSettings
    //        self.locationSettings = locationSettings // didset handles propogation to observable manager
    //    }
    
    // MARK: - Prayer Times
    
    /// A reference `Date` `days` calendar-days from today, in the given time zone.
    /// Uses calendar arithmetic (NOT `+ 86400`), so a DST-transition night — a
    /// 23- or 25-hour day — still resolves to the correct calendar day rather
    /// than skipping or repeating one when `now` is near midnight.
    private func adjacentDayReference(days: Int, timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.date(byAdding: .day, value: days, to: Date())
            ?? Date().addingTimeInterval(TimeInterval(days) * 86400)   // fallback only
    }

    /// Times for a day `days` either side of today, for the main screen's temporary
    /// day-browsing state. Goes through `adjacentDayReference` so a DST transition
    /// doesn't skip or repeat a day.
    func times(daysFromToday days: Int) -> PrayerTimes? {
        if days == 0 { return todayTimes }
        let tz = locationSettings.timeZone
        return calculateTimes(referenceDate: adjacentDayReference(days: days, timeZone: tz),
                              customTimeZone: tz,
                              adjustments: notificationSettings.adjustments())
    }

    func refreshTimes() {
        // swiftui publisher gets updates through didSet
        let tz = locationSettings.timeZone
        let adj = notificationSettings.adjustments()
        if let today = calculateTimes(referenceDate: Date(), customTimeZone: tz, adjustments: adj), let tomorrow = calculateTimes(referenceDate: adjacentDayReference(days: 1, timeZone: tz), customTimeZone: tz, adjustments: adj), let yesterday = calculateTimes(referenceDate: adjacentDayReference(days: -1, timeZone: tz), customTimeZone: tz, adjustments: adj) {
            todayTimes = today
            tomorrowTimes = tomorrow
            yesterdayTimes = yesterday
        } else {
            print("DANGER: unable to calculate times. TODO: handle this accordingly for places on the north pole.")
            // default back to settings defaults
            locationSettings = LocationSettings.defaultSetting()
            let dtz = locationSettings.timeZone
            todayTimes = calculateTimes(referenceDate: Date(), customTimeZone: dtz, adjustments: adj) // guaranteed fallback
            tomorrowTimes = calculateTimes(referenceDate: adjacentDayReference(days: 1, timeZone: dtz), customTimeZone: dtz, adjustments: adj)
            yesterdayTimes = calculateTimes(referenceDate: adjacentDayReference(days: -1, timeZone: dtz), customTimeZone: dtz, adjustments: adj)
        } // should never fail on cupertino time.
        // add 24 hours for next day
        currentPrayer = todayTimes.currentPrayer(at: athanNow()) ?? yesterdayTimes.currentPrayer(at: athanNow()) ?? .isha
        assert(todayTimes.currentPrayer(at: todayTimes.fajr.addingTimeInterval(-100)) == nil, "failed test on assumption about API nil values")
    }
    
    // NOTE: this function MUST not have SIDE EFFECTS
    func calculateTimes(referenceDate: Date, customCoordinate: CLLocationCoordinate2D? = nil, customTimeZone: TimeZone? = nil, adjustments: PrayerAdjustments?, prayerSettingsOverride: PrayerSettings? = nil) -> PrayerTimes? {
        let coord = locationSettings.locationCoordinate
        
        var cal = Calendar(identifier: Calendar.Identifier.gregorian)
        cal.timeZone = customTimeZone ?? cal.timeZone // if we want to pass a custom time zone not based on the device time zone
        let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
        let coordinates = Coordinates(latitude: customCoordinate?.latitude ?? coord.latitude, longitude: customCoordinate?.longitude ?? coord.longitude)
        
        // Either use override argument or global app settings
        let prayerSettings = prayerSettingsOverride ?? PrayerSettings.shared
        var params = prayerSettings.calculationMethod.params
        params.madhab = prayerSettings.madhab
        params.highLatitudeRule = prayerSettings.latitudeRule
        // custom minute offsets
        if let adjustments = adjustments {
            params.adjustments = adjustments
        }
        
        // handle ummAlQura +30m isha adjustment on ramadan
        // note: add +1day to reference date to account for taraweeh
        //      being on the night before the first day of ramadan
        let hijriCal = Calendar(identifier: .islamicUmmAlQura)
        // +1 calendar day (DST-safe) so taraweeh on the night before Ramadan's
        // first day gets the +30m isha adjustment.
        let refPlusDay = cal.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate.addingTimeInterval(24 * 60 * 60)
        let islamicComponents = hijriCal.dateComponents([.month], from: refPlusDay)
        if prayerSettings.calculationMethod == .ummAlQura && islamicComponents.month == 9 {
            params.adjustments.isha += 30
        }
        
        if let prayers = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params) {
            return prayers
        }
        return nil
    }
    
    // MARK: - Timers and timer callbacks
    
    var nextPrayerTimer: Timer?
    var reminderTimer: Timer?
    var newDayTimer: Timer?
    var tenSecondTimer: Timer?
    
    func resetTimers() {
        nextPrayerTimer?.invalidate()
        reminderTimer?.invalidate()
        newDayTimer?.invalidate()
        tenSecondTimer?.invalidate()
        nextPrayerTimer = nil
        reminderTimer = nil
        newDayTimer = nil
        tenSecondTimer = nil
        
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
        
        // time til next day — computed as the interval to the next local
        // midnight via calendar math, NOT `86400 - secondsSoFar`. On a DST
        // day that subtraction is off by ±1h (23-/25-hour day), firing the
        // new-day refresh an hour early or late. Use the location's time zone
        // so the day boundary matches the one prayer times are computed for.
        var dayCal = Calendar(identifier: .gregorian)
        dayCal.timeZone = locationSettings.timeZone
        let now = Date()
        let startOfTomorrow = dayCal.date(byAdding: .day, value: 1, to: dayCal.startOfDay(for: now)) ?? now.addingTimeInterval(86400)
        let remainingSecondsInDay = startOfTomorrow.timeIntervalSince(now)
        print("\(remainingSecondsInDay / 3600) hours left today")
        newDayTimer = Timer.scheduledTimer(timeInterval: remainingSecondsInDay + 1, // +1 to account for slight error
                                           target: self, selector: #selector(newDay),
                                           userInfo: nil, repeats: false)
    }
    
    private func watchForImminentPrayerUpdate() {
        // enter a background thread loop to wait on a change in case this timer is triggered too early
        let samplePrayer = todayTimes.currentPrayer(at: athanNow())
        let nextTime = guaranteedNextPrayerTime()
        let timeUntilChange = nextTime.timeIntervalSince(Date())
        if timeUntilChange < 5 && timeUntilChange > 0 {
            DispatchQueue.global().async {
                // wait on a change
                while (samplePrayer == self.todayTimes.currentPrayer(at: athanNow())) {
                    // do nothing
                } // on break, we can update our prayer
                DispatchQueue.main.async {
                    self.currentPrayer = self.todayTimes.currentPrayer(at: athanNow()) ?? self.yesterdayTimes.currentPrayer(at: athanNow()) ?? .isha
                }
            }
        } else {
            currentPrayer = todayTimes.currentPrayer(at: athanNow()) ?? self.yesterdayTimes.currentPrayer(at: athanNow()) ?? .isha
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
        reloadSettingsAndNotifications()
    }
    
    // MARK: - Helpers
    
    // calculate next prayer, considering next day's .fajr time in case we are on isha time
    func guaranteedNextPrayerTime() -> Date {
        let currentPrayer = todayTimes.currentPrayer(at: athanNow())
        // do not use api nextPrayeras it does not distinguish tomorrow fajr from today fajr nil
        // New: also account for cases where high latitudes have isha after 12am
        //        var nextPrayer: Prayer? = todayTimes.nextPrayer()
        var nextPrayerTime: Date! = nil
        if currentPrayer == .isha { // case for reading from tomorrow fajr times
            nextPrayerTime = tomorrowTimes.fajr
        } else if self.yesterdayTimes.currentPrayer(at: athanNow()) != nil && self.yesterdayTimes.currentPrayer(at: athanNow()) == .maghrib {
            // happens in cases that times extend to next day (isha after 12)
            // this case is true when isha from yday hasn't technically started yet
            nextPrayerTime = yesterdayTimes.isha
        } else if currentPrayer == nil { // case for reading from today's fajr times
            nextPrayerTime = todayTimes.fajr
        } else { // otherwise, next prayer time is based on today
            nextPrayerTime = todayTimes.time(for: currentPrayer!.next())
        }
        
        return nextPrayerTime
    }

    /// The prayer that `guaranteedNextPrayerTime()` refers to — mirrors its branching so the
    /// name and time always agree (handles day rollover and late-isha edge cases).
    func guaranteedNextPrayer() -> Prayer {
        let currentPrayer = todayTimes.currentPrayer(at: athanNow())
        if currentPrayer == .isha { return .fajr }
        if self.yesterdayTimes.currentPrayer(at: athanNow()) != nil && self.yesterdayTimes.currentPrayer(at: athanNow()) == .maghrib {
            return .isha
        }
        if currentPrayer == nil { return .fajr }
        return currentPrayer!.next()
    }

    func guaranteedCurrentPrayerTime() -> Date {
        var currentPrayer: Prayer? = todayTimes.currentPrayer(at: athanNow())
        var currentPrayerTime: Date! = nil
        if currentPrayer == nil { // case of new day before fajr
            // if yesterday maghrib is still "current", we are in exceptional case where isha is after 12 am
            if self.yesterdayTimes.currentPrayer(at: athanNow()) != nil && self.yesterdayTimes.currentPrayer(at: athanNow()) == .maghrib {
                currentPrayer = .maghrib
                currentPrayerTime = yesterdayTimes.maghrib
            } else {
                currentPrayer = .isha
                currentPrayerTime = yesterdayTimes.isha // use yesterday's isha time
            }
        } else {
            currentPrayerTime = todayTimes.time(for: currentPrayer!)
        }
        return currentPrayerTime
    }
}

// Listen for background events
extension AthanManager {
    // MARK: - Calculation-method suggestion

    /// UserDefaults key for the last country we already auto-updated the method for, so we
    /// only auto-update once per country (until the country changes) and never fight a
    /// deliberate later choice by the user.
    /// App-group defaults, shared between the app and the widget so a method update applied
    /// during a background widget refresh can surface the popup the next time the app opens.
    private var groupDefaults: UserDefaults? { UserDefaults(suiteName: "group.athanUtil") }

    private static let handledSuggestionCountryKey = "AthanHandledSuggestionCountry"
    /// App-group backed, NOT UserDefaults.standard. The widget extension has its own
    /// standard defaults, so a per-process record meant the widget never saw what the app
    /// had already handled: it would re-apply the recommendation and persist a fresh
    /// notice, and the popup then appeared on next launch with the user having changed
    /// nothing. One shared record keeps "we already decided about this country" true for
    /// both processes.
    private var handledSuggestionCountry: String? {
        get { groupDefaults?.string(forKey: Self.handledSuggestionCountryKey) }
        set { groupDefaults?.set(newValue, forKey: Self.handledSuggestionCountryKey) }
    }

    private static let pendingNoticeKey = "AthanPendingMethodUpdateNotice"

    private func persistPendingNotice(_ notice: MethodUpdateNotice?) {
        guard let d = groupDefaults else { return }
        if let notice, let data = try? JSONEncoder().encode(notice) {
            d.set(data, forKey: Self.pendingNoticeKey)
        } else {
            d.removeObject(forKey: Self.pendingNoticeKey)
        }
    }

    /// Any auto-update the user hasn't yet acknowledged (Undo/OK). Read on app launch so a
    /// background change (widget refresh) still shows the popup.
    func loadPendingMethodUpdateNotice() -> MethodUpdateNotice? {
        guard let d = groupDefaults, let data = d.data(forKey: Self.pendingNoticeKey) else { return nil }
        return try? JSONDecoder().decode(MethodUpdateNotice.self, from: data)
    }

    /// Best ISO 3166-1 alpha-2 country code we can infer from the information the user
    /// has shared: the GPS-derived country if available, otherwise the device's region
    /// (locale) so we can still suggest a method when location isn't shared.
    func bestAvailableCountryCode() -> String? {
        if let gps = locationSettings.countryCode, !gps.isEmpty { return gps.uppercased() }
        if #available(iOS 16, watchOS 9, *) {
            if let region = Locale.current.region?.identifier, !region.isEmpty { return region.uppercased() }
        }
        return Locale.current.regionCode?.uppercased()
    }

    /// Automatically switches the calculation method to the one recommended for `countryCode`
    /// (if different), archives it so widget/times reflect it even without opening the app,
    /// and records a notice that drives the "Updated Calculation Method" popup (with Undo).
    ///
    /// Only acts once per country: after an auto-update (or after skipping to preserve a
    /// returning user's deliberate choice) we stay quiet for that country until it changes.
    ///
    /// - Parameter rescheduleNotifications: pass `false` from the widget extension, which
    ///   must not reschedule notifications; the app reschedules on its next foreground.
    /// - Parameter userChangedLocation: `true` when the user just set the location by hand
    ///   (or tapped "use current location"). Both quiet-mode guards are skipped in that
    ///   case — see below.
    /// - Returns: `true` if the method was actually changed.
    /// Carry the old per-process record into the shared one, once, so upgrading doesn't
    /// look like "we've never handled any country" and fire a popup immediately.
    func migrateHandledSuggestionCountryIfNeeded() {
        guard groupDefaults?.string(forKey: Self.handledSuggestionCountryKey) == nil,
              let legacy = UserDefaults.standard.string(forKey: Self.handledSuggestionCountryKey) else { return }
        groupDefaults?.set(legacy, forKey: Self.handledSuggestionCountryKey)
    }

    @discardableResult
    func autoUpdateMethodIfNeeded(for countryCode: String?,
                                  rescheduleNotifications: Bool = true,
                                  userChangedLocation: Bool = false) -> Bool {
        // Never during a screenshot run: the notice floats over whatever is being
        // captured. Checked inline rather than via SnapshotSupport because this file also
        // compiles into the widget/Siri/watch targets, which don't include that type.
        if CommandLine.arguments.contains("-UITEST_DEMO")
            || CommandLine.arguments.contains("-UITEST_INTRO")
            || CommandLine.arguments.contains("-UITEST_DISCOVER") { return false }
        guard let code = countryCode?.uppercased(), !code.isEmpty else { return false }
        let recommended = CalculationMethod.recommended(forISOCountryCode: code)
        let current = prayerSettings.calculationMethod
        guard recommended != current else { return false }

        // Both guards below exist to keep *passive* evaluation (every launch, every widget
        // refresh) from nagging or from stomping a deliberate choice. Neither should apply
        // when the user has just told us where they are: that is exactly the moment they
        // expect the method to follow, and the first-evaluation guard in particular used to
        // swallow the very first manual location change a user ever made.
        if !userChangedLocation {
            // Only act once per country until it changes.
            guard handledSuggestionCountry != code else { return false }

            // First time we ever evaluate for a user who already finished setup (e.g. an
            // upgrade): don't override their deliberate method — just remember the country
            // so future *changes* (travel) still auto-update.
            if handledSuggestionCountry == nil && IntroSetupFlags.hasCompletedCalculationSetup {
                handledSuggestionCountry = code
                return false
            }
        }
        handledSuggestionCountry = code

        // Apply immediately (the didSet helper archives to the app group).
        let updated = prayerSettings.copy() as! PrayerSettings
        updated.calculationMethod = recommended
        prayerSettings = updated

        let notice = MethodUpdateNotice(oldMethod: current, newMethod: recommended, countryCode: code)
        persistPendingNotice(notice)

        if rescheduleNotifications {
            reloadSettingsAndNotifications() // reschedules notes + reloads widgets (app context)
        }
        DispatchQueue.main.async {
            ObservableAthanManager.shared.methodUpdateNotice = notice
        }
        return true
    }

    /// Reverts the auto-updated method back to what it was before, and remembers the country
    /// so we don't immediately re-apply the recommendation.
    func undoMethodUpdate(_ notice: MethodUpdateNotice) {
        handledSuggestionCountry = notice.countryCode
        let updated = prayerSettings.copy() as! PrayerSettings
        updated.calculationMethod = notice.oldMethod
        prayerSettings = updated
        reloadSettingsAndNotifications()
        persistPendingNotice(nil)
        DispatchQueue.main.async { ObservableAthanManager.shared.methodUpdateNotice = nil }
    }

    /// Marks the auto-update as acknowledged (user tapped OK) so it won't resurface.
    func acknowledgeMethodUpdate() {
        persistPendingNotice(nil)
        DispatchQueue.main.async { ObservableAthanManager.shared.methodUpdateNotice = nil }
    }

    func reloadSettingsAndNotifications() {
        // reload settings in case we are running widget and app changed them
        if let arch = LocationSettings.checkArchive() { locationSettings = arch }
        if let arch = NotificationSettings.checkArchive() { notificationSettings = arch }
        if let arch = PrayerSettings.checkArchive() { prayerSettings = arch }
        if let arch = AppearanceSettings.checkArchive() { appearanceSettings = arch }
        
        // unconditional update of day of month
        dayOfMonth = Calendar.current.component(.day, from: Date())
        refreshTimes()
        
        // always make notifications if user has edited from the default location
        if locationSettings.locationName != LocationSettings.defaultSetting().locationName {
            #if !os(watchOS) // dont schedule notes in watchos app
            NotificationsManager
                .createNotifications(coordinate: locationSettings.locationCoordinate,
                                     calculationMethod: prayerSettings.calculationMethod,
                                     madhab: prayerSettings.madhab,
                                     noteSettings: notificationSettings,
                                     shortLocationName: locationSettings.locationName)
            resetWidgets() // should happen when any of our settings change

            // Refresh the rolling AlarmKit window (iOS 26+). Gated on the
            // main-app bundle so widget / Siri / watch extension contexts
            // don't each try to schedule their own alarms. No-op pre-26 or
            // when the user hasn't enabled the feature.
            if let bundleID = Bundle.main.bundleIdentifier, bundleID == "com.omaralejel.Athan-Utility" {
                FajrAlarmManager.shared.syncAlarms()
            }
            
            #if !targetEnvironment(macCatalyst)
            if #available(iOS 16.2, *) {
                // Live Activities disabled: they linger after app is closed (pending fix)
                cleanupSuhoorActivity()
            } else {
                // Fallback on earlier versions
            }
            #endif
            #endif
        }
        
        #warning("may no longer need these timers with swiftui timers")
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
        reloadSettingsAndNotifications() // avoid making new notifications if not needed
        
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
                                                                        coord: locations.first!.coordinate, timeZone: timeZone, useCurrentLocation: true, countryCode: country)
                    
                    if let captureClosue = self.captureLocationUpdateClosure  {
                        captureClosue(potentialNewLocationSettings)
                        self.captureLocationUpdateClosure = nil
                    } else { // if this request is to be considered for storage (not captured in closure):
                        let oldRoundedLat = Int(self.locationSettings.locationCoordinate.latitude * 100)
                        let oldRoundedLon = Int(self.locationSettings.locationCoordinate.longitude * 100)
                        let newRoundedLat = Int(potentialNewLocationSettings.locationCoordinate.latitude * 100)
                        let newRoundedLon = Int(potentialNewLocationSettings.locationCoordinate.longitude * 100)
                        
                        // logical subexpressions qualifying for an update:
                        let sameCoordinate = oldRoundedLat == newRoundedLat && oldRoundedLon == newRoundedLon
                        // MUST check that new placemark is non-nil, otherwise we could be taking in nameless coords
                        let isNewName = placemark.name != nil && potentialNewLocationSettings.locationName != self.locationSettings.locationName
                        //                        if self.locationSettings.locationName != potentialNewLocationSettings.locationName {
                        if !sameCoordinate || (sameCoordinate && isNewName) {
                            // if not same location, OR we now have a placemark name for the location, update location settings
                            self.locationSettings = potentialNewLocationSettings
                            self.reloadSettingsAndNotifications()
                            // Auto-update the method for the freshly determined country. The
                            // change is applied + archived; the app surfaces an Undo popup.
                            self.autoUpdateMethodIfNeeded(for: potentialNewLocationSettings.countryCode)
                        }
                    }
                    return
                }
            }
            
            // falls through here if we failed to geocode

            // Losing the network is the common reason to land here, not standing somewhere
            // genuinely unnameable. If this fix is the same place we already have a name
            // for, keep everything we know: overwriting "Bloomfield Hills, MI" with
            // "42.58°, -83.24°" — and discarding the placemark's time zone and country code
            // along with it — is strictly worse than leaving the saved location alone. The
            // country code especially, since the auto-method logic reads it.
            let newCoord = locations.first!.coordinate
            let sameAsSaved = Int(self.locationSettings.locationCoordinate.latitude * 100) == Int(newCoord.latitude * 100)
                && Int(self.locationSettings.locationCoordinate.longitude * 100) == Int(newCoord.longitude * 100)
            if sameAsSaved {
                print("reverse geocode failed, but the coordinate is unchanged — keeping the saved location name")
                if let captureClosure = self.captureLocationUpdateClosure,
                   let kept = self.locationSettings.copy() as? LocationSettings {
                    captureClosure(kept)
                    self.captureLocationUpdateClosure = nil
                }
                self.reloadSettingsAndNotifications()
                return
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
            
            self.reloadSettingsAndNotifications()
            
            // once done dealing with error, print that we encountered an error
            if let x = error {
                print("failed to reverse geocode location")
                print(x) // fallback
                self.captureLocationUpdateClosure?(nil)
                self.captureLocationUpdateClosure = nil
            }
        })
    }
}
