//
//  ComplicationController.swift
//  Athan Watch Extension
//
//  Created by Omar Al-Ejel on 1/6/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import ClockKit
import Adhan

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let manager = AthanManager.shared
    
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
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Corner")!))
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: CLKRelativeDateTextProvider(date: date, relativeTo: nextPrayerDate, style: .timer, units: .hour), line2TextProvider: CLKTextProvider(format: nextPrayer.localizedOrCustomString()))
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!))
        default:
            return nil
        }
    }
}
