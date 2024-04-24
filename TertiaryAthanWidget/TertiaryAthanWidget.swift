//
//  TertiaryAthanWidget.swift
//  TertiaryAthanWidget
//
//  Created by Omar Al-Ejel on 4/23/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import WidgetKit
import SwiftUI
import Adhan

struct TertiaryAthanWidgetEntryView : View {
    var entry: AthanEntry
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var body: some View {
        switch (family, entry.tellUserToOpenApp || AthanManager.shared.locationSettings.locationName.isEmpty) {
        case (.accessoryRectangular, false):
            HalfAccessoryRectangularWidget(entry: entry, isLeftHandside: false)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryRectangular, true):
            AccessoryRectangularErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        default:
            Text(Strings.widgetOpenApp)
        }
    }
}

struct TertiaryAthanWidget: Widget {
    let kind: String = "TertiaryAthanWidget"
    
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: kind, provider: AthanProvider()) { entry in
                TertiaryAthanWidgetEntryView(entry: entry)
            }
            .contentMarginsDisabled()
            .configurationDisplayName("All Times (Right)")
            // lets not support the .systemLarge family for now...
            .supportedFamilies([.accessoryRectangular])
            .description(Strings.widgetUsefulDescription)
            
        } else {
            // Fallback on earlier versions
            return StaticConfiguration(kind: kind, provider: AthanProvider()) { entry in
                TertiaryAthanWidgetEntryView(entry: entry)
                
            }
            .configurationDisplayName("All Times (Right)")
            // lets not support the large widget family for now...
            .supportedFamilies([.systemSmall, .systemMedium])//, .systemLarge])
            .description(Strings.widgetUsefulDescription)
        }
    }
}



#Preview(as: .accessoryRectangular) {
    TertiaryAthanWidget()
} timeline: {
    AthanEntry(date: Date(),
                           currentPrayer: .sunrise,
                           currentPrayerDate: Date(),
                           nextPrayerDate: Date(),
                           todayPrayerTimes: [
                            Date(), Date(), Date(),
                            Date(), Date(), Date()
                           ],
                           gradient: Gradient(colors: [.black, .blue]))
}
