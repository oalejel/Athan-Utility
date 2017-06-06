//
//  WatchDataManager.swift
//  Athan Utility
//
//  Created by Omar Alejel on 12/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

enum PrayerType: Int {
    case fajr, shurooq, thuhr, asr, maghrib, isha
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
        }
    }
    
    //incrementors
    func next() -> PrayerType {
        if self == .isha {return .fajr}
        return PrayerType(rawValue: self.rawValue + 1)!
    }
    func previous() -> PrayerType {
        if self == .fajr {return .isha}
        return PrayerType(rawValue: self.rawValue - 1)!
    }
}

class WatchDataManager: NSObject, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    
    ///variables
    let dateFormatter = DateFormatter()
    var currentDay = 0
    var currentMonth = 0
    var currentYear = 0
    
    var yearTimes: [Int : [Int : [Int : [PrayerType : Date]]]] = Dictionary()
    var todayPrayerTimes: [PrayerType : Date] = Dictionary()
    var tomorrowPrayerTimes: [PrayerType : Date] = Dictionary()
    var yesterdayPrayerTimes: [PrayerType : Date] = Dictionary()
    var locationString = ""
    
    var currentPrayer = PrayerType.fajr
    
    var timeElapsed: TimeInterval = 0
    var interval: TimeInterval = 0
    
    var delegate: WatchDataDelegate!
    
    var elapsedTimer: Timer?
    var dataReady = false
    
//    var kickTimer: NSTimer?
//    var kickTime = 0
    
    //MARK: Init
    init(delegate: WatchDataDelegate) {
        super.init()
        self.delegate = delegate
        ///time to get data from phone!
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
  
//            let documentDirectories = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
//            let documentDirectory = documentDirectories.first
//            
//            let x = documentDirectory! + "/data"
            
            
            
            let fm = FileManager.default
            let prayersURL = prayersArchivePath()
//            let file = NSKeyedUnarchiver.unarchiveObject(withFile: containerURL!.absoluteString)
            print("the filepath is \(prayersURL.path)")

            
//            let data = NSData(contentsOf: containerURL!)
//            if let trueData = data {
            let data = NSKeyedUnarchiver.unarchiveObject(withFile: (prayersURL.path))
                if let dict = NSKeyedUnarchiver.unarchiveObject(withFile: (prayersURL.path)) as? NSDictionary {
                    print(dict)
                    //     parseDictionary(dict, fromFile: true)
                    
                    
                    parseDictionary(dict, fromFile: true)
                } else {
                    print("No saved file")
                }
        }
    }
    
    
    
    //MARK: - Data Saving
    
    func prayersArchivePath() -> URL{
        //        let documentDirectories = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        //        let documentDirectory = documentDirectories.first
        //
        //        let x = documentDirectory!.stringByAppendingString("/prayers.plist")
        
        let fm = FileManager.default
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")
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
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")
        containerURL = containerURL?.appendingPathComponent("customsettings.plist")
        return containerURL!
    }
    
    
    //MARK: Connectivity
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let documentDirectories = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectory = documentDirectories.first

        let x = documentDirectory! + "/data"
        
        if let dict = NSKeyedUnarchiver.unarchiveObject(withFile: file.fileURL.path) as? NSDictionary {
            print(dict)
            parseDictionary(dict, fromFile: true)
            //save for later...
            if NSKeyedArchiver.archiveRootObject(dict, toFile: x) {
                print("file saved")
            }
        } else {
            print("fail")
        }
    }
    

    //MARK: Other?
    
    func calculateProgress() {
        let startTime = currentPrayerTime()
        let endTime = nextPrayerTime()
        interval = endTime.timeIntervalSince(startTime)
        timeElapsed = Date().timeIntervalSince(startTime)
    }
    
    func currentPrayerTime() -> Date {
        if currentPrayer == .isha {
            if Date().timeIntervalSince(todayPrayerTimes[.isha]!) < 0 {
                if (Date().compare(tomorrowPrayerTimes[.fajr]!) == ComparisonResult.orderedAscending) {
                    let cal = Calendar.current
                    let closeToIsha = todayPrayerTimes[.isha]!
                    var comps = (cal as NSCalendar).components([.year, .month, .day, .hour, .minute], from: closeToIsha)
                    if comps.day == 1 {
                        if comps.month == 1 {
                            comps.year? -= 1
                            comps.month = 12
                            comps.day = daysInMonth(12)
                        } else {
                            comps.month? -= 1
                            comps.day = daysInMonth(comps.month!)
                        }
                    } else {
                        comps.day? -= 1
                    }
                    
                    return cal.date(from: comps)!
                }
            }
        }
        
        return todayPrayerTimes[currentPrayer]!
    }
    
    
    func nextPrayerTime() -> Date {
        if currentPrayer == .isha {
            if Date().timeIntervalSince(todayPrayerTimes[.isha]!) > 0 {
                return tomorrowPrayerTimes[.fajr]!
            } else {
                return todayPrayerTimes[.fajr]!
            }
        } else {
            //!!! this might not be good if the prayertype is none and next() returns fajr!!!
            return todayPrayerTimes[currentPrayer.next()]!
        }
    }
    
    
    
    
    ///
    
    func imageForPrayer(_ p: PrayerType) -> UIImage {
        var imageName = ""
        switch p {
        case .fajr:
            imageName = "sunhorizon"
        case .shurooq:
            imageName = "sunhorizon"
        case .thuhr:
            imageName = "sun"
        case .asr:
            imageName = "sunfilled"
        case .maghrib:
            imageName = "sunhorizon"
        case .isha:
            imageName = "moon"
        }
        
        return UIImage(named: imageName)!
    }

    func calculateCurrentPrayer() {
        //standard...
        currentPrayer = .isha
        let curDate = Date()
        for i in 0...5 {
            let p = PrayerType(rawValue: i)!
            //ascending if the compared one is greater
            if curDate.compare(todayPrayerTimes[p]!) == ComparisonResult.orderedDescending {
                //WARNING: THIS MIGHT FAIL WHEN THE DATE IS AFTER
                currentPrayer = PrayerType(rawValue: p.rawValue)!//select the previous date prayer
            }
        }
    }
    
    
    func parseDictionary(_ dict: NSDictionary, fromFile: Bool) {
//        if dict is Dictionary {
            if let x = dict["address"] as? String {
                if x != "" {
                    locationString = x
                } else {
                    //return
                    print("no location found...")
                }
//            }
            print("location: \(locationString)")
                
                
                
                
                
                
                
                
                
            
            
            
            
            //get prayer times in text and parse into dates
            if let daysArray = dict["items"] as? NSArray {
                //add days in months
                var dayOffset = 0
                let df = dateFormatter
                
                //get the date info for today to use for computation
                let curDate = Date()
                dateFormatter.dateFormat = "y"
                currentYear = Int(df.string(from: curDate))!
                dateFormatter.dateFormat = "d"
                currentDay = Int(df.string(from: curDate))!
                dateFormatter.dateFormat = "M"
                currentMonth = Int(df.string(from: curDate))!
                
                //below will be different if from a file in the past
                var startMonth = currentMonth
                var startYear = currentYear
                var startDay = currentDay
                
                //check to see if data is still up to date
                if fromFile {
                    
                    //if same year, continue
                    if let yearReceievedString = dict["year_recieved"] as? String {
                        let yearReceieved = Int(yearReceievedString)
                        
                        //find the index we want to start reading from
                        if let monthRecievedString = dict["month_recieved"] as? String {
                            let monthRecieved = Int(monthRecievedString)!
                            
                            //find the index we want to start reading from
                            if let dayRecievedString = dict["day_recieved"] as? String {
                                let dayRecieved = Int(dayRecievedString)!
                                
                                startYear = yearReceieved!
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
                var yearIncrementor = startYear
                var monthIncrementor = startMonth
                var dayIncrementor = startDay
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
                
                todayPrayerTimes = yearTimes[currentYear]![currentMonth]![currentDay]!
                
                var tomorrowDay = currentDay
                var tomorrowMonth = currentMonth
                var tomorrowYear = currentYear
                if currentDay == daysInMonth(currentMonth) {
                    if currentMonth == 12 {
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
                if let tomorrow = yearTimes[tomorrowYear]?[tomorrowMonth]?[tomorrowDay] {
                    tomorrowPrayerTimes = tomorrow
                }
                
                var yesterdayDay = currentDay
                var yesterdayMonth = currentMonth
                var yesterdayYear = currentYear
                if currentDay == 1 {
                    if currentMonth == 1 {
                        //new year
                        yesterdayYear -= 1
                        yesterdayDay = daysInMonth(12)
                        yesterdayMonth = 12
                    } else {
                        //new month
                        yesterdayMonth -= 1
                        yesterdayDay = daysInMonth(yesterdayMonth)
                    }
                } else {
                    yesterdayDay -= 1
                }
                //!!! important: need to make sure that we also have last month's prayer times if 1st day of month!!!
                if let yesterday = yearTimes[yesterdayYear]?[yesterdayMonth]?[yesterdayDay] {
                    yesterdayPrayerTimes = yesterday
                }
                
                print(tomorrowPrayerTimes)
                
                alignPrayerTimes()
                
                calculateCurrentPrayer()
                dataReady = true
                notifyDelegate()
                
                //must call set timers after updatecurrent prayer is called
                //setTimers()
                
                elapsedTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(WatchDataManager.updateElapsed), userInfo: nil, repeats: true)
                
            } else {
                print("didnt get items...")
            }
        }
    }
    
    func updateElapsed() {
        if interval == 0 {
            calculateProgress()
        } else {
            timeElapsed += 1
            if timeElapsed >= interval {
                //needs update for new prayer: new label colored, new label data, reset progress circle
                delegate.updatePrayer?()
            } else {
                //just update circle
                delegate.updateProgress?()
            }
        }
    }
    
    func notifyDelegate() {
        delegate.dataReady(manager: self)
    }
    
    //MARK: old datamanager stuff
    func alignPrayerTimes() {
        //get the date info for today to use for computation
        let curDate = Date()
        dateFormatter.dateFormat = "y"
        currentYear = Int(dateFormatter.string(from: curDate))!
        dateFormatter.dateFormat = "d"
        currentDay = Int(dateFormatter.string(from: curDate))!
        dateFormatter.dateFormat = "M"
        currentMonth = Int(dateFormatter.string(from: curDate))!
        
        todayPrayerTimes = yearTimes[currentYear]![currentMonth]![currentDay]!
        
        var tomorrowDay = currentDay
        var tomorrowMonth = currentMonth
        var tomorrowYear = currentYear
        if currentDay == daysInMonth(currentMonth) {
            if currentMonth == 12 {
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
        if let tomorrow = yearTimes[tomorrowYear]?[tomorrowMonth]?[tomorrowDay] {
            tomorrowPrayerTimes = tomorrow
        }
        
        var yesterdayDay = currentDay
        var yesterdayMonth = currentMonth
        var yesterdayYear = currentYear
        if currentDay == 1 {
            if currentMonth == 1 {
                //new year
                yesterdayYear -= 1
                yesterdayDay = daysInMonth(12)
                yesterdayMonth = 12
            } else {
                //new month
                yesterdayMonth -= 1
                yesterdayDay = daysInMonth(yesterdayMonth)
            }
        } else {
            yesterdayDay -= 1
        }
        //!!! important: need to make sure that we also have last month's prayer times if 1st day of month!!!
        if let yesterday = yearTimes[yesterdayYear]?[yesterdayMonth]?[yesterdayDay] {
            yesterdayPrayerTimes = yesterday
        }
    }
    
    func  daysInMonth(_ m: Int) -> Int {
        switch m {
        case 1:
            return 31
        case 2:
            let df = dateFormatter
            df.dateFormat = "y"
            let year = Int(df.string(from: Date()))!
            if year % 4 == 0 {
                if year % 100 == 0 {
                    if year % 400 != 0 {
                        return 28
                    }
                    return 29
                } else {
                    //only leap year when div. by 4, but if div by 100, then must be div by 400
                    return 29
                }
            } else {
                return 28
            }
        case 3:
            return 31
        case 4:
            return 30
        case 5:
            return 31
        case 6:
            return 30
        case 7:
            return 31
        case 8:
            return 31
        case 9:
            return 30
        case 10:
            return 31
        case 11:
            return 30
        case 12:
            return 31
        default:
            return 30
        }
    }
    
}
