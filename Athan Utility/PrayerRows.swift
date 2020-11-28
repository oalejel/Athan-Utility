//
//  PrayerRowContent.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/27/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct PrayerRowContent: Identifiable {
    var id = UUID()
    
    enum Highlight {
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
    
    var date: Date
    var prayer: Prayer
    var highlight: Highlight
}
