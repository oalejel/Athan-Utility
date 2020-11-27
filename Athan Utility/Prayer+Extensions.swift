//
//  Prayer+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/15/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation
import Adhan

extension Prayer: Codable {
    enum PrayerKey: CodingKey {
        case key
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PrayerKey.self)
        let raw = try container.decodeIfPresent(Int.self, forKey: .key)
        switch raw {
        case 0:
            self = .fajr
        case 1:
            self = .sunrise
        case 2:
            self = .dhuhr
        case 3:
            self = .asr
        case 4:
            self = .maghrib
        case 5:
            self = .isha
        default:
            self = .fajr
        }
    }

    public func encode(to encoder: Encoder) throws {
        let map: [Prayer:Int] = [.fajr:0, .sunrise:1, .dhuhr:2, .asr:3, .maghrib:4, .isha:5]
        var container = encoder.container(keyedBy: PrayerKey.self)
        try container.encode(map[self], forKey: .key)
    }
    
    func rawValue() -> Int {
        switch self {
        case .fajr:
            return 0
        case .sunrise:
            return 1
        case .dhuhr:
            return 2
        case .asr:
            return 3
        case .maghrib:
            return 4
        case .isha:
            return 5
        }
    }
    
    init(index: Int) {
        switch index {
        case 0:
            self = .fajr
        case 1:
            self = .sunrise
        case 2:
            self = .dhuhr
        case 3:
            self = .asr
        case 4:
            self = .maghrib
        case 5:
            self = .isha
        default:
            fatalError("index for initializing prayer out of bounds")
        }
    }
    
    func stringValue() -> String {
        switch self {
        case .fajr:
            return "Fajr"
        case .sunrise:
            return "Shurooq"
        case .dhuhr:
            return "Thuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
//        case .none:
//            return "This should not be visible"
        }
    }
    
    // use overridden name if provided
    func localizedString() -> String {
        return NSLocalizedString(self.stringValue(), comment: "")
    }
}
