//
//  WatchColors.swift
//  Athan Watch Extension
//
//  Per-prayer gradient colors, shared by the watch app and its complication widget.
//

import SwiftUI
import Adhan

func watchColorsForPrayer(_ p: Prayer) -> [Color] {
    switch p {
    case .fajr:
        return [.init(red: 208/255, green: 226/255 , blue: 1), .init(red: 0/255, green: 83/255 , blue: 233/255)]
    case .sunrise:
        return [.init(red: 229/255, green: 255/255, blue: 229/255), .init(red: 0/255, green: 136/255 , blue: 211/255)]
    case .dhuhr:
        return [.init(red: 216/255, green: 254/255, blue: 1), .init(red: 24/255, green: 109/255 , blue: 203/255)]
    case .asr:
        return [.init(red: 205/255, green: 238/255, blue: 255/255), .init(red: 0/255, green: 143/255 , blue: 205/255)]
    case .maghrib:
        return [.init(red: 254/255, green: 240/255, blue: 240/255), .init(red: 255/255, green: 97/255 , blue: 55/255)]
    case .isha:
        return [.init(red: 246/255, green: 237/255, blue: 255/255), .init(red: 77/255, green: 70/255 , blue: 255/255)]
    //            return [Color.white, .purple, .purple]
    }
}
