//
//  ExtensionDelegate.swift
//  Athan Watch Extension
//
//  Created by Omar Al-Ejel on 1/15/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import WatchKit

class CustomExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func handle(_ userActivity: NSUserActivity) {
        // can tell if user launched from complication
    }
    func applicationWillEnterForeground() {
        AthanManager.shared.movedToForeground()
    }
    func applicationDidBecomeActive() {
        print(">>:::: watch app became active!!!")
    }
}
