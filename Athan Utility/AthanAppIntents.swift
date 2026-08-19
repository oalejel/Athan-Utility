//
//  AthanAppIntents.swift
//  Athan Utility
//
//  Modern App Intents (iOS 16+) with an AppShortcutsProvider so prayer-time shortcuts are
//  auto-registered in Siri / Spotlight / the Shortcuts app with rich spoken phrases — no
//  manual "Add to Siri" step required. The legacy SiriKit intents remain for older iOS.
//

import Foundation
import AppIntents
import Adhan

// MARK: - Shared computation (not iOS-16-gated)

enum AthanSiriSupport {
    /// The next upcoming prayer from now, computed fresh so it works even if the app wasn't running.
    static func nextPrayerInfo() -> (name: String, date: Date) {
        let mgr = AthanManager.shared
        let adj = mgr.notificationSettings.adjustments()
        let now = Date()
        let obligatory: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        if let today = mgr.calculateTimes(referenceDate: now, adjustments: adj) {
            for p in obligatory {
                let t = today.time(for: p)
                if t > now { return (p.localizedOrCustomString(), t) }
            }
        }
        if let tomorrow = mgr.calculateTimes(referenceDate: Self.tomorrowReference(), adjustments: adj) {
            return (Prayer.fajr.localizedOrCustomString(), tomorrow.time(for: .fajr))
        }
        return (Prayer.fajr.localizedOrCustomString(), now)
    }

    /// Tomorrow's reference date via calendar arithmetic (DST-safe), matching
    /// the device-time-zone day that `calculateTimes` reads by default.
    private static func tomorrowReference() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
    }

    /// Today's time for a specific prayer (tomorrow's if today's already passed).
    static func time(for p: Prayer) -> (name: String, date: Date) {
        let mgr = AthanManager.shared
        let adj = mgr.notificationSettings.adjustments()
        let now = Date()
        if let today = mgr.calculateTimes(referenceDate: now, adjustments: adj) {
            let t = today.time(for: p)
            if t > now { return (p.localizedOrCustomString(), t) }
        }
        if let tomorrow = mgr.calculateTimes(referenceDate: Self.tomorrowReference(), adjustments: adj) {
            return (p.localizedOrCustomString(), tomorrow.time(for: p))
        }
        return (p.localizedOrCustomString(), now)
    }

    static func clock(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        df.timeZone = AthanManager.shared.locationSettings.timeZone
        return df.string(from: date)
    }

    static func nextPrayerSentence() -> String {
        let info = nextPrayerInfo()
        let remaining = max(0, info.date.timeIntervalSinceNow)
        return String(format: NSLocalizedString("siri_next_sentence",
            value: "The next prayer is %@ at %@, in %@.", comment: ""),
            info.name, clock(info.date), MainSwiftUI.durationPhrase(remaining))
    }

    static func prayerTimeSentence(for p: Prayer) -> String {
        let (name, date) = time(for: p)
        return String(format: NSLocalizedString("siri_prayer_sentence",
            value: "%@ is at %@.", comment: ""), name, clock(date))
    }
}

// MARK: - App Intents (iOS 16+)

@available(iOS 16.0, *)
enum PrayerAppEnum: String, AppEnum {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Prayer"
    static var caseDisplayRepresentations: [PrayerAppEnum: DisplayRepresentation] = [
        .fajr: "Fajr", .sunrise: "Sunrise", .dhuhr: "Dhuhr",
        .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"
    ]

    var prayer: Prayer {
        switch self {
        case .fajr: return .fajr
        case .sunrise: return .sunrise
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        }
    }
}

@available(iOS 16.0, *)
struct NextPrayerAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Prayer Time"
    static var description = IntentDescription("Find the next prayer and how long until it.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: IntentDialog(stringLiteral: AthanSiriSupport.nextPrayerSentence()))
    }
}

@available(iOS 16.0, *)
struct PrayerTimeAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Prayer Time"
    static var description = IntentDescription("Get the time for a specific prayer today.")
    static var openAppWhenRun = false

    @Parameter(title: "Prayer")
    var prayer: PrayerAppEnum

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: IntentDialog(stringLiteral: AthanSiriSupport.prayerTimeSentence(for: prayer.prayer)))
    }
}

@available(iOS 16.0, *)
struct AthanAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPrayerAppIntent(),
            phrases: [
                "Next prayer in \(.applicationName)",
                "When is the next prayer in \(.applicationName)",
                "Next athan in \(.applicationName)",
                "How long until the next prayer in \(.applicationName)",
                "\(.applicationName) next prayer time"
            ],
            shortTitle: "Next Prayer",
            systemImageName: "moon.stars.fill"
        )
        AppShortcut(
            intent: PrayerTimeAppIntent(),
            phrases: [
                "When is \(\.$prayer) in \(.applicationName)",
                "What time is \(\.$prayer) in \(.applicationName)",
                "\(.applicationName) \(\.$prayer) time"
            ],
            shortTitle: "Prayer Time",
            systemImageName: "sun.max.fill"
        )
    }
}
