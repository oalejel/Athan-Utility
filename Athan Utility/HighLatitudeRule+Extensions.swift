//
//  HighLatitudeRule+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/16/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import Adhan
import Foundation
import CoreLocation.CLLocation

extension HighLatitudeRule {    
    public func localizedString() -> String {
        switch self {
        case .middleOfTheNight:
            return NSLocalizedString("middleOfTheNight", comment: "")
        case .seventhOfTheNight:
            return NSLocalizedString("seventhOfTheNight", comment: "")
        case .twilightAngle:
            return NSLocalizedString("twilightAngle", comment: "")
        }
    }
    
    public static func recommended(for coordinate: CLLocationCoordinate2D) -> HighLatitudeRule {
        HighLatitudeRule.recommended(for: Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}
