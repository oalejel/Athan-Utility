//
//  NotificationPermission.swift
//  Athan Utility
//
//  The single place that asks for notification permission.
//
//  It used to be asked for inside NotificationsManager.createNotifications(), which
//  runs every time prayer times regenerate — so the system alert appeared the moment
//  the user finished choosing a location, stacked on top of the location flow and
//  before they had seen anything the app does. Asking there also meant a decline was
//  effectively permanent, since iOS only shows the prompt once.
//
//  Now the ask happens a few seconds after the user has actually looked at their
//  prayer times, which is the first moment "notify me for these" means anything.
//

import Foundation
import UserNotifications

enum NotificationPermission {

    /// Set once we have shown (or established we can't show) the system prompt.
    private static let promptedKey = "hasPromptedForNotificationPermission"

    /// Guards against the main view's onAppear firing more than once per launch.
    private static var scheduledThisLaunch = false

    /// How long to let the user look at the app before interrupting them.
    private static let delay: TimeInterval = 5

    /// Call when the main prayer-times UI appears. No-op after the first time.
    static func promptAfterMainUIAppears() {
        // A system alert three screens into a capture ruins the shot.
        guard !SnapshotSupport.isActive else { return }
        guard !scheduledThisLaunch else { return }
        scheduledThisLaunch = true
        guard !UserDefaults.standard.bool(forKey: promptedKey) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                // Already decided — either by this user earlier or by a prior version
                // that asked during location setup. Don't ask again; iOS wouldn't show
                // it anyway.
                guard settings.authorizationStatus == .notDetermined else {
                    UserDefaults.standard.set(true, forKey: promptedKey)
                    return
                }
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    UserDefaults.standard.set(true, forKey: promptedKey)
                    guard granted else { return }
                    // Permission arrived after times were already computed, so nothing
                    // is scheduled yet — regenerate now that we're allowed to.
                    DispatchQueue.main.async {
                        AthanManager.shared.reloadSettingsAndNotifications()
                    }
                }
            }
        }
    }
}
