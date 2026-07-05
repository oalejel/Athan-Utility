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

        registerFajrAlarmRefreshTask()
        scheduleFajrAlarmRefresh()

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
}

