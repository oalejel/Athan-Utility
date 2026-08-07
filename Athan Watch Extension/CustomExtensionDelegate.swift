//
//  CustomExtensionDelegate.swift
//  Athan Watch
//
//  Created by Omar Al-Ejel on 1/15/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import WatchKit
import ClockKit
import Adhan

class CustomExtensionDelegate: NSObject, WKApplicationDelegate {

    func applicationDidFinishLaunching() {
        // Keep complications fresh even when the app isn't opened.
        scheduleNextBackgroundRefresh()
    }

    func handle(_ userActivity: NSUserActivity) {
        // can tell if user launched from complication
    }

    func applicationWillEnterForeground() {
        AthanManager.shared.movedToForeground()
    }

    func applicationDidBecomeActive() {
        WatchSessionDelegate.shared.requestUpdateFromPhone()
        reloadComplications()
        scheduleNextBackgroundRefresh()
    }

    // MARK: - Background refresh

    /// System-scheduled wake-up: refresh prayer data, reload the complication
    /// timeline so it advances, and schedule the next wake-up.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                AthanManager.shared.refreshTimes()
                reloadComplications()
                scheduleNextBackgroundRefresh()
                refreshTask.setTaskCompletedWithSnapshot(false)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    /// Reload every active complication timeline (safe to call from any of the
    /// refresh paths; ClockKit coalesces within its budget).
    func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { server.reloadTimeline(for: $0) }
    }

    /// Wake the app around the next prayer so the timeline is reloaded before it
    /// runs out (getTimelineEndDate only reaches tomorrow's Maghrib).
    private func scheduleNextBackgroundRefresh() {
        let m = AthanManager.shared
        let now = Date()
        let candidates = (Prayer.allCases.compactMap { m.todayTimes?.time(for: $0) }
                          + Prayer.allCases.compactMap { m.tomorrowTimes?.time(for: $0) })
            .filter { $0 > now }
            .sorted()
        // Next prayer, or a couple hours out if we somehow have no future times.
        let base = candidates.first ?? now.addingTimeInterval(2 * 60 * 60)
        let when = max(base, now.addingTimeInterval(15 * 60)) // never schedule in the past
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: when, userInfo: nil) { error in
            if let error = error {
                print("bg refresh schedule error: \(error)")
            }
        }
    }
}
