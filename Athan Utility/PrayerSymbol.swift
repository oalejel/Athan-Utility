//
//  PrayerSymbol.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/27/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct PrayerSymbol: View {
    var prayerType: Prayer
    var body: some View {
        Image(systemName: prayerType.sfSymbolName())
    }
}

@available(iOS 13.0.0, *)
enum PrayerHighlightType {
    case past
    case present
    case future
    func color() -> Color {
        switch self {
        case .past: return Color(.lightText)
        case .present: return .green
        case .future: return .white
        }
    }
}
