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
    var coordinate: CLLocationCoordinate2D?
    
    var currentDay: Int!
    var currentMonth: Int!
    var currentYear: Int!
    
    //website JSON data request session
    fileprivate var session: URLSession!
    
    func prayerAPIURL(address: String, month: Int, year: Int) -> URL? {
        let escapedAddress = address.replacingOccurrences(of: " ", with: "+")
        let urlStr = "https://api.aladhan.com/calendarByAddress?address=\(escapedAddress)&month=\(month)&year=\(year)mode=yearly&method=2"
        return URL(string: urlStr)
    }
    
    var qibla: Double! = 0
    
    var todayPrayerTimes: [Int : Date] = Dictionary()
    var tomorrowPrayerTimes: [Int : Date] = Dictionary()
    var yesterdayPrayerTimes: [Int : Date] = Dictionary()
    
    //access by [year][month][day][PrayerType.rawValue() : Date]
    var yearTimes: [Int : [Int : [Int : [Int : Date]]]] = Dictionary()
    
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
        
        setCurrentDates()
        
        if let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            if currentAppVersion == "1.8" {
                removeDictionaryStore()
            }
        }
        
        delegate.manager = self
        
        getSettings()
        
        let conf = URLSessionConfiguration.default
        session = URLSession(configuration: conf, delegate: nil, delegateQueue: nil)
        
        //first, check the file, if there is useful data, use it, then get data from online without slowing things down
        if let dict = dictionaryFromFile() {
            print("should parse dict from file now!")
            parseDictionary(dict, fromFile: true)
        } else {
            delegate.showLoader()
        }
        
        self.coreManager.delegate = self
        self.coreManager.desiredAccuracy = kCLLocationAccuracyHundredMeters //can change for eff.
        self.coreManager.requestWhenInUseAuthorization()
        self.coreManager.startUpdatingLocation()
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
                    self.currentCityString = placemark.locality//cityNoSpaces
                    self.currentDistrictString = placemark.subAdministrativeArea
                    self.currentStateString = placemark.administrativeArea
                    self.currentCountryString = placemark.isoCountryCode
                    self.coordinate = placemark.location?.coordinate
                    //fetch data for this month and the next month
                    self.fetchJSONData(nil, dateTuple: nil)
                    let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
                    self.fetchJSONData(nil, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year))
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
                    s.alarmType = AlarmSetting(rawValue: Int(truncating: at))!
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
    
    func formattedAddressString() -> String {
        return "\(currentCityString ?? ""), \(currentStateString ?? ""), \(currentCountryString ?? "")"
    }
    
    //gets data from website then calls the parseJSONData function
    func fetchJSONData(_ searchString: String?, dateTuple: (month: Int, year: Int)?) {
        setCurrentDates()
        calculateAngle(coord: self.coordinate)
        self.lastFetchSuccessful = false
        
        //decide what URL to use in our data request based on date and location
        var URL: URL?
        if let s = searchString {
            URL = prayerAPIURL(address: s, month: dateTuple?.month ?? currentMonth, year: dateTuple?.year ?? currentYear)
        } else {
            var address = formattedAddressString()
            address = address.replacingOccurrences(of: " ", with: "+")
            URL = prayerAPIURL(address: address, month: dateTuple?.month ?? currentMonth, year: dateTuple?.year ?? currentYear)
        }
        
        //! dont forget to set this back to true if the app is on for a long time!!!
        if getData {
            getData = false
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
                            print("got data from online!")
                            self.parseDictionary(sureJSON, fromFile: false)
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
 
     func calculateAngle(coord: CLLocationCoordinate2D?) {
        if let coordinate = coord {
            let lat = coordinate.latitude
            let lon = coordinate.longitude
            
            let phiK = 21.4 * Double.pi / 180.0;
            let lambdaK = 39.8 * Double.pi / 180.0;
            let phi = lat * Double.pi / 180.0;
            let lambda = lon * Double.pi / 180.0;
            let psi = 180.0 / Double.pi * atan2(sin(lambdaK - lambda), cos(phi) * tan(phiK) - sin(phi) * cos(lambdaK - lambda));
            qibla = floor(100 * psi) / 100
        }
     }

    func tryRequestWithSearch(_ search: String) -> Bool {
        return false
    }
    
    func dictionaryFromFile() -> NSDictionary? {
        let dict = NSKeyedUnarchiver.unarchiveObject(withFile: prayersArchivePath().path) as? NSDictionary
        return dict
    }
    
    func removeDictionaryStore() {
        do {
            try FileManager.default.removeItem(atPath: prayersArchivePath().path)
        } catch {
            print(error)
        }
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
    func parseDictionary(_ dict: NSDictionary?, fromFile: Bool) {
        setCurrentDates()
        if var sureDict = dict as? Dictionary<String, AnyObject> {
            if sureDict["data"] != nil {
                    lastFetchSuccessful = true
                if let state = currentStateString {
                    locationString = "\(currentCityString ?? ""), \(state), \(currentCountryString ?? "")"
                } else {
                 locationString = "\(currentCityString ?? ""), \(currentCountryString ?? "")"
                }
            } else {
                return
            }
            
            
            if !fromFile {
                //if not from file, the object stored with the "date" key will be an array
                //get prayer times in text and parse into dates
                if let daysArray = sureDict["data"] as? NSArray {
                    //add days in months
                    //                var dayOffset = 0
                    let df = Global.dateFormatter
                
                    
                    let swiftDaysArray = daysArray as! [NSDictionary]
                    
                    let prayers: [PrayerType] = [.fajr, .shurooq, .thuhr, .asr, .maghrib, .isha]
                    let customNames = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
                    
                    //we will go through every day of the month from the api, get the dates, and then store those data points in a dict organized by year, month, date, and --> prayer times
                    for item in swiftDaysArray {
                        if let dictItem = item as? [String: NSDictionary] {
                            if let itemDateCluster = dictItem["date"] {
                                if let readableDateString = itemDateCluster["readable"] as? String {
                                    print("readable date string: \(readableDateString)")
                                    
                                    df.dateFormat = "d M y"
                                    
                                    if let parsedDate = df.date(from: readableDateString) {
                                        df.dateFormat = "d"
                                        let parsedDay = Int(df.string(from: parsedDate))
                                        
                                        df.dateFormat = "M"
                                        let parsedMonth = Int(df.string(from: parsedDate))
                                        
                                        let yearIndex = readableDateString.index(readableDateString.endIndex, offsetBy: -4)
                                        let parsedYear = Int(readableDateString[yearIndex...])
                                        
                                        if parsedDay != nil && parsedMonth != nil && parsedYear != nil {
                                            if yearTimes[parsedYear!] == nil {
                                                yearTimes[parsedYear!] = [:]
                                            }
                                            if yearTimes[parsedYear!]![parsedMonth!] == nil {
                                                yearTimes[parsedYear!]![parsedMonth!] = [:]
                                            }
                                            if yearTimes[parsedYear!]![parsedMonth!]![parsedDay!] == nil {
                                                yearTimes[parsedYear!]![parsedMonth!]![parsedDay!] = [:]
                                            }
                                            
                                            if let dayPrayersDict = dictItem["timings"] as? [String:String] {
                                                //print(dayPrayersDict)
                                                for p in prayers {
                                                    //access the time for this one prayer using teh custom names array and a corresponding index
                                                    if var prayerTimeString = dayPrayersDict[customNames[p.rawValue]] {
                                                        //remove the pesky annoying timezone string
                                                        let startingParensIndex = prayerTimeString.index(of: "(")
                                                        let endingParensIndex = prayerTimeString.index(of: ")")
                                                        prayerTimeString.removeSubrange(startingParensIndex!...endingParensIndex!)
                                                        
                                                        prayerTimeString += "\(parsedDay ?? 0) \(parsedMonth ?? 0) \(parsedYear ?? 0)"
                                                        //the format will now be something like "20:06 01 Sep 2017"
                                                        df.dateFormat = "HH:mm d M y"
                                                        
                                                        if let prayerDate = df.date(from: prayerTimeString) {
                                                            yearTimes[parsedYear!]![parsedMonth!]![parsedDay!]![p.rawValue] = prayerDate
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                
                    //save our new data from online
                    sureDict["location_recieved"] = formattedAddressString() as AnyObject?
                    sureDict["data"] = yearTimes as AnyObject
                    let objc = sureDict as NSDictionary
                    NSKeyedArchiver.archiveRootObject(objc, toFile: prayersArchivePath().path)
                } else {return}
            } else {
                if let formattedAddress = sureDict["location_recieved"] as? String {
                    locationString = formattedAddress
                }
                
                //if we are getting data from a file, we expect value for key "data" to be yearTimes
                if let formattedData = sureDict["data"] as? [Int : [Int : [Int : [Int : Date]]]] {
                    yearTimes = formattedData
                }
            }
            
            alignPrayerTimes()
            calculateCurrentPrayer()
            notifyDelegate()
            //must call set timers after updatecurrent prayer is called
            setTimers()
            
            scheduleAppropriateNotifications()
        }
        
        DispatchQueue.main.async {
            if #available(iOS 9.0, *) {
                let icon = UIApplicationShortcutIcon(type: .location)
                let dynamicItem = UIApplicationShortcutItem(type: "qibla", localizedTitle: "Qibla", localizedSubtitle: nil, icon: icon, userInfo: nil)
                UIApplication.shared.shortcutItems = [dynamicItem]
            }
        }
        
    }
    
    func getFutureDateTuple(daysToSkip: Int = 1) -> (day: Int, month: Int, year: Int) {
        var tomorrowDay = currentDay!
        var tomorrowMonth = currentMonth!
        var tomorrowYear = currentYear!
        if daysToSkip > 0 {
            for _ in 0..<daysToSkip {
                if tomorrowDay == daysInMonth(currentMonth) {
                    if tomorrowMonth == 12 {
                        //new year
                        tomorrowYear += 1
                        tomorrowDay = 1
                        tomorrowMonth = 1
                    } else {
                        //new month
                        tomorrowMonth += 1
                        tomorrowDay = 1
                    }
                } else {
                    tomorrowDay += 1
                }
            }
        }
        
        return (tomorrowDay, tomorrowMonth, tomorrowYear)
    }
    
    func alignPrayerTimes() {
        if let months = yearTimes[currentYear] {
            if let days = months[currentMonth] {
                if let dayTimes = days[currentDay] {
                    todayPrayerTimes = dayTimes
                }
            }
        }
        
        let (tomorrowDay, tomorrowMonth, tomorrowYear) = getFutureDateTuple(daysToSkip: 1)
        if let _tomorrowPrayerTimes = yearTimes[tomorrowYear]?[tomorrowMonth]?[tomorrowDay] {
            tomorrowPrayerTimes = _tomorrowPrayerTimes
        } else {
            print("Error Calculating tomorrow's date")
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
        DispatchQueue.main.async {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        
        for i in 0..<5 {
            var final = false
            if i == 4 {final = true}
            self.createNotificationsForDayItemTuple(getFutureDateTuple(daysToSkip: i), finalFlag: final)
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
            if let time = self.todayPrayerTimes[p.rawValue] {
                if curDate.compare(time) == ComparisonResult.orderedDescending {
                    //WARNING: THIS MIGHT FAIL WHEN THE DATE IS AFTER
                    self.currentPrayer = PrayerType(rawValue: p.rawValue)!//select the previous date prayer
                } else {
                    return
                }
            }
        }
    }
    
    func setTimers() {
        //set the prayer timers
        let curDate = Date()
        if currentPrayer != .isha {
            var startIndex = currentPrayer.rawValue + 1
            if currentPrayer == .none {
                startIndex = 0
            }
            for i in (startIndex)...5 {
                let p = PrayerType(rawValue: i)!
                if let pDate = todayPrayerTimes[p.rawValue] {
                    //timer for highlight red for 15 mins left
                    Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate) - 900, target: self, selector: #selector(PrayerManager.fifteenMinutesLeft), userInfo: nil, repeats: false)
                    //timer for new prayer
                    Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate), target: self, selector: #selector(PrayerManager.newPrayer), userInfo: nil, repeats: false)
                } else {
                    print("error getting prayer time while setting timers!")
                }
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
        
        Timer.scheduledTimer(timeInterval: nextMeridInterval!, target: self, selector: #selector(PrayerManager.newMeridiem), userInfo: nil, repeats: false)
        
        DispatchQueue.main.async { () -> Void in
            var seconds = 0
            var minutes = 0
            var hours = 0
            let df = Global.dateFormatter
            df.dateFormat = "s"
            seconds = Int(df.string(from: curDate))!
            df.dateFormat = "m"
            minutes = Int(df.string(from: curDate))!
            df.dateFormat = "H"
            hours = Int(df.string(from: curDate))!
            
            
            //set the newday timer
            let secondsInDay: Int? = seconds + (minutes * 60) + ((hours % 24) * 3600)
            if secondsInDay != nil {
                let secondsLeft = 86400 - secondsInDay!
                Timer.scheduledTimer(timeInterval: TimeInterval(secondsLeft), target: self, selector: #selector(PrayerManager.newDay), userInfo: nil, repeats: false)
                
            }
        }
        
        
    }
    
    @objc func newMeridiem() {
        Timer.scheduledTimer(timeInterval: 12 * 60 * 60, target: self, selector: #selector(PrayerManager.newMeridiem), userInfo: nil, repeats: false)
        delegate.newMeridiem()
    }
    
    func createNotificationsForDayItemTuple(_ t: (day: Int,  month: Int, year: Int), finalFlag: Bool) {
        print("making notifications for \(t.month), \(t.day), \(t.year), final: \(finalFlag)")
        
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
            
            let p = PrayerType(rawValue: i)!
            if let byMonth = yearTimes[t.year] {
                if let byDay = byMonth[t.month] {
                    if let byPrayer = byDay[t.day] {
                        if let pDate = byPrayer[p.rawValue] {
                            df.dateFormat = "h:mm"
                            let dateString = df.string(from: pDate)
                            
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
                                
                                DispatchQueue.main.async {
                                    UIApplication.shared.scheduleLocalNotification(note)
                                }
                            }
                            
                            if setting.alarmType == .all {
                                ////add a reminder for 15 minutes before
                                let preNote = UILocalNotification()
                                preNote.fireDate = pDate.addingTimeInterval(-900)//15 mins before
                                preNote.userInfo = ["intendedFireDate": preNote.fireDate ?? Date()]
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
                                    alertText = "15m left til \(p.stringValue()) in \(locationString!) [\(dateString)]"
                                }
                                
                                preNote.alertBody = alertText
                                
                                DispatchQueue.main.async {
                                    UIApplication.shared.scheduleLocalNotification(preNote)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func fifteenMinutesLeft() {
        print("15 mins (or less) left!!")
        Global.statusColor = UIColor.orange
        //statusColor = UIColor.orangeColor()
        delegate.fifteenMinutesLeft()
    }
    
    //for when the manager needs to notify itself mid-day
    @objc func newPrayer() {
        Global.statusColor = UIColor.green
        calculateCurrentPrayer()
        delegate.updatePrayer(manager: self)
    }
    
    func currentPrayerTime() -> Date? {
        if let closeToIsha = todayPrayerTimes[PrayerType.isha.rawValue] {

            if currentPrayer == .none && Date().timeIntervalSince(closeToIsha) < 0 {
                //if none and its the next day, then substract the day by one and use the today isha time
                let cal = Calendar.current
                
                    var comps = (cal as NSCalendar).components([.year, .month, .day, .hour, .minute, .timeZone], from: closeToIsha)
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
                    return cal.date(from: comps)
                } else {
                    return todayPrayerTimes[currentPrayer.rawValue]
                }
            }
        return nil
    }
    
    func previousPrayerTime() -> Date {
        if currentPrayer == .fajr || currentPrayer == .none {
            return yesterdayPrayerTimes[PrayerType.isha.rawValue]!
        } else {
            return todayPrayerTimes[currentPrayer.previous().rawValue]!
        }
    }
    
    func nextPrayerTime() -> Date? {
        //for cases where we are looking into next day
        if currentPrayer == .isha || currentPrayer == .none {
            if let storedNext = tomorrowPrayerTimes[PrayerType.fajr.rawValue] {
                return storedNext
            } else {
                return todayPrayerTimes[currentPrayer.next().rawValue]?.addingTimeInterval(86400)
            }
        } else {
            //standard case, taking time for prayer in same day
            return todayPrayerTimes[currentPrayer.next().rawValue]
        }
    }
    
    @objc func newDay() {
        setCurrentDates()
        alignPrayerTimes()
        calculateCurrentPrayer()
        setTimers()
        fetchJSONData(nil, dateTuple: nil)//not good enough of a solution long term!!...
        let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
        fetchJSONData(nil, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year))
    }
    
    func reload() {
        //for simulator
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            fetchJSONData(nil, dateTuple: nil)
            let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
            fetchJSONData(nil, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year))
        #endif
        getData = true
        coreManager.delegate = self
        coreManager.startUpdatingLocation()
    }
    
    @objc func cancelRequest() {
        getData = false
        SwiftSpinner.hide()
    }
    
    //MARK: - Data Saving
    
    func prayersArchivePath() -> URL{
        let fm = FileManager.default
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")
        containerURL = containerURL?.appendingPathComponent("prayers.plist")
        return containerURL!
    }
    
    func settingsArchivePath() -> URL {
        let fm = FileManager.default
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")
        containerURL = containerURL?.appendingPathComponent("customsettings.plist")
        return containerURL!
    }
    
}
