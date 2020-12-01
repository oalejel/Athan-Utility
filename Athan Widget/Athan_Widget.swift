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

struct ActivityRingView: View {
    @State var lineWidth: CGFloat = 7
    var progress: CGFloat = 0.0
    @State var outlineColor: Color
    var colors: [Color] = [Color.white, Color.gray]
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(outlineColor, lineWidth: lineWidth * 1.1)
            //                .blur(radius: 1)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                ).rotationEffect(.degrees(-90))
            //                .opacity(0)
            //            Circle()
            ////                .frame(width: lineWidth, height: lineWidth)
            //                .foregroundColor(.red)
            //                .offset(y: (lineWidth / 20) * 0)
            Circle()
                .trim(from: 0, to: 0.001) // just fills circle
                .stroke(colors.first!, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            
            //            Circle()
            //                .frame(width: lineWidth, height: lineWidth)
            //                .foregroundColor(progress > 0.95 ? colors[1] : colors[1].opacity(0))
            //                .offset(y: (lineWidth / 20) * -150)
            //                .rotationEffect(Angle.degrees(360 * Double(progress)))
            //                .shadow(color: progress > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: (lineWidth / 20) * 3, x: (lineWidth / 20) * 4, y: 0)
        }
    }
}

struct SmallWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Spacer()
                    ActivityRingView(
                        lineWidth: 10,
                        progress: CGFloat(Date().timeIntervalSince(entry.currentPrayerDate) / entry.nextPrayerDate.timeIntervalSince(entry.currentPrayerDate)),
                        outlineColor: .init(white: 1, opacity: 0.2),
                        colors: [.white, .init(white: 1, opacity: 0.5)]
                    )
                    .scaledToFit()
                    
                   
                }
                
                PrayerSymbol(prayerType: entry.currentPrayer)
                    .opacity(0.9)
                    .foregroundColor(.white)
                
                Text(entry.currentPrayer.localizedString())
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
                //                Text("\(dateFormatter.string(from: entry.nextPrayerDate))")
                Text("\(entry.currentPrayer.next().localizedString()) at \(entry.nextPrayerDate, style: .time)")
                    //                Text("\(entry.nextPrayerDate, style: .relative) left")
                    .foregroundColor(.init(UIColor.lightText))
                    .font(.system(size: 12))
                    .bold()
                Text("\(Date(), style: .time)") // remove later
                    .font(.footnote)
            }
            .padding()
            
        }
    }
}

struct ProgressBar: View {
    var progress: CGFloat
    @State var lineWidth: CGFloat = 7
    @State var outlineColor: Color
    
    var colors: [Color] = [Color.white, Color.white]
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(outlineColor)
                .frame(height: lineWidth)
                .cornerRadius(lineWidth * 0.5)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(colors.first)
                        .frame(width: max(0.01, progress) * g.size.width, height: lineWidth)
                        .cornerRadius(lineWidth * 0.5)
                    // having these circles might confuse users
                    //                    HStack(alignment: .center, spacing: 0) {
                    //                        ForEach(0..<5) { index in
                    //                            Circle()
                    //                                .foregroundColor(outlineColor.opacity(0.9))
                    //                                .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                    ////                                .scaledToFit()
                    //                                .position(x: (lineWidth * 0.5) + g.size.width * CGFloat((index / 5)), y: g.size.height * 0.5)
                    //                        }
                    //                    }
                }
            }
            .padding(.zero)
            //            .border(Color.green)
            .frame(height: lineWidth)
            
        }//.frame(idealWidth: 300, idealHeight: 300, alignment: .center)
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
                HStack(alignment: .firstTextBaseline, spacing: nil) {
                    Text(entry.currentPrayer.localizedString())
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(entry.nextPrayerDate, style: .relative) left")
                        .foregroundColor(.init(UIColor.lightText))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(1)
//                        .fixedSize(horizontal: false, vertical: true)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                    //                    Text("left")
                    //                        .foregroundColor(.init(UIColor.lightText))
                    //                        .font(.subheadline)
                    //                        .fontWeight(.bold)
                    Spacer()
                    PrayerSymbol(prayerType: entry.currentPrayer)
                        .foregroundColor(.white)
                    
                    Text("\(Date(), style: .time)") // remove later
                        .font(.footnote)
                    
                }
                
                ProgressBar(progress: CGFloat(Date().timeIntervalSince(entry.currentPrayerDate) / entry.nextPrayerDate.timeIntervalSince(entry.currentPrayerDate)),
                            lineWidth: 6,
                            outlineColor: .init(white: 1, opacity: 0.2),
                            colors: [.white, .white])
                //                Spacer()
                //                    .frame(maxWidth: .infinity)
                
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(0..<3) { i in
                            Text(Prayer(index: i).localizedString())
                                .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                                .font(Font.system(size: 26))
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
                                .font(Font.system(size: 26))
                                .fontWeight(.bold)
                                .allowsTightening(true)
                                .minimumScaleFactor(0.5)
                            if (i < 2) {
                                Spacer()
                            }
                        }
                    }
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

//struct SmallPlaceholderWidget: View {
//    var body: some View {
//        ZStack {
//            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
//
//            VStack(alignment: .leading, spacing: 0) {
//                HStack(alignment: .center) {
//                    Spacer()
//                    ActivityRingView(
//                        lineWidth: 10,
//                        progress: 0.25,
//                        outlineColor: .init(white: 1, opacity: 0.2),
//                        colors: [.white, .init(white: 1, opacity: 0.5)]
//                    )
//                    .scaledToFit()
//                }
//
//                PrayerSymbol(prayerType: .dhuhr)
//                    .opacity(0.9)
//                    .foregroundColor(Color.white)
//
//                Text("Athan")
//                    .foregroundColor(.white)
//                    .font(.title)
//                    .fontWeight(.bold)
//                //                Text("\(dateFormatter.string(from: entry.nextPrayerDate))")
//                Text("time")
//                    //                Text("\(entry.nextPrayerDate, style: .relative) left")
//                    .foregroundColor(.init(UIColor.lightText))
//                    .font(.system(size: 12))
//                    .bold()
//                    .redacted(reason: .placeholder)
//            }
//            .padding()
//
//        }
//    }
//}

//struct MediumPlaceholderWidget: View {
//    var body: some View {
//        ZStack {
//            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
//            VStack(alignment: .leading, spacing: 4) {
//                HStack(alignment: .firstTextBaseline, spacing: nil) {
//                    Text("Athan")
//                        .foregroundColor(.white)
//                        .font(.title)
//                        .fontWeight(.bold)
////                        .redacted(reason: .placeholder)
//                    Text("time left")
//                        .foregroundColor(.init(UIColor.lightText))
//                        .font(.subheadline)
//                        .fontWeight(.bold)
//                        .redacted(reason: .placeholder)
//                    //                    Text("left")
//                    //                        .foregroundColor(.init(UIColor.lightText))
//                    //                        .font(.subheadline)
//                    //                        .fontWeight(.bold)
//                    Spacer()
//                    PrayerSymbol(prayerType: .dhuhr)
//                        .foregroundColor(.white)
//                }
//
//                ProgressBar(progress: 0.25,
//                            lineWidth: 6,
//                            outlineColor: .init(white: 1, opacity: 0.2),
//                            colors: [.white, .white])
//                //                Spacer()
//                //                    .frame(maxWidth: .infinity)
//
//                HStack {
//                    VStack(alignment: .leading) {
//                        ForEach(0..<3) { i in
//                            Text("Salah")
//                                .foregroundColor(.white)
//                                .font(.caption)
//                                .fontWeight(.bold)
//                                .redacted(reason: .placeholder)
//                            if (i < 2) {
//                                Spacer()
//                            }
//                        }
//                    }
//                    Spacer()
//                    VStack(alignment: .trailing) {
//                        ForEach(0..<3) { i in
//                            Text("00:00")
//                                .foregroundColor(.white)
//                                .font(.caption)
//                                .fontWeight(.bold)
//                            if (i < 2) {
//                                Spacer()
//                            }
//                        }
//                    }
//                    Spacer()
//                    VStack(alignment: .leading) {
//                        ForEach(3..<6) { i in
//                            Text("Salah")
//                                .foregroundColor(.white)
//                                .font(.caption)
//                                .fontWeight(.bold)
//                                .redacted(reason: .placeholder)
//
//                            if (i < 5) {
//                                Spacer()
//                            }
//                        }
//                    }
//                    Spacer()
//                    VStack(alignment: .leading) {
//                        ForEach(3..<6) { i in
//                            Text("00:00")
//                                .foregroundColor(.white)
//                                .font(.caption)
//                                .fontWeight(.bold)
//                            if (i < 5) {
//                                Spacer()
//                            }
//                        }
//                    }
//                }.padding(.top, 10)
//
//            }
//            .padding()
//        }
//    }
//}

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
                                   ])
            
            Athan_WidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .flipsForRightToLeftLayoutDirection(true)
            //            .environment(\.layoutDirection, .rightToLeft)
            //            .environment(\.locale, Locale(identifier: "ar"))
        }
        
        let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        //        nextDate = Calendar.current.date(byAdding: .minute, value: 13, to: nextDate)!
        let entry = AthanEntry(date: Date(),
                               currentPrayer: .asr,
                               currentPrayerDate: Date(),
                               nextPrayerDate: nextDate,
                               todayPrayerTimes: [
                                nextDate, nextDate, nextDate,
                                nextDate, nextDate, nextDate
                               ])
        
        
        Athan_WidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        //        Athan_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
        //            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
