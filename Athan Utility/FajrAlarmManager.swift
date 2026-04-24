//
//  FajrAlarmManager.swift
//  Athan Utility
//
//  Thin wrapper around AlarmKit (iOS 26+) that keeps a rolling set of
//  scheduled Fajr/Sunrise wake-up alarms in sync with the user's
//  current prayer-time calculations.
//

import Foundation
import CoreLocation
import Adhan
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif

// Metadata attached to each scheduled alarm. Must conform to AlarmMetadata.
#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct FajrAlarmMetadata: AlarmMetadata {
    let prayerName: String
    let locationName: String
    let intendedFireDate: Date
}
#endif

// Snapshot of the settings + location state that the async scheduler needs.
// Captured on the caller's thread so the Task body never reads mutable shared
// state (AthanManager / FajrAlarmSettings.shared) concurrently.
private struct FajrSyncSnapshot {
    let enabled: Bool
    let target: FajrAlarmTarget
    let targetDisplayName: String
    let offsetMinutes: Int
    let weekdays: FajrAlarmWeekdayMask
    let snoozeEnabled: Bool
    let snoozeMinutes: Int
    let daysAhead: Int
    let coordinate: CLLocationCoordinate2D
    let timeZone: TimeZone
    let locationName: String
    let adjustments: PrayerAdjustments
}

// IDs of alarms we scheduled are persisted to the app group so that we can
// cancel stale alarms on the next sync pass even after the app relaunches.
private enum FajrAlarmStore {
    private static let key = "fajralarm.scheduledIDs"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: "group.athanUtil") ?? .standard
    }

    static func save(ids: [UUID]) {
        defaults.set(ids.map { $0.uuidString }, forKey: key)
    }

    static func load() -> [UUID] {
        let raw = defaults.stringArray(forKey: key) ?? []
        return raw.compactMap { UUID(uuidString: $0) }
    }
}

// Platform-agnostic snapshot of AlarmKit authorization state so that view
// code doesn't need to conditionally import AlarmKit.
enum FajrAlarmAuthorizationStatus {
    case unavailable      // iOS < 26 or AlarmKit not present
    case notDetermined
    case authorized
    case denied
}

class FajrAlarmManager {
    static let shared = FajrAlarmManager()
    private init() {}

    // Serial queue that owns all AlarmKit sync work. Prevents two concurrent
    // sync passes from racing on FajrAlarmStore and leaving orphaned alarms.
    private let syncQueue = DispatchQueue(label: "com.omaralejel.Athan-Utility.FajrAlarmManager.sync")

    // Snapshot the current authorization state. No system prompt is shown.
    func currentAuthorizationState() -> FajrAlarmAuthorizationStatus {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            switch AlarmManager.shared.authorizationState {
            case .authorized:    return .authorized
            case .denied:        return .denied
            case .notDetermined: return .notDetermined
            @unknown default:    return .notDetermined
            }
        }
        #endif
        return .unavailable
    }

    // Public entry point. Safe to call on any iOS version; no-op pre-26.
    // Captures settings + location on the caller's thread before dispatching
    // into the serial sync queue.
    func syncAlarms() {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard let snapshot = makeSnapshot() else { return }
            syncQueue.async {
                let sem = DispatchSemaphore(value: 0)
                Task {
                    await self.syncAlarmsAvailable(snapshot: snapshot)
                    sem.signal()
                }
                sem.wait()
            }
        }
        #endif
    }

    // Cancels every alarm we previously scheduled. Useful when the user
    // disables the feature or revokes authorization.
    func cancelAllManagedAlarms() {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            syncQueue.async {
                let sem = DispatchSemaphore(value: 0)
                Task {
                    await self.cancelAllAvailable()
                    sem.signal()
                }
                sem.wait()
            }
        }
        #endif
    }

    // Asks AlarmKit for authorization if we haven't yet. Returns the final
    // authorization state via the completion handler on the main thread.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                let granted = await requestAuthorizationAvailable()
                await MainActor.run { completion(granted) }
            }
            return
        }
        #endif
        completion(false)
    }

    // Build a snapshot of everything the scheduler needs, read synchronously
    // on the caller's thread.
    private func makeSnapshot() -> FajrSyncSnapshot? {
        let settings = FajrAlarmSettings.shared
        settings.sanitize()
        let athanManager = AthanManager.shared
        return FajrSyncSnapshot(
            enabled: settings.enabled,
            target: settings.target,
            targetDisplayName: settings.target.displayName,
            offsetMinutes: settings.offsetMinutes,
            weekdays: settings.weekdays,
            snoozeEnabled: settings.snoozeEnabled,
            snoozeMinutes: settings.snoozeMinutes,
            daysAhead: settings.daysAhead,
            coordinate: athanManager.locationSettings.locationCoordinate,
            timeZone: athanManager.locationSettings.timeZone,
            locationName: athanManager.locationSettings.locationName,
            adjustments: athanManager.notificationSettings.adjustments()
        )
    }

    // MARK: - iOS 26 implementation

    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    private func requestAuthorizationAvailable() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let state = try await manager.requestAuthorization()
                return state == .authorized
            } catch {
                print("FajrAlarmManager: authorization request failed: \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }

    @available(iOS 26.0, *)
    private func cancelAllAvailable() async {
        let manager = AlarmManager.shared
        let ids = FajrAlarmStore.load()
        var remaining: [UUID] = []
        for id in ids {
            do {
                try manager.cancel(id: id)
            } catch {
                // Couldn't cancel — keep it tracked so we can try again next sync.
                remaining.append(id)
            }
        }
        FajrAlarmStore.save(ids: remaining)
    }

    @available(iOS 26.0, *)
    private func syncAlarmsAvailable(snapshot: FajrSyncSnapshot) async {
        // If disabled, cancel everything we've scheduled and bail.
        guard snapshot.enabled else {
            await cancelAllAvailable()
            return
        }

        let authorized = await requestAuthorizationAvailable()
        guard authorized else {
            // User hasn't authorized AlarmKit; clean up anything stale.
            await cancelAllAvailable()
            return
        }

        let manager = AlarmManager.shared

        // Always cancel our previously managed alarms before re-scheduling.
        // AlarmKit does not expose a built-in "replace", so we wipe & rebuild
        // the rolling window each sync pass. Keep IDs that fail to cancel so
        // next sync can retry them instead of leaking orphans.
        let previous = FajrAlarmStore.load()
        var retained: [UUID] = []
        for id in previous {
            do {
                try manager.cancel(id: id)
            } catch {
                retained.append(id)
            }
        }

        // Compute the next N firing dates.
        let fireDates = await upcomingFireDates(snapshot: snapshot)

        // Title is built from a localized format string so Arabic / RTL
        // languages can rearrange the word order (e.g. "منبّه الفجر").
        let title = String(format: Strings.fajrAlarmTitleFormat, snapshot.targetDisplayName)
        let tint = Color(red: 4.0/255.0, green: 65.0/255.0, blue: 125.0/255.0)

        var newIDs: [UUID] = retained
        for date in fireDates {
            // Skip past dates defensively.
            guard date > Date() else { continue }

            let id = UUID()
            do {
                let config = try makeConfiguration(
                    title: title,
                    locationName: snapshot.locationName,
                    fireDate: date,
                    tint: tint,
                    snoozeEnabled: snapshot.snoozeEnabled,
                    snoozeMinutes: snapshot.snoozeMinutes,
                    prayerName: snapshot.targetDisplayName
                )
                _ = try await manager.schedule(id: id, configuration: config)
                newIDs.append(id)
            } catch {
                print("FajrAlarmManager: failed to schedule \(date): \(error)")
            }
        }

        FajrAlarmStore.save(ids: newIDs)
    }

    @available(iOS 26.0, *)
    private func makeConfiguration(
        title: String,
        locationName: String,
        fireDate: Date,
        tint: Color,
        snoozeEnabled: Bool,
        snoozeMinutes: Int,
        prayerName: String
    ) throws -> AlarmManager.AlarmConfiguration<FajrAlarmMetadata> {

        // LocalizedStringResource treats its argument as a key that resolves
        // at display time, so the alarm picks up the user's current system
        // language even if it changed between scheduling and firing.
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "stop.circle.fill"
        )

        let alert: AlarmPresentation.Alert
        let countdown: AlarmPresentation.Countdown?
        if snoozeEnabled {
            let snoozeButton = AlarmButton(
                text: "Snooze",
                textColor: .white,
                systemImageName: "zzz"
            )
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: title),
                stopButton: stopButton,
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
            // AlarmKit requires a Countdown presentation (and a Live Activity
            // that renders it) whenever secondaryButtonBehavior is .countdown.
            // Reuse the stop button so tapping "pause" during a snooze just
            // ends the alarm — there's no meaningful "pause the snooze" for
            // a prayer wake-up.
            countdown = AlarmPresentation.Countdown(
                title: LocalizedStringResource(stringLiteral: title),
                pauseButton: stopButton
            )
        } else {
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: title),
                stopButton: stopButton
            )
            countdown = nil
        }

        let presentation: AlarmPresentation
        if let countdown = countdown {
            presentation = AlarmPresentation(alert: alert, countdown: countdown)
        } else {
            presentation = AlarmPresentation(alert: alert)
        }

        let metadata = FajrAlarmMetadata(
            prayerName: prayerName,
            locationName: locationName,
            intendedFireDate: fireDate
        )

        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: metadata,
            tintColor: tint
        )

        let schedule = Alarm.Schedule.fixed(fireDate)

        // Configure optional snooze countdown duration (in seconds).
        let countdownDuration: Alarm.CountdownDuration?
        if snoozeEnabled {
            countdownDuration = Alarm.CountdownDuration(
                preAlert: nil,
                postAlert: TimeInterval(snoozeMinutes * 60)
            )
        } else {
            countdownDuration = nil
        }

        return AlarmManager.AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes
        )
    }
    #endif

    // MARK: - Fire-date math (plain Swift; no AlarmKit dependency)

    // Returns up to `daysAhead` upcoming alarm fire-dates, respecting the
    // weekday mask and offset. Uses the Adhan-computed prayer time for the
    // user's current location/settings. `calculateTimes` is main-isolated
    // as far as AthanManager's internal state goes, so hop to main before
    // invoking it.
    private func upcomingFireDates(snapshot: FajrSyncSnapshot) async -> [Date] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = snapshot.timeZone

        let now = Date()
        let startOfToday = cal.startOfDay(for: now)

        var results: [Date] = []
        // Scan enough days to find daysAhead matching weekdays even if the
        // weekday mask is sparse (minimum 7 days = whole week).
        let scanWindow = max(snapshot.daysAhead * 2, 7) + 1
        for offset in 0..<scanWindow {
            guard results.count < snapshot.daysAhead else { break }

            guard let day = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }

            // Respect weekday filter.
            let weekday = cal.component(.weekday, from: day) // Sunday == 1
            guard snapshot.weekdays.containsCalendarWeekday(weekday) else { continue }

            let times = await MainActor.run { () -> PrayerTimes? in
                return AthanManager.shared.calculateTimes(
                    referenceDate: day,
                    customCoordinate: snapshot.coordinate,
                    customTimeZone: snapshot.timeZone,
                    adjustments: snapshot.adjustments
                )
            }
            guard let times = times else { continue }

            let base: Date
            switch snapshot.target {
            case .fajr:    base = times.fajr
            case .sunrise: base = times.sunrise
            }
            let fireDate = base.addingTimeInterval(TimeInterval(snapshot.offsetMinutes * 60))

            // Skip times already in the past.
            if fireDate > now {
                results.append(fireDate)
            }
        }
        return results
    }
}
