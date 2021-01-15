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

class AlarmSetting: Codable {
    var athanAlertEnabled = true
    var athanSoundEnabled = true // might make sense to also silence reminder in this case
    
    var reminderAlertEnabled = true
    var reminderOffset = 15
}

// Manages loading and storing of settings for calculations
class PrayerSettings: Codable, NSCopying {
//    static func == (lhs: PrayerSettings, rhs: PrayerSettings) -> Bool {
//        lhs.calculationMethod == rhs.calculationMethod && lhs.customNames == rhs.customNames && lhs.madhab == rhs.madhab
//    }
    
    static var shared: PrayerSettings = {
        if let archive = checkArchive() {
            return archive
        } else {
            let defaultSettings = PrayerSettings(method: CalculationMethod.northAmerica, madhab: .shafi, customNames: [
                .fajr:"",
                .sunrise: "",
                .dhuhr: "",
                .asr: "",
                .maghrib: "",
                .isha: ""
            ])
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
    
    static let archiveName = "prayersettings"
    
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
        
        func localizedString() -> String { 
            switch self {
            case .ios_default: return NSLocalizedString("iOS Default", comment: "")
                case .echo: return NSLocalizedString("Echo", comment: "")
                case .makkah: return NSLocalizedString("Makkah", comment: "")
                case .madina: return NSLocalizedString("Madina", comment: "")
                case .alaqsa: return NSLocalizedString("Al-Aqsa", comment: "")
                case .egypt: return NSLocalizedString("Egypt", comment: "")
                case .abdulbaset: return NSLocalizedString("Abdulbaset", comment: "")
                case .abdulghaffar: return NSLocalizedString("Abdulghaffar", comment: "")
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
            let sunriseSpecificSetting = AlarmSetting()
            sunriseSpecificSetting.athanSoundEnabled = false // no athan for shurooq
            let defaultSettings = NotificationSettings(settings: [:], selectedSound: .alaqsa)
            defaultSettings.settings = [
                .fajr : AlarmSetting(),
                .sunrise : sunriseSpecificSetting,
                .dhuhr : AlarmSetting(),
                .asr : AlarmSetting(),
                .maghrib : AlarmSetting(),
                .isha : AlarmSetting()
            ]
            
            
            return defaultSettings
        }
    }()
    
    init(settings: [Prayer:AlarmSetting], selectedSound: Sounds) {
        self.settings = settings
        self.selectedSound = selectedSound
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
    
    var selectedSound: Sounds
    var settings: [Prayer:AlarmSetting]
    static let archiveName = "notificationsettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = NotificationSettings(settings: settings, selectedSound: selectedSound)
        return copy
    }

}

// MARK: - Location Settings

class LocationSettings: Codable, NSCopying {
    
    static var shared: LocationSettings = {
        if let archive = checkArchive() {
            print("> location archive: ", archive.locationName, archive.isLoadedFromArchive, archive.useCurrentLocation)
            return archive
        } else {
            return LocationSettings.defaultSetting()
        }
    }()
    
    init(locationName: String, coord: CLLocationCoordinate2D, timeZone: TimeZone, useCurrentLocation: Bool) {
        self.locationName = locationName
        self.lat = coord.latitude
        self.lon = coord.longitude
        self.useCurrentLocation = useCurrentLocation
        self.timeZone = timeZone
    }
    
    static func defaultSetting() -> LocationSettings {
        return LocationSettings(locationName: "Edit Location", coord: CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322), timeZone: TimeZone(identifier: "America/Los_Angeles")!, useCurrentLocation: false)
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
        if let check = checkArchive() {
            print("> found loc settings in archive", check.locationName, check.isLoadedFromArchive, check.useCurrentLocation)
        } else {
            print("> empty found in archive")
        }
    }
    var isLoadedFromArchive = false
    var locationName: String
    var timeZone: TimeZone
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
    static let archiveName = "locationsettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = LocationSettings(locationName: locationName, coord: locationCoordinate, timeZone: timeZone, useCurrentLocation: useCurrentLocation)
        return copy
    }
}

class AppearanceSettings: Codable, NSCopying, Equatable {
    static func == (lhs: AppearanceSettings, rhs: AppearanceSettings) -> Bool {
        lhs.id == rhs.id && lhs.isDynamic == rhs.isDynamic
    }
    
    
    static var shared: AppearanceSettings = {
        if let archive = checkArchive() {
            return archive
        } else {
            // I prefer not having UIColor extensions in a UIKit-agnostic class, so specifying rgb values like this is better
            return defaultSetting()
        }
    }()
    
    static func defaultSetting() -> AppearanceSettings {
        AppearanceSettings(colorDict: [
            nil: [[0, 0, 0], [Float(4)/255, Float(65)/255, Float(125)/255]], // black to blue hue when not using dynamic colors
            .fajr: [[Float(8)/255, Float(14)/255, Float(39)/255], [Float(1)/255, Float(69)/255, Float(106)/255]],
            .sunrise: [[Float(8)/255, Float(57)/255, Float(99)/255], [Float(151)/255, Float(144)/255, Float(102)/255]],
            .dhuhr: [[Float(15)/255, Float(83)/255, Float(175)/255], [Float(82)/255, Float(158)/255, Float(168)/255]],
            .asr: [[Float(62)/255, Float(175)/255, Float(235)/255], [Float(0)/255, Float(79)/255, Float(126)/255]],
            .maghrib: [[Float(0)/255, Float(34)/255, Float(97)/255], [Float(163)/255, Float(65)/255, Float(53)/255]],
            .isha: [[Float(0)/255, Float(1)/255, Float(12)/255], [Float(8)/255, Float(17)/255, Float(88)/255]]
        ])
    }
    
    init(colorDict: [Prayer?:[[Float]]], isDynamic: Bool = true, id: Int = 0) {
        self.colorDict = colorDict
        self.isDynamic = isDynamic
        self.id = id 
    }

    static func checkArchive() -> AppearanceSettings? {
        if let data = unarchiveData(archiveName) as? Data,
           let decoded = try? JSONDecoder().decode(AppearanceSettings.self, from: data) {
            return decoded
        }
        return nil
    }
    
    static func archive() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(AppearanceSettings.shared) as? Data { // weird runtime bug: encode fails unless i put an unnecessary as? Data cast
            archiveData(archiveName, object: data)
        }
    }
    var isDynamic: Bool
    var id = 0 // used to check if appearance settings are stale
    private var colorDict: [Prayer?:[[Float]]] = [:]
    func colorTuplesForContext(optionalPrayer: Prayer?) -> ((Double, Double, Double), (Double, Double, Double)){
        let colorArray = colorDict[optionalPrayer] ?? [[0, 0, 0], [0, 1, 0]]
        let color1 = (Double(colorArray[0][0]), Double(colorArray[0][1]), Double(colorArray[0][2]))
        let color2 = (Double(colorArray[1][0]), Double(colorArray[1][1]), Double(colorArray[1][2]))
        return (color1, color2)
    }
    
    func setRGBPairForContext(optionalPrayer: Prayer?, color1: (Float, Float, Float), color2: (Float, Float, Float)) {
        colorDict[optionalPrayer] = [[color1.0, color1.1, color1.2], [color2.0, color2.1, color2.2]]
    }
//        nil: ((1, 2, 3), (1, 2, 3))
    
    static let archiveName = "appearancesettings"
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = AppearanceSettings(colorDict: colorDict, isDynamic: isDynamic, id: id)
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
