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

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}


struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

extension Color {
    public static var outlineRed: Color {
        return Color(decimalRed: 34, green: 0, blue: 3)
    }
    
    public static var darkRed: Color {
        return Color(decimalRed: 221, green: 31, blue: 59)
    }
    
    public static var lightRed: Color {
        return Color(decimalRed: 239, green: 54, blue: 128)
    }
    
    public init(decimalRed red: Double, green: Double, blue: Double) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255)
    }
}


struct ActivityRingView: View {
    @Binding var progress: CGFloat
    @State var lineWidth: CGFloat = 7
    @State var outlineColor: Color
    
    var colors: [Color] = [Color.darkRed, Color.lightRed]
    
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
                .foregroundColor(Color.darkRed)
                .offset(y: (lineWidth / 20) * -150)
            Circle()
                .frame(width: lineWidth, height: lineWidth)
                .foregroundColor(progress > 0.95 ? Color.lightRed: Color.lightRed.opacity(0))
                .offset(y: (lineWidth / 20) * -150)
                .rotationEffect(Angle.degrees(360 * Double(progress)))
                .shadow(color: progress > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: (lineWidth / 20) * 3, x: (lineWidth / 20) * 4, y: 0)
        }//.frame(idealWidth: 300, idealHeight: 300, alignment: .center)
    }
}

struct SmallWidget: View {
    var entry: Provider.Entry
    @State var progress: CGFloat = 0.4
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Spacer()
                    ActivityRingView(progress: $progress,
                                     lineWidth: 10,
                                     outlineColor: .init(white: 1, opacity: 0.2),
                                     colors: [.white, .white])
//                        .border(Color.orange)
                        .scaledToFit()
                }
                
//                Spacer()
//                    .frame(maxWidth: .infinity)
                Image("sunhorizon")
                    .resizable()
                    .frame(width: 30, height: 30)
//                    .scaledToFit()
                    .offset(x: 0, y: 4)
//                    .border(Color.gray)
                    .padding(.zero)
                Text("Maghrib")
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
//                    .border(Color.red)
                Text("1h 5m left")
                    .foregroundColor(.init(UIColor.lightText))
                    .font(.system(size: 14))
//                    .border(Color.green)
                
            }
            .padding()
            
        }
    }
}

struct ProgressBar: View {
    @Binding var progress: CGFloat
    @State var lineWidth: CGFloat = 7
    @State var outlineColor: Color {
        mutating didSet {
            dotColor = outlineColor.opacity(0.9)
        }
    }
    
    var dotColor = Color.gray
    
    var colors: [Color] = [Color.darkRed, Color.lightRed]
    
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
            
//            Circle()
//                .stroke(outlineColor, lineWidth: lineWidth)
//            Circle()
//                .trim(from: 0, to: progress)
//                .stroke(
//                    AngularGradient(
//                        gradient: Gradient(colors: colors),
//                        center: .center,
//                        startAngle: .degrees(0),
//                        endAngle: .degrees(360)
//                    ),
//                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
//                ).rotationEffect(.degrees(-90))
//            Circle()
//                .frame(width: lineWidth, height: lineWidth)
//                .foregroundColor(Color.darkRed)
//                .offset(y: (lineWidth / 20) * -150)
//            Circle()
//                .frame(width: lineWidth, height: lineWidth)
//                .foregroundColor(progress > 0.95 ? Color.lightRed: Color.lightRed.opacity(0))
//                .offset(y: (lineWidth / 20) * -150)
//                .rotationEffect(Angle.degrees(360 * Double(progress)))
//                .shadow(color: progress > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: (lineWidth / 20) * 3, x: (lineWidth / 20) * 4, y: 0)
        }//.frame(idealWidth: 300, idealHeight: 300, alignment: .center)
    }
}



/*
 HStack(alignment: .top) {
     
     
     ForEach(0..<tempNames.count) { i in
         Spacer()
         VStack {
             Text(tempNames[i])
                 .font(.caption)
                 .foregroundColor(.white)
             Spacer()
             Text("11:00 PM")
                 .font(.caption2)
                 .foregroundColor(.init(UIColor.lightText))
                 .fixedSize()
                 
         }
         if i < 5 {
             Divider()
                 .background(Color.white)
         }
//                        Divider()
//                            .background(Color.white)
//                            .frame(maxWidth: .infinity)
//                            .foregroundColor(.white)
     }
     Spacer()
 }
 */

struct MediumWidget: View {
    var entry: Provider.Entry
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
                }
                
                ProgressBar(progress: $progress,
                            lineWidth: 6,
                            outlineColor: .init(white: 1, opacity: 0.2),
                            colors: [.white, .white])
                Spacer()
                    .frame(maxWidth: .infinity)
                
                HStack(alignment: .center) {
                    ForEach (0..<6) { i in
                        Spacer()
                        VStack {
                            Text(tempNames[i])
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("11:00 pm")
                                .font(.caption2)
                                .foregroundColor(.init(UIColor.lightText))
                        }
                        if i < 5 {
                            Divider()
                                .background(Color.white)
                        }
//                        Divider()
//                            .background(Color.white)
//                            .frame(maxWidth: .infinity)

//                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)

            }
            .padding()
            
        }
    }
}

struct LargeWidget: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct Athan_WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidget(entry: entry)
        case .systemMedium:
            MediumWidget(entry: entry)
        case .systemLarge:
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
        
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Athan_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct Athan_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Athan_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        Athan_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        Athan_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
