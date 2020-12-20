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
            Image(systemName: "sun.min")
        case .asr:
            Image(systemName: "sun.max")
        case .maghrib:
            Image(systemName: "sunset")
        case .isha:
            Image(systemName: "moon.stars")
        }
    }
}
