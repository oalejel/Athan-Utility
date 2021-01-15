//
//  PhoneWatchDelegate.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/13/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import Foundation
import WatchConnectivity

class PhoneWatchDelegate: NSObject, WCSessionDelegate {
    
    static let shared = PhoneWatchDelegate()
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(">>> phone->watch state: \(activationState == .activated)")
        if error != nil {
            print(">> error: \(error!)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable && session.activationState == .activated {
            print(">>> watch reachable and active")
            
            do {
                let encoded = try PropertyListEncoder().encode(WatchPackage(locationSettings: AthanManager.shared.locationSettings, prayerSettings: AthanManager.shared.prayerSettings))
                WCSession.default.sendMessage([PhoneMessage.SettingsPackage.rawValue : encoded]) { replyDict in
                    print("watchos reply: \(replyDict)")
                } errorHandler: { error in
                    print("> Error with WCSession send")
                }
            } catch {
                print(">>> unable to encode location settings response. error: \(error)")
            }
            
            
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(">>> got request from watch")
        if let msgType = message[WATCH_MSG_KEY] as? WatchMessage {
            switch msgType {
            case .RequestSettingsPackage:
                do {
                    let encoded = try PropertyListEncoder().encode(WatchPackage(locationSettings: AthanManager.shared.locationSettings, prayerSettings: AthanManager.shared.prayerSettings))
                    replyHandler([PhoneMessage.SettingsPackage.rawValue:encoded])
                } catch {
                    print(">>> unable to encode location settings response")
                }
            }
        }
    }
    
    //    func sessionDidBecomeInactive(_ session: WCSession) {
    //
    //    }
    
    //    func sessionDidDeactivate(_ session: WCSession) {
    //
    //    }
    
    
}
