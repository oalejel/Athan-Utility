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
// Captured on the main actor so the Task body never reads mutable shared
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

    // Each call to `syncAlarms()` starts a Task that first awaits the previous
    // Task's completion, producing a strict serial chain. This replaces an
    // earlier DispatchQueue + DispatchSemaphore implementation — bridging
    // `DispatchSemaphore.wait()` with `await` is a Swift-Concurrency
    // anti-pattern (blocks a cooperative thread waiting for a Task) and can
    // starve the main actor under load.
    private var latestSync: Task<Void, Never>?
    private let chainLock = NSLock()

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
    // Returns a Task that completes when this sync pass (and any queued before
    // it) finishes — callers that need to await completion (e.g. the
    // BGAppRefreshTask handler) can `await task.value`; fire-and-forget
    // callers can ignore the return value thanks to `@discardableResult`.
    @discardableResult
    func syncAlarms() -> Task<Void, Never> {
        chainLock.lock()
        let previous = latestSync
        let task = Task { [weak self] in
            _ = await previous?.value
            guard !Task.isCancelled else { return }
            await self?.performSync()
        }
        latestSync = task
        chainLock.unlock()
        return task
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

    private func performSync() async {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard let snapshot = await makeSnapshot() else { return }
            await syncAlarmsAvailable(snapshot: snapshot)
        }
        #endif
    }

    // Build a snapshot of everything the scheduler needs. Runs on the main
    // actor because it reads `FajrAlarmSettings.shared` and `AthanManager`
    // singleton state that the UI also writes to. Does NOT mutate those
    // singletons — `sanitize()` is applied at archive/load time instead.
    @MainActor
    private func makeSnapshot() -> FajrSyncSnapshot? {
        let settings = FajrAlarmSettings.shared
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

    // The system's current view of our alarms, keyed by ID. Returns nil when
    // the query fails, in which case callers must assume every stored ID is
    // still live rather than dropping IDs they can no longer verify.
    @available(iOS 26.0, *)
    private func knownAlarms(manager: AlarmManager) -> [UUID: Alarm]? {
        guard let alarms = try? manager.alarms else { return nil }
        var byID: [UUID: Alarm] = [:]
        for alarm in alarms { byID[alarm.id] = alarm }
        return byID
    }

    @available(iOS 26.0, *)
    private func cancelAllAvailable() async {
        let manager = AlarmManager.shared
        let known = knownAlarms(manager: manager)
        let ids = FajrAlarmStore.load()
        var remaining: [UUID] = []
        var processed = 0
        for id in ids {
            // Honor cooperative cancellation (e.g. BGTask expired). Persist
            // the un-processed tail so the next sync pass retries them
            // instead of leaking orphan alarms.
            if Task.isCancelled {
                remaining.append(contentsOf: ids.dropFirst(processed))
                FajrAlarmStore.save(ids: remaining)
                return
            }
            processed += 1
            // Forget IDs the system no longer knows about (already fired and
            // dismissed, or removed externally) — retrying cancel on those
            // would fail forever and grow the store without bound.
            if let known = known, known[id] == nil { continue }
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

        // Never trigger the one-shot system authorization prompt from a sync
        // pass — syncs run at launch and from background refresh, where a
        // permission dialog is either impossible or badly out of context.
        // The prompt is only shown by the explicit user flow in
        // `requestAuthorization(completion:)` (Fajr Alarm settings screen).
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            break
        case .denied:
            // User revoked AlarmKit access; clean up anything stale.
            await cancelAllAvailable()
            return
        case .notDetermined:
            return
        @unknown default:
            return
        }

        // Partition our previously scheduled alarms using the system's view:
        //  - gone:        the system no longer knows the ID (fired & dismissed)
        //                 → forget it.
        //  - in progress: alerting or counting down a snooze → must NOT be
        //                 cancelled; killing it would silence the user's
        //                 wake-up mid-ring or swallow the snooze re-alert.
        //  - scheduled:   part of the old rolling window → replaced below.
        // If the system query fails, treat every stored ID as "scheduled" so
        // nothing is forgotten while unverifiable.
        let known = knownAlarms(manager: manager)
        var inProgressIDs: [UUID] = []
        var oldIDs: [UUID] = []
        for id in FajrAlarmStore.load() {
            if let known = known {
                guard let alarm = known[id] else { continue } // gone → forget
                switch alarm.state {
                case .scheduled: oldIDs.append(id)
                default:         inProgressIDs.append(id)     // countdown / paused / alerting
                }
            } else {
                oldIDs.append(id)
            }
        }

        var newIDs: [UUID] = []
        // Persist the full tracked set after every mutation so that process
        // death or BGTask expiration mid-sync never orphans an alarm we
        // scheduled but hadn't recorded (or forgets one we still track).
        func persist() { FajrAlarmStore.save(ids: inProgressIDs + oldIDs + newIDs) }
        persist() // drops "gone" IDs immediately

        // Compute the next N firing dates.
        let fireDates = await upcomingFireDates(snapshot: snapshot)

        // Title is built from a localized format string so Arabic / RTL
        // languages can rearrange the word order (e.g. "منبّه الفجر").
        let title = String(format: Strings.fajrAlarmTitleFormat, snapshot.targetDisplayName)
        let tint = Color(red: 4.0/255.0, green: 65.0/255.0, blue: 125.0/255.0)

        // Schedule the new window BEFORE cancelling the old one so a
        // transient scheduling failure degrades to "yesterday's window is
        // still set" instead of "no alarms at all". The brief overlap is
        // bounded at 2× daysAhead alarms.
        var scheduleFailures = 0
        for date in fireDates {
            // Honor cooperative cancellation. Everything scheduled so far is
            // already persisted; the next sync pass finishes the rebuild.
            if Task.isCancelled { return }
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
                persist()
            } catch {
                scheduleFailures += 1
                print("FajrAlarmManager: failed to schedule \(date): \(error)")
            }
        }

        // If every schedule attempt failed, keep the old window in place as
        // a fallback wake-up rather than tearing it down and leaving the
        // user with nothing; the next sync pass retries the rebuild.
        if scheduleFailures > 0 && newIDs.isEmpty {
            return
        }

        // Cancel the old window. IDs that fail to cancel stay tracked so the
        // next sync pass retries them instead of leaking orphans.
        var stillOld: [UUID] = []
        var processed = 0
        for id in oldIDs {
            if Task.isCancelled {
                stillOld.append(contentsOf: oldIDs.dropFirst(processed))
                break
            }
            processed += 1
            do {
                try manager.cancel(id: id)
            } catch {
                stillOld.append(id)
            }
        }
        oldIDs = stillOld
        persist()
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

        // `AlarmButton.text` is a `LocalizedStringResource`; the bare string
        // literals below are implicitly promoted to keys that resolve against
        // `Localizable.strings` at display time. "Stop" and "Snooze" are both
        // defined in every shipped locale, so the buttons re-localize if the
        // user switches system language between scheduling and firing.
        //
        // The `title` below is different: it's already rendered into the
        // scheduling-time locale by `String(format:...)` at the call site, so
        // the alarm's title stays in that language until the rolling window
        // next refreshes. Rebuilding the title with a parameterized
        // `LocalizedStringResource` so it re-localizes at display time is a
        // possible follow-up but requires threading the prayer-name argument
        // through without losing the Arabic `ال` handling.
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
            // No pause button: AlarmKit gives that control *pause* semantics
            // (an earlier revision reused the stop button here, which rendered
            // a "Stop"-labeled control that actually paused the snooze
            // indefinitely — the re-alert then never fired). Pausing a
            // wake-up snooze has no meaning, so the countdown is view-only.
            countdown = AlarmPresentation.Countdown(
                title: LocalizedStringResource(stringLiteral: title),
                pauseButton: nil
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

        // Without an explicit sound, AlarmKit schedules a silent alarm.
        // Pass the system default alarm tone — looping, bypasses silent
        // switch — which is what a user expects for a wake-up alarm.
        return AlarmManager.AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            sound: .default
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
        // Empty mask → nothing to schedule. Avoids a pointless full-window scan.
        guard snapshot.weekdays.raw != 0 else { return [] }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = snapshot.timeZone

        let now = Date()
        let startOfToday = cal.startOfDay(for: now)

        var results: [Date] = []
        // Scan enough days to deliver `daysAhead` alarms even when the
        // weekday mask is sparse (e.g. Sundays only). Worst case is 1 matching
        // day per 7 calendar days, plus a small buffer for when today's fire
        // time has already passed.
        let maxScan = snapshot.daysAhead * 7 + 7
        var offset = 0
        while results.count < snapshot.daysAhead, offset < maxScan {
            defer { offset += 1 }

            guard let day = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }

            // Respect weekday filter.
            let weekday = cal.component(.weekday, from: day) // Sunday == 1
            guard snapshot.weekdays.containsCalendarWeekday(weekday) else { continue }

            // Extract the target Date inside the main-actor closure rather
            // than returning the whole PrayerTimes struct — PrayerTimes
            // (Adhan) is not Sendable, and sending it across the actor
            // boundary is an error in Swift 6 language mode. Date is Sendable.
            let target = snapshot.target
            let base = await MainActor.run { () -> Date? in
                guard let times = AthanManager.shared.calculateTimes(
                    referenceDate: day,
                    customCoordinate: snapshot.coordinate,
                    customTimeZone: snapshot.timeZone,
                    adjustments: snapshot.adjustments
                ) else { return nil }
                switch target {
                case .fajr:    return times.fajr
                case .sunrise: return times.sunrise
                }
            }
            guard let base = base else { continue }

            let fireDate = base.addingTimeInterval(TimeInterval(snapshot.offsetMinutes * 60))

            // Skip times already in the past.
            if fireDate > now {
                results.append(fireDate)
            }
        }
        return results
    }
}
