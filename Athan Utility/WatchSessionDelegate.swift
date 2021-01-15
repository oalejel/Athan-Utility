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
                WCSession.default.sendMessage([WATCH_MSG_KEY:WatchMessage.RequestSettingsPackage]) { (replyDict) in
                    if let encodedLocSettings = replyDict[PHONE_REPLY_KEY] as? Data {
                        do {
                            let package = try PropertyListDecoder().decode(WatchPackage.self, from: encodedLocSettings)
                            print(">>> WATCH GOT LOCATION: \(package.locationSettings.locationName)")
                        } catch {
                            print(">>> error decoding location data")
                        }
                    }
                } errorHandler: { error in
                    print(">>> WATCH GOT EERROR REQUESTING LOC: \(error)")
                }
            }

        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let package = message[PhoneMessage.SettingsPackage.rawValue] as? WatchPackage {
            print("got location from phone!!")
        } else {
            print("UNABLE TO PARSE PHONE MESSAGE \(message)")
        }
        replyHandler([WATCH_REPLY_KEY:"watch got the message"])
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didreceive message!!")
    }
}
