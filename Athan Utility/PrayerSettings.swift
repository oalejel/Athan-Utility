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
        if let archive = checkArchive() {
            return archive
        } else {
            let defaultSettings = PrayerSettings()
            return defaultSettings
        }
    }()
    
    static func checkArchive() -> PrayerSettings? {
        if let data = unarchiveData(archiveName) as? Data,
           let decoded = try? JSONDecoder().decode(PrayerSettings.self, from: data) {
            return decoded
        }
        return nil
    }
    
    static func archive() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(PrayerSettings.shared) as? Data {
            archiveData(archiveName, object: data)
        }
    }
    
    // default values to be overridden from settings if they exist
    var calculationMethod: CalculationMethod = CalculationMethod.northAmerica
    var madhab: Madhab = .shafi
    // store potential override names for athan times
    
    var customNames: [Prayer:String] = [:]
    private static let archiveName = "prayersettings"
}

// MARK: - Notification Settings
enum AlarmSetting: Int, Codable {
    case all, noEarly, none
}

struct NotificationSetting: Codable {
    var soundEnabled = true
    var alarmType = AlarmSetting.all
}

class NotificationSettings: Codable {
    
    static var shared: NotificationSettings = {
        if let archive = checkArchive() {
            return archive
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
    
    static func checkArchive() -> NotificationSettings? {
        if let data = unarchiveData(archiveName) as? Data,
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            return decoded
        }
        return nil
    }
    
    static func archive() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(NotificationSettings.shared) as? Data {
            archiveData(archiveName, object: data)
        }

    }
    var settings: [Prayer:NotificationSetting]
    private static let archiveName = "notificationsettings"
}

// MARK: - Location Settings

class LocationSettings: Codable {
    
    static var shared: LocationSettings = {
        if let archive = checkArchive() {
            return archive
        } else {
            return LocationSettings()
        }
    }()
    
    init() {}
    
    init(locationName: String, coord: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.locationCoordinate = coord
    }

    static func checkArchive() -> LocationSettings? {
        if let data = unarchiveData(archiveName) as? Data,
           let decoded = try? JSONDecoder().decode(LocationSettings.self, from: data) {
            decoded.isLoadedFromArchive = true
            return decoded
        }
        return nil
    }
    
    static func archive() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(LocationSettings.shared) as? Data { // weird runtime bug: encode fails unless i put an unnecessary as? Data cast
            archiveData(archiveName, object: data)
        }
    }
    var isLoadedFromArchive = false
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

//func unarchive2(_ name: String) -> Data? {
//    let data = UserDefaults.standard.object(forKey: name) as? Data
//    return data
//}
//
//func archive2(_ name: String, object: Any) {
//    print("WARNING: ADD ERROR HANDLER TO THIS")
//    do {
//        let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
//        UserDefaults.standard.setValue(data, forKey: name)
//    } catch {
//        print("error archiving prayer settings")
//    }
//}

// Helper function for storing settings
func archiveData(_ name: String, object: Any) {
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

func unarchiveData(_ name: String) -> Any? {
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
