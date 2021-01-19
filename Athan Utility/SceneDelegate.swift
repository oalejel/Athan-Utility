//
//  SceneDelegate.swift
//  testkit
//
//  Created by Omar Al-Ejel on 9/24/20.
//

import UIKit
import SwiftUI
import WhatsNewKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        // Create the SwiftUI view that provides the window contents.
        let _ = AthanManager.shared
        let man = ObservableAthanManager.shared
        let contentView = MainSwiftUI()
            .environmentObject(man)
            .colorScheme(.dark)
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
            
            #warning("localize whats new")
            // if systme language not explicity english, dont show whats new screen
            if !(Locale.preferredLanguages.first?.hasPrefix("en") ?? false) {
                return
            }
            
            let versionStore: WhatsNewVersionStore = KeyValueWhatsNewVersionStore()
            let whatsNew = WhatsNew(
                // The Title
                title: "What's New",
                // The features you want to showcase
                items: [
                    WhatsNew.Item(
                        title: "Apple Watch App",
                        subtitle: "Athan times at a glance with a new watchOS app and complications.",
                        image: UIImage(systemName: "applewatch.watchface")
                    ),
                    WhatsNew.Item(
                        title: "Always-on Qibla",
                        subtitle: "Point towards Mecca with the Qibla pointer in the top right of your screen.",
                        image: UIImage(systemName: "location.north")
                    ),
                    WhatsNew.Item(
                        title: "Times Calendar",
                        subtitle: "Drag up inside the athan times table for a full calendar.",
                        image: UIImage(systemName: "calendar")
                    ),
                    WhatsNew.Item(
                        title: "Reminder Settings",
                        subtitle: "Adjust reminder times to avoid missing salah.",
                        image: UIImage(systemName: "bell.badge")
                    ),
                    WhatsNew.Item(
                        title: "Widgets",
                        subtitle: "View athan times on your home screen with widgets.",
                        image: UIImage(systemName: "rectangle.fill.on.rectangle.fill")
                    ),
                    WhatsNew.Item(
                        title: "Interactive Sun and Moon",
                        subtitle: "Drag the sun and moon for fun!",
                        image: UIImage(systemName: "hand.draw")
                    ),
                    WhatsNew.Item(
                        title: "Customizable Colors",
                        subtitle: "Customize your app and widget background gradients.",
                        image: UIImage(systemName: "paintpalette.fill")
                    ),
                    WhatsNew.Item(
                        title: "And much more!",
                        subtitle: "Browse settings for even more new features.",
                        image: UIImage(systemName: "gear")
                    ),
                ]
            )
            
            guard let whatsNewViewController = WhatsNewViewController(whatsNew: whatsNew,
                                                                      configuration: .init(.darkBlue),
                                                                      versionStore: versionStore) else {
                return
            }
            
            window.rootViewController?.present(whatsNewViewController, animated: true, completion: nil)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

