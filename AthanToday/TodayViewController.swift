//
//  TodayViewController.swift
//  AthanToday
//
//  Created by Omar Alejel on 11/30/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import NotificationCenter

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

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var currentPrayerLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var nextTimeLabel: UILabel!
    @IBOutlet weak var nextPrayerLabel: UILabel!
    
    let dateFormatter = DateFormatter()
    var currentDay = 0
    var currentMonth = 0
    var currentYear = 0
    
    var yearTimes: [Int : [Int : [Int : [Int : Date]]]] = Dictionary()
    var todayPrayerTimes: [Int : Date] = Dictionary()
    var tomorrowPrayerTimes: [Int : Date] = Dictionary()
    var yesterdayPrayerTimes: [Int : Date] = Dictionary()
    var locationString = ""
    
    var currentPrayer = PrayerType.fajr
    
    var timeElapsed: TimeInterval = 0
    var interval: TimeInterval = 0
    
    var kickTimer: Timer?
    var kickTime = 0
    var secondsTimer: Timer!
    // @IBOutlet weak var locationLabel: UILabel!
    
    var viewAppearedOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        preferredContentSize = CGSize(width: 0, height: 80)
        
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        
        if let dict = dictionaryFromFile() {
            parseDictionary(dict, fromFile: true)
            calculateCurrentPrayer()
            setStuff()
            calculateProgress()
            progressView.setProgress(Float(timeElapsed / interval), animated: false)
            kickstartTimer()
            for v in view.subviews {
                if v.tag == 1 {
                    v.isHidden = true
                } else {
                    v.isHidden = false
                }
            }
        } else {
            //!! show a message
            for v in view.subviews {
                if v.tag == 1 {
                    v.isHidden = false
                } else {
                    v.isHidden = true
                }
            }
        }
    }
    
    func setStuff() {
        //no need for "true"
        
        imageView.image = imageForPrayer(currentPrayer)
        currentPrayerLabel.text = currentPrayer.stringValue()
        
        let nextPrayer = currentPrayer.next()
        dateFormatter.dateFormat = "hh:mm a"
        if nextPrayer == .fajr {
            if Date().timeIntervalSince(todayPrayerTimes[PrayerType.fajr.rawValue]!) < 0 {
                nextTimeLabel.text = dateFormatter.string(from: todayPrayerTimes[nextPrayer.rawValue]!)
            } else {
                nextTimeLabel.text = dateFormatter.string(from: tomorrowPrayerTimes[nextPrayer.rawValue]!)
            }
        } else {
            nextTimeLabel.text = dateFormatter.string(from: todayPrayerTimes[nextPrayer.rawValue]!)
        }
        nextPrayerLabel.text = nextPrayer.stringValue()
        
        //locationLabel.text = locationString
    }
    
    func calculateProgress() {
        if let startTime = currentPrayerTime() {
            if let endTime = nextPrayerTime() {
                interval = endTime.timeIntervalSince(startTime)
                timeElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    func kickstartTimer() {
        dateFormatter.dateFormat = "s"
        let currentSeconds = Int(dateFormatter.string(from: Date()))!
        kickTime = 60 - currentSeconds
        Timer.scheduledTimer(timeInterval: TimeInterval(kickTime), target: self, selector: #selector(TodayViewController.startSecondsTimer), userInfo: nil, repeats: false)
    }
    
    @objc func startSecondsTimer() {
        //increment time for the first minute passed
        timeElapsed += Double(kickTime)
        //start a timer that waits every MINUTE (more efficient) {REPEATS}
        progressView.setProgress(Float(timeElapsed / interval), animated: false)
        secondsTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(TodayViewController.updateProgressView), userInfo: nil, repeats: true)
    }
    
    //whenever another minute has passed
    @objc func updateProgressView() {
        timeElapsed += 60
        if timeElapsed >= interval {
            calculateCurrentPrayer()
            setStuff()
            calculateProgress()
        }
        progressView.setProgress(Float(timeElapsed / interval), animated: false)
    }
    
    
    func currentPrayerTime() -> Date? {
        if currentPrayer == .isha {
            if Date().timeIntervalSince(todayPrayerTimes[PrayerType.isha.rawValue] ?? Date()) < 0 {
                if (Date().compare(tomorrowPrayerTimes[PrayerType.fajr.rawValue]!) == ComparisonResult.orderedAscending) {
                    let cal = Calendar.current
                    if let closeToIsha = todayPrayerTimes[PrayerType.isha.rawValue] {
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
                        
                        return cal.date(from: comps)
                    }
                }
            }
        }
        
        return todayPrayerTimes[currentPrayer.rawValue]
    }
    
    
    
    func nextPrayerTime() -> Date? {
        if currentPrayer == .isha {
            if let ishaTime = todayPrayerTimes[PrayerType.isha.rawValue] {
                if Date().timeIntervalSince(ishaTime) > 0 {
                    return tomorrowPrayerTimes[PrayerType.fajr.rawValue]
                } else {
                    return todayPrayerTimes[PrayerType.fajr.rawValue]
                }
            }
        } else {
            //!!! this might not be good if the prayertype is none and next() returns fajr!!!
            return todayPrayerTimes[currentPrayer.next().rawValue]
        }
        return nil
    }
    
    func widgetMarginInsets
        (forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
        return UIEdgeInsets.zero
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        //        ///get new data if dict is old!!!!
        //
        //        calculateCurrentPrayer()
        //        calculateProgress()
        //        setStuff()
        
        completionHandler(NCUpdateResult.noData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewAppearedOnce {
            
            //reset todays prayers if its a new day...
            dateFormatter.dateFormat = "d"
            let testDay = Int(dateFormatter.string(from: Date()))
            if testDay != currentDay {
                alignPrayerTimes()
            }
            
            
            calculateCurrentPrayer()
            calculateProgress()
            progressView.setProgress(Float(timeElapsed / interval), animated: false)
            setStuff()
            if kickTimer == nil {
                kickstartTimer()
            }
        } else {
            viewAppearedOnce = true
        }
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
    
    func prayersArchivePath() -> URL {
        let fm = FileManager.default
        var containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")
        containerURL = containerURL?.appendingPathComponent("prayers.plist")
        return containerURL!
    }
    
    func dictionaryFromFile() -> NSDictionary? {
        let dict = NSKeyedUnarchiver.unarchiveObject(withFile: prayersArchivePath().path) as? NSDictionary
        return dict
    }
    
    func calculateCurrentPrayer() {
        //standard...
        currentPrayer = .isha
        let curDate = Date()
        for i in 0...5 {
            let p = PrayerType(rawValue: i)!
            //ascending if the compared one is greater
            if curDate.compare(todayPrayerTimes[p.rawValue]!) == ComparisonResult.orderedDescending {
                //WARNING: THIS MIGHT FAIL WHEN THE DATE IS AFTER
                currentPrayer = PrayerType(rawValue: p.rawValue)!//select the previous date prayer
            }
        }
    }
    
    
//    func parseDictionary(_ dict: NSDictionary, fromFile: Bool) {
//        if var sureDict = dict as? [String:AnyObject] {
//            if let x = sureDict["address"] as? String {
//                if x != "" {
//                    locationString = x
//                } else {
//                    return
//                }
//            }
//            print("location: \(locationString)", terminator: "")
//
//
//
//
//            //get prayer times in text and parse into dates
//            if let daysArray = sureDict["items"] as? NSArray {
//                //add days in months
//                var dayOffset = 0
//                let df = dateFormatter
//
//                //get the date info for today to use for computation
//                let curDate = Date()
//                dateFormatter.dateFormat = "y"
//                currentYear = Int(df.string(from: curDate))!
//                dateFormatter.dateFormat = "d"
//                currentDay = Int(df.string(from: curDate))!
//                dateFormatter.dateFormat = "M"
//                currentMonth = Int(df.string(from: curDate))!
//
//                //below will be different if from a file in the past
//                var startMonth = currentMonth
//                var startYear = currentYear
//                var startDay = currentDay
//
//                //check to see if data is still up to date
//                if fromFile {
//
//                    //if same year, continue
//                    if let yearReceievedString = sureDict["year_recieved"] as? String {
//                        let yearReceieved = Int(yearReceievedString)
//
//                        //find the index we want to start reading from
//                        if let monthRecievedString = sureDict["month_recieved"] as? String {
//                            let monthRecieved = Int(monthRecievedString)!
//
//                            //find the index we want to start reading from
//                            if let dayRecievedString = sureDict["day_recieved"] as? String {
//                                let dayRecieved = Int(dayRecievedString)!
//
//                                startYear = yearReceieved!
//                                startMonth = monthRecieved
//                                startDay = dayRecieved
//
//                                if currentMonth == monthRecieved {
//                                    dayOffset = currentDay - dayRecieved
//                                } else {
//                                    //might need to something
//                                    dayOffset += daysInMonth(monthRecieved) - dayRecieved
//                                    dayOffset += currentDay
//                                    if currentMonth - 1 != monthRecieved {
//                                        for m in (monthRecieved + 1)...(currentMonth - 1) {
//                                            dayOffset += daysInMonth(m)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//
//
//                let swiftDaysArray = daysArray as! [[String : String]]
//                let prayers: [PrayerType] = [.fajr, .shurooq, .thuhr, .asr, .maghrib, .isha]
//                let customNames = ["fajr", "shurooq", "dhuhr", "asr", "maghrib", "isha"]
//
//                //will change throughout the days
//                var yearIncrementor = startYear
//                var monthIncrementor = startMonth
//                var dayIncrementor = startDay
//                //loop through all of the days and adjust the date each one is from using MATHS
//
//                //!!! remember to look at this!!!
//                var limiter = 40
//                for (_, dayDict) in swiftDaysArray.enumerated() {
//                    limiter -= 1
//                    if limiter == 0 {break}
//                    for p in prayers {
//                        //get the time for the prayer on the day, and then adjust turn into NSDate
//                        var timeString = dayDict[customNames[p.rawValue]]! as String
//                        df.dateFormat = "h:m a d:M:y"
//                        timeString = "\(timeString) \(dayIncrementor):\(monthIncrementor):\(yearIncrementor)"
//                        let theDate = df.date(from: timeString)
//
//                        if yearTimes[yearIncrementor] == nil {
//                            yearTimes[yearIncrementor] = [:]
//                        }
//                        if yearTimes[yearIncrementor]![monthIncrementor] == nil {
//                            yearTimes[yearIncrementor]![monthIncrementor] = [:]
//                        }
//                        if yearTimes[yearIncrementor]![monthIncrementor]![dayIncrementor] == nil {
//                            yearTimes[yearIncrementor]![monthIncrementor]![dayIncrementor] = [:]
//                        }
//
//                        yearTimes[yearIncrementor]![monthIncrementor]![dayIncrementor]![p] = theDate
//                    }
//
//                    if daysInMonth(monthIncrementor) == dayIncrementor {
//                        if monthIncrementor == 12 {
//                            //new year
//                            yearIncrementor += 1
//                            monthIncrementor = 1
//                            dayIncrementor = 1
//                        } else {
//                            //new month
//                            monthIncrementor += 1
//                            dayIncrementor = 1
//                        }
//                    } else {
//                        //new day
//                        dayIncrementor += 1
//                    }
//
//                }
//
//                todayPrayerTimes = yearTimes[currentYear]![currentMonth]![currentDay]!
//
//                var tomorrowDay = currentDay
//                var tomorrowMonth = currentMonth
//                var tomorrowYear = currentYear
//                if currentDay == daysInMonth(currentMonth) {
//                    if currentMonth == 12 {
//                        //new year
//                        tomorrowYear += 1
//                        tomorrowDay = 1
//                        tomorrowMonth = 1
//                    } else {
//                        //new month
//                        tomorrowMonth += 1
//                        tomorrowDay = 1
//                    }
//                } else {
//                    tomorrowDay += 1
//                }
//                if let tomorrow = yearTimes[tomorrowYear]?[tomorrowMonth]?[tomorrowDay] {
//                    tomorrowPrayerTimes = tomorrow
//                }
//
//                var yesterdayDay = currentDay
//                var yesterdayMonth = currentMonth
//                var yesterdayYear = currentYear
//                if currentDay == 1 {
//                    if currentMonth == 1 {
//                        //new year
//                        yesterdayYear -= 1
//                        yesterdayDay = daysInMonth(12)
//                        yesterdayMonth = 12
//                    } else {
//                        //new month
//                        yesterdayMonth -= 1
//                        yesterdayDay = daysInMonth(yesterdayMonth)
//                    }
//                } else {
//                    yesterdayDay -= 1
//                }
//                //!!! important: need to make sure that we also have last month's prayer times if 1st day of month!!!
//                if let yesterday = yearTimes[yesterdayYear]?[yesterdayMonth]?[yesterdayDay] {
//                    yesterdayPrayerTimes = yesterday
//                }
//            }
//        }
//    }
    
    
    
    //this organizes the data and notifies the delegate
    func parseDictionary(_ dict: NSDictionary?, fromFile: Bool) {
        if var sureDict = dict as? Dictionary<String, AnyObject> {

            if let formattedData = sureDict["data"] as? [Int : [Int : [Int : [Int : Date]]]] {
                yearTimes = formattedData
            } else {
                print("could not parse dictionary")
                return
            }
            
            if let formattedAddress = sureDict["location_recieved"] as? String {
                locationString = formattedAddress
            }
    
            alignPrayerTimes()
            calculateCurrentPrayer()
        } else {
            print("could not parse dictionary")
            return
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
    
    @IBAction func tapped(_ sender: AnyObject) {
        if let appURL = URL(string: "athan://home") {
            extensionContext?.open(appURL, completionHandler: nil)
        }
    }
}

