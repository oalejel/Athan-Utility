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

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Request another refresh whenever we're backgrounded so the rolling
        // AlarmKit window can be topped up while the app is suspended.
        scheduleFajrAlarmRefresh()
    }

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

    private func scheduleFajrAlarmRefresh() {
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

        // Reload latest persisted settings from the app group. This kicks off
        // its own `FajrAlarmManager.syncAlarms()` internally (gated on the
        // main-app bundle); our explicit `syncAlarms()` below chains after
        // that one and is the Task we actually await before marking the
        // BGTask complete, so the rolling AlarmKit window is guaranteed to
        // be rebuilt before the OS suspends us.
        AthanManager.shared.reloadSettingsAndNotifications()
        let syncTask = FajrAlarmManager.shared.syncAlarms()

        task.expirationHandler = {
            syncTask.cancel()
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            await syncTask.value
            task.setTaskCompleted(success: true)
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

