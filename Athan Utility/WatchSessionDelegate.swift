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
        
        // whenever we become active, request location from phone
        if activationState == .activated {
            print("requesting location from iphone")
            WCSession.default.sendMessage([WATCH_MSG_KEY:WatchMessage.RequestLocationSettings]) { (replyDict) in
                if let encodedLocSettings = replyDict[PHONE_REPLY_KEY] as? Data {
                    do {
                        let locSettings = try PropertyListDecoder().decode(LocationSettings.self, from: encodedLocSettings)
                        print(">>> WATCH GOT LOCATION: \(locSettings.locationName)")
                    } catch {
                        print(">>> error decoding location data")
                    }
                }
            } errorHandler: { error in
                print(">>> WATCH GOT EERROR REQUESTING LOC")
            }

        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didreceive message!!")
    }
}
