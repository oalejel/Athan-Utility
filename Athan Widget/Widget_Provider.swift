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

class AthanProvider: TimelineProvider {
    var manager = AthanManager.shared
    
    func placeholder(in context: Context) -> AthanEntry {
        // let UI handle case with nil data
        let exampleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let useDynamicColors = manager.appearanceSettings.isDynamic
        let colors = manager.appearanceSettings.colors(for: useDynamicColors ? (manager.currentPrayer ?? Prayer.isha) : nil)
        
        // pass .none for placeholders
        return AthanEntry(date: Date(timeIntervalSinceNow: 100), currentPrayer: Prayer.fajr, currentPrayerDate: Date(),
                          nextPrayerDate: exampleDate, todayPrayerTimes: [Date(), Date(timeIntervalSinceNow: 200), Date(), Date(), Date(), Date()], gradient: Gradient(colors: [colors.0, colors.1]))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AthanEntry) -> Void) {
        if manager.locationSettings.isLoadedFromArchive {
            // WARNING: no foreground updates here --> must manually tell manager to refresh
            // for now, dont call enterForeground since that will request new location
            manager.reloadSettingsAndNotifications()
            
            let useDynamicColors = manager.appearanceSettings.isDynamic
            let colors = manager.appearanceSettings.colors(for: useDynamicColors ? (manager.currentPrayer ?? Prayer.isha) : nil)
            let timeArray = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
            let entry = AthanEntry(date: Date(),
                                   currentPrayer: manager.currentPrayer ?? Prayer.isha,
                                   currentPrayerDate: manager.guaranteedCurrentPrayerTime(),
                                   nextPrayerDate: manager.guaranteedNextPrayerTime(),
                                   todayPrayerTimes: timeArray,
                                   gradient: Gradient(colors: [colors.0, colors.1]))
            
            completion(entry)
        } else { // if not loaded from settings, give user an error
            let openAppEntry = AthanEntry(date: Date(),
                                   currentPrayer: Prayer.fajr, // dummy data
                                   currentPrayerDate: Date(),
                                   nextPrayerDate: Date(),
                                   todayPrayerTimes: [],
                                   tellUserToOpenApp: true,
                                   gradient: Gradient(colors: [.black, .blue]))
            completion(openAppEntry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AthanEntry>) -> Void) {
        var entries: [AthanEntry] = []
        // OLD goal (leaving for later): users should be able to never open athan utility – in this case, we should use the prayer manager to load all of our data!
        // at the very least allow the widget provider to request new data on the last entry if we only have one day left of data!
        
        // WARNING: no foreground updates here --> must manually tell manager to refresh
        // for now, dont call enterForeground since that will request new location
        manager.reloadSettingsAndNotifications()

        // A widget timeline executing at all proves this is an existing install
        // with a widget already configured (a brand-new install can't have one
        // yet) — one of the two triggers for the one-time new-features announcement.
        NewFeaturesAnnouncement.announceFromWidgetIfEligible()

        // Auto-update the calculation method if the stored country now recommends a different
        // one — so times reflect it without opening the app. Don't reschedule notifications
        // from the widget (the app does that on next foreground); reload settings once more so
        // this timeline is built with the new method.
        if manager.autoUpdateMethodIfNeeded(for: manager.bestAvailableCountryCode(), rescheduleNotifications: false) {
            manager.reloadSettingsAndNotifications()
        }
        if !manager.locationSettings.isLoadedFromArchive {
            let openAppEntry = AthanEntry(date: Date(),
                                   currentPrayer: Prayer.fajr, // dummy data
                                   currentPrayerDate: Date(),
                                   nextPrayerDate: Date(),
                                   todayPrayerTimes: [],
                                   tellUserToOpenApp: true,
                                   gradient: Gradient(colors: [.black, .blue]))
            
            let timeline = Timeline(entries: [openAppEntry], policy: .atEnd)
            completion(timeline)
            return
        }
        
        let useDynamicColors = manager.appearanceSettings.isDynamic
        let todayTimesArray = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
        let tomorrowTimesArray = Prayer.allCases.map { manager.tomorrowTimes.time(for: $0) }
        
        // first, add a snapshot entry for NOW, since we may be on isha time
        // on a new day (at like 1 AM), where there is no entry made above that
        // precedes the current time
        let nowColors = manager.appearanceSettings.colors(for: useDynamicColors ? (manager.currentPrayer ?? Prayer.isha) : nil)
        let nowEntry = AthanEntry(date: Date(),
                                  currentPrayer: manager.currentPrayer ?? Prayer.isha,
                                  currentPrayerDate: manager.guaranteedCurrentPrayerTime(),
                                  nextPrayerDate: manager.guaranteedNextPrayerTime(),
                                  todayPrayerTimes: todayTimesArray,
                                  relevance: TimelineEntryRelevance.init(score: EntryRelevance.High.rawValue),
                                  gradient: Gradient(colors: [nowColors.0, nowColors.1]))
        entries.append(nowEntry)
        
        

        // Smart Stack relevance window: how long before a prayer starts the
        // OUTGOING prayer's entry gets bumped to High (an "ending soon" heads-up),
        // and how long after a prayer starts the INCOMING entry stays at High
        // (the "just switched" window). Both requested at 15 minutes.
        let relevanceWindow: TimeInterval = 15 * 60

        // Precedes a transition entry with a clone of the still-current (about
        // to end) entry, redated to `transitionDate - relevanceWindow` and
        // scored High — so Smart Stack surfaces the OUTGOING prayer as its
        // window closes, not just the incoming one.
        func appendHeadsUpIfNeeded(before transitionDate: Date) {
            guard let previous = entries.last else { return }
            let headsUpDate = transitionDate.addingTimeInterval(-relevanceWindow)
            guard headsUpDate > previous.date, headsUpDate > Date() else { return }
            var headsUp = previous
            headsUp.date = headsUpDate
            headsUp.relevance = TimelineEntryRelevance(score: EntryRelevance.High.rawValue, duration: relevanceWindow)
            entries.append(headsUp)
        }

        // create a single entry for every remaining prayer of the day
        // if we are currently on isha after 12 am, nextPrayer will return fajr
        for pIndex in (manager.todayTimes.nextPrayer()?.rawValue() ?? 6)..<6 {

            let iterationPrayer = Prayer(index: pIndex) // the prayer we want to create a single update for
            let prayerDate = manager.todayTimes.time(for: iterationPrayer)
            let pColors = manager.appearanceSettings.colors(for: useDynamicColors ? iterationPrayer : nil)

            // get time of prayer that follows this one. isha will have fajr tomorrow
            var nextPrayer = Prayer.fajr
            var nextTime = manager.tomorrowTimes.fajr
            if iterationPrayer != .isha {
                nextPrayer = Prayer(index: pIndex + 1)
                nextTime = manager.todayTimes.time(for: nextPrayer)
            }

            appendHeadsUpIfNeeded(before: prayerDate)

            // create single entry for prayer to be triggered on prayerDate.
            // High relevance + a decay window: Smart Stack should treat this as
            // most relevant right as the prayer switches in.
            let entry = AthanEntry(date: prayerDate,
                                   currentPrayer: iterationPrayer,
                                   currentPrayerDate: prayerDate,
                                   nextPrayerDate: nextTime,
                                   todayPrayerTimes: todayTimesArray,
                                   relevance: TimelineEntryRelevance(score: EntryRelevance.High.rawValue, duration: relevanceWindow),
                                   gradient: Gradient(colors: [pColors.0, pColors.1]))
            entries.append(entry)
        }

        // now add times for tomorrow up til maghrib time
        // note that after first day of updates, we will only ever be preparing the next day's timeline
        for tomorrowPIndex in 0..<5 {
            let iterationPrayer = Prayer(index: tomorrowPIndex)
            let prayerDate = manager.tomorrowTimes.time(for: iterationPrayer)
            let pColors = manager.appearanceSettings.colors(for: useDynamicColors ? iterationPrayer : nil)

            // get time of prayer that follows this one
            // will NOT have to worry about isha -> tomorrow since tomorrowPIndex never goes to 5
            let nextPrayer = Prayer(index: tomorrowPIndex + 1)
            let nextTime = manager.tomorrowTimes.time(for: nextPrayer)

            appendHeadsUpIfNeeded(before: prayerDate)

            let entry = AthanEntry(date: prayerDate,
                                   currentPrayer: iterationPrayer,
                                   currentPrayerDate: prayerDate,
                                   nextPrayerDate: nextTime,
                                   todayPrayerTimes: tomorrowTimesArray,
                                   relevance: TimelineEntryRelevance(score: EntryRelevance.High.rawValue, duration: relevanceWindow),
                                   gradient: Gradient(colors: [pColors.0, pColors.1]))
            entries.append(entry)
            // no worry for type == isha, since tomorrow's entries only go up to maghrib
        }
        print("--- WIDGET TIMELINE ---")
        entries.map { "\($0.currentPrayer) - \($0.date) -> \($0.nextPrayerDate)" }.forEach {
            print($0)
        }
        print("^^^ WIDGET TIMELINE ^^^")
        // .atEnd means that the timeline will request new timeline info on the date of the last timeline entry
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
        
    }
}
