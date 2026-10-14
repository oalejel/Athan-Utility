//
//  CalculationMethod+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan
import Foundation

extension CalculationMethod {
    // exclude "other"
    static func usefulCases() -> [CalculationMethod] {
        var methods = CalculationMethod.allCases
        methods.removeAll { $0 == .other }
        return methods
    }
    
    func localizedString() -> String {
        switch self {
        case .muslimWorldLeague:
            return NSLocalizedString("Muslim World League", comment: "")
        case .egyptian:
            return NSLocalizedString("Egyptian", comment: "")
        case .karachi:
            return NSLocalizedString("Karachi", comment: "")
        case .ummAlQura:
            return NSLocalizedString("Umm Al-Qura", comment: "")
        case .dubai:
            return NSLocalizedString("Dubai", comment: "")
        case .moonsightingCommittee:
            return NSLocalizedString("Moonsighting Committee", comment: "")
        case .northAmerica:
            return NSLocalizedString("North America", comment: "")
        case .kuwait:
            return NSLocalizedString("Kuwait", comment: "")
        case .qatar:
            return NSLocalizedString("Qatar", comment: "")
        case .singapore:
            return NSLocalizedString("Singapore", comment: "")
        case .tehran:
            return NSLocalizedString("Tehran", comment: "")
        case .turkey:
            return NSLocalizedString("Turkey", comment: "")
        case .other:
            return NSLocalizedString("Other", comment: "")
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

extension PrayerMethod {
    func localizedString() -> String {
        switch self {
        case .standard(let method):
            return method.localizedString()
        case .jordan:
            return NSLocalizedString("method_jordan", value: "Jordan (Ministry of Awqaf)", comment: "Calculation method name")
        case .edmonton:
            return NSLocalizedString("method_edmonton", value: "Edmonton (Al Rashid Mosque)", comment: "Calculation method name")
        }
    }
}
