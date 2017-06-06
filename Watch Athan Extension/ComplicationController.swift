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
    
    var dateFormatter = DateFormatter()
    
    //MARK: Init
    override init() {
        super.init()
        manager = WatchDataManager(delegate: self)
        
    }
    
    //MARK: Data Manager Delegate
    func dataReady(manager: WatchDataManager) {
        dataReady = true
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler(CLKComplicationTimeTravelDirections())
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: (@escaping (CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        
        if dataReady {
            var entry: CLKComplicationTimelineEntry?
            let now = Date()
            
            print(complication.family)
            
            switch complication.family {
            case .modularSmall:
                //shows next prayer name and time
                let line1Text = manager.currentPrayer.next().stringValue()
                dateFormatter.dateFormat = "h:m"
                let line2Text = dateFormatter.string(from: manager.nextPrayerTime())
                
                let textTemplate = CLKComplicationTemplateModularSmallStackText()
                textTemplate.line1TextProvider = CLKSimpleTextProvider(text: line1Text)
                textTemplate.line2TextProvider = CLKSimpleTextProvider(text: line2Text)
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .modularLarge:
                //shows name and time for next prayer in row 1, time left in row 2
                dateFormatter.dateFormat = "h:m a"
                let nextTimeString = dateFormatter.string(from: manager.nextPrayerTime())
                let line1Text = "\(manager.currentPrayer.next().stringValue()) \(nextTimeString)"
                
                let textTemplate = CLKComplicationTemplateModularLargeStandardBody()
                textTemplate.body1TextProvider = CLKSimpleTextProvider(text: line1Text)
                
                let dp = CLKRelativeDateTextProvider(date: manager.nextPrayerTime(), style: CLKRelativeDateStyle.natural, units: [.hour, .minute])
                textTemplate.body2TextProvider = dp
                
                textTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Athan")
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .utilitarianSmall:
                //shows next prayer and time
                dateFormatter.dateFormat = "h:m"
                let nextTimeString = dateFormatter.string(from: manager.nextPrayerTime())
                let string = manager.currentPrayer.next().stringValue()
                let range = string.startIndex..<string.characters.index(string.startIndex, offsetBy: 1)
                let text = "\(string.substring(with: range)): \(nextTimeString)"

                let textTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
                textTemplate.textProvider = CLKSimpleTextProvider(text: text)
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .utilitarianLarge:
                //shows next prayer, time, and image
                dateFormatter.dateFormat = "h:m a"
                let nextTimeString = dateFormatter.string(from: manager.nextPrayerTime())
                let text = "\(manager.currentPrayer.next().stringValue()) at \(nextTimeString)"
                
                let textTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
                textTemplate.textProvider = CLKSimpleTextProvider(text: text)
                //textTemplate.imageProvider = CLKImageProvider(onePieceImage: imageForPrayer(manager.currentPrayer.next()))
                
                entry = CLKComplicationTimelineEntry(date: now, complicationTemplate: textTemplate)
                break
            case .circularSmall:
                
                break
            default:
                ///there are now more options. add these so that you dont  need this default statement
                break
            }
            
            handler(entry)
        }
        
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: (@escaping ([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: (@escaping ([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(nil);
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    func imageForPrayer(_ p: PrayerType) -> UIImage {
        var imageName = ""
        switch p {
        case .fajr:
            imageName = "sunhorizon"
        case .shurooq:
            imageName = "sunhorizon"
        case .thuhr:
            imageName = "sun"
        case .asr:
            imageName = "sunfilled"
        case .maghrib:
            imageName = "sunhorizon"
        case .isha:
            imageName = "moon"
        }
        
        return UIImage(named: imageName)!
    }
}
