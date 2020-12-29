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
        ZStack {
            LinearGradient(gradient: entry.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    
                    Spacer()
                    Text("\(entry.nextPrayerDate, style: .relative) left")
                        .foregroundColor(.init(UIColor.lightText))
    //                    .font(.subheadline)
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        
//                        .minimumScaleFactor(0.01)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                    


                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                Spacer()


                PrayerSymbol(prayerType: entry.currentPrayer)
                    .foregroundColor(.white)
//                    .opacity(0.8)
                    .font(.headline)
//                    .padding([.bottom], 4)
                HStack {
                    Text(entry.currentPrayer.localizedString())
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(1)
//                        .fixedSize(horizontal: false, vertical: true)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.01)

                    Spacer()
                }

                
                Text("\(entry.currentPrayer.next().localizedString()) at \(entry.nextPrayerDate, style: .time)")
                    //                Text("\(entry.nextPrayerDate, style: .relative) left")
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
        }
    }
}
          

struct MediumWidget: View {
    var entry: AthanEntry
    @State var progress: CGFloat = 0.5
    var tempNames = ["Fajr", "Shurooq", "Thuhr", "Asr", "Maghrib", "Isha"]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: nil) {
                    Text(entry.currentPrayer.localizedString())
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(entry.nextPrayerDate, style: .relative) \(NSLocalizedString("left", comment: ""))")
                        .foregroundColor(.init(UIColor.lightText))
                        .font(.system(size: 14))
                        .fontWeight(.bold)
//                        .lineLimit(1)
//                        .allowsTightening(true)
//                        .minimumScaleFactor(0.01)
                    Spacer()
                    
                    PrayerSymbol(prayerType: entry.currentPrayer)
                        .foregroundColor(.white)
    //                    .opacity(0.8)
                        .font(.headline)
//                        .padding([.bottom], 4)

//                    Text("\(Date(), style: .time)") // remove later
//                        .font(.footnote)
                }

                HStack {
                    VStack(alignment: .leading) {
                        ForEach(0..<3) { i in
                            Text(Prayer(index: i).localizedString())
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
                            Text(Prayer(index: i).localizedString())
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
            .padding()
        }
    }
}


struct SmallErrorWidget: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Image(systemName: "sun.max")
                    .foregroundColor(.white)
                Text("Open Athan Utility to load times.")
                    .foregroundColor(.white)
                    .font(.body)
                    .fontWeight(.bold)

            }
            .padding()
        }
    }
}

struct MediumErrorWidget: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                HStack {
                    VStack(alignment: .leading) {
                        Image(systemName: "sun.max")
                            .foregroundColor(.white)
                        Text("Open Athan Utility to load athan times.")
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
}

struct LargeWidget: View {
    var entry: AthanEntry
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
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
        switch (family, entry.tellUserToOpenApp) {

        case (.systemSmall, true):
            SmallErrorWidget()
        case (.systemMedium, true):
            MediumErrorWidget()
        case (.systemLarge, true): // ignored since not in supported list
            LargeWidget(entry: entry)

//        case (.systemSmall, .some(Prayer.none)):
//            SmallPlaceholderWidget()
//        case (.systemMedium, .some(Prayer.none)):
//            MediumPlaceholderWidget()

        case (.systemSmall, false):
            SmallWidget(entry: entry)
        case (.systemMedium, false):
            MediumWidget(entry: entry)
        case (.systemLarge, false): // ignored since not in supported list
            LargeWidget(entry: entry)

        @unknown default:
            SmallErrorWidget()
        }
    }
}

@main
struct Athan_Widget: Widget {
    let kind: String = "Athan_Widget"

    var body: some WidgetConfiguration {

        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: AthanProvider()) { entry in
            Athan_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Athan Widget")
        // lets not support the large widget family for now...
        .supportedFamilies([.systemSmall, .systemMedium])//, .systemLarge])
        .description("Use Athan Widgets to view upcoming salah times at a glance.")
    }
}

struct Athan_Widget_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<2) { i in
            let nextDate = Calendar.current.date(byAdding: .minute, value: 130, to: Date())!
            //        nextDate = Calendar.current.date(byAdding: .minute, value: 13, to: nextDate)!
            let entry = AthanEntry(date: Date(),
                                   currentPrayer: Prayer(index: i),
                                   currentPrayerDate: Date(),
                                   nextPrayerDate: nextDate,
                                   todayPrayerTimes: [
                                    nextDate, nextDate, nextDate,
                                    nextDate, nextDate, nextDate
                                   ],
                                   gradient: Gradient(colors: [.black, .blue]))

            Athan_WidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .flipsForRightToLeftLayoutDirection(true)
            //            .environment(\.layoutDirection, .rightToLeft)
            //            .environment(\.locale, Locale(identifier: "ar"))
        }

        let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        //        nextDate = Calendar.current.date(byAdding: .minute, value: 13, to: nextDate)!
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

        //        Athan_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
        //            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
