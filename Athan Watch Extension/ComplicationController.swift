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
        
    // MARK: - Complication Configuration
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        var families = CLKComplicationFamily.allCases
        families.removeAll {$0 == .graphicExtraLarge} // drop graphicExtraLarge since extraLarge covers it
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication",
                                     displayName: "Athan Utility",
                                     supportedFamilies: families)
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
        if manager.locationSettings.locationName == LocationSettings.defaultSetting().locationName {
            handler(nil) // havent sent location
        } else {
            handler(manager.tomorrowTimes.maghrib) // maybe good to update data before penuultimate prayer -- no empirical evidence yet
        }
        
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        if manager.locationSettings.locationName == LocationSettings.defaultSetting().locationName {
            handler(nil) // case if we have not set our location
        } else if let template = getComplicationTemplate(for: complication, using: Date()) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil) // case where we cant produce a template
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
        var currentPrayerDate = Date() // set to time before nextPrayerTime
        if firstGreaterTimeIndex == 0 { // if zero, use today isha - 86400 seconds as estimate for current prayer start
            currentPrayerDate = manager.todayTimes.isha.addingTimeInterval(-86400)
        } else {
            currentPrayerDate = sortedStoredTimes[firstGreaterTimeIndex - 1]
        }
        let nextPrayerDate = sortedStoredTimes[firstGreaterTimeIndex]
        let nextPrayer = Prayer.allCases[firstGreaterTimeIndex % 6] // % 6 makes index 6 (fajr) go back to 0
        
        switch complication.family {
        case .graphicCircular:
            
            let timeProv = CLKTimeTextProvider(date: nextPrayerDate)
            let colors = watchColorsForPrayer(nextPrayer).map { UIColor($0) }
            timeProv.tintColor = blend(colors: colors)

            if nextPrayer == .sunrise || nextPrayer == .maghrib { // use an image for sunrise or sunset
                let imageProv = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 15), scale: UIImage.SymbolScale.small))!)
                return CLKComplicationTemplateGraphicCircularStackImage(line1ImageProvider: imageProv,
                                                                        line2TextProvider: timeProv)
            } else {
                let nameProvider = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString())
                return CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: nameProvider, line2TextProvider: timeProv)
            }
        case .circularSmall:
            let timeProv = CLKTimeTextProvider(date: nextPrayerDate)
            let colors = watchColorsForPrayer(nextPrayer).map { UIColor($0) }
            timeProv.tintColor = blend(colors: colors)

            if nextPrayer == .sunrise || nextPrayer == .maghrib { // use an image for sunrise or sunset
                let imageProv = CLKImageProvider(onePieceImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 15), scale: UIImage.SymbolScale.small))!)
                return CLKComplicationTemplateCircularSmallStackImage(line1ImageProvider: imageProv,
                                                                      line2TextProvider: timeProv)
            } else {
                let nameProvider = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString())
                //                nameProvider.tintColor = tintColor(prayer: nextPrayer)
                return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: nameProvider,
                                                                     line2TextProvider: timeProv)
            }
        case .graphicBezel:
            let cView = CLKComplicationTemplateGraphicCircularView(
                ZStack {
                    let colors = AppearanceSettings.shared.colors(for: nextPrayer.previous())
                    LinearGradient(gradient: Gradient(colors: [colors.0, colors.1]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: nextPrayer.previous().sfSymbolName())
                        .font(Font.headline.bold())
                        .foregroundColor(Color(.sRGB, white: 1, opacity: 0.8))
                        .offset(y: (nextPrayer.previous() == .sunrise || nextPrayer.previous() == .maghrib) ? -2 : 0)
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
            let timeProv = CLKTimeTextProvider(date: nextPrayerDate)
            let imageProv = CLKImageProvider(onePieceImage: UIImage(systemName: nextPrayer.sfSymbolName())!)
            let prov = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: timeProv, imageProvider: imageProv)
            return prov
            // this style gets too large
        // FAJR 4:55PM
//            let textProv = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@",
//                                           CLKTimeTextProvider(date: nextPrayerDate))
//
//            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProv)
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
        case.graphicRectangular:
            let timeProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
                                                       style: .naturalAbbreviated, units: [.hour, .minute])
            
            let colors = watchColorsForPrayer(nextPrayer.previous()).map { UIColor($0) }
            let headerTextProv = CLKTextProvider(format: "\(nextPrayer.previous().localizedOrCustomString()) • %@ left", timeProv)
            headerTextProv.tintColor = blend(colors: colors) //UIColor(watchColorsForPrayer(nextPrayer.previous()).last!)
            let nextTimeProvider = CLKTimeTextProvider(date: nextPrayerDate)
            let gaugeProv = CLKTimeIntervalGaugeProvider(style: .fill, gaugeColors: colors, gaugeColorLocations: [0, 1], start: currentPrayerDate, end: nextPrayerDate)
            let bodyProvider = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@", nextTimeProvider)
            return CLKComplicationTemplateGraphicRectangularTextGauge(headerTextProvider: headerTextProv,
                                                                      body1TextProvider: bodyProvider,
                                                                      gaugeProvider: gaugeProv)
        case .utilitarianSmall:
            let dateProv = CLKTimeTextProvider(date: nextPrayerDate)
            let shortableNameProv = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString(), shortText:String( nextPrayer.localizedOrCustomString().prefix(3)))
            
            let textProv = CLKTextProvider(format: "%@ %@", shortableNameProv, dateProv)

            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProv, imageProvider: CLKImageProvider(onePieceImage: UIImage()))
            
        case .extraLarge:
            return CLKComplicationTemplateExtraLargeStackImage(line1ImageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: nextPrayer.previous().sfSymbolName(), withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 70), scale: UIImage.SymbolScale.large))!), line2TextProvider: CLKSimpleTextProvider(text: nextPrayer.previous().localizedOrCustomString(), shortText: String(nextPrayer.previous().localizedOrCustomString().prefix(3))))

        case .modularLarge:
            let timeProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
                                                       style: .naturalAbbreviated, units: [.hour, .minute])
            let colors = watchColorsForPrayer(nextPrayer.previous()).map { UIColor($0) }
            let headerTextProv = CLKTextProvider(format: "\(nextPrayer.previous().localizedOrCustomString()) • %@ left", timeProv)
            headerTextProv.tintColor = blend(colors: colors) //UIColor(watchColorsForPrayer(nextPrayer.previous()).last!)
            let nextTimeProvider = CLKTimeTextProvider(date: nextPrayerDate)
            let bodyProvider = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@", nextTimeProvider)

            return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: headerTextProv, body1TextProvider: bodyProvider)
        
        // exclude this type, as extrLarge covers it
        // case .graphicExtraLarge:

        default:
            return nil
        }
    }
    
    func blend(colors: [UIColor]) -> UIColor {
        let numberOfColors = CGFloat(colors.count)
        var (red, green, blue, alpha) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        
        let componentsSum = colors.reduce((red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat())) { temp, color in
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return (temp.red+red, temp.green + green, temp.blue + blue, temp.alpha+alpha)
        }
        return UIColor(red: componentsSum.red / numberOfColors,
                       green: componentsSum.green / numberOfColors,
                       blue: componentsSum.blue / numberOfColors,
                       alpha: componentsSum.alpha / numberOfColors)
    }
}

//struct LargeComplication_Preview: PreviewProvider {
//    static var previews: some View {
////        CLKComplicationTemplateGraphicRectangularLargeView(headerTextProvider: CLKSimpleTextProvider(text: "Fajr"), content: Text("sd"))
////            .previewContext()
//
//
//        CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeView(
//            gaugeProvider: CLKTimeIntervalGaugeProvider(style: .fill, gaugeColors: nil, gaugeColorLocations: [0, 1], start: Date().addingTimeInterval(-100), end: Date().addingTimeInterval(40)), centerTextProvider: CLKSimpleTextProvider(text: "Sunrise"), bottomLabel: Text("4h 3m").font(Font.body)
//        )
//            .previewContext()
//
//        CLKComplicationTemplateExtraLargeStackImage(line1ImageProvider: CLKImageProvider(onePieceImage: UIImage(systemName: "sunset.fill", withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 70), scale: UIImage.SymbolScale.large))!), line2TextProvider: CLKSimpleTextProvider(text: "Fajr"))
//            .previewContext()
//
//        CLKComplicationTemplateExtraLargeStackText(line1TextProvider: CLKSimpleTextProvider(text: "Sunrise"), line2TextProvider: CLKSimpleTextProvider(text: "Sunrise"))
//            .previewContext()
//
//        CLKComplicationTemplateExtraLargeColumnsText(row1Column1TextProvider: CLKSimpleTextProvider(text: "Sunrise"), row1Column2TextProvider: CLKSimpleTextProvider(text: "Sunrise"), row2Column1TextProvider: CLKSimpleTextProvider(text: "Sunrise"), row2Column2TextProvider: CLKSimpleTextProvider(text: "Sunrise"))
//            .previewContext()
//
//
//
//
//
//
//    }
//}
