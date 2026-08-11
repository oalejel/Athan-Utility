//
//  AppDelegate.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

// بسم الله الرحمان الرحيم

import UIKit
import UserNotifications
import WatchConnectivity
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    // Identifier must match BGTaskSchedulerPermittedIdentifiers in Info.plist.
    static let fajrAlarmRefreshTaskID = "com.omaralejel.Athan-Utility.fajrAlarmRefresh"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if WCSession.isSupported() {
            WCSession.default.delegate = PhoneWatchDelegate.shared
            WCSession.default.activate()
        }

        // Required for willPresent/didReceive to fire (foreground alerts and
        // notification-tap handling — e.g. NewFeaturesAnnouncement's deep link).
        UNUserNotificationCenter.current().delegate = self

        // Seed deterministic demo state when launched by the snapshot UI test.
        SnapshotSupport.seedIfNeeded()

        ExploreSettingsNudge.recordLaunchAndScheduleIfNeeded()
        NewFeaturesAnnouncement.handleAppLaunch()

        registerFajrAlarmRefreshTask()
        scheduleFajrAlarmRefresh()

        #if targetEnvironment(macCatalyst)
        // Load the native-macOS helper bundle, show the menu bar item, and start the live
        // title driver — but OFF the launch critical path. The title driver touches
        // AthanManager/settings (file I/O); doing that synchronously here blocks scene
        // creation and can trip the launch watchdog if the read is slow.
        DispatchQueue.main.async {
            MenuBarBridge.shared.start()
            MenuBarController.shared.start()
        }
        // First launch on Mac: proactively surface the system location prompt
        // instead of waiting for the user to find the "Use Current Location"
        // button. Only fires once ever, and only if location hasn't already
        // been decided (avoids re-prompting after a prior grant/deny).
        let key = "didRequestMacLocationOnFirstLaunch"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            if AthanManager.shared.locationManager.authorizationStatus == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    // Pre-set so didChangeAuthorization auto-fetches on grant
                    // instead of just unlocking a still-default location.
                    if let updated = AthanManager.shared.locationSettings.copy() as? LocationSettings {
                        updated.useCurrentLocation = true
                        AthanManager.shared.locationSettings = updated
                    }
                    AthanManager.shared.requestLocationPermission()
                }
            }
        }
        #endif

        return true
    }

    // Note: `applicationDidEnterBackground` is not invoked on scene-based
    // apps (this project has `UIApplicationSceneManifest` in Info.plist),
    // so the background-refresh top-up is wired from
    // `SceneDelegate.sceneDidEnterBackground` instead.

    // MARK: - AlarmKit background refresh

    private func registerFajrAlarmRefreshTask() {
        // Run the launch handler on the main queue. `reloadSettingsAndNotifications`
        // mutates `@Published` state on `ObservableAthanManager` and touches
        // timers / `WidgetCenter.shared`, both of which require the main thread.
        // Passing `nil` here would put the handler on a system background
        // queue, triggering Combine's "Publishing changes from background
        // threads is not allowed" runtime issue.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppDelegate.fajrAlarmRefreshTaskID,
            using: .main
        ) { task in
            self.handleFajrAlarmRefresh(task: task as! BGAppRefreshTask)
        }
    }

    // Internal so SceneDelegate can re-submit on backgrounding.
    func scheduleFajrAlarmRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: AppDelegate.fajrAlarmRefreshTaskID)
        // Refresh at most every ~6 hours. System decides the actual firing.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("AppDelegate: could not submit Fajr alarm refresh task: \(error)")
        }
    }

    private func handleFajrAlarmRefresh(task: BGAppRefreshTask) {
        // Always reschedule for the next window first so a slow completion
        // doesn't drop the rolling refresh.
        scheduleFajrAlarmRefresh()

        // `setTaskCompleted(success:)` must be called exactly once per
        // BGAppRefreshTask. Both `expirationHandler` and the awaiting Task
        // below can fire (if the OS expires us while the sync's in-flight
        // scheduling continues — cooperative cancellation doesn't abort
        // AlarmKit calls immediately), so funnel both paths through a
        // guarded completion. NSLock because Apple doesn't contractually
        // guarantee `expirationHandler` runs on the same queue as the
        // `using:` queue passed to `register`.
        let completionLock = NSLock()
        var hasCompleted = false
        let complete: (Bool) -> Void = { success in
            completionLock.lock()
            defer { completionLock.unlock() }
            guard !hasCompleted else { return }
            hasCompleted = true
            task.setTaskCompleted(success: success)
        }

        // Rebuild only the AlarmKit window here — deliberately NOT
        // `reloadSettingsAndNotifications()`. That call wipes and re-adds all
        // pending athan notifications on untracked async callbacks; if the OS
        // suspends us right after this task completes, the wipe can land
        // without the re-adds, leaving the user with zero prayer
        // notifications until the next app open. It also spawns an internal
        // `syncAlarms()` Task that the expiration handler below couldn't
        // cancel. Settings are already fresh: this process (even when
        // background-launched) loads every settings archive on first access,
        // and the sync reads them via its own main-actor snapshot.
        let syncTask = FajrAlarmManager.shared.syncAlarms()

        task.expirationHandler = {
            syncTask.cancel()
            complete(false)
        }

        Task { @MainActor in
            await syncTask.value
            complete(true)
        }
    }
    
    // launching from a force-press shortcut item
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("opening into foreground with shortcut")
    }
    
    // allow local notification in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }

    // Handle notification taps — specifically the one-time new-features
    // announcement, which deep-links to the Discover Features sheet.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == NewFeaturesAnnouncement.notificationIdentifier {
            NotificationCenter.default.post(name: .athanOpenFeatureDiscovery, object: nil)
        }
        completionHandler()
    }
}

