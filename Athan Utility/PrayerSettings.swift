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
//    static func == (lhs: PrayerSettings, rhs: PrayerSettings) -> Bool {
//        lhs.calculationMethod == rhs.calculationMethod && lhs.customNames == rhs.customNames && lhs.madhab == rhs.madhab
//    }
    
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


class NotificationSettings: Codable, NSCopying {
    enum Sounds: Int, CaseIterable, Codable {
        case ios_default
        case echo
        case makkah
        case madina
        case alaqsa
        case egypt
        case abdulbaset
        case abdulghaffar
        
        func localizedString() -> String { #warning("make this use localized strings")
            switch self {
            case .ios_default: return "iOS Default"
            case .echo: return "Echo"
            case .makkah: return "Makkah"
            case .madina: return "Madina"
            case .alaqsa: return "Al-Aqsa"
            case .egypt: return "Egypt"
            case .abdulbaset: return "Abdulbaset"
            case .abdulghaffar: return "Abdulghaffar"
            }
        }
        
        func filename() -> String? {
            switch self {
            case .ios_default: return nil // no file associated
            case .echo: return "echo"
            case .makkah: return "makkah"
            case .madina: return "madina"
            case .alaqsa: return "alaqsa"
            case .egypt: return "egypt"
            case .abdulbaset: return "abdulbaset"
            case .abdulghaffar: return "abdulghaffar"
            }
        }
    }
    
    static var shared: NotificationSettings = {
        if let archive = checkArchive() {
            return archive
        } else {
            let defaultSettings = NotificationSettings(settings: [:])
            defaultSettings.settings = [
                .fajr : AlarmSetting(),
                .sunrise : AlarmSetting(),
                .dhuhr : AlarmSetting(),
                .asr : AlarmSetting(),
                .maghrib : AlarmSetting(),
                .isha : AlarmSetting()
            ]
            
            
            return defaultSettings
        }
    }()
    
    init(settings: [Prayer:AlarmSetting]) {
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
    var selectedSound = Sounds.makkah
    var settings: [Prayer:AlarmSetting]
    private static let archiveName = "notificationsettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = NotificationSettings(settings: settings)
        return copy
    }

}

// MARK: - Location Settings

class LocationSettings: Codable, NSCopying {
    
    static var shared: LocationSettings = {
        let x = Date()
        print("here1", x)
        if let archive = checkArchive() {
            print("here2", x)
            return archive
        } else {
            print("here3", x)
            return LocationSettings(locationName: "Cupertino, CA", coord: CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322), useCurrentLocation: false)
        }
    }()
    
    init(locationName: String, coord: CLLocationCoordinate2D, useCurrentLocation: Bool) {
        self.locationName = locationName
        self.lat = coord.latitude
        self.lon = coord.longitude
        self.useCurrentLocation = useCurrentLocation
    }

    static func checkArchive() -> LocationSettings? {
        if let data = unarchiveData(archiveName) as? Data,
           let decoded = try? JSONDecoder().decode(LocationSettings.self, from: data) {
            decoded.isLoadedFromArchive = true
            print("))) check gives: \(decoded.locationName)")
            return decoded
        }
        return nil
    }
    
    static func archive() {
        print(")) SAVING: \(LocationSettings.shared.locationName)")
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(LocationSettings.shared) as? Data { // weird runtime bug: encode fails unless i put an unnecessary as? Data cast
            archiveData(archiveName, object: data)
        }
        let check = checkArchive()
        
    }
    var isLoadedFromArchive = false
    var locationName: String
    var useCurrentLocation = false
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
        let copy = LocationSettings(locationName: locationName, coord: locationCoordinate, useCurrentLocation: useCurrentLocation)
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
