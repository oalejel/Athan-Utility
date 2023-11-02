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
            // if system language not explicity english, dont show whats new screen
            if !(Locale.preferredLanguages.first?.hasPrefix("en") ?? false) {
                return
            }
            
            let versionStore: WhatsNewVersionStore = UserDefaultsWhatsNewVersionStore()
            print("presented versions")
            print(versionStore.presentedVersions)
            var featuresToDisplay: [WhatsNew.Feature] = []
            // since we changed our version store, need an additional check for if this is a first time user
            let isFirstTimeUser = versionStore.presentedVersions.count == 0 || UserDefaults.standard.string(forKey: "moonsettings") == nil
            if isFirstTimeUser {
                featuresToDisplay = [
                    .init(
                        image: .init(systemName: "applewatch.watchface"),
                        title: "Apple Watch App",
                        subtitle: "Athan times at a glance with a new watchOS app and complications."
                    ),
                    .init(
                        image: .init(systemName: "location.north"),
                        title: "Always-on Qibla",
                        subtitle: "Point towards Mecca with the Qibla pointer in the top right of your screen."
                    ),
                    .init(
                        image: .init(systemName: "calendar"),
                        title: "Times Calendar",
                        subtitle: "Drag up inside the athan times table for a full calendar."
                    ),
                    .init(
                        image: .init(systemName: "bell.badge"),
                        title: "Reminder Settings",
                        subtitle: "Adjust reminder times to avoid missing salah."
                    ),
                    .init(
                        image: .init(systemName: "rectangle.fill.on.rectangle.fill"),
                        title: "Widgets",
                        subtitle: "View athan times on your home screen with widgets."
                    ),
                    .init(
                        image: .init(systemName: "hand.draw"),
                        title: "Interactive Sun and Moon",
                        subtitle: "Drag the sun and moon for fun!"
                    ),
                    .init(
                        image: .init(systemName: "paintpalette.fill"),
                        title: "Customizable Colors",
                        subtitle: "Customize your app and widget background gradients."
                    ),
                    .init(
                        image: .init(systemName: "gear"),
                        title: "And much more!",
                        subtitle: "Browse settings for even more new features."
                    ),
                ]
            }
            
            // LATEST FEATURES - show for existing and new users
            // If newly updating to v7.x.x
            let hasPresentedV7 = versionStore.presentedVersions.contains(where: { $0.major == 7 })
            if !hasPresentedV7 {
                // Remove "and more" entry from general list
                if !featuresToDisplay.isEmpty { featuresToDisplay.removeLast() }
                
                featuresToDisplay.append(contentsOf: [
                    .init(image: .init(systemName: "platter.2.filled.iphone.landscape"),
                          title: "StandBy Widgets",
                          subtitle: "See the latest Athan times in iOS 17's StandBy mode."),
                    .init(image: .init(systemName: "message.badge.filled.fill"),
                          title: "iMessage Stickers",
                          subtitle: "Share fun stickers in iMessage with the new Athan Sticker pack."),
                    .init(image: .init(systemName: "stopwatch"),
                          title: "30 second Athan",
                          subtitle: "Choose between 5 and 30 second-long Athan notifications."),
                    .init(image: .init(systemName: "plus.forwardslash.minus"),
                          title: "Time Adjustments",
                          subtitle: "Set custom time adjustments for each prayer."),
                    .init(image: .init(systemName: "calendar"),
                          title: "Calendar Button",
                          subtitle: "The monthly Athan Calendar is now easier to find."),
                    .init(image: .init(systemName: "square.and.arrow.up.on.square.fill"),
                          title: "Calendar Export",
                          subtitle: "Export Athan times to .csv to chart in Excel or Numbers."),
                ])
            }
            
            // Don't present WhatsNew if no new features exist
            if featuresToDisplay.isEmpty {
                return
            }
            
            let whatsNew = WhatsNew(
                title: "What's New",
                features: featuresToDisplay
            )
            
            // Debug with InMemoryWhatsNewVersionStore()
            guard let whatsNewViewController = WhatsNewViewController(whatsNew: whatsNew, versionStore:versionStore) else {
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

