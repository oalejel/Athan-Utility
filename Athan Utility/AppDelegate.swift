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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if WCSession.isSupported() {
            WCSession.default.delegate = PhoneWatchDelegate.shared
            WCSession.default.activate()
        }

        // Seed deterministic demo state when launched by the snapshot UI test.
        SnapshotSupport.seedIfNeeded()

        #if targetEnvironment(macCatalyst)
        // Load the native-macOS helper bundle, show the menu bar item, and start the live
        // title driver — but OFF the launch critical path. The title driver touches
        // AthanManager/settings (file I/O); doing that synchronously here blocks scene
        // creation and can trip the launch watchdog if the read is slow.
        DispatchQueue.main.async {
            MenuBarBridge.shared.start()
            MenuBarController.shared.start()
            if MenuBarSettings.menuBarOnly {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    MenuBarBridge.shared.setDockIconHidden(true)
                }
            }
        }
        #endif

        return true
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

