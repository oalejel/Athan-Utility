//
//  Prayer+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/15/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation
import Adhan

extension Prayer {
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
