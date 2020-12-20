//
//  Madhab+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan

extension Madhab {
    func stringValue() -> String {
        switch self {
        case .hanafi:
            return "Hanafi"
        case .shafi:
            return "Shafi"
        }
    }
}
