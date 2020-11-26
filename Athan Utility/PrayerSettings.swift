//
//  PrayerSettings.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/21/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation
import Adhan
import CoreLocation.CLLocation

// Helper function for storing settings
func archiveToPath(_ path: String, object: AnyObject) {
    print("WARNING: ADD ERROR HANDLER TO THIS")
    let fm = FileManager.default
    var url = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")!
    url = url.appendingPathComponent("prayersettings.plist")
    
    if #available(iOS 11.0, *) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
            try data.write(to: url)
        } catch {
            print("error archiving prayer settings")
        }
    } else {
        // Fallback on earlier versions
        NSKeyedArchiver.archiveRootObject(object, toFile: url.path)
    }
}

func unarchiveFromPath(_ path: String) -> Any? {
    let fm = FileManager.default
    var url = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")!
    url = url.appendingPathComponent("prayersettings.plist")
    var object: Any?
    do {
        if #available(iOS 11.0, *) {
            let data = try Data(contentsOf: url)
            object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
        } else {
            // Fallback on earlier versions
            object = NSKeyedUnarchiver.unarchiveObject(withFile: url.path)
        }
    } catch {
        print("Couldn't unarchive from path: \(path)")
    }
    return object
}

// Manages loading and storing of settings for calculations
class PrayerSettings {
    static var shared = PrayerSettings()
    
    // default values to be overridden from settings if they exist
    var calculationMethod: CalculationMethod = CalculationMethod.northAmerica
    var madhab: Madhab = .shafi
    // store potential override names for athan times
    
    var customNames: [Prayer:String] = [:]
}

class NotificationSettings {
    static var shared = NotificationSettings()
    
    
}


class LocationSettings {
    static var shared = LocationSettings()

    var locationCoordinate: CLLocationCoordinate2D? = nil
    var locationName: String? = nil
}
