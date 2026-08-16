//
//  HijriSettings.swift
//  Athan Utility
//
//  Which Hijri calendar the date line uses, and a manual day offset.
//
//  There is no single correct answer here: Umm al-Qura is the Saudi civil calendar,
//  the tabular calendars are arithmetic, and many communities follow a local moon
//  sighting that lands a day either side of all of them. So the calendar is the user's
//  choice, and Ramadan — the one month where being a day off actually matters to people
//  — gets a manual nudge.
//
//  Stored in the app group so the widget and watch render the same date the app does.
//

import Foundation

enum HijriCalendarMode: Int, Codable, CaseIterable, Identifiable {
    case ummAlQura
    case civil
    case tabular

    var id: Int { rawValue }

    var calendarIdentifier: Calendar.Identifier {
        switch self {
        case .ummAlQura: return .islamicUmmAlQura
        case .civil:     return .islamicCivil
        case .tabular:   return .islamicTabular
        }
    }

    var localizedName: String {
        switch self {
        case .ummAlQura:
            return NSLocalizedString("hijri_mode_ummalqura", value: "Umm al-Qura", comment: "Name of the Saudi civil Hijri calendar")
        case .civil:
            return NSLocalizedString("hijri_mode_civil", value: "Islamic Civil", comment: "Name of the arithmetic civil Hijri calendar")
        case .tabular:
            return NSLocalizedString("hijri_mode_tabular", value: "Islamic Tabular", comment: "Name of the arithmetic tabular Hijri calendar")
        }
    }
}

final class HijriSettings: Codable {

    static let archiveName = "hijrisettings"

    static var shared: HijriSettings = checkArchive() ?? HijriSettings()

    /// Which Hijri calendar to render dates with.
    var mode: HijriCalendarMode = .ummAlQura

    /// Days to shift the rendered Hijri date by, to match a local sighting.
    /// Deliberately narrow — this is a correction, not a free-form date picker.
    var dayOffset: Int = 0

    static let offsetRange = -2...2

    // MARK: - Date rendering

    /// The date to render, after applying the user's offset.
    func adjusted(_ date: Date) -> Date {
        guard dayOffset != 0 else { return date }
        return Calendar.current.date(byAdding: .day, value: dayOffset, to: date) ?? date
    }

    func calendar() -> Calendar { Calendar(identifier: mode.calendarIdentifier) }

    /// Hijri month (1–12) for a Gregorian date, with the offset applied.
    func hijriMonth(for date: Date) -> Int {
        calendar().component(.month, from: adjusted(date))
    }

    /// The date a given calendar would show right now, used to let the picker present
    /// the options side by side instead of making the user pick one and check.
    func previewString(mode option: HijriCalendarMode, dayOffset offset: Int, date: Date = Date()) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: option.calendarIdentifier)
        df.dateStyle = .medium
        if Locale.preferredLanguages.first?.hasPrefix("ar") ?? false {
            df.locale = Locale(identifier: "ar_SY")
        }
        let shifted = offset == 0
            ? date
            : (Calendar.current.date(byAdding: .day, value: offset, to: date) ?? date)
        return df.string(from: shifted)
    }

    /// True in Ramadan, and on the day immediately before it — the only window where
    /// a ±1 correction is something people actually need to make.
    func isRamadanAdjustmentRelevant(on date: Date = Date()) -> Bool {
        let ramadan = 9
        if hijriMonth(for: date) == ramadan { return true }
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return false }
        return hijriMonth(for: tomorrow) == ramadan
    }

    // MARK: - Persistence

    static func checkArchive() -> HijriSettings? {
        guard let data = unarchiveData(archiveName) as? Data,
              let decoded = try? JSONDecoder().decode(HijriSettings.self, from: data) else { return nil }
        return decoded
    }

    static func archive() {
        if let data = try? JSONEncoder().encode(shared) as? Data {
            archiveData(archiveName, object: data)
        }
    }
}
