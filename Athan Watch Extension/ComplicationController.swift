//
//  ComplicationController.swift
//  Athan Watch Extension
//
//  Created by Omar Al-Ejel on 1/6/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import ClockKit
import SwiftUI
import Adhan

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let manager = AthanManager.shared
    
    //    override init() {
    //        print("COMPLICATION CONTROLLER INIT")
    //    }
    
    // MARK: - Complication Configuration
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            
            CLKComplicationDescriptor(identifier: "complication", displayName: "Athan Utility", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        
        handler(manager.tomorrowTimes.isha)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        if let template = getComplicationTemplate(for: complication, using: Date()) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        
        // first, ensure that we are able to produce the desired complication
        guard let _ = getComplicationTemplate(for: complication, using: Date()) else {
            handler(nil)
            return
        }
        
        // get all times we could possibly have entries for
        var sortedStoredTimes = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
        sortedStoredTimes += Prayer.allCases.map { manager.tomorrowTimes.time(for: $0) }
        // filter out times that are in the past, based on passed in `date`
        sortedStoredTimes = sortedStoredTimes.filter { date < $0 }
        // if going beyond limit, cut out latest times we cannot fit
        if limit < sortedStoredTimes.count {
            sortedStoredTimes.removeSubrange(limit..<sortedStoredTimes.endIndex)
        }
        
        // for each date, create a timeline entry
        var entries: [CLKComplicationTimelineEntry] = []
        for entryDate in sortedStoredTimes {
            if let template = getComplicationTemplate(for: complication, using: entryDate) {
                entries.append(CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template))
            } else {
                print("ERROR: should not have errors producing template for provided dates at this point.")
            }
        }
        handler(entries)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        if let template = getComplicationTemplate(for: complication, using: Date()) {
            handler(template)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Helpers
    
    func getComplicationTemplate(for complication: CLKComplication, using date: Date) -> CLKComplicationTemplate? {
        // check if queried date takes place after a time we have stored
        print(">>> COMPLICATION MANAGER USING LOCATION: \(manager.locationSettings.locationName)")
        var sortedStoredTimes = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
        sortedStoredTimes += Prayer.allCases.map { manager.tomorrowTimes.time(for: $0) }
        guard let firstGreaterTimeIndex = sortedStoredTimes.firstIndex(where: { (storedDate) -> Bool in
            date < storedDate // first date where queried time takes place before
        }) else {
            return nil
        }
        
        let nextPrayerDate = sortedStoredTimes[firstGreaterTimeIndex]
        let nextPrayer = Prayer.allCases[firstGreaterTimeIndex % 6] // % 6 makes index 6 (fajr) go back to 0
        
        switch complication.family {
        case .graphicCircular:
            let df = DateFormatter()
            df.dateFormat = "h:mm"
            if nextPrayer == .sunrise || nextPrayer == .maghrib { // use an image for sunrise or sunset
                let imageProv = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill")!)
                //                imageProv.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateGraphicCircularStackImage(line1ImageProvider: imageProv,
                                                                        line2TextProvider: CLKTextProvider(format: df.string(from: nextPrayerDate)))
            } else {
                let nameProvider = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString())
                //                nameProvider.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: nameProvider, line2TextProvider: CLKTextProvider(format: df.string(from: nextPrayerDate)))
            }
        case .circularSmall:
            let df = DateFormatter()
            df.dateFormat = "h:mm"
            if nextPrayer == .sunrise || nextPrayer == .maghrib { // use an image for sunrise or sunset
                let imageProv = CLKImageProvider(onePieceImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill")!)
                //                imageProv.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateCircularSmallStackImage(line1ImageProvider: imageProv,
                                                                      line2TextProvider: CLKTextProvider(format: df.string(from: nextPrayerDate)))
            } else {
                let nameProvider = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString())
                //                nameProvider.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: nameProvider, line2TextProvider: CLKTextProvider(format: df.string(from: nextPrayerDate)))
            }
        case .graphicBezel:
            let cView = CLKComplicationTemplateGraphicCircularView(
                ZStack {
                    let colors = AppearanceSettings.shared.colors(for: nextPrayer.previous())
                    LinearGradient(gradient: Gradient(colors: [colors.0, colors.1]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: nextPrayer.previous().sfSymbolName())
                        .font(Font.headline.bold())
                        .foregroundColor(Color(.sRGB, white: 1, opacity: 0.8))
                    //                        .offset(y: -2)
                    
                }
            )
            // round image of sf symbol for for current salah time
            // text format: "FAJR 8:45 • 3h 32m left"
            let dateProv = CLKTimeTextProvider(date: nextPrayerDate)
            let timeLeftProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
                                                           style: .naturalAbbreviated, units: [.hour, .minute])
            let firstTextBlock = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@ • %@ left", dateProv, timeLeftProv)
            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: cView, textProvider: firstTextBlock)
        case .graphicCorner:
            // Outer: Current prayer, Inner: "NEXTPRAYER at 4:30 PM"
            let df = DateFormatter()
            df.dateFormat = "h:mm"
            let nameProvider = CLKSimpleTextProvider(text: nextPrayer.previous().localizedOrCustomString())
            let dateProv = CLKTimeTextProvider(date: nextPrayerDate)
            let innerTextProvider = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) at %@", dateProv)
            innerTextProvider.tintColor = .orange
            let template = CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: innerTextProvider, outerTextProvider: nameProvider)
            return template
            
        case .utilitarianSmallFlat:
            // FAJR 4:55PM
            let textProv = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@",
                                           CLKTimeTextProvider(date: nextPrayerDate))
            
            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProv)
        case .utilitarianLarge:
            //            let timeLeftProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
            //                                                           style: .naturalAbbreviated, units: [.hour, .minute])
            //            let textProv = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@ • %@ left",
            //                                           CLKTimeTextProvider(date: nextPrayerDate),
            //                                           timeLeftProv)
            let dateProv = CLKTimeTextProvider(date: nextPrayerDate)
            let timeLeftProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
                                                           style: .naturalAbbreviated, units: [.hour, .minute])
            let firstTextBlock = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@ %@", dateProv, timeLeftProv)
            return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: firstTextBlock)
        case .modularSmall:
            let df = DateFormatter()
            df.dateFormat = "h:mm"
            if nextPrayer == .sunrise || nextPrayer == .maghrib { // use an image for sunrise or sunset
                let imageProv = CLKImageProvider(onePieceImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill")!)
                //                imageProv.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateModularSmallStackImage(line1ImageProvider: imageProv,
                                                                     line2TextProvider: CLKTextProvider(format: df.string(from: nextPrayerDate)))
            } else {
                let nameProvider = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString())
                //                nameProvider.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateModularSmallStackText(line1TextProvider: nameProvider, line2TextProvider: CLKTextProvider(format: df.string(from: nextPrayerDate)))
            }
        case .modularLarge:
            return nil
        case.graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularLargeView(headerTextProvider: CLKSimpleTextProvider(text: "Fajr"), content: LargeComplication2())
            
//            return CLKComplicationTemplateGraphicRectangularFullView(LargeComplication2())
//            return CLKComplicationTemplateGraphicRectangularFullView(LargeComplication(currentPrayer: nextPrayer.previous(), nextDate: nextPrayerDate, text2: "asdf", text3: "asdf"))
            
        //            let guageprov = CLKTimeIntervalGaugeProvider(style: .fill, gaugeColors: [.white], gaugeColorLocations: nil, start: , end: <#T##Date#>)
        //            CLKComplicationTemplateGraphicRectangularTextGauge(headerImageProvider: <#T##CLKFullColorImageProvider?#>, headerTextProvider: <#T##CLKTextProvider#>, body1TextProvider: <#T##CLKTextProvider#>, gaugeProvider: <#T##CLKGaugeProvider#>)
        default:
            return nil
        }
    }
    
    func tintColor(prayer: Prayer) -> UIColor {
        return .red
    }
}

//struct MV: CLKComplicationTemplateGraphicCircularView {
//    @Environment(\.complicationRenderingMode) var renderingMode
//
//    body
//}

struct LargeComplication: View {
    @Environment(\.complicationRenderingMode) var renderingMode
    @State var currentPrayer: Prayer
    @State var nextDate: Date
    @State var text2: String
    @State var text3: String
    
    var body: some View {
        GeometryReader { g in
            HStack {
                //                ZStack(alignment: .center) {
                //                    ProgressView("")
                //                        .labelsHidden()
                //                        .progressViewStyle(LinearProgressViewStyle())
                //                        .rotationEffect(.degrees(90), anchor: .center)
                //                        .complicationForeground()
                //                        .frame(width: g.size.height, height: 10, alignment: .leading)
                //                }
                //                .frame(width: 15, height: g.size.height, alignment: .leading)
                //                .offset(x: -15)
                
                //                RoundedRectangle(cornerRadius: 4)
                //                    .gradientForeground(colors: watchColorsForPrayer(.fajr))
                //                    .frame(width: 8)
                //                    .complicationForeground()

                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: currentPrayer.sfSymbolName())
                            .frame(width: 14)
                        Text(currentPrayer.localizedOrCustomString())
                            .bold()
                        Spacer()
                        Text(nextDate, style: .relative)
                            .bold()
                            .multilineTextAlignment(.trailing)
                    }
                    .foregroundColor(watchColorsForPrayer(currentPrayer).first!)
                    .complicationForeground()
                    
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: currentPrayer.next().sfSymbolName())
                            .frame(width: 14)
                        Text(currentPrayer.next().localizedOrCustomString())
                            .bold()
                        Spacer()
                        Text(text2)
                            .bold()
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: currentPrayer.next().next().sfSymbolName())
                            .frame(width: 14)
                        Text(currentPrayer.next().next().localizedOrCustomString())
                            .bold()
                        Spacer()
                        Text(text3)
                            .bold()
                    }
                }
            }
            
        }
        //        .border(Color.red)
    }
}

struct LargeComplication2: View {
    @Environment(\.complicationRenderingMode) var renderingMode
    
    var body: some View {
        HStack {
            
            ForEach(0..<4, id: \.self) { pIndex in
                let prayer = Prayer(index: pIndex)
                Divider()
                Spacer()
                
                VStack {
                    Text(String(prayer.localizedOrCustomString().first ?? " ".first!))
                        .font(Font.system(size: 10))
                        .fixedSize()
                    Spacer()
                    Image(systemName: prayer.sfSymbolName())
                        .font(Font.caption)
                        
                    Spacer()
                    Text("12:34")
                        .font(Font.footnote)
                        .fixedSize()
                }
                .foregroundColor(pIndex == 3 ? .orange : .white)
                .complicationForeground()
            }
            Spacer()
            Divider()
        }
        .padding([.leading, .trailing], 1)
    }
}

struct LargeComplication_Preview: PreviewProvider {
    static var previews: some View {
        CLKComplicationTemplateGraphicRectangularLargeView(headerTextProvider: CLKSimpleTextProvider(text: "Fajr"), content: LargeComplication2())
            .previewContext()
        
//        CLKComplicationTemplateGraphicRectangularFullView(LargeComplication(currentPrayer: .fajr, nextDate: Date().addingTimeInterval(100), text2: "2:12PM", text3: "5:20PM")).previewContext()
//        GraphicRectangularFullView(LargeComplication2()).previewContext()

        
//                CLKComplicationTemplateGraphicRectangularTextGaugeView(headerLabel: Text("test"), headerTextProvider: CLKSimpleTextProvider(text: "test"), bodyTextProvider: CLKSimpleTextProvider(text: "test"), gaugeProvider: CLKTimeIntervalGaugeProvider(style: .fill, gaugeColors: nil, gaugeColorLocations: nil, start: Date().addingTimeInterval(-1000), end: Date().addingTimeInterval(1000)))
//                    .previewContext(faceColor: .red)
//
//                CLKComplicationTemplateGraphicRectangularStandardBodyView(headerLabel: Rectangle().foregroundColor(.blue), headerTextProvider: CLKSimpleTextProvider(text: "test"), body1TextProvider: CLKSimpleTextProvider(text: "tet3")).previewContext()
//                CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeView(gaugeProvider: CLKTimeIntervalGaugeProvider(style: .fill, gaugeColors: nil, gaugeColorLocations: nil, start: Date().addingTimeInterval(-1000), end: Date().addingTimeInterval(1000)), centerTextProvider: CLKSimpleTextProvider(text: "test"), bottomLabel: nil)
//
    }
}
