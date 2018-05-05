//
//  AppDelegate.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //NOTE: ask for notifications permissions once features are shown so that the user can digest the app before allowing notifications
        
        return true
    }
    
    @available(iOS 9.0, *)
    // launching from a force-press shortcut item
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        Global.openQibla = true
    }
    
    // give an alert when the application is meant to receive a local notification
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if Int(Date().timeIntervalSince(notification.fireDate!)) < 10 {
            if let intendedDate = notification.userInfo?["intendedDate"] as? Date {
                let interval = Date().timeIntervalSince(intendedDate)
                let minutes = (interval / 60)
                if minutes > 0 {
                    let originalTitle = notification.alertBody
                    let newTitle = originalTitle?.replacingOccurrences(of: "15m", with: "\(minutes)m")
                    let av = UIAlertView(title: newTitle, message: nil, delegate: nil, cancelButtonTitle: "OK")
                    av.show()
                }
            }
            
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

