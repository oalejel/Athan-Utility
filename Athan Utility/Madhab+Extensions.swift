//
//  Madhab+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan
import Foundation

extension Madhab {
    func stringValue() -> String {
        switch self {
        case .hanafi:
            return NSLocalizedString("Hanafi", comment: "")
        case .shafi:
            return NSLocalizedString("Shafi", comment: "")
        }
    }
}
