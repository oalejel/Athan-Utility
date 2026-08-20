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
            
            // NOT `.atEnd`: this timeline's single entry is dated now, so `.atEnd`
            // means "reload immediately" — the widget then re-requests in a tight
            // loop and burns its refresh budget, after which WidgetKit throttles it
            // and even an explicit reloadAllTimelines() from the app stops landing.
            // Retry on a fixed interval instead.
            let timeline = Timeline(entries: [openAppEntry],
                                    policy: .after(Date().addingTimeInterval(30 * 60)))
            completion(timeline)
            return
        }
        
        let useDynamicColors = manager.appearanceSettings.isDynamic
        let todayTimesArray = Prayer.allCases.map { manager.todayTimes.time(for: $0) }
        
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

        // Build a ROLLING WINDOW of days rather than "rest of today + part of
        // tomorrow". The old shape ended at tomorrow's maghrib and carried no isha
        // entry beyond it, so the widget depended on the single `.atEnd` reload
        // landing on time. iOS is free to defer that reload by hours (low power,
        // idle device, spent budget), and when it did the widget sat on a stale
        // prayer with nothing left in the timeline to advance it. Covering several
        // days means the timeline keeps stepping itself even when no reload arrives.
        var slots: [(date: Date, prayer: Prayer, dayTimes: [Date])] = []
        for dayOffset in 0...3 {
            let dayTimes: PrayerTimes?
            switch dayOffset {
            case 0: dayTimes = manager.todayTimes
            case 1: dayTimes = manager.tomorrowTimes
            default: dayTimes = manager.times(daysFromToday: dayOffset)
            }
            guard let dayTimes else { continue }
            let dayArray = Prayer.allCases.map { dayTimes.time(for: $0) }
            for prayer in Prayer.allCases {
                slots.append((dayTimes.time(for: prayer), prayer, dayArray))
            }
        }
        // Sorted so a day boundary (or a DST shift) can't produce out-of-order
        // entries — WidgetKit's behaviour on an unsorted timeline is undefined.
        slots.sort { $0.date < $1.date }

        let now = Date()
        for (i, slot) in slots.enumerated() where slot.date > now {
            // The next prayer is simply the next slot, so isha -> next day's fajr
            // falls out of the ordering instead of needing its own special case.
            let nextDate = i + 1 < slots.count
                ? slots[i + 1].date
                : slot.date.addingTimeInterval(60 * 60)
            let pColors = manager.appearanceSettings.colors(for: useDynamicColors ? slot.prayer : nil)

            appendHeadsUpIfNeeded(before: slot.date)

            // High relevance + a decay window: Smart Stack should treat this as
            // most relevant right as the prayer switches in.
            entries.append(AthanEntry(date: slot.date,
                                      currentPrayer: slot.prayer,
                                      currentPrayerDate: slot.date,
                                      nextPrayerDate: nextDate,
                                      todayPrayerTimes: slot.dayTimes,
                                      relevance: TimelineEntryRelevance(score: EntryRelevance.High.rawValue, duration: relevanceWindow),
                                      gradient: Gradient(colors: [pColors.0, pColors.1])))
        }

        print("--- WIDGET TIMELINE ---")
        entries.map { "\($0.currentPrayer) - \($0.date) -> \($0.nextPrayerDate)" }.forEach {
            print($0)
        }
        print("^^^ WIDGET TIMELINE ^^^")
        // Ask for a fresh timeline twice a day rather than `.atEnd`. The window above
        // now runs several days out, so `.atEnd` would mean asking only once every
        // few days — too rare to pick up a location change, a DST shift or a method
        // change on its own. A periodic request stays far inside WidgetKit's refresh
        // budget, and if the system defers one, the entries already on the timeline
        // keep the widget correct in the meantime.
        let timeline = Timeline(entries: entries,
                                policy: .after(Date().addingTimeInterval(12 * 60 * 60)))
        completion(timeline)
        
    }
}
