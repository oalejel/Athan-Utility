//
//  AthanWidgetEntry.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/23/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import SwiftUI
import WidgetKit
import Intents
import Adhan

struct AthanEntry: TimelineEntry {
    let date: Date // just represents time to update the timeline. != always equal start of prayer
    var currentPrayer: Prayer
    var currentPrayerDate: Date
    var nextPrayerDate: Date // will refer to Fajr of next day if prayerType is isha
    var todayPrayerTimes: [Date]

    var tellUserToOpenApp = false
    var relevance: TimelineEntryRelevance?
    var gradient: Gradient
}

enum EntryRelevance: Float {
    case Medium = 1
    case High = 2
}

