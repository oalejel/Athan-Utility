//
//  FajrAlarmSettings.swift
//  Athan Utility
//
//  Persistent user configuration for the iOS 26 AlarmKit-backed
//  prayer alarms (Fajr, Dhuhr, Asr, Maghrib, Isha).
//

import Foundation
import Adhan

// AlarmKit target: which prayer an alarm is anchored to. Raw values are
// persisted, so existing cases keep their numbers and new ones are appended.
enum FajrAlarmTarget: Int, Codable, CaseIterable {
    case fajr = 0
    case sunrise = 1
    case dhuhr = 2
    case asr = 3
    case maghrib = 4
    case isha = 5

    // What the settings screen offers. Sunrise is left out: an alarm around
    // sunrise is Fajr with a later offset. It stays a valid case so an alarm
    // saved by an older version keeps firing until the user turns it off.
    static let selectable: [FajrAlarmTarget] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    // Equivalent Prayer for reusing existing localized + user-custom names.
    var prayer: Prayer {
        switch self {
        case .fajr:    return .fajr
        case .sunrise: return .sunrise
        case .dhuhr:   return .dhuhr
        case .asr:     return .asr
        case .maghrib: return .maghrib
        case .isha:    return .isha
        }
    }

    // Day order, so alarms list and schedule in the order the prayers happen.
    var dayOrder: Int {
        switch self {
        case .fajr: return 0
        case .sunrise: return 1
        case .dhuhr: return 2
        case .asr: return 3
        case .maghrib: return 4
        case .isha: return 5
        }
    }

    // Honors the user's custom prayer-name overrides (same as the rest of the app).
    var displayName: String {
        return prayer.localizedOrCustomString()
    }
}

// One prayer's alarm: which prayer, and how far before (negative) or after
// (positive) its time the alarm fires.
struct FajrAlarmEntry: Codable, Equatable {
    var target: FajrAlarmTarget
    var offsetMinutes: Int
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
    // The prayers that get an alarm, each with its own offset, in day order.
    // Offsets are negative = before the prayer, positive = after, clamped to
    // ±offsetLimit.
    var alarms: [FajrAlarmEntry] = [FajrAlarmEntry(target: .fajr, offsetMinutes: 0)]
    // Wide enough to reach sunrise from Fajr, which is well over two hours
    // apart at high latitudes in summer.
    static let offsetLimit = 180
    // Days of the week the alarm should fire on.
    var weekdays: FajrAlarmWeekdayMask = .all
    // When true, snooze button is shown in the alarm presentation.
    var snoozeEnabled: Bool = true
    // Snooze duration in minutes.
    var snoozeMinutes: Int = 5
    // Number of upcoming alarms to keep scheduled per prayer (the rolling window).
    // With a sparse weekday mask this can span more calendar days than its
    // value — the scheduler delivers this many alarms, not calendar days.
    // Bounded to avoid exhausting any AlarmKit quota.
    var daysAhead: Int = 7

    init() {}

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case enabled, alarms, weekdays, snoozeEnabled, snoozeMinutes, daysAhead
        // Written by versions that supported a single alarm. Still read to
        // migrate, and still written so a downgrade keeps the first alarm.
        case target, offsetMinutes
    }

    // Decode each field independently, falling back to its default when a
    // key is missing or malformed. The synthesized decoder would hard-fail
    // the whole archive on any single missing key (e.g. after a field is
    // added or removed in an update), silently resetting the user's alarm
    // to disabled and cancelling their wake-ups on the next sync.
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled       = (try? c.decodeIfPresent(Bool.self, forKey: .enabled)) .flatMap { $0 } ?? false
        if let saved = (try? c.decodeIfPresent([FajrAlarmEntry].self, forKey: .alarms)) .flatMap({ $0 }) {
            alarms = saved
        } else {
            let target = (try? c.decodeIfPresent(FajrAlarmTarget.self, forKey: .target)) .flatMap { $0 } ?? .fajr
            let offset = (try? c.decodeIfPresent(Int.self, forKey: .offsetMinutes)) .flatMap { $0 } ?? 0
            alarms = [FajrAlarmEntry(target: target, offsetMinutes: offset)]
        }
        weekdays      = (try? c.decodeIfPresent(FajrAlarmWeekdayMask.self, forKey: .weekdays)) .flatMap { $0 } ?? .all
        snoozeEnabled = (try? c.decodeIfPresent(Bool.self, forKey: .snoozeEnabled)) .flatMap { $0 } ?? true
        snoozeMinutes = (try? c.decodeIfPresent(Int.self, forKey: .snoozeMinutes)) .flatMap { $0 } ?? 5
        daysAhead     = (try? c.decodeIfPresent(Int.self, forKey: .daysAhead)) .flatMap { $0 } ?? 7
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(alarms, forKey: .alarms)
        try c.encode(weekdays, forKey: .weekdays)
        try c.encode(snoozeEnabled, forKey: .snoozeEnabled)
        try c.encode(snoozeMinutes, forKey: .snoozeMinutes)
        try c.encode(daysAhead, forKey: .daysAhead)
        // Older versions only know Fajr and Sunrise, so hand them one of those.
        let legacy = alarms.first { $0.target == .fajr || $0.target == .sunrise }
        try c.encode(legacy?.target ?? .fajr, forKey: .target)
        try c.encode(legacy?.offsetMinutes ?? 0, forKey: .offsetMinutes)
    }

    func alarm(for target: FajrAlarmTarget) -> FajrAlarmEntry? {
        alarms.first { $0.target == target }
    }

    // "At Fajr time" / "15 min before Isha", shared by the settings screen and
    // the one-line summary on the Settings entry row.
    static func offsetDescription(_ entry: FajrAlarmEntry) -> String {
        let name = entry.target.displayName
        if entry.offsetMinutes == 0 {
            return String(format: Strings.fajrAlarmOffsetZero, name)
        } else if entry.offsetMinutes > 0 {
            return String(format: Strings.fajrAlarmOffsetAfter, entry.offsetMinutes, name)
        } else {
            return String(format: Strings.fajrAlarmOffsetBefore, abs(entry.offsetMinutes), name)
        }
    }

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
        let limit = Self.offsetLimit
        var seen = Set<FajrAlarmTarget>()
        alarms = alarms
            .filter { seen.insert($0.target).inserted }
            .map { FajrAlarmEntry(target: $0.target, offsetMinutes: max(-limit, min(limit, $0.offsetMinutes))) }
            .sorted { $0.target.dayOrder < $1.target.dayOrder }
        snoozeMinutes = max(1, min(30, snoozeMinutes))
        daysAhead = max(1, min(14, daysAhead))
    }

    // MARK: NSCopying

    func copy(with zone: NSZone? = nil) -> Any {
        let c = FajrAlarmSettings()
        c.enabled = enabled
        c.alarms = alarms
        c.weekdays = weekdays
        c.snoozeEnabled = snoozeEnabled
        c.snoozeMinutes = snoozeMinutes
        c.daysAhead = daysAhead
        return c
    }
}
