//
//  FajrAlarmSettings.swift
//  Athan Utility
//
//  Persistent user configuration for the iOS 26 AlarmKit-backed
//  Fajr/Sunrise wake-up alarm.
//

import Foundation
import Adhan

// AlarmKit target: which prayer we anchor the alarm to.
enum FajrAlarmTarget: Int, Codable, CaseIterable {
    case fajr = 0
    case sunrise = 1

    // Equivalent Prayer for reusing existing localized + user-custom names.
    var prayer: Prayer {
        switch self {
        case .fajr:    return .fajr
        case .sunrise: return .sunrise
        }
    }

    // Honors the user's custom prayer-name overrides (same as the rest of the app).
    var displayName: String {
        return prayer.localizedOrCustomString()
    }
}

// 7-day selection stored as a bitmask. Sunday = 1<<0, ... Saturday = 1<<6.
// This matches Calendar.current.component(.weekday, ...) with Sunday==1.
struct FajrAlarmWeekdayMask: Codable, Equatable {
    var raw: Int

    static let all = FajrAlarmWeekdayMask(raw: 0b1111111)
    static let empty = FajrAlarmWeekdayMask(raw: 0)

    func isOn(weekdayIndex: Int) -> Bool {
        // weekdayIndex: 0=Sunday ... 6=Saturday
        guard weekdayIndex >= 0, weekdayIndex < 7 else { return false }
        return (raw & (1 << weekdayIndex)) != 0
    }

    mutating func toggle(weekdayIndex: Int) {
        guard weekdayIndex >= 0, weekdayIndex < 7 else { return }
        raw ^= (1 << weekdayIndex)
    }

    // Convert from Calendar weekday (Sunday==1) to our bitmask index (Sunday==0).
    func containsCalendarWeekday(_ weekday: Int) -> Bool {
        return isOn(weekdayIndex: weekday - 1)
    }
}

// All user-facing settings for the AlarmKit sync feature.
class FajrAlarmSettings: Codable, NSCopying {

    static let archiveName = "fajralarmsettings"

    // Enabled master switch.
    var enabled: Bool = false
    // Which prayer the alarm is anchored to.
    var target: FajrAlarmTarget = .fajr
    // Offset in minutes relative to the target prayer time.
    // Negative = before target, positive = after target. Clamped to [-120, 120].
    var offsetMinutes: Int = 0
    // Days of the week the alarm should fire on.
    var weekdays: FajrAlarmWeekdayMask = .all
    // When true, snooze button is shown in the alarm presentation.
    var snoozeEnabled: Bool = true
    // Snooze duration in minutes.
    var snoozeMinutes: Int = 5
    // Number of days ahead to schedule alarms. AlarmKit supports many, but
    // keeping this bounded avoids exhausting any system quota.
    var daysAhead: Int = 7

    init() {}

    // MARK: Shared singleton

    static var shared: FajrAlarmSettings = {
        let instance = checkArchive() ?? FajrAlarmSettings()
        // Sanitize once at load time. The scheduler no longer sanitizes on
        // every read (that would mutate the shared singleton off the main
        // actor); the UI and saveAndExit handle clamping on write.
        instance.sanitize()
        return instance
    }()

    static func checkArchive() -> FajrAlarmSettings? {
        guard let data = unarchiveData(archiveName) as? Data else { return nil }
        return try? JSONDecoder().decode(FajrAlarmSettings.self, from: data)
    }

    static func archive() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(FajrAlarmSettings.shared) {
            archiveData(archiveName, object: data)
        }
    }

    // Clamp user-adjustable fields to their valid ranges.
    func sanitize() {
        offsetMinutes = max(-120, min(120, offsetMinutes))
        snoozeMinutes = max(1, min(30, snoozeMinutes))
        daysAhead = max(1, min(14, daysAhead))
    }

    // MARK: NSCopying

    func copy(with zone: NSZone? = nil) -> Any {
        let c = FajrAlarmSettings()
        c.enabled = enabled
        c.target = target
        c.offsetMinutes = offsetMinutes
        c.weekdays = weekdays
        c.snoozeEnabled = snoozeEnabled
        c.snoozeMinutes = snoozeMinutes
        c.daysAhead = daysAhead
        return c
    }
}
