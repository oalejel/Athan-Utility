//
//  Global.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/9/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

import UIKit

/*
    Global.swift contains many standard Athan Utility
    functions and colors used throughout the application
 */



func hijriString(for month: Int, day: Int, year: Int) -> String {
    let months = ["Muḥarram", "Ṣafar", "Rabīʿ al-Awwal",
                  "Rabīʿ ath-Thānī", "Jumādá al-Ūlá", "Jumādá al-Ākhirah",
                  "Rajab", "Sha‘bān", "Ramaḍān", "Shawwāl", "Dhū al-Qa‘dah", "Dhū al-Ḥijjah"
    ]
    return "\(day) \(months[(month - 1) % 12]), \(year)"
}

func daysInMonth(_ m: Int) -> Int {
    switch m {
    case 1:
        return 31
    case 2:
        let df = Global.dateFormatter
        df.dateFormat = "y"
        let curDate = Date()
        let year = Int(df.string(from: curDate))!
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

extension UIColor {
    static var darkestGray = UIColor(white: 0.1, alpha: 1)//for things that need to contrast with other gray
    static var darkerGray = UIColor(white: 0.15, alpha: 1)//lighter than darkest, use for buttons and other
}

class Global {
    //put shared classes and stuff here
    class var dateFormatter: DateFormatter {
        struct Formatter {
            static let instance = DateFormatter()
        }
        
        return Formatter.instance
    }
    static var statusColor = UIColor.green
    
    static var manager: PrayerManager!
    
    static var openQibla = false

    static let HIDE_SIRI_SHORTCUTS_KEY = "hideSiriShortcuts"
    
    /*
    class func colorsForPrayer(_ p: PrayerType) -> [CGColor] {
        var colors: [CGColor]!
        switch p {
        case .fajr:
            colors = [UIColor(red: 0.98823, green: 0.6549, blue: 0.498, alpha: 1).cgColor, UIColor(red: 0.54509, green: 0.30588, blue: 0.7098, alpha: 1).cgColor]
        case .shurooq:
            colors = [UIColor(red: 0.9019, green: 0.694, blue: 0.1882, alpha: 1).cgColor, UIColor(red: 0.8627, green: 0.6039, blue: 0.7490, alpha: 1).cgColor]
        case .thuhr:
            colors = [UIColor(red: 0.5333, green: 0.8549, blue: 0.9058, alpha: 1).cgColor, UIColor(red: 0.2235, green: 0.50196, blue: 1, alpha: 1).cgColor]
        case .asr:
            colors = [UIColor(red: 0.4078, green: 1, blue: 0.51764, alpha: 1).cgColor, UIColor(red: 0.05098, green: 0.4980, blue: 1, alpha: 1).cgColor]
        case .maghrib:
            colors = [UIColor(red: 0.79215, green: 0.6823, blue: 0.9490, alpha: 1).cgColor, UIColor(red: 0.8509, green: 0.1294, blue: 0.21569, alpha: 1).cgColor]
        case .isha:
            colors = [UIColor(red: 0.33333, green: 0.2078, blue: 0.98039, alpha: 1).cgColor, UIColor(red: 0.85098, green: 0.12941, blue: 0.21569, alpha: 1).cgColor]
        default:
            colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        }
        
        return colors
    }
 */    
}
