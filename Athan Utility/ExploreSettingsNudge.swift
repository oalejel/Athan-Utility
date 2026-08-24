//
//  ExploreSettingsNudge.swift
//  Athan Utility
//
//  Nudges users who never explore any Settings feature (see SettingsFeatureGrid /
//  AdoptedFeature) after updating to a new version. Scheduled optimistically on the
//  first launch of each new version, then cancelled the moment the user explores any
//  feature (see AdoptedFeature.activate in SettingsFeatureGrid.swift).
//

import Foundation
import UserNotifications

enum ExploreSettingsNudge {
    static let notificationIdentifier = "explore_settings_nudge"
    // Renamed from "exploreNudge_lastSeenVersion" (v1 shipped placeholder copy —
    // "TODO_EXPLORE_SETTINGS_TITLE"/"_BODY" literally — in 8.0.0 through 8.0.2). Any
    // value stored under the old key is now simply never read, so every affected
    // install's next launch looks like "first launch of this version" again and
    // re-arms the nudge with real copy, independent of whether CFBundleShortVersionString
    // actually changes in this release. Do not rename this back or reuse the old key.
    private static let lastSeenVersionKey = "exploreNudge_lastSeenVersion_v2"
    private static let delayDays = 3

    private static var store: UserDefaults? { UserDefaults(suiteName: "group.athanUtil") }

    /// Call once per app launch (AppDelegate). If this is the first launch of a new
    /// version and the user hasn't explored any Settings feature yet, schedule a nudge
    /// for a few days out. No-ops on repeat launches of the same version.
    static func recordLaunchAndScheduleIfNeeded() {
        // Kill any nudge already sitting in the pending queue from before this fix —
        // its content was captured at schedule time with the old placeholder strings
        // baked in, so simply updating the app does not correct one already scheduled.
        // Safe to call even when nothing is pending.
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        let lastSeenVersion = store?.string(forKey: lastSeenVersionKey)
        guard lastSeenVersion != currentVersion else { return } // not the first launch of this version

        store?.set(currentVersion, forKey: lastSeenVersionKey)

        guard AdoptedFeature.loadDone().isEmpty else { return } // already explored something — nothing to nudge about

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = Strings.exploreSettingsNudgeTitle
            content.body = Strings.exploreSettingsNudgeBody
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delayDays * 24 * 60 * 60), repeats: false)
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// Call whenever the user explores any Settings feature — cancels the pending nudge
    /// since the condition it exists to address no longer applies.
    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}
