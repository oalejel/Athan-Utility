//
//  SuhoorActivityTrigger.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 2/17/26.
//  Copyright © 2026 Omar Alejel. All rights reserved.
//

import Foundation
import ActivityKit

@available(iOS 16.2, *)
func startSuhoorLiveActivity(activityStart: Date, fajrTime: Date, locationName: String) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    // end existing
    Task {
        
        
        // If any Suhoor activity is already active (or stale), do not request another.
        if Activity<SuhoorActivityAttributes>.activities.contains(where: { activity in
            switch activity.activityState {
            case .active, .stale:
                // only return true for exact location matches
                if activity.content.state.locationName == locationName && activity.content.state.fajrTime == fajrTime {
                    return true
                }
                return false
            default:
                return false
            }
        }) {
            return
        }
        
        // otherwise, end all potentially redundant activities
        for activity in Activity<SuhoorActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
                
        // Ensure our target dates are in the future; if not, bail early.
        let now = Date()
        guard fajrTime > now else { return }
        
        let attributes = SuhoorActivityAttributes(activityName: "Suhoor Countdown")
        let state = SuhoorActivityAttributes.ContentState(
            suhoorTime: activityStart,
            fajrTime: fajrTime,
            locationName: locationName
        )
        // set stale 5 mins after fajr
        let staleDate = fajrTime.addingTimeInterval(5 * 60)
        let content = ActivityContent(
            state: state,
            staleDate: staleDate  // marks stale after suhoor passes
        )
        
        do {
            let activity = try Activity<SuhoorActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
}

@available(iOS 16.2, *)
func cleanupSuhoorActivity() {
    Task {
        for activity in Activity<SuhoorActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

