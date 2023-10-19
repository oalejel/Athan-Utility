//
//  GetXIntentHandler.swift
//  AthanSiriIntents
//
//  Created by Omar Al-Ejel on 10/15/23.
//  Copyright © 2023 Omar Alejel. All rights reserved.
//

import Foundation
import Intents

// for requests like "when is fajr/thuhr/etc"

//func selectDate(manager: AthanManager) -> Date? {
//    guard let currentPrayer = manager.currentPrayer else {
//        completion(GetFajrIntentResponse(code: .failure, userActivity: nil))
//        return
//    }
//
//    if PrayerType(apiPrayer: currentPrayer).rawValue > requestedPrayer.rawValue {
//
//}

class GetFajrHandler: NSObject, GetFajrIntentHandling {
    let manager = AthanManager.shared
    let intentType = PrayerType.fajr
    
    func handle(intent: GetFajrIntent, completion: @escaping (GetFajrIntentResponse) -> Void) {
        
        // get current prayer to check if requested type has already passed today
        guard let currentPrayer = manager.currentPrayer else {
            completion(GetFajrIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // If requested prayer has already passed, get
        // tomorrow's time for that salah
        var pDate = manager.todayTimes.time(for: intentType.apiPrayer())
        if PrayerType(apiPrayer: currentPrayer).rawValue > intentType.rawValue {
            // Step 1: get date from today's times
            pDate = manager.tomorrowTimes.time(for: intentType.apiPrayer())
        }
        let response = GetFajrIntentResponse(code: .success, userActivity: nil)
        response.prayerName = .fajr
        response.prayerDate = Calendar.current.dateComponents([.hour, .minute], from: pDate)
        response.recentLocation = manager.locationSettings.locationName
        completion(response)
        
    }
}

class GetThuhrHandler: NSObject, GetThuhrIntentHandling {
    let manager = AthanManager.shared
    let intentType = PrayerType.thuhr
    
    func handle(intent: GetThuhrIntent, completion: @escaping (GetThuhrIntentResponse) -> Void) {
        guard let currentPrayer = manager.currentPrayer else {
            completion(GetThuhrIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        var pDate = manager.todayTimes.time(for: intentType.apiPrayer())
        if PrayerType(apiPrayer: currentPrayer).rawValue > intentType.rawValue {
            // Step 1: get date from today's times
            pDate = manager.tomorrowTimes.time(for: intentType.apiPrayer())
        }
        let response = GetThuhrIntentResponse(code: .success, userActivity: nil)
        response.prayerName = .dhuhr
        response.prayerDate = Calendar.current.dateComponents([.hour, .minute], from: pDate)
        response.recentLocation = manager.locationSettings.locationName
        completion(response)
    }
}

class GetAsrHandler: NSObject, GetAsrIntentHandling {
    let manager = AthanManager.shared
    let intentType = PrayerType.asr
    
    func handle(intent: GetAsrIntent, completion: @escaping (GetAsrIntentResponse) -> Void) {
        guard let currentPrayer = manager.currentPrayer else {
            completion(GetAsrIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        var pDate = manager.todayTimes.time(for: intentType.apiPrayer())
        if PrayerType(apiPrayer: currentPrayer).rawValue > intentType.rawValue {
            // Step 1: get date from today's times
            pDate = manager.tomorrowTimes.time(for: intentType.apiPrayer())
        }
        let response = GetAsrIntentResponse(code: .success, userActivity: nil)
        response.prayerName = .asr
        response.prayerDate = Calendar.current.dateComponents([.hour, .minute], from: pDate)
        response.recentLocation = manager.locationSettings.locationName
        completion(response)
    }
}


class GetMaghribHandler: NSObject, GetMaghribIntentHandling {
    let manager = AthanManager.shared
    let intentType = PrayerType.maghrib
    
    func handle(intent: GetMaghribIntent, completion: @escaping (GetMaghribIntentResponse) -> Void) {
        guard let currentPrayer = manager.currentPrayer else {
            completion(GetMaghribIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        var pDate = manager.todayTimes.time(for: intentType.apiPrayer())
        if PrayerType(apiPrayer: currentPrayer).rawValue > intentType.rawValue {
            // Step 1: get date from today's times
            pDate = manager.tomorrowTimes.time(for: intentType.apiPrayer())
        }
        let response = GetMaghribIntentResponse(code: .success, userActivity: nil)
        response.prayerName = .maghrib
        response.prayerDate = Calendar.current.dateComponents([.hour, .minute], from: pDate)
        response.recentLocation = manager.locationSettings.locationName
        completion(response)
        
    }
}

class GetIshaHandler: NSObject, GetIshaIntentHandling {
    let manager = AthanManager.shared
    let intentType = PrayerType.isha
    
    func handle(intent: GetIshaIntent, completion: @escaping (GetIshaIntentResponse) -> Void) {
        guard let currentPrayer = manager.currentPrayer else {
            completion(GetIshaIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        var pDate = manager.todayTimes.time(for: intentType.apiPrayer())
        if PrayerType(apiPrayer: currentPrayer).rawValue > intentType.rawValue {
            // Step 1: get date from today's times
            pDate = manager.tomorrowTimes.time(for: intentType.apiPrayer())
        }
        let response = GetIshaIntentResponse(code: .success, userActivity: nil)
        response.prayerName = .isha
        response.prayerDate = Calendar.current.dateComponents([.hour, .minute], from: pDate)
        response.recentLocation = manager.locationSettings.locationName
        completion(response)
    }
}
