//
//  PrayerManager.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/9/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

/*
 PrayerManager
 
 */

import UIKit
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

//import WatchConnectivity



enum PrayerType: Int {
    case fajr, shurooq, thuhr, asr, maghrib, isha, none
    func stringValue() -> String {
        switch self {
        case .fajr:
            return "Fajr"
        case .shurooq:
            return "Shurooq"
        case .thuhr:
            return "Thuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
        case .none:
            return "This should not be visible"
        }
    }
    
    //incrementors
    func next() -> PrayerType {
        if self == .isha {return .fajr}
        if self == .none {return .fajr}//none can happen when it is a new day
        return PrayerType(rawValue: self.rawValue + 1)!
    }
    func previous() -> PrayerType {
        if self == .fajr {return .isha}
        return PrayerType(rawValue: self.rawValue - 1)!
    }
}

enum AlarmSetting: Int {
    case all, noEarly, none
}

class PrayerSetting {
    var soundEnabled = true
    var alarmType = AlarmSetting.all
}

class PrayerManager: NSObject, CLLocationManagerDelegate {
    enum OtherData: Int {
        case qibla, city, state, country
    }
    
    //location services data provider
    fileprivate let coreManager = CLLocationManager()
    
    var currentPrayer: PrayerType = PrayerType.fajr //default prayer before arrival of data. should be based on a plist int
    
    //important data that comes from the coremanager
    var currentCityString: String?
    var currentStateString: String?
    var currentCountryString: String?
    var currentDistrictString: String?
    var locationString: String?
    
    var currentDay: Int!
    var currentMonth: Int!
    var currentYear: Int!
    
    //website JSON data request session
    fileprivate var session: URLSession!
    
    //    var URLString: String {
    //        get {
    //            return "https://muslimsalat.com/\(currentCityString!)\(currentStateString!)\(currentCountryString!)/yearly.json?key=7a28c064c1ea9d2779baf747f45b2f85"
    //        }
    //    }
    
    func URLString(_ arg1: String?, arg2: String?, arg3: String?, arg4: String?) -> URL? {
        let urlStr = "https://muslimsalat.com/\(arg1  ?? "")+\(arg2 ?? "")+\(arg3 ?? "")+\(arg4 ?? "")/yearly/true.json"
        print(urlStr)
        return URL(string: urlStr)
    }
    
    func standardURL() -> URL? {
        return URLString(currentCityString, arg2: currentDistrictString, arg3: currentStateString, arg4: currentCountryString)
    }
    
    
    
    var qibla: Double! = 0
    
    var monthTimes: [Int : [PrayerType : Date]] = Dictionary()
    var todayPrayerTimes: [PrayerType : Date] = Dictionary()
    var tomorrowPrayerTimes: [PrayerType : Date] = Dictionary()
    var yesterdayPrayerTimes: [PrayerType : Date] = Dictionary()
    
    //access by [year][month][day]
    var yearTimes: [Int : [Int : [Int : [PrayerType : Date]]]] = Dictionary()
    
    //for settings with alarms
    var timesSettings: [PrayerType : AlarmSetting]!
    var soundsSettings: [PrayerType : Bool] = [:]
    //ultimate settings object..
    var prayerSettings: [PrayerType : PrayerSetting] = [:]
    
    var delegate: PrayerManagerDelegate!
    
    var fetchCompletionClosure: (() -> ())?
    var lastFetchSuccessful = false
    
    var getData = true
    var dataAvailable = false
    
    weak var headingDelegate: HeadingDelegate? {
        didSet {
            //getting heading data for qibla
            if headingDelegate != nil {
                if qibla != nil {
                    coreManager.startUpdatingHeading()
                }
            } else {
                coreManager.stopUpdatingHeading()
            }
        }
    }
    
    //MARK: - Initializer
    
    init(delegate: PrayerManagerDelegate) {
        self.delegate = delegate
        super.init()
        
        delegate.manager = self
        
        getSettings()
        
        let conf = URLSessionConfiguration.default
        session = URLSession(configuration: conf, delegate: nil, delegateQueue: nil)
        
        //first, check the file, if there is useful data, use it, then get data from online without slowing things down
        if let dict = dictionaryFromFile() {
            parseDictionary(dict, fromFile: true)
        } else {
            delegate.showLoader()
        }
        
        //dispatch_async(dispatch_get_main_queue()) { () -> Void in
        self.coreManager.delegate = self
        self.coreManager.desiredAccuracy = kCLLocationAccuracyHundredMeters //can change for eff.
        
        self.coreManager.requestWhenInUseAuthorization()
        
        self.coreManager.startUpdatingLocation()
        
        //simulator must do this since it has no location services
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            print("Building for ios simulator")
            self.currentCityString = "Everett"
            self.currentCountryString = "US"
            self.currentStateString = "WA"
            self.fetchJSONData(nil)
        #endif
        //}
        
        //        if #available(iOS 9.0, *) {
        //            if WCSession.isSupported() {
        //                let session = WCSession.defaultSession()
        //                session.delegate = self
        //                session.activateSession()
        //            }
        //        } else {
        //            // Fallback on earlier versions
        //        }
    }
    
    
    //MARK: - Location Services
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        coreManager.stopUpdatingLocation()//change if stopping without getting reliable info
        
        
        
        CLGeocoder().reverseGeocodeLocation(locations.first!, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) -> Void in
            if let x = error {
                print(x)
            } else {
                if placemarks?.count > 0 {
                    let placemark = placemarks![0]
                    let cityWithSpaces = placemark.locality
                    let cityNoSpaces = cityWithSpaces?.replacingOccurrences(of: " ", with: "+")
                    self.currentCityString = cityNoSpaces
                    self.currentDistrictString = placemark.subAdministrativeArea
                    self.currentStateString = placemark.administrativeArea
                    self.currentCountryString = placemark.isoCountryCode
                    self.fetchJSONData(nil)
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingDelegate?.newHeading(newHeading)
    }
    
    
    //MARK: - Data Management
    
    func getSettings() {
        let dict = NSKeyedUnarchiver.unarchiveObject(withFile: settingsArchivePath().path) as? [String:AnyObject]
        if let prayersDict = dict?["prayersettings"] as? [String:AnyObject] {
            for i in 0...5 {
                let p = PrayerType(rawValue: i)!
                let pSettingDict = prayersDict[p.stringValue()]
                let s = PrayerSetting()
                if let at = pSettingDict?["alarmtype"] as? NSNumber {
                    s.alarmType = AlarmSetting(rawValue: Int(at))!
                    if let sound = pSettingDict?["soundenabled"] as? Bool {
                        s.soundEnabled = sound
                    }
                }
                prayerSettings[p] = s
            }
        } else {
            for i in 0...5 {
                let s = PrayerSetting()
                let p = PrayerType(rawValue: i)!
                prayerSettings[p] = s
            }
        }
    }
    
    func saveSettings() {
        var allSettingsDict = [String:[String:AnyObject]]()
        for i in 0...5 {
            let p = PrayerType(rawValue: i)!
            var settingDict: [String:AnyObject] = [:]
            let specificSettings = prayerSettings[p]
            settingDict["alarmtype"] = specificSettings?.alarmType.rawValue as AnyObject
            settingDict["soundenabled"] = specificSettings?.soundEnabled as AnyObject
            allSettingsDict[p.stringValue()] = settingDict
        }
        
        NSKeyedArchiver.archiveRootObject(["prayersettings":allSettingsDict], toFile: settingsArchivePath().path)
    }
    
    //gets data from website then calls the parseJSONData function
    func fetchJSONData(_ searchString: String?) {
        self.lastFetchSuccessful = false
        var URL: Foundation.URL?
        if let s = searchString {
            URL = URLString(s, arg2: "", arg3: "", arg4: "")
        } else {
            URL = standardURL()
        }
        //! dont forget to set this back to true if the app is on for a long time!!!
        if getData {
            getData = false
            //get url from url string
            
            if let sureURL = URL {
                print("going to request data")
                let request = URLRequest(url: sureURL)
                let dataTask = session.dataTask(with: request, completionHandler: {
                    (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    if error != nil {
                        print("here")
                        self.getData = true
                    }
                    
                    if let sureData = data {
                        //this also stores to a file
                        let JSON = (try? JSONSerialization.jsonObject(with: sureData, options: [])) as? NSDictionary
                        if let sureJSON = JSON {
                            self.parseDictionary(sureJSON, fromFile: false)
                            print("got data from online!")
                        }
                    }
                    if let closure = self.fetchCompletionClosure {
                        closure()
                    }
                })
                
                dataTask.resume()
            } else {
                if let closure = self.fetchCompletionClosure {
                    closure()
                }
            }
        }
    }
    
    func tryRequestWithSearch(_ search: String) -> Bool {
        
        return false
    }
    
    func dictionaryFromFile() -> NSDictionary? {
        let dict = NSKeyedUnarchiver.unarchiveObject(withFile: prayersArchivePath().path) as? NSDictionary
        return dict
    }
    
    func setCurrentDates() {
        let df = Global.dateFormatter
        //get the date info for today to use for computation
        let curDate = Date()
        Global.dateFormatter.dateFormat = "y"
        currentYear = Int(df.string(from: curDate))
        Global.dateFormatter.dateFormat = "d"
        currentDay = Int(df.string(from: curDate))
        Global.dateFormatter.dateFormat = "M"
        currentMonth = Int(df.string(from: curDate))
    }
    
    //this organizes the data and notifies the delegate
    func parseDictionary(_ dict: NSDictionary, fromFile: Bool) {
        if var sureDict = dict as? Dictionary<String, AnyObject> {
            //for some reason printing this will cause a different part ot crash?
            print("JSON: \(sureDict)")
            
            if let x = sureDict["address"] as? String {
                if x != "" {
                    lastFetchSuccessful = true
                    locationString = x
                } else {
                    return
                }
            } else {
                return
            }
            print("location: \(locationString)")
            
            print(sureDict["qibla_direction"]!)
            if let a = sureDict["qibla_direction"] as? Double {
                //if let q = qString.doubleValue as? Double {
                qibla = a
                //}
            }
            
            if let qString = sureDict["qibla_direction"] as? NSString {
                qibla = qString.doubleValue
            }
            
            
            //get prayer times in text and parse into dates
            if let daysArray = sureDict["items"] as? NSArray {
                //add days in months
                var dayOffset = 0
                let df = Global.dateFormatter
                
                setCurrentDates()
                
                //below will be different if from a file in the past
                var startMonth = currentMonth
                var startYear = currentYear
                var startDay = currentDay
                
                //check to see if data is still up to date
                if fromFile {
                    
                    //if same year, continue
                    if let yearReceievedString = sureDict["year_recieved"] as? String {
                        let yearReceieved = Int(yearReceievedString)
                        
                        //find the index we want to start reading from
                        if let monthRecievedString = sureDict["month_recieved"] as? String {
                            let monthRecieved = Int(monthRecievedString)!
                            
                            //find the index we want to start reading from
                            if let dayRecievedString = sureDict["day_recieved"] as? String {
                                let dayRecieved = Int(dayRecievedString)!
                                
                                startYear = yearReceieved
                                startMonth = monthRecieved
                                startDay = dayRecieved
                                
                                if currentMonth == monthRecieved {
                                    dayOffset = currentDay - dayRecieved
                                } else {
                                    //might need to something
                                    dayOffset += daysInMonth(monthRecieved) - dayRecieved
                                    dayOffset += currentDay
                                    if currentMonth - 1 != monthRecieved {
                                        for m in (monthRecieved + 1)...(currentMonth - 1) {
                                            dayOffset += daysInMonth(m)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                let swiftDaysArray = daysArray as! [[String : String]]
                let prayers: [PrayerType] = [.fajr, .shurooq, .thuhr, .asr, .maghrib, .isha]
                let customNames = ["fajr", "shurooq", "dhuhr", "asr", "maghrib", "isha"]
                
                //will change throughout the days
                var yearIncrementor = startYear!
                var monthIncrementor = startMonth!
                var dayIncrementor = startDay!
                //loop through all of the days and adjust the date each one is from using MATHS
                
                //!!! remember to look at this!!!
                var limiter = 40
                for (_, dayDict) in swiftDaysArray.enumerated() {
                    limiter -= 1
                    if limiter == 0 {break}
                    for p in prayers {
                        //get the time for the prayer on the day, and then adjust turn into NSDate
                        var timeString = dayDict[customNames[p.rawValue]]! as String
                        df.dateFormat = "h:m a d:M:y"
                        timeString = "\(timeString) \(dayIncrementor):\(monthIncrementor):\(yearIncrementor)"
                        let theDate = df.date(from: timeString)
                        
                        if yearTimes[yearIncrementor] == nil {
                            yearTimes[yearIncrementor] = [:]
                        }
                        if yearTimes[yearIncrementor]![monthIncrementor] == nil {
                            yearTimes[yearIncrementor]![monthIncrementor] = [:]
                        }
                        if yearTimes[yearIncrementor]![monthIncrementor]![dayIncrementor] == nil {
                            yearTimes[yearIncrementor]![monthIncrementor]![dayIncrementor] = [:]
                        }
                        
                        yearTimes[yearIncrementor]![monthIncrementor]![dayIncrementor]![p] = theDate
                    }
                    
                    if daysInMonth(monthIncrementor) == dayIncrementor {
                        if monthIncrementor == 12 {
                            //new year
                            yearIncrementor += 1
                            monthIncrementor = 1
                            dayIncrementor = 1
                        } else {
                            //new month
                            monthIncrementor += 1
                            dayIncrementor = 1
                        }
                    } else {
                        //new day
                        dayIncrementor += 1
                    }
                    
                }
                
                alignPrayerTimes()
                
                calculateCurrentPrayer()
                notifyDelegate()
                
                //must call set timers after updatecurrent prayer is called
                setTimers()
                
                
                //need to define number of alarms in a day to a different number based on whtat the user selects to get notifications for
                //!! might want to check if notifications have been allowed...
                // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                // })
                
                scheduleAppropriateNotifications()
                
                
                if !fromFile {
                    //                    if #available(iOS 9.0, *) {
                    //                        if WCSession.isSupported() {
                    //                            for transfer in WCSession.defaultSession().outstandingFileTransfers {
                    //                                transfer.cancel()
                    //                            }
                    //                            WCSession.defaultSession().transferFile(prayersArchivePath(), metadata: nil)
                    //                        }
                    //                    }
                    
                    //archive the dictionary
                    sureDict["day_recieved"] = currentDay as AnyObject?
                    sureDict["month_recieved"] = currentMonth as AnyObject?
                    sureDict["year_recieved"] = currentYear as AnyObject?
                    let objc = sureDict as NSDictionary
                    NSKeyedArchiver.archiveRootObject(objc, toFile: prayersArchivePath().path)
                    
                }
            } else {return}
        }
        
        if #available(iOS 9.0, *) {
            let icon = UIApplicationShortcutIcon(type: .location)
            let dynamicItem = UIApplicationShortcutItem(type: "qibla", localizedTitle: "Qibla", localizedSubtitle: nil, icon: icon, userInfo: nil)
            UIApplication.shared.shortcutItems = [dynamicItem]
        }
    }
    
    func alignPrayerTimes() {
        todayPrayerTimes = yearTimes[currentYear]![currentMonth]![currentDay]!
        
        var tomorrowDay = currentDay
        var tomorrowMonth = currentMonth
        var tomorrowYear = currentYear
        if currentDay == daysInMonth(currentMonth) {
            if currentMonth == 12 {
                //new year
                tomorrowYear! += 1
                tomorrowDay = 1
                tomorrowMonth = 1
            } else {
                //new month
                tomorrowMonth! += 1
                tomorrowDay = 1
            }
        } else {
            tomorrowDay! += 1
        }
        if let tomorrow = yearTimes[tomorrowYear!]?[tomorrowMonth!]?[tomorrowDay!] {
            tomorrowPrayerTimes = tomorrow
        }
        
        var yesterdayDay = currentDay
        var yesterdayMonth = currentMonth
        var yesterdayYear = currentYear
        if currentDay == 1 {
            if currentMonth == 1 {
                //new year
                yesterdayYear! -= 1
                yesterdayDay = daysInMonth(12)
                yesterdayMonth = 12
            } else {
                //new month
                yesterdayMonth! -= 1
                yesterdayDay = daysInMonth(yesterdayMonth!)
            }
        } else {
            yesterdayDay! -= 1
        }
        //!!! important: need to make sure that we also have last month's prayer times if 1st day of month!!!
        if let yesterday = yearTimes[yesterdayYear!]?[yesterdayMonth!]?[yesterdayDay!] {
            yesterdayPrayerTimes = yesterday
        }
        
    }
    
    func scheduleAppropriateNotifications() {
        //remove this later??!
        UIApplication.shared.cancelAllLocalNotifications()
        
        var scheduled = 0
        //create a notification for every day
        outerLoop: for year in self.yearTimes.keys.sorted() {
            if year < self.currentYear {continue} //go to the next year or quit
            for month in self.yearTimes[year]!.keys.sorted() {
                if year == self.currentYear {
                    if month < self.currentMonth {continue} //if its the same y but m is old, then next
                }
                for day in self.yearTimes[year]![month]!.keys.sorted() {
                    if month == self.currentMonth {
                        if day < self.currentDay {continue} //return if the day is passed if current m
                    }
                    
                    var finalNotificationDay = false
                    if scheduled + 12 >= 60 {
                        finalNotificationDay = true
                    }
                    self.createNotificationsForDayItemTuple((year, month, day), finalFlag: finalNotificationDay)
                    
                    //limit to 60 notifications (12 per day)
                    scheduled += 12
                    print("scdeduled: \(scheduled)")
                    if scheduled >= 60 {
                        break outerLoop
                    }
                }
            }
        }
    }
    
    
    func notifyDelegate() {
        dataAvailable = true
        delegate?.dataReady(manager: self)
    }
    
    func calculateCurrentPrayer() {
        self.currentPrayer = .none//in case its a new day and fajr didnt start
        let curDate = Date()
        
        for i in 0...5 {
            let p = PrayerType(rawValue: i)!
            //ascending if the compared one is greater
            if curDate.compare(self.todayPrayerTimes[p]!) == ComparisonResult.orderedDescending {
                //WARNING: THIS MIGHT FAIL WHEN THE DATE IS AFTER
                self.currentPrayer = PrayerType(rawValue: p.rawValue)!//select the previous date prayer
            } else {
                return
            }
        }
    }
    
    func setTimers() {
        //set the prayer timers
        let curDate = Date()
        print(currentPrayer)
        if currentPrayer != .isha {
            var startIndex = currentPrayer.rawValue + 1
            if currentPrayer == .none {
                startIndex = 0
            }
            for i in (startIndex)...5 {
                let p = PrayerType(rawValue: i)!
                let pDate = todayPrayerTimes[p]!
                
                //timer for highlight red for 15 mins left
                Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate) - 900, target: self, selector: #selector(PrayerManagerDelegate.fifteenMinutesLeft), userInfo: nil, repeats: false)
                //timer for new prayer
                Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate), target: self, selector: #selector(PrayerManager.newPrayer), userInfo: nil, repeats: false)
            }
        }
        
        let cal = Calendar.current
        var comps = (cal as NSCalendar).components([.year, .month, .day, .hour], from: curDate)
        if comps.hour! >= 12 {
            comps.hour = 24
        } else {
            comps.hour = 12
        }
        let nextMeridDate = cal.date(from: comps)
        let nextMeridInterval = nextMeridDate?.timeIntervalSince(curDate)
        
        Timer.scheduledTimer(timeInterval: nextMeridInterval!, target: self, selector: #selector(PrayerManagerDelegate.newMeridiem), userInfo: nil, repeats: false)
        
        
        DispatchQueue.main.async { () -> Void in
            var seconds = 0
            var minutes = 0
            var hours = 0
            let df = Global.dateFormatter
            df.dateFormat = "s"
            seconds = Int(df.string(from: curDate))!
            df.dateFormat = "m"
            minutes = Int(df.string(from: curDate))!
            df.dateFormat = "k"//tried: hh, h,
            hours = Int(df.string(from: curDate))!
            
            
            //set the newday timer
            let secondsInDay: Int? = seconds + (minutes * 60) + ((hours % 24) * 3600)
            if secondsInDay != nil {
                let secondsLeft = 86400 - secondsInDay!
                Timer.scheduledTimer(timeInterval: TimeInterval(secondsLeft), target: self, selector: #selector(PrayerManager.newDay), userInfo: nil, repeats: false)
                
            }
        }
        
        
    }
    
    func newMeridiem() {
        Timer.scheduledTimer(timeInterval: 12 * 60 * 60, target: self, selector: #selector(PrayerManagerDelegate.newMeridiem), userInfo: nil, repeats: false)
        delegate.newMeridiem()
    }
    
    func createNotificationsForDayItemTuple(_ t: (year: Int, month: Int, day: Int), finalFlag: Bool) {
        let df = Global.dateFormatter
        df.dateFormat = "h:mm"
        var min = 0
        //account for prayers that could have passed today
        if t.day == currentDay && t.month == currentMonth && t.year == currentYear {
            if currentPrayer == .none {
                min = 0
            } else if currentPrayer == .isha {
                return
            } else {
                min = currentPrayer.rawValue + 1
            }
        }
        
        for i in min...5 {
            //!!annoying bg thread problem where we need to reset the format...
            df.dateFormat = "h:mm"
            let p = PrayerType(rawValue: i)!
            let pDate = yearTimes[t.year]![t.month]![t.day]![p]
            let dateString = df.string(from: pDate!)
            
            let setting = prayerSettings[p]!
            
            //schedule a normal if settings allow
            if setting.alarmType == .all || setting.alarmType == .noEarly {
                let note = UILocalNotification()
                note.fireDate = pDate
                note.timeZone = TimeZone.autoupdatingCurrent
                
                if setting.soundEnabled {
                    note.soundName = "chime1.aiff"
                }
                
                var alertText = ""
                if finalFlag {
                    if p == .isha {
                        alertText = "Time for \(p.stringValue()) [\(dateString)]. Please reopen Athan Utility to continue to recieve notificaitons..."
                    }
                } else {
                    var alternativeString: String?
                    if var charRange = locationString?.range(of: ",") {
                        if let stringEnd = locationString?.endIndex {
                            //                            charRange.upperBound = stringEnd
                            charRange = Range(uncheckedBounds: (lower: charRange.lowerBound, upper: stringEnd))
                            alternativeString = locationString?.replacingCharacters(in: charRange, with: "")
                        }
                    }
                    
                    if let alt = alternativeString {
                        print(dateString)
                        alertText = "Time for \(p.stringValue()) in \(alt) [\(dateString)]"
                    } else {
                        alertText = "Time for \(p.stringValue()) in \(locationString!) [\(dateString)]"
                    }
                    
                }
                
                note.alertBody = alertText
                
                UIApplication.shared.scheduleLocalNotification(note)
            }
            
            if setting.alarmType == .all {
                ////add a reminder for 15 minutes before
                let preNote = UILocalNotification()
                preNote.fireDate = pDate?.addingTimeInterval(-900)//15 mins before
                preNote.timeZone = TimeZone.autoupdatingCurrent
                //!! i think i would rather not have this one make a sound...would it still be noticeable?
                if setting.soundEnabled {
                    preNote.soundName = UILocalNotificationDefaultSoundName
                }
                
                var alertText = ""
                
                var alternativeString: String?
                if var charRange = locationString?.range(of: ",") {
                    if let stringEnd = locationString?.endIndex {
                        //                        charRange.upperBound = stringEnd
                        charRange = Range(uncheckedBounds: (lower: charRange.lowerBound, upper: stringEnd))
                        alternativeString = locationString?.replacingCharacters(in: charRange, with: "")
                    }
                }
                
                if let alt = alternativeString {
                    alertText = "15m left til \(p.stringValue()) in \(alt)! [\(dateString)]"
                } else {
                    alertText = "Time for \(p.stringValue()) in \(locationString!) [\(dateString)]"
                }
                
                preNote.alertBody = alertText
                
                UIApplication.shared.scheduleLocalNotification(preNote)
            }
        }
    }
    
    func fifteenMinutesLeft() {
        print("15 mins (or less) left!!")
        Global.statusColor = UIColor.orange
        //statusColor = UIColor.orangeColor()
        delegate.fifteenMinutesLeft()
    }
    
    //for when the manager needs to notify itself mid-day
    func newPrayer() {
        Global.statusColor = UIColor.green
        calculateCurrentPrayer()
        delegate.updatePrayer(manager: self)
    }
    
    func currentPrayerTime() -> Date {
        print("got to here***")
        if currentPrayer == .none {
            let cal = Calendar.current
            
            //!!!will be off... but its ok for now... (yesterday times n/a in api)
            let closeToIsha = todayPrayerTimes[.isha]!
            var comps = (cal as NSCalendar).components([.year, .month, .day, .hour, .minute], from: closeToIsha)
            if comps.day == 1 {
                if comps.month == 1 {
                    comps.year! -= 1
                    comps.month = 12
                    comps.day = daysInMonth(12)
                } else {
                    comps.month! -= 1
                    comps.day = daysInMonth(comps.month!)
                }
            } else {
                comps.day! -= 1
            }
            
            return cal.date(from: comps)!
        } else {
            return todayPrayerTimes[currentPrayer]!
        }
    }
    
    func previousPrayerTime() -> Date {
        if currentPrayer == .fajr {
            return yesterdayPrayerTimes[.isha]!
        } else {
            return todayPrayerTimes[currentPrayer.previous()]!
        }
    }
    
    func nextPrayerTime() -> Date {
        if currentPrayer == .isha {
            return tomorrowPrayerTimes[.fajr]!
        } else {
            //!!! this might not be good if the prayertype is none and next() returns fajr!!!
            return todayPrayerTimes[currentPrayer.next()]!
        }
    }
    
    func newDay() {
        //MARK: WARNING
        setCurrentDates()
        alignPrayerTimes()
        calculateCurrentPrayer()
        setTimers()
        ///is ^ enough??
        fetchJSONData(nil)//um, not good enough of a solution!!...
    }
    
    func reload() {
        //for simulator
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            fetchJSONData(nil)
        #endif
        getData = true
        coreManager.delegate = self
        coreManager.startUpdatingLocation()
        
    }
    
    func cancelRequest() {
        getData = false
        //session.invalidateAndCancel()
        //!! take into account alternative loading screen and hiding it here!!
        SwiftSpinner.hide()
        
    }
    
    //MARK: - Data Saving
    
    func prayersArchivePath() -> URL{
        //        let documentDirectories = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        //        let documentDirectory = documentDirectories.first
        //
        //        let x = documentDirectory!.stringByAppendingString("/prayers.plist")
        
        let fm = FileManager.default
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athan")
        containerURL = containerURL?.appendingPathComponent("prayers.plist")
        return containerURL!
    }
    
    func settingsArchivePath() -> URL {
        //        let documentDirectories = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        //        let documentDirectory = documentDirectories.first
        //        
        //        let x = documentDirectory!.stringByAppendingString("/customsettings.plist")
        //        return NSURL(string: x)!
        
        let fm = FileManager.default
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athan")
        containerURL = containerURL?.appendingPathComponent("customsettings.plist")
        return containerURL!
    }
    
}
