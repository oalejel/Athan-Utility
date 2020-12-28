//
//  CalculationMethod+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan

extension CalculationMethod {
    // exclude "other"
    static func usefulCases() -> [CalculationMethod] {
        var methods = CalculationMethod.allCases
        methods.removeAll { $0 == .other }
        return methods
    }
    
    func stringValue() -> String {
        switch self {
        case .muslimWorldLeague:
            return "Muslim World League"
        case .egyptian:
            return "Egyptian"
        case .karachi:
            return "Karachi"
        case .ummAlQura:
            return "Umm Al-Qura"
        case .dubai:
            return "Dubai"
        case .moonsightingCommittee:
            return "Moonsighting Committee"
        case .northAmerica:
            return "North America"
        case .kuwait:
            return "Kuwait"
        case .qatar:
            return "Qatar"
        case .singapore:
            return "Singapore"
        case .tehran:
            return "Tehran"
        case .turkey:
            return "Turkey"
        case .other:
            return "Other"
        }
    }
    
    init(index: Int) {
        let cases = Array(CalculationMethod.allCases)
        if index >= cases.count {
            fatalError("index for initializing calculation method out of bounds")
        }
        self = cases[index]
    }
}
