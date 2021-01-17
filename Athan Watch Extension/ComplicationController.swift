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
    
//    let manager = AthanManager.shared
    
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
        
        handler(AthanManager.shared.tomorrowTimes.isha)
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
        var sortedStoredTimes = Prayer.allCases.map { AthanManager.shared.todayTimes.time(for: $0) }
        sortedStoredTimes += Prayer.allCases.map { AthanManager.shared.tomorrowTimes.time(for: $0) }
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
        print(">>> COMPLICATION MANAGER USING LOCATION: \(AthanManager.shared.locationSettings.locationName)")
        var sortedStoredTimes = Prayer.allCases.map { AthanManager.shared.todayTimes.time(for: $0) }
        sortedStoredTimes += Prayer.allCases.map { AthanManager.shared.tomorrowTimes.time(for: $0) }
        guard let firstGreaterTimeIndex = sortedStoredTimes.firstIndex(where: { (storedDate) -> Bool in
            date < storedDate // first date where queried time takes place before
        }) else {
            return nil
        }
        
        let nextPrayerDate = sortedStoredTimes[firstGreaterTimeIndex]
        let nextPrayer = Prayer.allCases[firstGreaterTimeIndex % 6] // % 6 makes index 6 (fajr) go back to 0
        
        switch complication.family {
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Corner")!))
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
                }
            )
            // round image of sf symbol for for current salah time
            // text format: "FAJR UNTIL 8:45 • 3h 32m left"
            let roundImage = UIImage(systemName: nextPrayer.sfSymbolName())!.withTintColor(.white).applyingSymbolConfiguration(.init(weight: .bold))!
            let imageProv = CLKFullColorImageProvider(fullColorImage: roundImage)
//            let circleView =
            let imageTemplate = CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProv)
            let dateProv = CLKTimeTextProvider(date: nextPrayerDate)
            let timeLeftProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
                                                           style: .naturalAbbreviated, units: [.hour, .minute])
            let firstTextBlock = CLKTextProvider(format: "\(nextPrayer.previous().localizedOrCustomString()) UNTIL %@ • %@ left", dateProv, timeLeftProv)
            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: cView, textProvider: firstTextBlock)
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
