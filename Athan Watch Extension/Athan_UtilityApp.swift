//
//  Athan_UtilityApp.swift
//  Athan Watch Extension
//
//  Created by Omar Al-Ejel on 1/6/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI

@main
struct Athan_UtilityApp: App {
    @WKExtensionDelegateAdaptor(CustomExtensionDelegate.self) var delegate
    
    @SceneBuilder var body: some Scene {
        
        WindowGroup {
            ContentView()
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
    
    
}
