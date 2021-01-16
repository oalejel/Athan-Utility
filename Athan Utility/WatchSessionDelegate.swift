//
//  WatchSessionDelegate.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/13/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import Foundation
import WatchConnectivity
import CoreLocation.CLLocation
import ClockKit

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(">>> watch->phone state: \(activationState == .activated) reachable: \(session.isReachable)")
        if session.isReachable && activationState == .activated {
            requestUpdateFromPhone()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            // whenever we become active and reachable, request location from phone
            print(">>> PHONE NOW REACHABLE")
            if session.activationState == .activated {
                requestUpdateFromPhone()
            }
        }
    }
    
    func requestUpdateFromPhone() {
        print("requesting location from iphone")
        WCSession.default.sendMessageData(WATCH_MSG_KEY.data(using: .ascii)!) { responseData in
            do {
                let package = try PropertyListDecoder().decode(WatchPackage.self, from: responseData)
                print(">>> WATCH GOT LOCATION after request: \(package.locationSettings.locationName)")
                DispatchQueue.main.async {
                    AthanManager.shared.prayerSettings = package.prayerSettings
                    AthanManager.shared.locationSettings = package.locationSettings
                }
            } catch {
                print(">>> error decoding location data")
            }
        } errorHandler: { error in
            
        }

    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
            print("got message w reply handler from iphone")
        do {
            let package = try PropertyListDecoder().decode(WatchPackage.self, from: messageData)
            print(">>> WATCH RECEIVED LOCATION: \(package.locationSettings.locationName)")
            DispatchQueue.main.async {
                AthanManager.shared.prayerSettings = package.prayerSettings
                AthanManager.shared.locationSettings = package.locationSettings
            }
            replyHandler("watch successfully got package".data(using: .ascii)!)
            return
        } catch {
            print(">> watch error decoding reponse from phone")
        }
        replyHandler("watch received with error".data(using: .ascii)!)
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        print("***>>> watch finished user info transfer")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("watch received complication update \(userInfo)")
        
        if let locName = userInfo["locname"] as? String, let lat = userInfo["latitude"] as? Double,
           let lon = userInfo["latitude"] as? Double, let currentloc = userInfo["currentloc"] as? Bool,
           let timezoneid = userInfo["timezoneid"] as? String {
            
            DispatchQueue.main.async {
                AthanManager.shared.locationSettings = LocationSettings(locationName: locName,
                                                                        coord: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                                                        timeZone: TimeZone(identifier: timezoneid)!,
                                                                        useCurrentLocation: currentloc)
            }
            
            // complications will be autoupdated in athanmanager
//            // Update complication
//            let complicationServer = CLKComplicationServer.sharedInstance()
//            guard let activeComplications = complicationServer.activeComplications else { // watchOS 2.2
//                return
//            }
//
//            for complication in activeComplications {
//                complicationServer.reloadTimeline(for: complication)
//            }
        }
        
//        "locname" : locationSettings.locationName,
//        "latitude" : locationSettings.locationCoordinate.latitude,
//        "longitude" : locationSettings.locationCoordinate.longitude,
//        "currentloc" : locationSettings.useCurrentLocation,
//        "timezoneid" : locationSettings.timeZone.identifier

    }
}
