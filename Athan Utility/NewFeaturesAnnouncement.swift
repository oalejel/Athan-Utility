//
//  NewFeaturesAnnouncement.swift
//  Athan Utility
//
//  One-time local notification telling EXISTING users about recent feature work,
//  deep-linking to the "Discover Features" list. Compiled into both the app and the
//  widget extension (they share the app-group defaults below) since either can be
//  the process that first observes an eligible, active install.
//
//  Trigger (either, whichever happens first):
//   - the widget's timeline provider executes (proves an existing install: a widget
//     must already be configured, which a brand-new install can't have yet at launch), OR
//   - the main app is reopened (not its very first-ever launch) with no active widgets.
//  Never fires for a brand-new install — new users get the light-bulb hint instead.
//  Fires at most once, ever.
//

import Foundation
import UserNotifications
#if canImport(WidgetKit)
import WidgetKit
#endif

extension Notification.Name {
    /// Posted when the user taps the new-features local notification; MainSwiftUI
    /// opens the Discover Features sheet in response.
    static let athanOpenFeatureDiscovery = Notification.Name("AthanOpenFeatureDiscovery")
}

enum NewFeaturesAnnouncement {
    static let notificationIdentifier = "new_features_announcement"

    private static let suite = UserDefaults(suiteName: "group.athanUtil")
    private static let hasEverLaunchedKey = "newFeatures_hasEverLaunchedMainApp"
    private static let announcedKey = "newFeatures_announced_v1"
    private static let pendingOpenKey = "newFeatures_pendingOpen"

    /// Set when the notification is tapped. A live `.athanOpenFeatureDiscovery`
    /// NotificationCenter post is lost if the app is cold-launched by the tap —
    /// SwiftUI's `.onReceive` subscriber doesn't exist yet at that instant. This
    /// flag survives that gap; MainSwiftUI's `.onAppear` consumes it once.
    static func markPendingOpen() {
        suite?.set(true, forKey: pendingOpenKey)
    }

    /// Call once from MainSwiftUI's startup check. Returns true (and clears the
    /// flag) at most once per tap.
    static func consumePendingOpen() -> Bool {
        guard suite?.bool(forKey: pendingOpenKey) == true else { return false }
        suite?.set(false, forKey: pendingOpenKey)
        return true
    }

    /// Call once from AppDelegate on every launch, before anything else touches
    /// these flags. Brand-new installs never get the announcement — only the
    /// SECOND+ launch of the main app counts as "existing user."
    static func handleAppLaunch() {
        let isFirstEverLaunch = !(suite?.bool(forKey: hasEverLaunchedKey) ?? false)
        suite?.set(true, forKey: hasEverLaunchedKey)
        guard !isFirstEverLaunch else { return }   // brand-new install: never announce
        guard suite?.bool(forKey: announcedKey) != true else { return }   // already handled, ever

        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.getCurrentConfigurations { result in
                let hasActiveWidgets = ((try? result.get())?.isEmpty == false)
                // If widgets ARE configured, let the widget's own timeline refresh
                // (announceFromWidgetIfEligible) be the trigger instead — avoids a
                // double-fire race between the two paths.
                guard !hasActiveWidgets else { return }
                scheduleIfNeeded()
            }
            return
        }
        #endif
        scheduleIfNeeded()
    }

    /// Call from the widget's timeline provider (e.g. `getTimeline`). No-ops unless
    /// the main app has launched at least once before — otherwise a fresh install
    /// that adds a widget immediately would look like an existing user.
    static func announceFromWidgetIfEligible() {
        guard suite?.bool(forKey: hasEverLaunchedKey) == true else { return }
        guard suite?.bool(forKey: announcedKey) != true else { return }
        scheduleIfNeeded()
    }

    private static func scheduleIfNeeded() {
        // Set the flag BEFORE scheduling to keep the already-tiny cross-process
        // race window (app + widget both eligible at once) as small as possible;
        // a request is also fine to re-add under the same identifier, so a rare
        // double-add is harmless.
        guard suite?.bool(forKey: announcedKey) != true else { return }
        suite?.set(true, forKey: announcedKey)

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = Strings.newFeaturesAnnouncementTitle
            content.body = Strings.newFeaturesAnnouncementBody
            content.sound = .default
            content.userInfo = ["identifier": notificationIdentifier]

            // A short delay rather than immediate delivery — avoids firing mid
            // app-launch animation or mid widget-timeline computation.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
