//
//  ComplicationController.swift
//  Watch Athan Extension
//
//  Created by Omar Alejel on 12/23/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource, WatchDataDelegate {
    
    var manager: WatchDataManager!
    
    let ComplicationCurrentEntry = "ComplicationCurrentEntry"
    let ComplicationTextData = "ComplicationTextData"
    let ComplicationShortTextData = "ComplicationShortTextData"
    
    var dataReady = false
    
    var dateFormatter = NSDateFormatter()
    
    //MARK: Init
    override init() {
        super.init()
        manager = WatchDataManager(delegate: self)
        
    }
    
    //MARK: Data Manager Delegate
    func dataReady(manager manager: WatchDataManager) {
        dataReady = true
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.None])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        
        if dataReady {
            var entry: CLKComplicationTimelineEntry?
            let now = NSDate()
            
            print(complication.family)
            
            switch complication.family {
            case .ModularSmall:
                //shows next prayer name and time
                let line1Text = manager.currentPrayer.next().stringValue()
                dateFormatter.dateFormat = "h:m"
                let line2Text = dateFormatter.stringFromDate(manager.nextPrayerTime())
                
                let textTemplate = CLKComplicationTemplateModularSmallStackText()
                textTemplate.line1TextProvider = CLKSimpleTextProvider(text: line1Text)
                textTemplate.line2TextProvider = CLKSimpleTextProvider(text: line2Text)
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .ModularLarge:
                //shows name and time for next prayer in row 1, time left in row 2
                dateFormatter.dateFormat = "h:m a"
                let nextTimeString = dateFormatter.stringFromDate(manager.nextPrayerTime())
                let line1Text = "\(manager.currentPrayer.next().stringValue()) \(nextTimeString)"
                
                let textTemplate = CLKComplicationTemplateModularLargeStandardBody()
                textTemplate.body1TextProvider = CLKSimpleTextProvider(text: line1Text)
                
                let dp = CLKRelativeDateTextProvider(date: manager.nextPrayerTime(), style: CLKRelativeDateStyle.Natural, units: [.Hour, .Minute])
                textTemplate.body2TextProvider = dp
                
                textTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Athan")
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .UtilitarianSmall:
                //shows next prayer and time
                dateFormatter.dateFormat = "h:m"
                let nextTimeString = dateFormatter.stringFromDate(manager.nextPrayerTime())
                let string = manager.currentPrayer.next().stringValue()
                let range = string.startIndex..<string.startIndex.advancedBy(1)
                let text = "\(string.substringWithRange(range)): \(nextTimeString)"

                let textTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
                textTemplate.textProvider = CLKSimpleTextProvider(text: text)
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .UtilitarianLarge:
                //shows next prayer, time, and image
                dateFormatter.dateFormat = "h:m a"
                let nextTimeString = dateFormatter.stringFromDate(manager.nextPrayerTime())
                let text = "\(manager.currentPrayer.next().stringValue()) at \(nextTimeString)"
                
                let textTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
                textTemplate.textProvider = CLKSimpleTextProvider(text: text)
                //textTemplate.imageProvider = CLKImageProvider(onePieceImage: imageForPrayer(manager.currentPrayer.next()))
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .CircularSmall:
                
                break
            }
            
            handler(entry)
        }
        
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(nil);
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    func imageForPrayer(p: PrayerType) -> UIImage {
        var imageName = ""
        switch p {
        case .Fajr:
            imageName = "sunhorizon"
        case .Shurooq:
            imageName = "sunhorizon"
        case .Thuhr:
            imageName = "sun"
        case .Asr:
            imageName = "sunfilled"
        case .Maghrib:
            imageName = "sunhorizon"
        case .Isha:
            imageName = "moon"
        }
        
        return UIImage(named: imageName)!
    }
}
