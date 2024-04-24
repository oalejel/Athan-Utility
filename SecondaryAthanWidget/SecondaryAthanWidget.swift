//
//  SecondaryAthanWidget.swift
//  SecondaryAthanWidget
//
//  Created by Omar Al-Ejel on 4/23/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import WidgetKit
import SwiftUI
import Adhan

struct HalfAccessoryRectangularWidget: View {
    var entry: AthanEntry
    var isLeftHandside = true
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                ForEach(isLeftHandside ? 0..<3 : 3..<6) { i in
                    Text(Prayer(index: i).localizedOrCustomString())
                        .foregroundColor(i == entry.currentPrayer.rawValue() ? .white : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                        .font(Font.system(size: 24))
                        .fontWeight(.bold)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                }
            }
            
            Spacer(minLength: 1)
            
            VStack(alignment: .trailing) {
                ForEach(isLeftHandside ? 0..<3 : 3..<6) { i in
                    Text(entry.todayPrayerTimes[i], style: .time)
                        .foregroundColor(i == entry.currentPrayer.rawValue() ? .white : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                        .font(Font.system(size: 24))
                        .fontWeight(.bold)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                }
            }
        }
    }
}

struct AccessoryRectangularErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "sun.max")
                .foregroundColor(.white)
            Text(Strings.widgetOpenApp)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.bold)
        }
    }
}

struct SecondaryAthanWidgetEntryView : View {
    var entry: AthanEntry
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var body: some View {
        switch (family, entry.tellUserToOpenApp || AthanManager.shared.locationSettings.locationName.isEmpty) {
        case (.accessoryRectangular, false):
            HalfAccessoryRectangularWidget(entry: entry, isLeftHandside: true)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryRectangular, true):
            AccessoryRectangularErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        default:
            Text(Strings.widgetOpenApp)
        }
    }
}

struct SecondaryAthanWidget: Widget {
    let kind: String = "SecondaryAthanWidget"
    
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: kind, provider: AthanProvider()) { entry in
                SecondaryAthanWidgetEntryView(entry: entry)
            }
            .contentMarginsDisabled()
            .configurationDisplayName("All Times (Left)")
            // lets not support the .systemLarge family for now...
            .supportedFamilies([.accessoryRectangular])
            .description(Strings.widgetUsefulDescription)
            
        } else {
            // Fallback on earlier versions
            return StaticConfiguration(kind: kind, provider: AthanProvider()) { entry in
                SecondaryAthanWidgetEntryView(entry: entry)
                
            }
            .configurationDisplayName("All Times (Left)")
            // lets not support the large widget family for now...
            .supportedFamilies([.systemSmall, .systemMedium])//, .systemLarge])
            .description(Strings.widgetUsefulDescription)
        }
    }
}



#Preview(as: .accessoryRectangular) {
    SecondaryAthanWidget()
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
