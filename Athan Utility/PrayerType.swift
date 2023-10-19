//
//  PrayerType.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 7/21/18.
//  Copyright © 2018 Omar Alejel. All rights reserved.
//

import Foundation
import Adhan

public enum PrayerType: Int {
    case fajr, shurooq, thuhr, asr, maghrib, isha, none
    func stringValue() -> String {
        switch self {
        case .fajr:
            return "Fajr"
        case .shurooq:
            return "Shurooq"
        case .thuhr:
            return "Thuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
        case .none:
            return "This should not be visible"
        }
    }
    
    // Helpful for interoperability in prayer types between the API and this app's internal representation
    // TODO: consider unifying enums under one
    init(apiPrayer: Prayer) {
        switch apiPrayer {
        case .fajr:
            self = .fajr
        case .sunrise:
            self = .shurooq
        case .dhuhr:
            self = .thuhr
        case .asr:
            self = .asr
        case .maghrib:
            self = .maghrib
        case .isha:
            self = .isha
        default:
            print("ERROR: UNKNOWN TYPE")
            self = .fajr
        }
    }
    
    func apiPrayer() -> Prayer {
        switch self {
        case .fajr:
            return .fajr
        case .shurooq:
            return .sunrise
        case .thuhr:
            return .dhuhr
        case .asr:
            return .asr
        case .maghrib:
            return .maghrib
        case .isha:
            return .isha
        case .none:
            print("ERROR: NONE TYPE INVALID")
            return .fajr
        }
    }
    
    func localizedString() -> String {
        return NSLocalizedString(self.stringValue(), comment: "")
    }
    
    //incrementors
    func next() -> PrayerType {
        if self == .isha {return .fajr}
        if self == .none {return .fajr}//none can happen when it is a new day
        return PrayerType(rawValue: self.rawValue + 1)!
    }
    func previous() -> PrayerType {
        if self == .fajr {return .isha}
        return PrayerType(rawValue: self.rawValue - 1)!
    }
}
