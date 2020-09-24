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
        
        // for now, lets attempt to load all prayer data from file
        let _ = PrayerManager(delegate: nil) { (res) in
            switch res {
            case .success(let man):
                var times = [PrayerType:Date]()
                man.todayPrayerTimes.forEach { (k, v) in
                    times[PrayerType(rawValue: k)!] = v
                }
                let entry = AthanEntry(date: Date(), currentPrayer: man.currentPrayer, currentPrayerDate: man.currentPrayerTime(), nextPrayerDate: man.nextPrayerTime()!, todayPrayerTimes: times)
                completion(entry)
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
                
        // read today and tomorrow's athan times, create timeline entries for today and tomorrow's prayers
        let _ = PrayerManager(delegate: nil) { result in
            switch result {
            case .success(let man):
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
                return
            case .failure:
                break // move on to failure mode
            }
            print("Widget failed to load prayer times")
            completion(Timeline(entries: [], policy: .atEnd))
        }
    }
}
