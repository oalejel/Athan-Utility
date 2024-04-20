//
//  Athan_Widget.swift
//  Athan Widget
//
//  Created by Omar Al-Ejel on 9/21/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import Adhan

struct SmallWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                
                Spacer()
                HStack(spacing: 0) {
                    Text(entry.nextPrayerDate, style: .relative)
                        .foregroundColor(.init(UIColor.lightText))
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.trailing)
                    
                    if Strings.left != "" {
                        Text(" \(Strings.left)")
                            .foregroundColor(.init(UIColor.lightText))
                            .fontWeight(.bold)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer()
            
            PrayerSymbol(prayerType: entry.currentPrayer)
                .foregroundColor(.white)
                .font(.headline)
            HStack {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.01)
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                Text(entry.currentPrayer.next().localizedOrCustomString())
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                
                Text(" ")
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                
                Text(entry.nextPrayerDate, style: .time)
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
        }
        //        .padding()
        
    }
}

struct MediumWidget: View {
    var entry: AthanEntry
    @State var progress: CGFloat = 0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: nil) {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: true, vertical: true)
                Text("\(entry.nextPrayerDate, style: .relative) \(Strings.left)")
                    .foregroundColor(.init(UIColor.lightText))
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                Spacer()
                
                PrayerSymbol(prayerType: entry.currentPrayer)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    ForEach(0..<3) { i in
                        Text(Prayer(index: i).localizedOrCustomString())
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 24))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        if i < 2 {
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    ForEach(0..<3) { i in
                        Text(entry.todayPrayerTimes[i], style: .time)
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 24))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        if (i < 2) {
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                Rectangle()
                    .frame(width: 1)
                    .opacity(0.5)
                    .foregroundColor(Color(.lightText))
                
                Spacer()
                
                VStack(alignment: .leading) {
                    ForEach(3..<6) { i in
                        Text(Prayer(index: i).localizedOrCustomString())
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 26))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        
                        if (i < 5) {
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    ForEach(3..<6) { i in
                        Text(entry.todayPrayerTimes[i], style: .time)
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 26))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        if (i < 5) {
                            Spacer()
                        }
                    }
                }
            }.padding(.top, 10)
            
        }
        
    }
}


struct SmallErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Image(systemName: "sun.max")
                .foregroundColor(.white)
            Text(Strings.widgetOpenApp)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.bold)
            
        }
        .padding()
        
    }
}

struct MediumErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: "sun.max")
                        .foregroundColor(.white)
                    Text(Strings.widgetOpenApp)
                        .foregroundColor(.white)
                        .font(.body)
                        .fontWeight(.bold)
                }
                
                Spacer(minLength: 100)
            }
        }
        .padding()
        
    }
}

struct LargeWidget: View {
    var entry: AthanEntry
    var body: some View {
        EmptyView() // TODO: not supported yet
    }
}


struct AccessoryInlineErrorWidget: View {
    var body: some View {
        Text(Strings.widgetOpenApp)
    }
}

struct AccessoryInlineWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        Text(entry.currentPrayer.next().localizedOrCustomString())
        + Text(" at ")
        + Text(entry.nextPrayerDate, style: .time)
    }
}

struct AccessoryRectangularWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .padding(.trailing, 2)
                PrayerSymbol(prayerType: entry.currentPrayer)
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 0) {
                Text(entry.currentPrayer.next().localizedOrCustomString())
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                Text(" ")
                Text(entry.nextPrayerDate, style: .time)
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack(spacing: 0) {
                Text(entry.nextPrayerDate, style: .relative)
                    .foregroundColor(.init(UIColor.lightText))
                    .bold()
                + Text(" \(Strings.left)")
                    .foregroundColor(.init(UIColor.lightText))
                    .bold()
                Spacer()
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

struct AccessoryCircularErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "sun.max")
                .foregroundColor(.white)
                .font(.title)
        }
    }
}

struct AccessoryCircularWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        VStack(alignment: .center) {
            Text(entry.currentPrayer.next().localizedOrCustomString())
                .foregroundColor(.white)
                .font(.caption)
                .fontWeight(.bold)
            Text(entry.nextPrayerDate, style: .time)
                .foregroundColor(.white)
                .font(.caption)
        }
    }
}

struct Athan_WidgetEntryView : View {
    var entry: AthanEntry
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    @ViewBuilder
    var body: some View {
        // none means that we have a placeholder
        // nil means error
        switch (family, entry.tellUserToOpenApp || AthanManager.shared.locationSettings.locationName.isEmpty) {
            
            // supported cases with available data
        case (.systemSmall, false):
            SmallWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemMedium, false):
            MediumWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemLarge, false): // ignored since not in supported list
            LargeWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.accessoryRectangular, false):
            AccessoryRectangularWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryInline, false):
            AccessoryInlineWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryCircular, false):
            AccessoryCircularWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
            
            
            // error cases (no athan data)
        case (.systemSmall, true):
            SmallErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemMedium, true):
            MediumErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemLarge, true): // ignored since not in supported list
            LargeWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.accessoryRectangular, true):
            AccessoryRectangularErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryInline, true):
            AccessoryInlineErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryCircular, true):
            AccessoryCircularErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
            
            
            // Error version of other currently unsupported widgets...
        case (.systemExtraLarge, _):
            MediumErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        @unknown default:
            SmallErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        }
    }
}

// Support iOS 17+ container backgrounds.
// Some widgets don't have background or need padding.
extension View {
    @ViewBuilder
    func applyContainerBackground(entry: AthanEntry, useGradientBackground: Bool, usePadding: Bool) -> some View {
        if #available(iOS 17, *) {
            self
                .padding(.all, usePadding ? nil : 0)
                .containerBackground(for: .widget) {
                    if useGradientBackground {
                        LinearGradient(gradient: entry.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .ignoresSafeArea()
                        
                    }
                }
                .contentMargins(0)
                .ignoresSafeArea()
        } else {
            ZStack {
                if useGradientBackground {
                    LinearGradient(gradient: entry.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                self
                    .padding(.all, usePadding ? nil : 0)
            }
        }
    }
}

@main
struct Athan_Widget: Widget {
    let kind: String = "Athan_Widget"
    
    var body: some WidgetConfiguration {
        
        if #available(iOSApplicationExtension 16.0, *) {
            return IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: AthanProvider()) { entry in
                Athan_WidgetEntryView(entry: entry)
                
            }
            .contentMarginsDisabled()
            .configurationDisplayName("Athan Widget")
            // lets not support the .systemLarge family for now...
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])//, .systemLarge])
            .description(Strings.widgetUsefulDescription)
            
        } else {
            // Fallback on earlier versions
            return IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: AthanProvider()) { entry in
                Athan_WidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Athan Widget")
            // lets not support the large widget family for now...
            .supportedFamilies([.systemSmall, .systemMedium])//, .systemLarge])
            .description(Strings.widgetUsefulDescription)
        }
    }
}

struct Athan_Widget_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<2) { i in
            
            let nextDate = Calendar.current.date(byAdding: .minute, value: 130, to: Date())!
            let entry = AthanEntry(date: Date(),
                                   currentPrayer: Prayer(index: i),
                                   currentPrayerDate: Date(),
                                   nextPrayerDate: nextDate,
                                   todayPrayerTimes: [
                                    nextDate, nextDate, nextDate,
                                    nextDate, nextDate, nextDate
                                   ],
                                   gradient: Gradient(colors: [.black, .blue]))
            // comment this line to test error widgets
            let _: Int = {
                AthanManager.shared.locationSettings.locationName = "San Francisco"
                return 0
            }()
            
            if #available(iOSApplicationExtension 16.0, *) {
                Athan_WidgetEntryView(entry: entry)
                    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        
        let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let entry = AthanEntry(date: Date(),
                               currentPrayer: .sunrise,
                               currentPrayerDate: Date(),
                               nextPrayerDate: nextDate,
                               todayPrayerTimes: [
                                nextDate, nextDate, nextDate,
                                nextDate, nextDate, nextDate
                               ],
                               gradient: Gradient(colors: [.black, .blue]))
        
        Athan_WidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
