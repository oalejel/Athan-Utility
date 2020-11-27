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

// Manages loading and storing of settings for calculations
class PrayerSettings: Codable {
    static var shared: PrayerSettings = {
        if let s = unarchive(archiveName) as? PrayerSettings {
            return s
        } else {
            let defaultSettings = PrayerSettings()
            return defaultSettings
        }
    }()
    
    static func archive() {
        UserDefaults.standard.setValue(PrayerSettings.shared, forKey: archiveName)
//        archiveToName(archiveName, object: shared)
    }
    
    // default values to be overridden from settings if they exist
    var calculationMethod: CalculationMethod = CalculationMethod.northAmerica
    var madhab: Madhab = .shafi
    // store potential override names for athan times
    
    var customNames: [Prayer:String] = [:]
    private static let archiveName = "prayersettings"
}




enum AlarmSetting: Int, Codable {
    case all, noEarly, none
}

struct NotificationSetting: Codable {
    var soundEnabled = true
    var alarmType = AlarmSetting.all
}

extension Prayer: Codable {
    enum PrayerKey: CodingKey {
        case key
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PrayerKey.self)
        let raw = try container.decodeIfPresent(Int.self, forKey: .key)
        switch raw {
        case 0:
            self = .fajr
        case 1:
            self = .sunrise
        case 2:
            self = .dhuhr
        case 3:
            self = .asr
        case 4:
            self = .maghrib
        case 5:
            self = .isha
        default:
            self = .fajr
        }
    }

    public func encode(to encoder: Encoder) throws {
        let map: [Prayer:Int] = [.fajr:0, .sunrise:1, .dhuhr:2, .asr:3, .maghrib:4, .isha:5]
        var container = encoder.container(keyedBy: PrayerKey.self)
        try container.encode(map[self], forKey: .key)
    }
}

class NotificationSettings: Codable {
    static var shared: NotificationSettings = {
        if let s = unarchive(archiveName) as? NotificationSettings {
            return s
        } else {
            let defaultSettings = NotificationSettings(settings: [:])
            defaultSettings.settings = [
                .fajr : NotificationSetting(soundEnabled: true, alarmType: .all),
                .sunrise : NotificationSetting(soundEnabled: true, alarmType: .all),
                .dhuhr : NotificationSetting(soundEnabled: true, alarmType: .all),
                .asr : NotificationSetting(soundEnabled: true, alarmType: .all),
                .maghrib : NotificationSetting(soundEnabled: true, alarmType: .all),
                .isha : NotificationSetting(soundEnabled: true, alarmType: .all),
            ]
            
            
            return defaultSettings
        }
    }()
    
    init(settings: [Prayer:NotificationSetting]) {
        self.settings = settings
    }
    
    static func archive() {
        UserDefaults.standard.setValue(NotificationSettings.shared, forKey: archiveName)
//        archiveToName(archiveName, object: shared)
    }
    var settings: [Prayer:NotificationSetting]
    private static let archiveName = "notificationsettings"
}

class LocationSettings: Codable {
    
    static var shared: LocationSettings = {
        if let s = unarchive(archiveName) as? LocationSettings {
            return s
        } else {
            return LocationSettings()
        }
    }()
    
    init() {}
    
    init(locationName: String, coord: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.locationCoordinate = coord
    }
    
    static func archive() {
        UserDefaults.standard.setValue(LocationSettings.shared, forKey: archiveName)
//        archiveToName(archiveName, object: shared)
    }
    
    var locationName: String = "Cupertino, CA"
    var locationCoordinate: CLLocationCoordinate2D {
        get {
            .init(latitude: lat, longitude: lon)
        }
        set {
            lat = newValue.latitude
            lon = newValue.longitude
        }
    }
    private var lat: Double = 37.3230
    private var lon: Double = -122.0322
    private static let archiveName = "locationsettings"
}




// MARK: - Archive Helpers

// Helper function for storing settings
func archiveToName(_ name: String, object: AnyObject) {
    print("WARNING: ADD ERROR HANDLER TO THIS")
    let fm = FileManager.default
    var url = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")!
    url = url.appendingPathComponent("\(name)")
    
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

func unarchive(_ name: String) -> Any? {
    let fm = FileManager.default
    var url = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.athanUtil")!
    url = url.appendingPathComponent("\(name)")
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
        print("Couldn't unarchive for name: \(name)")
    }
    return object
}
