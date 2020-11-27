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
import WidgetKit
import os // for logging errors / updates

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

//enum AlarmSetting: Int {
//    case all, noEarly, none
//}

class PrayerSetting {
    var soundEnabled = true
    var alarmType = AlarmSetting.all
}

class PrayerManager: NSObject, CLLocationManagerDelegate {
    enum OtherData: Int {
        case qibla, city, state, country
    }
    
    //location services data provider
    let coreManager = CLLocationManager()
    var lastAuthStatus = CLAuthorizationStatus.notDetermined
    
    var currentPrayer: PrayerType = PrayerType.fajr //default prayer before arrival of data. should be based on a plist int
    
    //important data that comes from the coremanager
    struct GPSStrings {
        var currentCityString: String?
        var currentDistrictString: String?
        var currentStateString: String?
        var currentCountryString: String?
        
        func concatenated() -> String {
            var out = ""
            if let s = currentCityString { out += s + ", "}
            if let s = currentDistrictString { out += s + ", "}
            if let s = currentStateString { out += s + ", "}
            if let s = currentCountryString { out += s}
            return out
        }
    }
    var gpsStrings: GPSStrings?
    
    var readableLocationString: String?
    var coordinate: CLLocationCoordinate2D?
    
    var currentDay: Int!
    var currentMonth: Int!
    var currentYear: Int!
    
    // user has ability to keep location set to only one place if they specify a custom location
    var ignoreLocationUpdates = false
    var shouldSyncLocation = true
    
    // website JSON data request session
    fileprivate var session: URLSession!
    
    func prayerAPIURL(address: String, month: Int, year: Int) -> URL? {
        let escapedAddress = address.replacingOccurrences(of: " ", with: "+")
        let urlStr = "https://api.aladhan.com/calendarByAddress?address=\(escapedAddress)&month=\(month)&year=\(year)mode=yearly&method=\(Settings.getCalculationMethodIndex() + 1)"
        // must add 1 to calc method since website uses 1-indexing
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
    
    var delegate: PrayerManagerDelegate?
    
    var calculationCompletionClosure: ((Result<PrayerManager, Error>) -> ())?
    var lastFetchSuccessful = false
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
    
    // calculation completion only called once. if we load from a local dictionary, we load from there
    init(delegate: PrayerManagerDelegate?, requestLocationOnStart: Bool = false, calculationCompletion: ((Result<PrayerManager, Error>) -> ())? = nil) {
        self.delegate = delegate
        super.init()
        
        setCurrentDates()
        
        // important update changed storage format
        if let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            if Float(currentAppVersion) ?? 99.9 <= 1.8 {
                removeDictionaryStore()
            }
        }
        
        // the delegate, (typically a view controller) gets information from the PrayerManager
        delegate?.manager = self
        
        // unload user settings on notifications
        getSettings()
        
        let conf = URLSessionConfiguration.default
        session = URLSession(configuration: conf, delegate: nil, delegateQueue: nil)
        
        // first, check the file, if there is useful data, use it, then get data from online without slowing things down
        if let dict = dictionaryFromFile() {
            print("should parse dict from file now!")
            parseDictionary(dict, fromFile: true)
//            calculationCompletionClosure = calculationCompletion
//            notifyWidget()
        } else {
            delegate?.setShouldShowLoader?()
        }
        // hold onto this so that we can tell the user that we have data
        // only once we try to update from location / from current location data
        calculationCompletionClosure = calculationCompletion
        
        self.coreManager.delegate = self
        self.coreManager.desiredAccuracy = kCLLocationAccuracyHundredMeters //can change for eff
        
        // DO NOT REQUEST permissions yet, since we only use this to trigger early updates in the case that the user has already accepted permissions
        if requestLocationOnStart {
            self.coreManager.requestWhenInUseAuthorization()
//            self.coreManager.startUpdatingLocation()
        }
        
        if !shouldSyncLocation {
//            fetchMonthsJSONDataForCurrentLocation(gpsStr)
        }
                
        #if targetEnvironment(simulator)
        self.gpsStrings = GPSStrings(currentCityString: "Bloomfield Hills",
                                     currentDistrictString: "Oakland",
                                     currentStateString: "MI",
                                     currentCountryString: "USA")
        self.coordinate = CLLocationCoordinate2D(latitude: 42.588, longitude: -83.2975)
        //fetch data for this month and the next month
        self.fetchJSONData(forLocation: "Bloomfield Hills, MI, USA", dateTuple: nil, completion: nil)
//        let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
        #endif
    }
    
    //MARK: - Location Services
    
    func readyToRequestPermissions() {
        self.coreManager.requestWhenInUseAuthorization()
        if shouldSyncLocation {
            self.coreManager.startUpdatingLocation()
        }
    }
    
    // tell widget whether we have current data. this should get called once we finish attempting to check our location
    // if the user has data on file that is correct, but the location request failed, we will fallback on that data
    // since this only checks for data existing
    func notifyWidget() {
        if todayPrayerTimes.count > 0 {
            self.calculationCompletionClosure?(.success(self))
        } else {
            self.calculationCompletionClosure?(.failure(NSError(domain: "widget", code: 0, userInfo: nil)))
        }
        
        self.calculationCompletionClosure = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER ERROR: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coreManager.stopUpdatingLocation() //change if stopping without getting reliable info
        
        // need this since location managers send multiple updates even after being told to stop updating
        if ignoreLocationUpdates == true {
            // hide swift spinner in case we are blocking the screen
            delegate?.hideLoadingView?()
            return
        }
        ignoreLocationUpdates = true
        
        CLGeocoder().reverseGeocodeLocation(locations.first!, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) -> Void in
            if let x = error {
                print(x)
            } else {
                if placemarks?.count > 0 {
                    let placemark = placemarks![0]
                    
                    // if we should not update, then abort fetching
                    if !self.shouldRequestJSONForLocation(locality: placemark.locality, subAdminArea: placemark.subAdministrativeArea, state: placemark.administrativeArea, countryCode: placemark.isoCountryCode) {
                        // we know that the location we already have is correct
//                        self.delegate?.syncLocation = true
                        self.delegate?.locationIsSynced = true
                        self.delegate?.hideLoadingView?()
                        
                        // tell widgets / requester that we have success, since there is no need for an update
                        self.notifyWidget()
                        return
                    }
                    
                    // update our recorded location
                    self.gpsStrings = GPSStrings(currentCityString: placemark.locality,
                                                 currentDistrictString: placemark.subAdministrativeArea,
                                                 currentStateString: placemark.administrativeArea,
                                                 currentCountryString: placemark.isoCountryCode)
                    self.coordinate = placemark.location?.coordinate
                    
                    //update our location string used to make queries and display in UI
                    self.readableLocationString = self.readableAddressString()
                    
                    //fetch data for this month and the next month
//                    self.fetchJSONData(forLocation: self.locationString!, dateTuple: nil, completion: nil)
//                    let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
//                    self.fetchJSONData(forLocation: self.locationString!, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year), completion: nil)
                    self.fetchMonthsJSONDataForCurrentLocation(completion: { (success) in
                        self.ignoreLocationUpdates = success
                        self.delegate?.locationIsSynced = success
                        if success {
                            var times = [PrayerType:Date]()
                            self.todayPrayerTimes.forEach { (k, v) in
                                times[PrayerType(rawValue: k)!] = v
                            }
                            self.notifyWidget()
                        } else {
                            self.gpsStrings = nil
                            self.ignoreLocationUpdates = false
                            self.shouldSyncLocation = true
                            self.notifyWidget()
                        }
                    })
                }
            }
        })
    }
    
    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if lastAuthStatus == .denied || lastAuthStatus == .notDetermined {
            if shouldSyncLocation && (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways) {
                coreManager.startUpdatingLocation() // user has decided to share location, so start process of getting data
                lastAuthStatus = manager.authorizationStatus
                return
            }
        }
        
        // try to load data for the current location if current data is out of date
        if !hasDataForNextMonth() && gpsStrings != nil {
            fetchMonthsJSONDataForCurrentLocation { (success) in
                self.notifyWidget()
            }
        } else if manager.authorizationStatus != .notDetermined { // ONLY if we are not in the notDetermined stage can we be sure that we have probably failed
            self.notifyWidget()
        }
        lastAuthStatus = manager.authorizationStatus
    }
    
    // in case user initially prevents location updates and decides to switch back
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if lastAuthStatus == .denied || lastAuthStatus == .notDetermined {
            if shouldSyncLocation && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                coreManager.startUpdatingLocation() // user has decided to share location, so start process of getting data
                lastAuthStatus = status
                return
            }
        }
        
        // try to load data for the current location if current data is out of date
        if !hasDataForNextMonth() && gpsStrings != nil {
            fetchMonthsJSONDataForCurrentLocation { (success) in
                self.notifyWidget()
            }
        } else if status != .notDetermined { // ONLY if we are not in the notDetermined stage can we be sure that we have probably failed
            self.notifyWidget()
        }
        lastAuthStatus = status
    }
    
    // tell our delegate that the heading has been updated (qibla view controller)
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingDelegate?.newHeading(newHeading)
    }
    
    //MARK: - Data Management
    
    func getSettings() {
        var dict: [String:AnyObject]?
        do {
            if #available(iOS 11.0, *) {
                let data = try Data(contentsOf: settingsArchivePath())
                dict = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String:AnyObject]
            } else {
                // Fallback on earlier versions
                dict = NSKeyedUnarchiver.unarchiveObject(withFile: settingsArchivePath().path) as? [String:AnyObject]
            }
        } catch {
            logOrPrint("Couldn't unarchive prayer settings")
        }

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
        
        // archive the settings
        do {
            if #available(iOS 11.0, *) {
                let data = try NSKeyedArchiver.archivedData(withRootObject: ["prayersettings":allSettingsDict], requiringSecureCoding: false)
                try data.write(to: settingsArchivePath())
            } else {
                // Fallback on earlier versions
                NSKeyedArchiver.archiveRootObject(["prayersettings":allSettingsDict], toFile: settingsArchivePath().path)
            }
        } catch {
            logOrPrint("Couldn't archive prayer settings")
        }
    }
    
    func readableAddressString() -> String {
        // if country is divided into statess, organize location string accordingly
        if let state = gpsStrings?.currentStateString {
            return"\(gpsStrings?.currentCityString ?? ""), \(state)"
        } else {
            return "\(gpsStrings?.currentCityString ?? ""), \(gpsStrings?.currentCountryString ?? "")"
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
        //#error("remove either needsDataUpdate or ignoreLocationUpdates")
//        if needsDataUpdate {
//        needsDataUpdate = false
        if let sureURL = queryURL {
            logOrPrint("Going to request data for a month")
            var request = URLRequest(url: sureURL)
            request.httpMethod = "GET" // should be default setting, but just making this a point
//            request.timeoutInterval =
            let dataTask = session.dataTask(with: request, completionHandler: {
                (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error != nil {
//                    self.needsDataUpdate = true
//                    #warning("might want to figure out an appropriate response")
                }
                
                if let sureData = data {
                    // this also stores to a file
                    let JSON = (try? JSONSerialization.jsonObject(with: sureData, options: [])) as? NSDictionary
                    if let sureJSON = JSON {
                        self.logOrPrint("Got data from online")
                        
                        // in case we got a custom location from a text field input,
                        // and now decide to make the query string our official locationString
                        self.readableLocationString = self.readableAddressString()
                        if self.readableLocationString == nil || self.readableLocationString == "" {
                            self.readableLocationString = queryLocationString
                        }
                        
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
            logOrPrint("URL error")
            // still execute completion handler, telling handler that we had an unsuccessful fetch
            completion?(false)
        }
        
    }
 
    /// calculate angle to point to Mecca
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
    
    // MARK: - Dictionary Storage
    
    func dictionaryFromFile() -> NSDictionary? {
        do {
            if #available(iOS 11.0, *) {
                let data = try Data(contentsOf: prayersArchivePath())
                return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSDictionary
            } else {
                // Fallback on earlier versions
                return NSKeyedUnarchiver.unarchiveObject(withFile: prayersArchivePath().path) as? NSDictionary
            }
        } catch {
            logOrPrint("Couldn't unarchive prayer times")
        }
        
        logOrPrint("Nil dictionary in attempt to unarchive")
        return nil
    }
    
    func removeDictionaryStore() {
        do {
            try FileManager.default.removeItem(atPath: prayersArchivePath().path)
        } catch {
            print(error)
        }
    }
    
    func setCurrentDates() {
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
                                                        let startingParensIndex = prayerTimeString.firstIndex(of: "(")
                                                        let endingParensIndex = prayerTimeString.firstIndex(of: ")")
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
//                    sureDict["location_recieved"] = formattedAddressString() as AnyObject?
                    
                    sureDict["last_city"] = (gpsStrings?.currentCityString ?? "") as AnyObject
                    sureDict["last_district"] = (gpsStrings?.currentDistrictString ?? "") as AnyObject
                    sureDict["last_state"] = (gpsStrings?.currentStateString ?? "") as AnyObject
                    sureDict["last_country"] = (gpsStrings?.currentCountryString ?? "") as AnyObject
                    
                    sureDict["data"] = yearTimes as AnyObject
                    sureDict["qibla"] = qibla as AnyObject
                    
                    let objc = sureDict as NSDictionary
                    
                    do {
                        if #available(iOS 11.0, *) {
                            let data = try NSKeyedArchiver.archivedData(withRootObject: objc, requiringSecureCoding: false)
                            try data.write(to: prayersArchivePath())
                        } else {
                            // Fallback on earlier versions
                            NSKeyedArchiver.archiveRootObject(objc, toFile: prayersArchivePath().path)
                        }
                    } catch {
                        logOrPrint("Couldn't archive prayers")
                    }
                    
                } else { return false }
            } else {
                // if reading data from file, deal with stored dictionary accordingly
                
                // check the last record's recieved location
//                if let formattedAddress = sureDict["location_recieved"] as? String {
//                    locationString = formattedAddress
//                }
                gpsStrings = GPSStrings(currentCityString: sureDict["last_city"] as? String,
                                        currentDistrictString: sureDict["last_district"] as? String,
                                        currentStateString: sureDict["last_state"] as? String,
                                        currentCountryString: sureDict["last_country"] as? String)
                
                readableLocationString = readableAddressString()
                
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
            // may still be nil if we are reading prayer times for a date not including today!
            if todayPrayerTimes.count != 0 {
                calculateCurrentPrayer()
                notifyDelegate()
                //must call set timers after updatecurrent prayer is called
                setTimers()
                scheduleAppropriateNotifications()
            }
        }
        
        return successful
    }
    
    func getFutureDateTuple(daysToSkip: Int = 1) -> (day: Int, month: Int, year: Int) {
        setCurrentDates()
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
            logOrPrint("Error Calculating tomorrow's date")
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
                self.logOrPrint("User denied use of notifications")
            }
            //            let alertController = UIAlertController(title: "Notifications Disabled", message: "To allow notifications later, use iOS settings", preferredStyle: .)
        }
        
        center.removeAllPendingNotificationRequests()
//
//        center.getDeliveredNotifications { (reqs) in
//            print("last delivered notification count: \(reqs.count)")
//        }
        
        //        center.getPendingNotificationRequests(completionHandler: { (reqs) in
        //            print("last pending notification count: \(reqs.count)")
        //        })
        //
        
        for i in 0..<5 {
            self.createNotificationsForDayItemTuple(getFutureDateTuple(daysToSkip: i), finalFlag: i == 4)
        }
    }
    
    func notifyDelegate() {
        dataExists = true
        delegate?.dataReady(manager: self)
    }
    
    func calculateCurrentPrayer() {
        self.currentPrayer = .isha //in case its a new day and fajr didnt start
        let curDate = Date()
        
        for i in 0...5 {
            let p = PrayerType(rawValue: i)!
            //ascending if the compared one is greater
            if let time = self.todayPrayerTimes[p.rawValue] {
                // allow for 2 seconds of overestimation of current time in case this is triggered just before a prayer is calculated
                let adjTime = Calendar.current.date(byAdding: .second, value: -2, to: time)!
                if curDate.compare(adjTime) == ComparisonResult.orderedDescending {
                    //WARNING: THIS MIGHT FAIL WHEN THE DATE IS AFTER
                    print("CURRENT PRAYER IS \(p.rawValue)")
                    self.currentPrayer = PrayerType(rawValue: p.rawValue)! // select the previous date prayer
                } else {
                    return
                }
            }
        }
    }
    
    
    func logOrPrint(_ str: StaticString) {
        if #available(iOS 12.0, *) {
            os_log(.debug, str)
            print(str)
        } else {
            print(str)
        }
    }
    
    /// set triggers that relate to repeated app state changes
    func setTimers() {
        // create prayer times
        let curDate = Date()
        // if we arent in the case where we are on the same day as "today's fajr" and its not isha
        if !(currentPrayer == .isha && todayPrayerTimes[0] < Date()) {
            var startIndex = currentPrayer.rawValue + 1
            if currentPrayer == .isha {
                startIndex = 0
            }
//            if currentPrayer == .none {
//                startIndex = 0
//            }
            for i in (startIndex)...5 {
                let p = PrayerType(rawValue: i)!
                if let pDate = todayPrayerTimes[p.rawValue] {
                    //timer for highlight red for 15 mins left
//                    print("time interval til 15 m warning: \(pDate.timeIntervalSince(curDate) - 900)")
                    Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate) - 900, target: self, selector: #selector(PrayerManager.fifteenMinutesLeft), userInfo: nil, repeats: false)
                    //timer for new prayer
                    Timer.scheduledTimer(timeInterval: pDate.timeIntervalSince(curDate), target: self, selector: #selector(PrayerManager.newPrayerTimerTrigger), userInfo: nil, repeats: false)
                } else {
                    logOrPrint("error getting prayer time while setting timers!")
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
    
    /// Called on change of AM / PM time
    @objc func newMeridiem() {
        Timer.scheduledTimer(timeInterval: 12 * 60 * 60, target: self, selector: #selector(PrayerManager.newMeridiem), userInfo: nil, repeats: false)
        delegate?.newMeridiem?()
    }
    
    /// Generates UNUserNotification for given day
    /// - parameters:
    ///     - t: tuple for day to make notifications in
    ///     - finalFlag: indicates whether that day is the last to have notifications before user mus reopen app
    func createNotificationsForDayItemTuple(_ t: (day: Int,  month: Int, year: Int), finalFlag: Bool) {
        print("making notifications for month: \(t.month), day: \(t.day), year: \(t.year), final: \(finalFlag)")
        
        let df = Global.dateFormatter
        df.dateFormat = "h:mm"
        
        // min holds raw value + 1 of prayer we want to calculate for teh day
        var min = 0
        //account for prayers that could have passed today
        if t.day == currentDay && t.month == currentMonth && t.year == currentYear {
            if currentPrayer == .isha && todayPrayerTimes[0] > Date() {
                min = 0 // case where its isha but we are on a new day
            } else if currentPrayer == .isha {
                return
            } else {
                min = currentPrayer.rawValue + 1
            }
        }
        
        let center = UNUserNotificationCenter.current()
        let noteSoundFilename = Settings.getSelectedSoundFilename()
        
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
                                    if noteSoundFilename == "DEFAULT" {
                                        noteContent.sound = .default
                                    } else {
                                        let soundName = UNNotificationSoundName(rawValue: "\(noteSoundFilename)-preview.caf")
                                        noteContent.sound = UNNotificationSound(named: soundName)
                                    }
                                }
                                
                                var alertString = ""
                                // finalFlag indicates that we have reached the limit for stored
                                // local notifications, and should let the user know
                                if finalFlag {
                                    if p == .isha {
                                        let localizedAlertString = NSLocalizedString("Time for %1$@ [%2$@]. Please reopen Athan Utility to continue recieving notifications.", comment: "")
                                        alertString = String(format: localizedAlertString, p.localizedString(), dateString)
                                    }
                                } else {
                                    var alternativeString: String?
                                    if var charRange = readableLocationString?.range(of: ",") {
                                        if let stringEnd = readableLocationString?.endIndex {
                                            charRange = Range(uncheckedBounds: (lower: charRange.lowerBound, upper: stringEnd))
                                            alternativeString = readableLocationString?.replacingCharacters(in: charRange, with: "")
                                        }
                                    }
                                    
                                    // Alternative string stores a shorter version of the location
                                    // in order to show "San Francisco" instead of "San Francisco, CA, USA"
                                    let localizedStandardNote = NSLocalizedString("Time for %1$@ in %2$@ [%3$@]", comment: "")
                                    if let alt = alternativeString {
                                        alertString = String(format: localizedStandardNote, p.localizedString(), alt, dateString)
                                    } else {
                                        alertString = String(format: localizedStandardNote, p.localizedString(), readableLocationString ?? "", dateString)
                                    }
                                }
                                
                                // set the notification body
                                noteContent.body = alertString

                                // create a trigger with the correct date
                                let dateComp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: pDate)
                                let noteTrigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: false)
                                // create request, and make sure it is added on the main thread (there was an issue before with the old UINotificationCenter. test for whether this is needed)
                                let noteID = "standard_note_\(dateComp.day!)_\(dateComp.hour!)_\(dateComp.minute!)"
                                let noteRequest = UNNotificationRequest(identifier: noteID, content: noteContent, trigger: noteTrigger)
//                                print(alertString)
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
                                    preNoteContent.sound = .default
                                }
                                
                                var alertString = ""
                                
                                var alternativeString: String?
                                if var charRange = readableLocationString?.range(of: ",") {
                                    if let stringEnd = readableLocationString?.endIndex {
                                        charRange = Range(uncheckedBounds: (lower: charRange.lowerBound, upper: stringEnd))
                                        alternativeString = readableLocationString?.replacingCharacters(in: charRange, with: "")
                                    }
                                }
                                
                                let localized15mAlert = NSLocalizedString("15m left til %1$@ in %2$@! [%3$@]", comment: "")
                                if let alt = alternativeString {
                                    alertString = String(format: localized15mAlert, p.localizedString(), alt, dateString)
                                } else {
                                    alertString = String(format: localized15mAlert, p.localizedString(), readableLocationString!, dateString)
                                }
                                
                                preNoteContent.body = alertString
                                
                                // hold onto the intended date for notification so that local notes can be handled in an accurate alert view
                                preNoteContent.userInfo["intendedDate"] = pDate
                               
                                //create a unique time based id
                                let preNoteID = "pre_note_\(preNoteComponents.day!)_\(preNoteComponents.hour!)_\(preNoteComponents.minute!)"
                                
                                let preNoteRequest = UNNotificationRequest(identifier: preNoteID, content: preNoteContent, trigger: preNoteTrigger)
                                
//                                print(alertString)
                                center.add(preNoteRequest, withCompletionHandler: nil)
                            }
                        }
                    }
                }
            }
        }
    }
        
    /// indicates that there are 15 m left til next prayer begins.
    /// Should adjust app by changing color of certain things to orange
    @objc func fifteenMinutesLeft() {
        print("15 mins (or less) left!!")
        Global.statusColor = UIColor.orange
        delegate?.fifteenMinutesLeft?()
    }
    
    // for when the manager needs to notify itself mid-day
    @objc func newPrayerTimerTrigger() {
        Global.statusColor = UIColor.green
        calculateCurrentPrayer()
        
        delegate?.newPrayer?(manager: self)
    }
    
    // returns the athan time for the "active" or "current" prayer session time
    func currentPrayerTime() -> Date {
        if currentPrayer == .isha && Date() < todayPrayerTimes[0] {
            // if none and its the next day, then substract the day by one and use the today isha time
            let cal = Calendar.current
            let closeToTodaysIsha = todayPrayerTimes[PrayerType.isha.rawValue]!
            var comps = (cal as NSCalendar).components([.year, .month, .day, .hour, .minute, .timeZone], from: closeToTodaysIsha)
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
            return todayPrayerTimes[currentPrayer.rawValue]!
        }
//        if let closeToIsha = todayPrayerTimes[PrayerType.isha.rawValue] {
//            if currentPrayer == .none && Date().timeIntervalSince(closeToIsha) < 0 {
//                // if none and its the next day, then substract the day by one and use the today isha time
//                let cal = Calendar.current
//
//                    var comps = (cal as NSCalendar).components([.year, .month, .day, .hour, .minute, .timeZone], from: closeToIsha)
//                    if comps.day == 1 {
//                        if comps.month == 1 {
//                            comps.year! -= 1
//                            comps.month = 12
//                            comps.day = daysInMonth(12)
//                        } else {
//                            comps.month! -= 1
//                            comps.day = daysInMonth(comps.month!)
//                        }
//                    } else {
//                        comps.day! -= 1
//
//                    }
//                    return cal.date(from: comps)
//            } else if currentPrayer != .none {
//                return todayPrayerTimes[currentPrayer.rawValue]
//            }
//        }
//        return nil
    }
    
    func previousPrayerTime() -> Date {
        if currentPrayer == .fajr || (currentPrayer == .isha && Date() < todayPrayerTimes[0]) {
            return yesterdayPrayerTimes[PrayerType.isha.rawValue]!
        } else {
            return todayPrayerTimes[currentPrayer.previous().rawValue]!
        }
    }
    
    func nextPrayerTime() -> Date? {
        //for cases where we are looking into next day
        if currentPrayer == .isha && Date() > todayPrayerTimes[0] { // case where we must read from tomorrow
            if let storedNext = tomorrowPrayerTimes[PrayerType.fajr.rawValue] {
                return storedNext
            } else {
                return todayPrayerTimes[PrayerType.fajr.rawValue]?.addingTimeInterval(86400)
            }
        } else if currentPrayer == .isha {
            return todayPrayerTimes[0]
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
        fetchMonthsJSONDataForCurrentLocation()
    }
    
    func fetchMonthsJSONDataForCurrentLocation(completion: ((Bool) -> ())? = nil) {
        var gpsLoc = (gpsStrings?.currentCityString ?? "") + ", "
        gpsLoc += (gpsStrings?.currentDistrictString ?? "") + ", "
        gpsLoc += (gpsStrings?.currentStateString ?? "") + ", "
        gpsLoc += (gpsStrings?.currentCountryString ?? "")
        fetchJSONData(forLocation: gpsLoc, dateTuple: nil) { success1 in
            if success1 {
                let nextMonthTuple = self.getFutureDateTuple(daysToSkip: daysInMonth(self.currentMonth!) + 1 - self.currentDay!)
                self.fetchJSONData(forLocation: gpsLoc, dateTuple: (month: nextMonthTuple.month, nextMonthTuple.year)) { success2 in
                    if success2 {
                        // update widgets if available
                        if #available(iOS 14.0, *) {
                            // only if this is being run in the main app:
                            if let bundleID = Bundle.main.bundleIdentifier, bundleID == "com.omaralejel.Athan-Utility" {
                                DispatchQueue.main.async {
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                        }
                    } else {
                        completion?(false)
                    }
                }
            } else {
                completion?(false)
            }
        }
    }
    
    /// - important: testing this function in simulator will not accurately reflect change of location and locked locations
    func userRequestsReload() {
        //for simulator
        ignoreLocationUpdates = false
        
        if !shouldSyncLocation {
            // if a custom location is explicitly set, get JSON
            fetchMonthsJSONDataForCurrentLocation { (success) in
                self.delegate?.locationIsSynced = false
            }
        } else {
            // else, we check for our current location as well
            coreManager.startUpdatingLocation()
        }
    }
    
    @objc func userCanceledDataRequest() {
        delegate?.hideLoadingView?()
    }
    
    //MARK: – Automatic Refreshing
    
    
    // note that this is not called on the first foreground update
    @objc func enteredForeground() {
        ignoreLocationUpdates = false
        // not sure if we are still in same location – will know later
        delegate?.locationIsSynced = false
        coreManager.startUpdatingLocation()
    }
    
    private func hasDataForNextMonth() -> Bool {
        let daysTilNextMonth = daysInMonth(self.currentMonth!) + 1 - self.currentDay!
        let nextMonthTuple = getFutureDateTuple(daysToSkip: daysTilNextMonth)
        if let _ = yearTimes[nextMonthTuple.year]?[nextMonthTuple.month] {
            return false
        }
        return true
    }
    
    /// returns true of user is in same location and there is enough data stored for the next month
    func shouldRequestJSONForLocation(locality: String?, subAdminArea: String?, state: String?, countryCode: String?) -> Bool {
        print("Checking if should update location")
        // first test if user is in same location
        if gpsStrings?.currentCityString == locality && gpsStrings?.currentDistrictString == subAdminArea && gpsStrings?.currentCountryString == countryCode {
            // then test if we have have data for next month before saving
            if hasDataForNextMonth() {
                print(" - no")
                return false
            }
        }
        print(" - yes")
        return true
    }
    
    //MARK: - Data Saving
    
    func prayersArchivePath() -> URL {
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
