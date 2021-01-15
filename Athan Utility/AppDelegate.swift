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
        // NOTE: ask for notifications permissions once features are shown so that the
        // user can digest the app before allowing notifications
        
        if #available(iOS 13.0.0, *) {
            // assuming swift ui works in this case/
//            UIView.appearance().tintColor = .white
            print("SWIFT UI WILL HANDLE IOS 13+")
            
            if WCSession.isSupported() {
                WCSession.default.delegate = PhoneWatchDelegate.shared
                WCSession.default.activate()
            }
//            assert(WCSession.isSupported(), "This sample requires Watch Connectivity support!")

            
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
            let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
            window?.rootViewController = sb.instantiateInitialViewController()
            window?.makeKeyAndVisible()
        }
        
        UNUserNotificationCenter.current().delegate = self
        if let shortcut = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            if shortcut.type == "qibla" {
                Global.openQibla = true
            }
        }
        return true
    }
    
    // launching from a force-press shortcut item
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("opening into foreground with shortcut")
        if let mainVC = application.keyWindow?.rootViewController as? ViewController {
            mainVC.showQibla(mainVC)
        }
    }
    
    // allow local notification in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    
}

