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
    case Fajr, Shurooq, Thuhr, Asr, Maghrib, Isha
    func stringValue() -> String {
        switch self {
        case .Fajr:
            return "Fajr"
        case .Shurooq:
            return "Shurooq"
        case .Thuhr:
            return "Thuhr"
        case .Asr:
            return "Asr"
        case .Maghrib:
            return "Maghrib"
        case .Isha:
            return "Isha"
        }
    }
    
    //incrementors
    func next() -> PrayerType {
        if self == .Isha {return .Fajr}
        return PrayerType(rawValue: self.rawValue + 1)!
    }
    func previous() -> PrayerType {
        if self == .Fajr {return .Isha}
        return PrayerType(rawValue: self.rawValue - 1)!
    }
}

class WatchDataManager: NSObject, WCSessionDelegate {
    
    ///variables
    let dateFormatter = NSDateFormatter()
    var currentDay = 0
    var currentMonth = 0
    var currentYear = 0
    
    var yearTimes: [Int : [Int : [Int : [PrayerType : NSDate]]]] = Dictionary()
    var todayPrayerTimes: [PrayerType : NSDate] = Dictionary()
    var tomorrowPrayerTimes: [PrayerType : NSDate] = Dictionary()
    var yesterdayPrayerTimes: [PrayerType : NSDate] = Dictionary()
    var locationString = ""
    
    var currentPrayer = PrayerType.Fajr
    
    var timeElapsed: NSTimeInterval = 0
    var interval: NSTimeInterval = 0
    
    var delegate: WatchDataDelegate!
    
    var elapsedTimer: NSTimer?
    var dataReady = false
    
//    var kickTimer: NSTimer?
//    var kickTime = 0
    
    //MARK: Init
    init(delegate: WatchDataDelegate) {
        super.init()
        self.delegate = delegate
        ///time to get data from phone!
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
  
            let documentDirectories = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let documentDirectory = documentDirectories.first
            
            let x = documentDirectory!.stringByAppendingString("/data")
            if let dict = NSKeyedUnarchiver.unarchiveObjectWithFile(x) as? NSDictionary {
                print(dict)
                parseDictionary(dict, fromFile: true)
            } else {
                print("No saved file")
            }
        }
        
    }
    
    //MARK: Connectivity
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        let documentDirectories = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentDirectory = documentDirectories.first

        let x = documentDirectory!.stringByAppendingString("/data")
        
        if let dict = NSKeyedUnarchiver.unarchiveObjectWithFile(file.fileURL.path!) as? NSDictionary {
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
        interval = endTime.timeIntervalSinceDate(startTime)
        timeElapsed = NSDate().timeIntervalSinceDate(startTime)
    }
    
    func currentPrayerTime() -> NSDate {
        if currentPrayer == .Isha {
            if NSDate().timeIntervalSinceDate(todayPrayerTimes[.Isha]!) < 0 {
                if (NSDate().compare(tomorrowPrayerTimes[.Fajr]!) == NSComparisonResult.OrderedAscending) {
                    let cal = NSCalendar.currentCalendar()
                    let closeToIsha = todayPrayerTimes[.Isha]!
                    let comps = cal.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeToIsha)
                    if comps.day == 1 {
                        if comps.month == 1 {
                            comps.year -= 1
                            comps.month = 12
                            comps.day = daysInMonth(12)
                        } else {
                            comps.month -= 1
                            comps.day = daysInMonth(comps.month)
                        }
                    } else {
                        comps.day -= 1
                    }
                    
                    return cal.dateFromComponents(comps)!
                }
            }
        }
        
        return todayPrayerTimes[currentPrayer]!
    }
    
    
    func nextPrayerTime() -> NSDate {
        if currentPrayer == .Isha {
            if NSDate().timeIntervalSinceDate(todayPrayerTimes[.Isha]!) > 0 {
                return tomorrowPrayerTimes[.Fajr]!
            } else {
                return todayPrayerTimes[.Fajr]!
            }
        } else {
            //!!! this might not be good if the prayertype is none and next() returns fajr!!!
            return todayPrayerTimes[currentPrayer.next()]!
        }
    }
    
    
    
    
    ///
    
    func imageForPrayer(p: PrayerType) -> UIImage {
        var imageName = ""
        switch p {
        case .Fajr:
            imageName = "sunhorizon"
        case .Shurooq:
            imageName = "sunhorizon"
        case .Thuhr:
            imageName = "sun"
        case .Asr:
            imageName = "sunfilled"
        case .Maghrib:
            imageName = "sunhorizon"
        case .Isha:
            imageName = "moon"
        }
        
        return UIImage(named: imageName)!
    }

    func calculateCurrentPrayer() {
        //standard...
        currentPrayer = .Isha
        let curDate = NSDate()
        for i in 0...5 {
            let p = PrayerType(rawValue: i)!
            //ascending if the compared one is greater
            if curDate.compare(todayPrayerTimes[p]!) == NSComparisonResult.OrderedDescending {
                //WARNING: THIS MIGHT FAIL WHEN THE DATE IS AFTER
                currentPrayer = PrayerType(rawValue: p.rawValue)!//select the previous date prayer
            }
        }
    }
    
    
    func parseDictionary(dict: NSDictionary, fromFile: Bool) {
        if var sureDict = dict as Dictionary? {
            if let x = sureDict["address"] as? String {
                if x != "" {
                    locationString = x
                } else {
                    //return
                    print("no location found...")
                }
            }
            print("location: \(locationString)")
            
            
            
            
            //get prayer times in text and parse into dates
            if let daysArray = sureDict["items"] as? NSArray {
                //add days in months
                var dayOffset = 0
                let df = dateFormatter
                
                //get the date info for today to use for computation
                let curDate = NSDate()
                dateFormatter.dateFormat = "y"
                currentYear = Int(df.stringFromDate(curDate))!
                dateFormatter.dateFormat = "d"
                currentDay = Int(df.stringFromDate(curDate))!
                dateFormatter.dateFormat = "M"
                currentMonth = Int(df.stringFromDate(curDate))!
                
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
                let prayers: [PrayerType] = [.Fajr, .Shurooq, .Thuhr, .Asr, .Maghrib, .Isha]
                let customNames = ["fajr", "shurooq", "dhuhr", "asr", "maghrib", "isha"]
                
                //will change throughout the days
                var yearIncrementor = startYear
                var monthIncrementor = startMonth
                var dayIncrementor = startDay
                //loop through all of the days and adjust the date each one is from using MATHS
                
                //!!! remember to look at this!!!
                var limiter = 40
                for (_, dayDict) in swiftDaysArray.enumerate() {
                    limiter -= 1
                    if limiter == 0 {break}
                    for p in prayers {
                        //get the time for the prayer on the day, and then adjust turn into NSDate
                        var timeString = dayDict[customNames[p.rawValue]]! as String
                        df.dateFormat = "h:m a d:M:y"
                        timeString = "\(timeString) \(dayIncrementor):\(monthIncrementor):\(yearIncrementor)"
                        let theDate = df.dateFromString(timeString)
                        
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
                
                elapsedTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(WatchDataManager.updateElapsed), userInfo: nil, repeats: true)
                
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
        let curDate = NSDate()
        dateFormatter.dateFormat = "y"
        currentYear = Int(dateFormatter.stringFromDate(curDate))!
        dateFormatter.dateFormat = "d"
        currentDay = Int(dateFormatter.stringFromDate(curDate))!
        dateFormatter.dateFormat = "M"
        currentMonth = Int(dateFormatter.stringFromDate(curDate))!
        
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
    
    func  daysInMonth(m: Int) -> Int {
        switch m {
        case 1:
            return 31
        case 2:
            let df = dateFormatter
            df.dateFormat = "y"
            let year = Int(df.stringFromDate(NSDate()))!
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
