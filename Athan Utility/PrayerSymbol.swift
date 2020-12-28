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
        switch prayerType {
        case .fajr:
            Image(systemName: "light.max")
        case .sunrise:
            Image(systemName: "sunrise")
        case .dhuhr:
            Image(systemName: "sun.max")
        case .asr:
            Image(systemName: "sun.min")
        case .maghrib:
            Image(systemName: "sunset")
        case .isha:
            Image(systemName: "moon.stars")
        }
    }
}

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
