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
            Circle()
                .frame(width: lineWidth, height: lineWidth)
                .foregroundColor(colors.first)
                .offset(y: (lineWidth / 20) * -150)
            Circle()
                .frame(width: lineWidth, height: lineWidth)
                .foregroundColor(progress > 0.95 ? colors[1] : colors[1].opacity(0))
                .offset(y: (lineWidth / 20) * -150)
                .rotationEffect(Angle.degrees(360 * Double(progress)))
                .shadow(color: progress > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: (lineWidth / 20) * 3, x: (lineWidth / 20) * 4, y: 0)
        }
    }
}

struct PrayerSymbol: View {
    var prayerType: PrayerType
    var body: some View {
        switch prayerType {
            case .fajr:
                Image(systemName: "light.max")
            case .shurooq:
                Image(systemName: "sunrise")
            case .thuhr:
                Image(systemName: "sun.min")
            case .asr:
                Image(systemName: "sun.max")
            case .maghrib:
                Image(systemName: "sunset")
            case .isha:
                Image(systemName: "moon.stars")
            default:
                Image(systemName: "sun.min")
        }
    }
}

struct SmallWidget: View {
    var entry: AthanEntry
//    @State var progress: CGFloat = 0.4
        
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
                        colors: [.white, .white]
                    )
                        .scaledToFit()
                }

                PrayerSymbol(prayerType: entry.currentPrayer)
                    .opacity(0.9)
                    .foregroundColor(.white)
//                HStack(alignment: .bottom) {
//                        .resizable()
//                        .frame(width: 30, height: 30)
//                        .offset(x: 0, y: 4)
//                        .opacity(0.9)
//                    Text("Bloomfield Hills")
//                        .foregroundColor(.init(.lightText))
//                        .font(.caption)
//                        .autocapitalization(.allCharacters)
//                        .truncationMode(.tail)
//                        .scaledToFit()
//                }
                
                Text(entry.currentPrayer.localizedString())
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
//                Text("\(dateFormatter.string(from: entry.nextPrayerDate))")
//                Text("\(entry.nextPrayerDate, formatter: relativeDF) left")
                Text("\(entry.nextPrayerDate, style: .relative) left")
                    .foregroundColor(.init(UIColor.lightText))
                    .font(.system(size: 14))
                    .bold()
                    .scaledToFit()
                
            }
            .padding()
            
        }
    }
}

struct ProgressBar: View {
    @Binding var progress: CGFloat
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
                        .frame(width: progress * g.size.width, height: lineWidth)
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
                HStack(alignment: .firstTextBaseline, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/) {
                    Text("Asr")
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("1h 10m left")
                        .foregroundColor(.init(UIColor.lightText))
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Image("sunhorizon")
                            .resizable()
                            .frame(width: 30, height: 30)
    //                        .border(Color.red)
        //                    .scaledToFit()
                            .offset(x: 0, y: 8)
        //                    .border(Color.gray)
    //                        .padding(.zero)
//                        Text("Barcelona")
//                            .foregroundColor(.init(.lightText))
//                            .font(.caption)
//                            .autocapitalization(.allCharacters)

                    }
                }
                
                ProgressBar(progress: $progress,
                            lineWidth: 6,
                            outlineColor: .init(white: 1, opacity: 0.2),
                            colors: [.white, .white])
                Spacer()
                    .frame(maxWidth: .infinity)
                
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(0..<3) { i in
                            Text(tempNames[i])
                                .foregroundColor(.init(UIColor.lightText))
                                .font(.caption)
                                .fontWeight(.bold)
                            if (i < 2) {
                                Spacer()
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        ForEach(0..<3) { i in
                            Text("11:30 PM")
                                .foregroundColor(.init(UIColor.lightText))
                                .font(.caption)
                                .fontWeight(.bold)
                            if (i < 2) {
                                Spacer()
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        ForEach(3..<6) { i in
                            Text(tempNames[i])
                                .foregroundColor(i == 3 ? .green : .white)
                                .font(.caption)
                                .fontWeight(.bold)
                            if (i < 5) {
                                Spacer()
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        ForEach(3..<6) { i in
                            Text("2:13 PM")
                                .foregroundColor(i == 3 ? .green : .white)
                                .font(.caption)
                                .fontWeight(.bold)
                            if (i < 5) {
                                Spacer()
                            }
                        }
                    }
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
        switch family {
        case .systemSmall:
            SmallWidget(entry: entry)
        case .systemMedium:
            MediumWidget(entry: entry)
        case .systemLarge:
            // this family is not in the supported list, so this wont be run
            LargeWidget(entry: entry)
        @unknown default:
            SmallWidget(entry: entry)
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
        .description("Use Athan Widgets to view upcoming salah times at a glance.")
        // lets not support the large widget family for now...
        .supportedFamilies([.systemSmall, .systemMedium])//, .systemLarge])
    }
}

struct Athan_Widget_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<6) { i in
            let nextDate = Calendar.current.date(byAdding: .minute, value: 130, to: Date())!
    //        nextDate = Calendar.current.date(byAdding: .minute, value: 13, to: nextDate)!
            let entry = AthanEntry(date: Date(),
                                   currentPrayer: PrayerType(rawValue: i)!, currentPrayerDate: Date(),
                                   nextPrayerDate: nextDate,
                                   todayPrayerTimes: [
                                    .fajr : Date(), .shurooq : Date(),
                                    .thuhr : Date(), .asr : Date(),
                                    .maghrib : Date(), .isha : Date()
                                   ])

            Athan_WidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .flipsForRightToLeftLayoutDirection(true)
    //            .environment(\.layoutDirection, .rightToLeft)
    //            .environment(\.locale, Locale(identifier: "ar"))

        }
        
        let nextDate = Calendar.current.date(byAdding: .minute, value: 130, to: Date())!
//        nextDate = Calendar.current.date(byAdding: .minute, value: 13, to: nextDate)!
        let entry = AthanEntry(date: Date(),
                               currentPrayer: .fajr, currentPrayerDate: Date(),
                               nextPrayerDate: nextDate,
                               todayPrayerTimes: [
                                .fajr : Date(), .shurooq : Date(),
                                .thuhr : Date(), .asr : Date(),
                                .maghrib : Date(), .isha : Date()
                               ])

        
        Athan_WidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
//        Athan_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
