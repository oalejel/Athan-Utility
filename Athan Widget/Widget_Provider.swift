//
//  Widget_Bundle.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 9/23/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import WidgetKit
import Intents
import Adhan

struct AthanEntry: TimelineEntry {
    let date: Date // just represents time to update the timeline. != always equal start of prayer
    var currentPrayer: Prayer
    var currentPrayerDate: Date
    var nextPrayerDate: Date // will refer to Fajr of next day if prayerType is isha
    var todayPrayerTimes: [Date]
    
    // I don't think I'll need intents for these widgets
    // allowing users to load times for different locations
    // is a feature for another day
    //let configuration: ConfigurationIntent
//    init(date: Date) {
//        self.date = date
//    }
}

class AthanProvider: IntentTimelineProvider {
    var manager = AthanManager.shared
    
    func placeholder(in context: Context) -> AthanEntry {
        // let UI handle case with nil data
        let exampleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        // pass .none for placeholders
        return AthanEntry(date: Date(), currentPrayer: Prayer.fajr, currentPrayerDate: Date(),
                          nextPrayerDate: exampleDate, todayPrayerTimes: [Date(), Date(), Date(), Date(), Date(), Date()])
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (AthanEntry) -> ()) {
        let timeArray = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
        let entry = AthanEntry(date: Date(),
                               currentPrayer: manager.currentPrayer ?? Prayer.isha,
                               currentPrayerDate: manager.guaranteedCurrentPrayerTime(),
                               nextPrayerDate: manager.guaranteedNextPrayerTime(),
                               todayPrayerTimes: timeArray)
        
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<AthanEntry>) -> ()) {
        var entries: [AthanEntry] = []
        // NOTE: users should be able to never open athan utility – in this case, we should use the prayer manager to load all of our data!
        // at the very least allow the widget provider to request new data on the last entry if we only have one day left of data!
        
    
        
        // first, add a snapshot entry for NOW, since we may be on isha time
        // on a new day (at like 1 AM), where there is no entry made above that
        // precedes the current time
        let todayTimesArray = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
        let nowEntry = AthanEntry(date: Date(),
                                  currentPrayer: manager.currentPrayer ?? Prayer.isha,
                                  currentPrayerDate: manager.guaranteedCurrentPrayerTime(),
                                  nextPrayerDate: manager.guaranteedNextPrayerTime(),
                                  todayPrayerTimes: todayTimesArray)
        entries.append(nowEntry)
        
        // create entries with 10% increments between now and the next prayer, unless there are less than 5 mins left,
        // in which case make a single middle update between now and the next prayer
        let timeLeftToNextPrayer = manager.guaranteedNextPrayerTime().timeIntervalSince(Date())
        if timeLeftToNextPrayer < 5 * 60 { // if less than a min left, consider a single update
            if timeLeftToNextPrayer > 60 { //
                let midpointDate = Date().addingTimeInterval(timeLeftToNextPrayer / 2)
                let midpointEntry = AthanEntry(date: midpointDate,
                                               currentPrayer: manager.currentPrayer ?? Prayer.isha,
                                               currentPrayerDate: manager.guaranteedCurrentPrayerTime(),
                                               nextPrayerDate: manager.guaranteedNextPrayerTime(),
                                               todayPrayerTimes: todayTimesArray)
                entries.append(midpointEntry)
            } // otherwise too little time left to give another update for current prayer
        } else {
            // make 10% increments
            
        }
        

        // create entry for every prayer AFTER the current prayer today
        // this prevents putting in entries for dates before now
        for pIndex in (1 + (manager.currentPrayer ?? Prayer.isha).rawValue())..<6 {
            let iterationPrayer = Prayer(index: pIndex)
            let prayerDate = manager.todayTimes.time(for: iterationPrayer)
            
            // get time of prayer that follows this one. isha will have fajr tomorrow
            var nextPrayer = Prayer.fajr
            var nextTime = manager.tomorrowTimes.fajr
            if iterationPrayer != .isha {
                nextPrayer = Prayer(index: pIndex + 1)
                nextTime = manager.todayTimes.time(for: nextPrayer)
            }
            
            // create a timestamp for every 10% increment between prayerDate and the next prayer date
            // this allows the view to update in order to show a proper competion status
            let percentSplit = 10.0
            let timeRange = nextTime.timeIntervalSince(prayerDate)
            let tenPercentIncrements = floor(timeRange / percentSplit) // seconds between each 10%

            for percent in 0..<Int(percentSplit) {
                // for i = 0, updateDate = prayerDate
                let updateDate = Calendar.current.date(byAdding: .second, value: percent * Int(tenPercentIncrements), to: prayerDate)!
                let entry = AthanEntry(date: updateDate,
                                       currentPrayer: iterationPrayer,
                                       currentPrayerDate: prayerDate,
                                       nextPrayerDate: nextTime,
                                       todayPrayerTimes: todayTimesArray)
                entries.append(entry)
            }
            
            // add a timestamp for when we have 5 minutes left iff our previous timestamps do not cover that time range
            if tenPercentIncrements > 5 * 60 { // subtract 5 mins from next prayer's time for a 5 minute update ust so we're precise near the end
                let updateDate = nextTime.addingTimeInterval(-5 * 60)
//                assert(updateDate < nextTime)
                let entry = AthanEntry(date: updateDate,
                                       currentPrayer: iterationPrayer,
                                       currentPrayerDate: prayerDate,
                                       nextPrayerDate: nextTime,
                                       todayPrayerTimes: todayTimesArray)
                entries.append(entry)
            }
        }
        
        // now add times for tomorrow up til dhuhr time (when we reach asr, we want tomorrow's times to be ready for isha -> fajr's calc
        // DO NOT GO UP TO ISHA
        for tomorrowPIndex in 0..<2 {
            let iterationPrayer = Prayer(index: tomorrowPIndex)
            let prayerDate = manager.todayTimes.time(for: iterationPrayer)
            
            // get time of prayer that follows this one
            // will NOT have to worry about isha -> tomorrow since tomorrowPIndex never goes to 5
            let nextPrayer = Prayer(index: tomorrowPIndex + 1)
            let nextTime = manager.todayTimes.time(for: nextPrayer)
            
            // create a timestamp for every 10% increment between prayerDate and the next prayer date
            // this allows the view to update in order to show a proper competion status
            let percentSplit = 10.0
            let timeRange = nextTime.timeIntervalSince(prayerDate)
            let tenPercentIncrements = floor(timeRange / percentSplit) // seconds between each 10%

            for percent in 0..<Int(percentSplit) {
                // for i = 0, updateDate = prayerDate
                let updateDate = Calendar.current.date(byAdding: .second, value: percent * Int(tenPercentIncrements), to: prayerDate)!
                let entry = AthanEntry(date: updateDate,
                                       currentPrayer: iterationPrayer,
                                       currentPrayerDate: prayerDate,
                                       nextPrayerDate: nextTime,
                                       todayPrayerTimes: todayTimesArray)
                entries.append(entry)
            }
            
            // add a timestamp for when we have 5 minutes left iff our previous timestamps do not cover that time range
            if tenPercentIncrements > 5 * 60 { // subtract 5 mins from next prayer's time for a 5 minute update ust so we're precise near the end
                let updateDate = nextTime.addingTimeInterval(-5 * 60)
                let entry = AthanEntry(date: updateDate,
                                       currentPrayer: iterationPrayer,
                                       currentPrayerDate: prayerDate,
                                       nextPrayerDate: nextTime,
                                       todayPrayerTimes: todayTimesArray)
                entries.append(entry)
            }
            
            // no worry for type == isha, since tomorrow's entries only go up to maghrib
        }
        
        // .atEnd means that the timeline will request new timeline info on the date of the last timeline entry
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
