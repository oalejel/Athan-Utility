//
//  NextPrayerIntent.swift
//  AthanSiriIntents
//
//  Created by Omar Al-Ejel on 5/7/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import Foundation
import Intents

// for requests like "when is the next prayer?"
// should respond with the time, and remaining hours, minutes

class NextPrayerIntentHandler: NSObject, NextPrayerIntentHandling, PrayerManagerDelegate {
    
    var manager: PrayerManager!
    
    var locationIsUpToDate: Bool = false
    
    func dataReady(manager: PrayerManager) {
        
    }


    
    func handle(intent: NextPrayerIntent, completion: @escaping (NextPrayerIntentResponse) -> Void) {
        // get prayer data if available
        let manager = PrayerManager(delegate: self)
        
        let response = NextPrayerIntentResponse(code: .success, userActivity: nil)
    }
    
    // uncomment this to test out optionality of a custom request location
//    func confirm(intent: NextPrayerIntent, completion: @escaping (NextPrayerIntentResponse) -> Void) {
//        <#code#>
//    }
    
}
