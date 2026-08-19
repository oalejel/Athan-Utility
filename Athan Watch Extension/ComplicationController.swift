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
        let families = CLKComplicationFamily.allCases // includes graphicExtraLarge (large full-color faces / Ultra)
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
        manager.refreshTimes()
        if manager.locationSettings.locationName == LocationSettings.defaultSetting().locationName {
            handler(nil) // havent sent location
        } else {
            // Reach several days out, not tomorrow's Maghrib. When the timeline runs dry
            // ClockKit keeps showing the LAST entry it was given, so a watch that misses
            // its background refreshes sits on a stale prayer indefinitely — which is
            // exactly the "stuck on Isha in the morning" report. Entries are cheap and
            // each one computes its own times, so there is no reason to stop early.
            let end = futurePrayerTimes(after: Date(), days: 4).last
            print("latest scheduled complication: \(String(describing: end))")
            handler(end)
        }
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        manager.refreshTimes()
        if manager.locationSettings.locationName == LocationSettings.defaultSetting().locationName {
            handler(nil) // case if we have not set our locdeation
        } else if let template = getComplicationTemplate(for: complication, using: Date()) {
            print(">>> COMPLICATION MANAGER USING LOCATION (creating current entry): \(manager.locationSettings.locationName)")
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil) // case where we cant produce a template
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        manager.refreshTimes()

        // first, ensure that we are able to produce the desired complication
        //        guard let _ = getComplicationTemplate(for: complication, using: Date()) else {
        //            handler(nil)
        //            return
        //        }

        // Every prayer time in the window the end date promises. Each entry recomputes
        // its own times, so these stay correct however long the watch sleeps.
        var sortedStoredTimes = futurePrayerTimes(after: date, days: 4)
        // if going beyond limit, cut out latest times we cannot fit
        if limit < sortedStoredTimes.count {
            sortedStoredTimes.removeSubrange(limit..<sortedStoredTimes.endIndex)
        }
        
        // for each date, create a timeline entry
        var entries: [CLKComplicationTimelineEntry] = []
        print(">>> COMPLICATION MANAGER USING LOCATION: \(manager.locationSettings.locationName)")
        for entryDate in sortedStoredTimes {
            if let template = getComplicationTemplate(for: complication, using: entryDate) {
                print("succeeded template: \(complication.family.rawValue)")
                entries.append(CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template))
            } else {
                print("FAILED template: \(complication.family.rawValue)")
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
    
    /// Prayer times strictly after `date`, covering `days` days forward.
    private func futurePrayerTimes(after date: Date, days: Int) -> [Date] {
        let calendar = Calendar.current
        let adjustments = manager.notificationSettings.adjustments()
        var times: [Date] = []
        for offset in 0...days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date),
                  let dayTimes = manager.calculateTimes(referenceDate: day, adjustments: adjustments) else {
                continue
            }
            times += Prayer.allCases.map { dayTimes.time(for: $0) }
        }
        return times.filter { date < $0 }.sorted()
    }

    /// Every prayer time from the day before `date` through the day after, in order.
    ///
    /// Computed from `date` itself so a timeline entry is correct whenever it happens to
    /// be rendered, however stale the manager's cached times are. The day either side is
    /// what makes the boundaries work: before today's Fajr the current prayer is
    /// yesterday's Isha, and after today's Isha the next one is tomorrow's Fajr.
    private func surroundingPrayerTimes(for date: Date) -> [Date]? {
        let calendar = Calendar.current
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date),
              let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        let adjustments = manager.notificationSettings.adjustments()
        var times: [Date] = []
        for day in [previousDay, date, nextDay] {
            guard let dayTimes = manager.calculateTimes(referenceDate: day, adjustments: adjustments) else {
                return nil
            }
            times += Prayer.allCases.map { dayTimes.time(for: $0) }
        }
        return times
    }

    func getComplicationTemplate(for complication: CLKComplication, using date: Date) -> CLKComplicationTemplate? {
        // check if queried date takes place after a time we have stored
        
        //        // to account for high precision similarity in dates, move date forward by 1 second
        //        let date = date.addingTimeInterval(1)
        // Times are recomputed around the ENTRY's own date rather than read from the
        // manager's cached today/tomorrow. Those two are whatever the last refresh
        // happened to compute, and a watch that has been asleep can render an entry
        // against a stale pair — which is how the rectangular complication ended up
        // showing Isha in the morning. Yesterday is included so the period before
        // today's Fajr resolves to yesterday's Isha for real, instead of the old
        // "today's isha minus 86400" estimate.
        guard let sortedStoredTimes = surroundingPrayerTimes(for: date),
              let firstGreaterTimeIndex = sortedStoredTimes.firstIndex(where: { date < $0 }),
              firstGreaterTimeIndex > 0 else {
            return nil
        }
        let currentPrayerDate = sortedStoredTimes[firstGreaterTimeIndex - 1]
        let nextPrayerDate = sortedStoredTimes[firstGreaterTimeIndex]
        let nextPrayer = Prayer.allCases[firstGreaterTimeIndex % 6] // 6 per day, so % 6 maps back onto the cases
        
        switch complication.family {
        case .graphicCircular:
            let timeProv = CLKTimeTextProvider(date: nextPrayerDate)
            let colors = watchColorsForPrayer(nextPrayer).map { UIColor($0) }
            timeProv.tintColor = blend(colors: colors)

            if nextPrayer == .sunrise || nextPrayer == .maghrib { // use an image for sunrise or sunset
                let imageProv = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 15), scale: UIImage.SymbolScale.small))!.withTintColor(.white))
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

        case .graphicExtraLarge:
            let timeProv = CLKTimeTextProvider(date: nextPrayerDate)
            let colors = watchColorsForPrayer(nextPrayer).map { UIColor($0) }
            timeProv.tintColor = blend(colors: colors)
            if nextPrayer == .sunrise || nextPrayer == .maghrib {
                let imageProv = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 30), scale: .large))!.withTintColor(.white))
                return CLKComplicationTemplateGraphicExtraLargeCircularStackImage(line1ImageProvider: imageProv, line2TextProvider: timeProv)
            } else {
                let nameProvider = CLKSimpleTextProvider(text: nextPrayer.localizedOrCustomString())
                return CLKComplicationTemplateGraphicExtraLargeCircularStackText(line1TextProvider: nameProvider, line2TextProvider: timeProv)
            }

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
//
//
////        CLKcomplicationtemplateview
////                CLKComplicationTemplateGraphicRectangularLargeView(headerTextProvider: CLKSimpleTextProvider(text: "Fajr"), content: Text("sd"))
////                    .previewContext()
//
//
////        { () -> View in
////            let timeProv = CLKRelativeDateTextProvider(date: nextPrayerDate, relativeTo: nil,
////                                                                style: .naturalAbbreviated, units: [.hour, .minute])
////            let colors = watchColorsForPrayer(nextPrayer.previous()).map { UIColor($0) }
////            let headerTextProv = CLKTextProvider(format: "\(nextPrayer.previous().localizedOrCustomString()) • %@ left", timeProv)
////            headerTextProv.tintColor = blend(colors: colors) //UIColor(watchColorsForPrayer(nextPrayer.previous()).last!)
////            let nextTimeProvider = CLKTimeTextProvider(date: nextPrayerDate)
////            let bodyProvider = CLKTextProvider(format: "\(nextPrayer.localizedOrCustomString()) %@", nextTimeProvider)
////
////            return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: headerTextProv, body1TextProvider: bodyProvider)
////
////            clkcomplicationtemplate
////        }
//    }
//}
