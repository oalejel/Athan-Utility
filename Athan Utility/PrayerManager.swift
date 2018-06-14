//
//  PrayerManager.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/9/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

// Comparison operators with optionals were removed from the Swift Standard Libary.
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

// Comparison operators with optionals were removed from the Swift Standard Libary.
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
    
    func localizedString() -> String {
        return NSLocalizedString(self.stringValue(), comment: "")
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
    
    // user has ability to keep location set to only one place if they specify a custom location
    var lockLocation = false
    var ignoreLocationUpdates = false
    
    // website JSON data request session
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
    
    // access by [year][month][day][PrayerType.rawValue() : Date]
    var yearTimes: [Int : [Int : [Int : [Int : Date]]]] = Dictionary()
    
    //for settings with alarms
    var timesSettings: [PrayerType : AlarmSetting]!
    var soundsSettings: [PrayerType : Bool] = [:]
    // ultimate settings object..
    var prayerSettings: [PrayerType : PrayerSetting] = [:]
    
    var delegate: PrayerManagerDelegate!
    
    var fetchCompletionClosure: (() -> ())?
    var lastFetchSuccessful = false
    
    var needsDataUpdate = true
    var dataExists = false
    
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
        
        // important update changed storage format
        if let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            if currentAppVersion == "1.8" {
                removeDictionaryStore()
            }
        }
        
        // the delegate, (typically a view controller) gets information from the PrayerManager
        delegate.manager = self
        
        // unload user settings on notifications
        getSettings()
        
        let conf = URLSessionConfiguration.default
        session = URLSession(configuration: conf, delegate: nil, delegateQueue: nil)
        
        // first, check the file, if there is useful data, use it, then get data from online without slowing things down
        if let dict = dictionaryFromFile() {
            print("should parse dict from file now!")
            parseDictionary(dict, fromFile: true)
        } else {
            delegate.setShouldShowLoader()
        }
        
        self.coreManager.delegate = self
        self.coreManager.desiredAccuracy = kCLLocationAccuracyHundredMeters //can change for eff.
    }
    
    //MARK: - Location Services
    
    func beginLocationRequest() {
        if !lockLocation {
            self.coreManager.requestWhenInUseAuthorization()
            self.coreManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        coreManager.stopUpdatingLocation() //change if stopping without getting reliable info
        
        // need this since location managers send multiple updates even after being told to stop updating
        if ignoreLocationUpdates == true {return}
        ignoreLocationUpdates = true
        
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
                    
                    //update our location string used to make queries and display in UI
                    self.locationString = self.formattedAddressString()
                    
                    //fetch data for this month and the next month
                    self.fetchJSONData(forLocation: self.locationString!, dateTuple: nil, completion: nil)
                    let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
                    self.fetchJSONData(forLocation: self.locationString!, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year), completion: nil)
                    self.ignoreLocationUpdates = false
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
        // if country is divided into statess, organize location string accordingly
        if let state = currentStateString {
            return"\(currentCityString ?? ""), \(state), \(currentCountryString ?? "")"
        } else {
            return "\(currentCityString ?? ""), \(currentCountryString ?? "")"
        }
//        return "\(currentCityString ?? ""), \(currentStateString ?? ""), \(currentCountryString ?? "")"
    }
    
    /// Gets data from website then calls the parseJSONData function.
    /// - parameters:
    ///     - searchString: string with location of query. we sometimes want to override the current location
    ///     - dateTuple: tuple of month and year of data queried
    ///     - completion: be called on completion of fetch, whether or not it is successful, with a success boolean
    /// - returns: *nothing*
    
    func fetchJSONData(forLocation queryLocationString: String, dateTuple: (month: Int, year: Int)?, completion: ((Bool) -> Void)?) {
        setCurrentDates()
        calculateAngle(coord: self.coordinate)
        self.lastFetchSuccessful = false
        
        // WARNING: should not need to actually readjust this.
//        locationString = formattedAddressString()
        
        //decide what URL to use in our data request based on date and location
        let escapedLocation = queryLocationString.replacingOccurrences(of: " ", with: "+")
        let queryURL = prayerAPIURL(address: escapedLocation, month: dateTuple?.month ?? currentMonth, year: dateTuple?.year ?? currentYear)
        
        //WARNING! dont forget to set this back to true if the app is on for a long time!!!
        if needsDataUpdate {
            needsDataUpdate = false
            if let sureURL = queryURL {
                print("Going to request data")
                var request = URLRequest(url: sureURL)
                request.httpMethod = "GET" // should be default setting, but just making this a point
                request.timeoutInterval = 6
                let dataTask = session.dataTask(with: request, completionHandler: {
                    (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    if error != nil {
                        self.needsDataUpdate = true
                    }
                    
                    if let sureData = data {
                        // this also stores to a file
                        let JSON = (try? JSONSerialization.jsonObject(with: sureData, options: [])) as? NSDictionary
                        if let sureJSON = JSON {
                            print("Got data from online")
                            
                            // in case we got a custom location from a text field input,
                            // and now decide to make the query string our official locationString
                            self.locationString = queryLocationString
                            
                            // if parsing dictionary goes well, call completion handler with true
                            if self.parseDictionary(sureJSON, fromFile: false) {
                                completion?(true)
                                return
                            }
                        }
                    }
                    //unsuccessful fetch if reaching this point
                    completion?(false)
                })
                
                dataTask.resume()
            } else {
                // did not have a working URL
                print("URL error")
                // still execute completion handler, telling handler that we had an unsuccessful fetch
                completion?(false)
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
//        let df = Global.dateFormatter
        //get the date info for today to use for computation
        let curDate = Date()
        currentYear = Calendar.current.component(.year, from: curDate)
        currentDay = Calendar.current.component(.day, from: curDate)
        currentMonth = Calendar.current.component(.month, from: curDate)
    }
    
    // this organizes the data and notifies the delegate. dict should either be coming with proper formatting from a file, or from the API with a need for special JSON parsing
    @discardableResult
    func parseDictionary(_ dict: NSDictionary, fromFile: Bool) -> Bool {
        // readjust current date measurements for use later
        setCurrentDates()
        
        var successful = false
        
        // check whether we have a dictionary formatted in the format we like
        if var sureDict = dict as? Dictionary<String, AnyObject> {
            if sureDict["data"] != nil {
                //WARNING: next step is getting rid of lastFetchSuccessful and instead relying on return type
                    lastFetchSuccessful = true
            } else {
                return false
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
//                                    print("readable date string: \(readableDateString)")
                                    
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
                                                            successful = true // will set to true if we got at least one thing
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
                    sureDict["qibla"] = qibla as AnyObject
                    let objc = sureDict as NSDictionary
                    NSKeyedArchiver.archiveRootObject(objc, toFile: prayersArchivePath().path)
                } else { return false }
            } else {
                // if reading data from file, deal with stored dictionary accordingly
                
                // check the last record's recieved location
                if let formattedAddress = sureDict["location_recieved"] as? String {
                    locationString = formattedAddress
                }
                
                // if we are getting data from a file, we expect value for key
                // "data" to be in the format of yearTimes
                if let formattedData = sureDict["data"] as? [Int : [Int : [Int : [Int : Date]]]] {
                    successful = true // true since we got the date in the form needed
                    yearTimes = formattedData
                }
                
                if let q = sureDict["qibla"] as? Double {
                    qibla = q
                }
            }
            
            alignPrayerTimes()
            calculateCurrentPrayer()
            notifyDelegate()
            //must call set timers after updatecurrent prayer is called
            setTimers()
            
            scheduleAppropriateNotifications()
        }
        
        // now that we actually have a qibla heading, we can have a dynamic quick action
        DispatchQueue.main.async {
            let icon = UIApplicationShortcutIcon(type: .location)
            let dynamicItem = UIApplicationShortcutItem(type: "qibla", localizedTitle: "Qibla", localizedSubtitle: nil, icon: icon, userInfo: nil)
            UIApplication.shared.shortcutItems = [dynamicItem]
        }
        
        return successful
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
        //ask user for notifications capabilities
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, err) in
            if !granted {
                print("User denied use of notifications")
            }
            //            let alertController = UIAlertController(title: "Notifications Disabled", message: "To allow notifications later, use iOS settings", preferredStyle: .)
        }
        
        center.getPendingNotificationRequests(completionHandler: { (reqs) in
            print("last pending notification count: \(reqs.count)")
        })
        
        center.removeAllPendingNotificationRequests()
        
        center.getDeliveredNotifications { (reqs) in
            print("last delivered notification count: \(reqs.count)")
        }
        
        for i in 0..<5 {
            self.createNotificationsForDayItemTuple(getFutureDateTuple(daysToSkip: i), finalFlag: i == 4)
        }
    }
    
    func notifyDelegate() {
        dataExists = true
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
        // create prayer times
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
                    print("time interval til 15 m warning: \(pDate.timeIntervalSince(curDate) - 900)")
                    Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate) - 900, target: self, selector: #selector(PrayerManager.fifteenMinutesLeft), userInfo: nil, repeats: false)
                    //timer for new prayer
                    Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate), target: self, selector: #selector(PrayerManager.newPrayer), userInfo: nil, repeats: false)
                } else {
                    print("error getting prayer time while setting timers!")
                }
            }
        }
    
        // create a timer that tells us when we switch between AM and PM
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
        
        
        // create a timer that tells us when it has become a new day
        DispatchQueue.main.async { () -> Void in
            var seconds = 0
            var minutes = 0
            var hours = 0
            let df = Global.dateFormatter
            df.dateFormat = "ss"
            guard let s = Int(df.string(from: curDate)) else { return }
            seconds = s
            df.dateFormat = "m"
            guard let m = Int(df.string(from: curDate)) else { return }
            minutes = m
            df.dateFormat = "H"
            guard let h = Int(df.string(from: curDate)) else { return }
            hours = h
            
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
        print("making notifications for month: \(t.month), day: \(t.day), year: \(t.year), final: \(finalFlag)")
        
        let df = Global.dateFormatter
        df.dateFormat = "h:mm"
        
        // min holds raw value + 1 of prayer we want to calculate for teh day
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
        
        let center = UNUserNotificationCenter.current()
        
        for i in min...5 {
            let p = PrayerType(rawValue: i)!
            if let byMonth = yearTimes[t.year] {
                if let byDay = byMonth[t.month] {
                    if let byPrayer = byDay[t.day] {
                        if let pDate = byPrayer[p.rawValue] {
                            df.dateFormat = "h:mm"
                            let dateString = df.string(from: pDate)
                            let setting = prayerSettings[p]!
                            
                            // The object that stores text and sound for a note
                            let noteContent = UNMutableNotificationContent()
                            
                            //schedule a normal if settings allow
                            if setting.alarmType == .all || setting.alarmType == .noEarly {
                                if setting.soundEnabled {
                                    noteContent.sound = UNNotificationSound(named: "chime1.aiff")
                                }
                                
                                var alertString = ""
                                // finalFlag indicates that we have reached the limit for stored
                                // local notifications, and should let the user know
                                if finalFlag {
                                    if p == .isha {
                                        alertString = "Time for \(p.stringValue()) [\(dateString)]. Please reopen Athan Utility to continue to recieve notificaitons..."
                                    }
                                } else {
                                    var alternativeString: String?
                                    if var charRange = locationString?.range(of: ",") {
                                        if let stringEnd = locationString?.endIndex {
                                            charRange = Range(uncheckedBounds: (lower: charRange.lowerBound, upper: stringEnd))
                                            alternativeString = locationString?.replacingCharacters(in: charRange, with: "")
                                        }
                                    }
                                    
                                    // Alternative string stores a shorter version of the location
                                    // in order to show "San Francisco" instead of "San Francisco, CA, USA"
                                    if let alt = alternativeString {
                                        alertString = "Time for \(p.stringValue()) in \(alt) [\(dateString)]"
                                    } else {
                                        alertString = "Time for \(p.stringValue()) in \(locationString!) [\(dateString)]"
                                    }
                                }

                                // set the notification body
                                noteContent.body = alertString

                                // create a trigger with the correct date
                                let dateComp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: pDate)
                                print(dateComp.isValidDate)
                                let noteTrigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: false)
                                // create request, and make sure it is added on the main thread (there was an issue before with the old UINotificationCenter. test for whether this is needed)
                                let noteID = "standard_note_\(dateComp.day!)_\(dateComp.hour!)_\(dateComp.minute!)"
                                let noteRequest = UNNotificationRequest(identifier: noteID, content: noteContent, trigger: noteTrigger)
                                center.add(noteRequest) { print($0 ?? "", separator: "", terminator: "") }
                            }
                            
                            // if user would ALSO like to get notified 15 minutes prior
                            if setting.alarmType == .all {
                                // adding a reminder for 15 minutes before the actual prayer time
                                let preNoteContent = UNMutableNotificationContent()
                                let preDate = pDate.addingTimeInterval(-900) // 15 mins before
                                preNoteContent.userInfo = ["intendedFireDate": preDate]
                                let preNoteComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: preDate)
                                
                                let preNoteTrigger = UNCalendarNotificationTrigger(dateMatching: preNoteComponents, repeats: false)
                                
                                //use a standard note tone when giving a 15m reminder
                                if setting.soundEnabled {
                                    preNoteContent.sound = UNNotificationSound.default()
                                }
                                
                                var alertString = ""
                                
                                var alternativeString: String?
                                if var charRange = locationString?.range(of: ",") {
                                    if let stringEnd = locationString?.endIndex {
                                        charRange = Range(uncheckedBounds: (lower: charRange.lowerBound, upper: stringEnd))
                                        alternativeString = locationString?.replacingCharacters(in: charRange, with: "")
                                    }
                                }
                                
                                if let alt = alternativeString {
                                    alertString = "15m left til \(p.stringValue()) in \(alt)! [\(dateString)]"
                                } else {
                                    alertString = "15m left til \(p.stringValue()) in \(locationString!) [\(dateString)]"
                                }
                                
                                preNoteContent.body = alertString
                                
                                // hold onto the intended date for notification so that local notes can be handled in an accurate alert view
                                preNoteContent.userInfo["intendedDate"] = pDate
                               
                                //create a unique time based id
                                let preNoteID = "pre_note_\(preNoteComponents.day!)_\(preNoteComponents.hour!)_\(preNoteComponents.minute!)"
                                
                                let preNoteRequest = UNNotificationRequest(identifier: preNoteID, content: preNoteContent, trigger: preNoteTrigger)
                                
//                                DispatchQueue.main.async {
                                center.add(preNoteRequest, withCompletionHandler: nil)
//                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func timeLeftColor() -> UIColor {
        if nextPrayerTime()?.timeIntervalSinceNow < 900 {
            return UIColor.orange
        }
        return UIColor.green
    }
    
    /// indicates that there are 15 m left til next prayer begins.
    /// Should adjust app by changing color of certain things to orange
    @objc func fifteenMinutesLeft() {
        print("15 mins (or less) left!!")
        Global.statusColor = timeLeftColor()
        delegate.fifteenMinutesLeft()
    }
    
    // for when the manager needs to notify itself mid-day
    @objc func newPrayer() {
        Global.statusColor = UIColor.green
        calculateCurrentPrayer()
        delegate.updatePrayer(manager: self)
    }
    
    func currentPrayerTime() -> Date? {
        if let closeToIsha = todayPrayerTimes[PrayerType.isha.rawValue] {

            if currentPrayer == .none && Date().timeIntervalSince(closeToIsha) < 0 {
                // if none and its the next day, then substract the day by one and use the today isha time
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
        if currentPrayer == .isha {
            if let storedNext = tomorrowPrayerTimes[PrayerType.fajr.rawValue] {
                return storedNext
            } else {
                return todayPrayerTimes[PrayerType.fajr.rawValue]?.addingTimeInterval(86400)
            }
        } else {
            // = .none when we are at a new day and before fajr
            //standard case, taking time for prayer in same day
            return todayPrayerTimes[currentPrayer.next().rawValue]
        }
    }
    /// - important: may assume that we have valid location and date info, since newDay is only set on a timer created post-successful fetch
    @objc func newDay() {
        setCurrentDates()
        alignPrayerTimes()
        calculateCurrentPrayer()
        setTimers()
        fetchJSONData(forLocation: self.locationString!, dateTuple: nil, completion: nil)//not good enough of a solution long term!!...
        let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
        fetchJSONData(forLocation: self.locationString!, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year), completion: nil)
    }
    
    /// - important: testing this function in simulator will not accurately reflect change of location and locked locations
    func reload() {
        //for simulator
        #if targetEnvironment(simulator)
        fetchJSONData(forLocation: self.locationString!, dateTuple: nil, completion: nil)
            let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
        fetchJSONData(forLocation: self.locationString!, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year), completion: nil)
        #endif
        needsDataUpdate = true
        coreManager.delegate = self // WARNING: check if redundant
        if !lockLocation {
            coreManager.startUpdatingLocation()
        }
    }
    
    @objc func userCanceledDataRequest() {
        needsDataUpdate = false
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
