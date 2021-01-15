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
                WCSession.default.sendMessageData(encoded) { (respData) in
                    print(">>> got response from sending watch data")
                } errorHandler: { error in
                    print(">>> error from watch in sending data \(error)")
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
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        // dont care what the message is. always respond with settings packge for now.
        do {
            let encoded = try PropertyListEncoder().encode(WatchPackage(locationSettings: AthanManager.shared.locationSettings, prayerSettings: AthanManager.shared.prayerSettings))
            replyHandler(encoded)
        } catch {
            print(">>> unable to encode location settings response")
        }
    }
    
}
