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

struct AthanProvider: IntentTimelineProvider {
    
    
    func placeholder(in context: Context) -> AthanEntry {
        // let UI handle case with nil data
        AthanEntry(date: Date(), prayerTimes: nil)
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (AthanEntry) -> ()) {
        
        // for now, lets attempt to load all prayer data from file
        let entry = AthanEntry(date: Date(), prayerTimes: nil)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<AthanEntry>) -> ()) {
        var entries: [AthanEntry] = []
        // NOTE: users should be able to never open athan utility – in this case, we should use the prayer manager to load all of our data!
        // at the very least allow the widget provider to request new data on the last entry if we only have one day left of data!
//        let d = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
//        let entry = AthanEntry(date: d, prayerTimes: [:])
//        completion(Timeline(entries: [entry], policy: .atEnd))
                
        // read today and tomorrow's athan times, create timeline entries for today and tomorrow's prayers
        let manager = PrayerManager(delegate: nil)// { result in
//            switch result {
//            case .success(let prayerDict):
//                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//                for pIndex in 0...5 {
//                    let pType = PrayerType(rawValue: pIndex)!
//                    guard let prayerTime = prayerDict[pType] else { fatalError("empty prayer dict") }
//                    let entry = AthanEntry(date: prayerTime, prayerTimes: prayerDict)
//                    entries.append(entry)
//                }
//
//                // .atEnd means that the timeline will request new timeline info on the date of the last timeline entry
//                let timeline = Timeline(entries: entries, policy: .atEnd)
//                completion(timeline)
//            case .failure(let error):
//                print(error)
//                completion(Timeline(entries: [], policy: .atEnd))
//            }
//        }
        
        var times = [PrayerType:Date]()
        manager.todayPrayerTimes.forEach { (k, v) in
            times[PrayerType(rawValue: k)!] = v
        }
        for pIndex in 0...5 {
            let pType = PrayerType(rawValue: pIndex)!
            guard let prayerTime = times[pType] else { fatalError("empty prayer dict") }
            let entry = AthanEntry(date: prayerTime, prayerTimes: times)
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
