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
class PrayerSettings: Codable, NSCopying {
    static var shared: PrayerSettings = {
        if let archive = checkArchive() {
            return archive
        } else {
            let defaultSettings = PrayerSettings(method: CalculationMethod.northAmerica, madhab: .shafi, customNames: [:])
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
    
    init(method: CalculationMethod, madhab: Madhab, customNames: [Prayer:String]) {
        self.calculationMethod = method
        self.madhab = madhab
        self.customNames = customNames
    }
    
    static func archive() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(PrayerSettings.shared) as? Data {
            archiveData(archiveName, object: data)
        }
    }
    
    // default values to be overridden from settings if they exist
    var calculationMethod: CalculationMethod
    var madhab: Madhab
    var customNames: [Prayer:String] // store potential override names for athan times
    
    private static let archiveName = "prayersettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = PrayerSettings(method: calculationMethod, madhab: madhab, customNames: customNames)
        return copy
    }
}

// MARK: - Notification Settings
enum AlarmSetting: Int, Codable {
    case all, noEarly, none
}

struct NotificationSetting: Codable {
    var soundEnabled = true
    var alarmType = AlarmSetting.all
}

class NotificationSettings: Codable, NSCopying {
    
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
    var selectedSoundIndex = 2
    static let noteSoundNames = ["iOS Default", "Echo", "Makkah", "Madina",
                                 "Al-Aqsa", "Egypt", "Abdulbaset", "Abdulghaffar"]
    var settings: [Prayer:NotificationSetting]
    private static let archiveName = "notificationsettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = NotificationSettings(settings: settings)
        return copy
    }

}

// MARK: - Location Settings

class LocationSettings: Codable, NSCopying {
    
    static var shared: LocationSettings = {
        if let archive = checkArchive() {
            return archive
        } else {
            return LocationSettings(locationName: "Cupertino, CA", coord: CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322))
        }
    }()
    
    init(locationName: String, coord: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.lat = coord.latitude
        self.lon = coord.longitude
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
    var locationName: String
    private var lat: Double
    private var lon: Double
    var locationCoordinate: CLLocationCoordinate2D {
        get {
            .init(latitude: lat, longitude: lon)
        }
        set {
            lat = newValue.latitude
            lon = newValue.longitude
        }
    }
    private static let archiveName = "locationsettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = LocationSettings(locationName: locationName, coord: locationCoordinate)
        return copy
    }
}

// MARK: - Archive Helpers

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
