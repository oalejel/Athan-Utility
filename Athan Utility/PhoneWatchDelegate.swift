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
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(">>> got request from watch")
        if let msgType = message[WATCH_MSG_KEY] as? WatchMessage {
            switch msgType {
            case .RequestLocationSettings:
                do {
                    let encoded = try PropertyListEncoder().encode(AthanManager.shared.locationSettings)
                    replyHandler([PHONE_REPLY_KEY:encoded])
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
