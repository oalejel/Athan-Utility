//
//  WatchSessionDelegate.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/13/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(">>> watch->phone state: \(activationState == .activated)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            // whenever we become active and reachable, request location from phone
            print(">>> PHONE NOW REACHABLE")
            if session.activationState == .activated {
                print("requesting location from iphone")
                WCSession.default.sendMessageData(WATCH_MSG_KEY.data(using: .ascii)!) { responseData in
                    do {
                        let package = try PropertyListDecoder().decode(WatchPackage.self, from: responseData)
                        print(">>> WATCH GOT LOCATION: \(package.locationSettings.locationName)")
                        AthanManager.shared.locationSettings = package.locationSettings
                        AthanManager.shared.prayerSettings = package.prayerSettings
                    } catch {
                        print(">>> error decoding location data")
                    }
                } errorHandler: { error in
                    
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
            print("got message w reply handler from iphone")
        do {
            let package = try PropertyListDecoder().decode(WatchPackage.self, from: messageData)
            print(">>> WATCH GOT LOCATION: \(package.locationSettings.locationName)")
            AthanManager.shared.locationSettings = package.locationSettings
            AthanManager.shared.prayerSettings = package.prayerSettings
            replyHandler("watch successfully got package".data(using: .ascii)!)
            return
        } catch {
            print(">> watch error decoding reponse from phone")
        }
        replyHandler("watch received with error".data(using: .ascii)!)
    }        
}
