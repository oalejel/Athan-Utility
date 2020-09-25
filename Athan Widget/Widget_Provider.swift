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

struct AthanEntry: TimelineEntry {
    let date: Date // just represents time to update the timeline. != always equal start of prayer
    var currentPrayer: PrayerType
    var currentPrayerDate: Date
    var nextPrayerDate: Date // will refer to Fajr of next day if prayerType is isha
    var todayPrayerTimes: [PrayerType:Date]
    
    // I don't think I'll need intents for these widgets
    // allowing users to load times for different locations
    // is a feature for another day
    //let configuration: ConfigurationIntent
}

struct AthanProvider: IntentTimelineProvider {
    
    func placeholder(in context: Context) -> AthanEntry {
        // let UI handle case with nil data
        let exampleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return AthanEntry(date: Date(), currentPrayer: .fajr, currentPrayerDate: Date(), nextPrayerDate: exampleDate, todayPrayerTimes: [:])
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (AthanEntry) -> ()) {
        
        func generateSnapshotOnManager(manager: PrayerManager) {
            var times = [PrayerType:Date]()
            manager.todayPrayerTimes.forEach { (k, v) in
                times[PrayerType(rawValue: k)!] = v
            }
            let entry = AthanEntry(date: Date(), currentPrayer: manager.currentPrayer, currentPrayerDate: manager.currentPrayerTime(), nextPrayerDate: manager.nextPrayerTime()!, todayPrayerTimes: times)
            completion(entry)
        }
        
        // lets try to load from file for a snapshot
        // if no times available, then have the prayer manager load things
        func attemptLoadFromFile() {
            let manager = PrayerManager(delegate: nil)
            if manager.dataExists {
                generateSnapshotOnManager(manager: manager)
                return
            } else if manager.readableLocationString == nil {
                // if no location was ever set, give up
                print("location services not allowed")
                let errorEntry = AthanEntry(date: Date(), currentPrayer: .none, currentPrayerDate: Date(), nextPrayerDate: Date(), todayPrayerTimes: [:])
                completion(errorEntry)
            }
        }
        attemptLoadFromFile()
        
        // if we reach this point, the old discarded manager was not able
        // to read data from a file, and so we need GPS data
        let _ = PrayerManager(delegate: nil) { (res) in
            switch res {
            case .success(let man):
                generateSnapshotOnManager(manager: man)
                return
            case .failure:
                print("Unable to get prayer snapshot")
                // create dummy date in this case
                let exampleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
                let entry = AthanEntry(date: Date(), currentPrayer: .fajr, currentPrayerDate: Date(), nextPrayerDate: exampleDate, todayPrayerTimes: [:])
                completion(entry)
            }
        }
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<AthanEntry>) -> ()) {
        var entries: [AthanEntry] = []
        // NOTE: users should be able to never open athan utility – in this case, we should use the prayer manager to load all of our data!
        // at the very least allow the widget provider to request new data on the last entry if we only have one day left of data!
        
        func generateTimeline(man: PrayerManager) {
            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            
            guard man.todayPrayerTimes.count == 6 && man.tomorrowPrayerTimes.count == 6 else {
                print("Incomplete prayer times for today")
                completion(Timeline(entries: [], policy: .atEnd))
                return
            }
            
            // store times as ptype -> date dict
            var todayTimesDict = [PrayerType:Date]()
            man.todayPrayerTimes.forEach { (k, v) in
                todayTimesDict[PrayerType(rawValue: k)!] = v
            }
            var tomorrowTimesDict = [PrayerType:Date]()
            man.tomorrowPrayerTimes.forEach { (k, v) in
                tomorrowTimesDict[PrayerType(rawValue: k)!] = v
            }
            
            // first, add a snapshot entry for NOW, since we may be on isha time
            // on a new day (at like 1 AM), where there is no entry made above that
            // precedes the current time
            let nowEntry = AthanEntry(date: Date(), currentPrayer: man.currentPrayer, currentPrayerDate: man.currentPrayerTime(), nextPrayerDate: man.nextPrayerTime()!, todayPrayerTimes: todayTimesDict)
            entries.append(nowEntry)

            
            // create entry for every prayer of today
            // maybe its ok if we put things that have dates after now?
            for i in 0...5 {
                let type = PrayerType(rawValue: i)!
                let prayerDate = man.todayPrayerTimes[i]!
                
                // get time of prayer that follows this one
                guard var nextTime = todayTimesDict[type.next()] else {
                    print("Widget failed to load next prayer time")
                    completion(Timeline(entries: [], policy: .atEnd))
                    return
                }
                
                // we should really be reading from tomorrow's fajr time in this case
                if type == .isha {
                    nextTime = man.tomorrowPrayerTimes[0] ?? nextTime
                }
                
                // create a timestamp for every 10% increment between prayerDate and the next prayer date
                // this allows the view to update in order to show a proper competion status
                let timeRange = nextTime.timeIntervalSince(prayerDate)
                let tenPercentIncrements = floor(timeRange / 10) // seconds between each 10%
                
                for i in 0..<10 {
                    // for i = 0, updateDate = prayerDate
                    let updateDate = Calendar.current.date(byAdding: .second, value: i * Int(tenPercentIncrements), to: prayerDate)!
                    let entry = AthanEntry(date: updateDate, currentPrayer: type, currentPrayerDate: prayerDate, nextPrayerDate: nextTime, todayPrayerTimes: todayTimesDict)
                    entries.append(entry)
                }
                
                // add a timestamp for when we have 5 minutes left iff our previous timestamps do not cover that time range
                if tenPercentIncrements > 5 * 60 { // subtract 5 mins from next prayer's time for a 5 minute update ust so we're precise near the end
                    let updateDate = Calendar.current.date(byAdding: .second, value: -5 * 60, to: nextTime)!
                    let entry = AthanEntry(date: updateDate, currentPrayer: type, currentPrayerDate: prayerDate, nextPrayerDate: nextTime, todayPrayerTimes: todayTimesDict)
                    entries.append(entry)
                }
            }
            
            // now add times for tomorrow up til asr time (when we reach asr, we want tomorrow's times to be ready for isha -> fajr's calc
            for i in 0...2 {
                let type = PrayerType(rawValue: i)!
                let prayerDate = man.tomorrowPrayerTimes[i]!
                
                // get time of prayer that follows this one
                guard let nextTime = man.tomorrowPrayerTimes[type.next().rawValue] else {
                    print("Widget failed to load next prayer time")
                    completion(Timeline(entries: [], policy: .atEnd))
                    return
                }
                
                // repeat what we did for today's times with the 10% increment updates
                let timeRange = nextTime.timeIntervalSince(prayerDate)
                let tenPercentIncrements = floor(timeRange / 10) // seconds between each 10%
                
                for i in 0..<10 {
                    // for i = 0, updateDate = prayerDate
                    let updateDate = Calendar.current.date(byAdding: .second, value: i * Int(tenPercentIncrements), to: prayerDate)!
                    let entry = AthanEntry(date: updateDate, currentPrayer: type, currentPrayerDate: prayerDate, nextPrayerDate: nextTime, todayPrayerTimes: tomorrowTimesDict)
                    entries.append(entry)
                }
                
                // add a timestamp for when we have 5 minutes left iff our previous timestamps do not cover that time range
                if tenPercentIncrements > 5 * 60 { // subtract 5 mins from next prayer's time for a 5 minute update ust so we're precise near the end
                    let updateDate = Calendar.current.date(byAdding: .second, value: -5 * 60, to: nextTime)!
                    let entry = AthanEntry(date: updateDate, currentPrayer: type, currentPrayerDate: prayerDate, nextPrayerDate: nextTime, todayPrayerTimes: tomorrowTimesDict)
                    entries.append(entry)
                }
                // no worry for type == isha, since tomorrow's entries only go up to maghrib
            }
            
            // .atEnd means that the timeline will request new timeline info on the date of the last timeline entry
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
        
        let manager = PrayerManager(delegate: nil)
        if !manager.todayPrayerTimes.isEmpty && !manager.tomorrowPrayerTimes.isEmpty {
            // first attempt to read from new data, otherwise stick with this file data
            generateTimeline(man: manager)
//            manager.fetchMonthsJSONDataForCurrentLocation { (success) in
//                generateTimeline(man: manager)
//            }
        } else {
            // tell user to open app
            // create dummy date in this case
            let exampleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let entry = AthanEntry(date: Date(), currentPrayer: .none, currentPrayerDate: Date(), nextPrayerDate: exampleDate, todayPrayerTimes: [:])
            completion(Timeline(entries: [entry], policy: .atEnd))
        }
        
//        let _ = PrayerManager(delegate: nil) { (res) in
//            switch res {
//            case .success(let man):
//                generateTimeline(man: man)
//                return
//            case .failure:
//                print("Unable to get prayer snapshot")
//                // create dummy date in this case
//                let exampleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
//                let entry = AthanEntry(date: Date(), currentPrayer: .none, currentPrayerDate: Date(), nextPrayerDate: exampleDate, todayPrayerTimes: [:])
//                completion(Timeline(entries: [entry], policy: .atEnd))
//            }
//        }
    }
}
