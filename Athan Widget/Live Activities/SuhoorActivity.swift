//
//  SuhoorActivity.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 2/17/26.
//  Copyright © 2026 Omar Alejel. All rights reserved.
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit
#if canImport(AlarmKit)
import AlarmKit
#endif


@available(iOS 16.1, *)
struct SuhoorActivityView: View {
    let context: ActivityViewContext<SuhoorActivityAttributes>
    let customColorPair = ObservableAthanManager.shared.appearance.colors(for: .isha)
    
    var body: some View {

        ZStack {
            LinearGradient(gradient: .init(colors: [customColorPair.0, customColorPair.1]), startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundColor(.yellow)
                        .font(.headline)
                        .frame(width: 16, alignment: .center)
                    Text("Suhoor ends in ")
                        .font(.headline)
                        .foregroundColor(.white)
//                    + Text(context.state.fajrTime, style: .timer)
                    Text(timerInterval: Date()...context.state.fajrTime)
                        .font(.headline)
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundColor(.yellow)
                    Spacer()
                }
                .strikethrough(context.state.fajrTime.timeIntervalSinceNow < 0)
                
                HStack {
                    Image(systemName: "sunrise.fill")
                        .foregroundColor(.yellow)
                        .font(.headline)
                        .frame(width: 16, alignment: .center)
                    Group {
                        Text("Fajr at ")
                            .foregroundColor(.white)
                        + Text(context.state.fajrTime, style: .time)
                            .foregroundColor(.white)
                        + Text(" in ")
                            .foregroundColor(.gray)
                        + Text(context.state.locationName)
                            .foregroundColor(.gray)

                    }

                    .font(.headline)
                    .bold()
                    .fontDesign(.rounded)

                    Spacer()
                    Image("kaba")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20,
                               height: 20,
                               alignment: .center)
                        .opacity(0.7)
                }
                
                TimelineView(.periodic(from: .now, by: 30)) { _ in
                    let total = context.state.fajrTime.timeIntervalSince(context.state.suhoorTime)
                    let remaining = max(0, context.state.fajrTime.timeIntervalSince(Date()))
                    let progress = total > 0 ? min(1.0, max(0.0, 1.0 - (remaining / total))) : 0

                    // 10 mins left = urgent
                    let isUrgent = remaining < 600
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: geo.size.width, height: 4)
                            Capsule()
                                .fill(isUrgent ? Color.red : Color.white)
                                .frame(width: geo.size.width * CGFloat(progress), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                
            }
            .padding()

        }
    }
}



@available(iOS 16.1, *)
struct SuhoorLiveActivity: Widget {
    let customColorPair = ObservableAthanManager.shared.appearance.colors(for: .isha)

    
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SuhoorActivityAttributes.self) { context in
            // Lock screen / banner
            SuhoorActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
//                    Label("Suhoor", systemImage: "")
//                        .foregroundColor(.yellow)
//                        .fontDesign(.rounded)
//                        .font(.headline)
                    Label("ATHAN", systemImage: "")
                        .foregroundColor(.gray)
                        .fontDesign(.rounded)
                        .font(.headline)
                        .bold()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image("kaba")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20,
                               height: 20,
                               alignment: .center)
                        .opacity(0.5)
                        .padding(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                        VStack {
                            HStack {
                                Image(systemName: "hourglass")
                                    .foregroundColor(.yellow)
                                    .font(.headline)
                                    .frame(width: 16, alignment: .center)
                                Text("Suhoor ends in ")
                                    .font(.headline)
                                    .foregroundColor(.white)
//                                + Text(context.state.fajrTime, style: .timer)
                                + Text(timerInterval: Date()...context.state.fajrTime)
                                    .font(.headline)
                                    .bold()
                                    .fontDesign(.rounded)
                                    .foregroundColor(.yellow)
                                Spacer()
                            }
                            .strikethrough(context.state.fajrTime.timeIntervalSinceNow < 0)
                            .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "sunrise.fill")
                                    .foregroundColor(.yellow)
                                    .font(.headline)
                                    .frame(width: 16, alignment: .center)
                                Group {
                                    Text("Fajr at ")
                                        .foregroundColor(.white)
                                    + Text(context.state.fajrTime, style: .time)
                                        .foregroundColor(.white)
                                    + Text(" in ")
                                        .foregroundColor(.gray)
                                    + Text(context.state.locationName)
                                        .foregroundColor(.gray)

                                }

                                .font(.headline)
                                .bold()
                                .fontDesign(.rounded)

                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            TimelineView(.periodic(from: .now, by: 30)) { _ in
                                let total = context.state.fajrTime.timeIntervalSince(context.state.suhoorTime)
                                let remaining = max(0, context.state.fajrTime.timeIntervalSince(Date()))
                                let progress = total > 0 ? min(1.0, max(0.0, 1.0 - (remaining / total))) : 0
                                
                                // 10 mins left = urgent
                                let isUrgent = remaining < 600
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: geo.size.width, height: 4)
                                        Capsule()
                                            .fill(isUrgent ? Color.red : Color.white)
                                            .frame(width: geo.size.width * CGFloat(progress), height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                            
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(colors: [.clear, customColorPair.1], startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                        )

                    
                    
                }
            } compactLeading: {
                Image(systemName: "sunrise.fill")
                    .foregroundColor(.yellow)
                    .font(.headline)
                    .padding(.horizontal, 4)
            } compactTrailing: {
//                Text(context.state.fajrTime, style: .timer)
                Text(timerInterval: Date()...context.state.fajrTime)
                    .foregroundColor(.yellow)
                    .font(.caption2.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .frame(width: 44)
                    

//                + Text(" left")
//                    .foregroundColor(.yellow)
//                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "hourglass")
            }
        }
    }

}

// MARK: - Fajr Alarm (AlarmKit) Live Activity
//
// AlarmKit requires apps that use `secondaryButtonBehavior: .countdown` to
// register a Live Activity for `AlarmAttributes<FajrAlarmMetadata>` so the
// system can render the snooze countdown on the Lock Screen, in the Dynamic
// Island, and in StandBy. The UI is intentionally minimal — AlarmKit drives
// the actual countdown timer; we just provide labels and a tint.

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct FajrAlarmLiveActivity: Widget {
    // Matches the tint passed to AlarmAttributes in FajrAlarmManager.
    private let tint = Color(red: 4.0/255.0, green: 65.0/255.0, blue: 125.0/255.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<FajrAlarmMetadata>.self) { context in
            // Lock screen / banner
            HStack(spacing: 12) {
                Image(systemName: "alarm.fill")
                    .font(.title2)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.metadata?.prayerName ?? "")
                        .font(.headline)
                    if let locationName = context.attributes.metadata?.locationName,
                       !locationName.isEmpty {
                        Text(locationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .foregroundStyle(tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.metadata?.prayerName ?? "")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.center) {
                    if let locationName = context.attributes.metadata?.locationName,
                       !locationName.isEmpty {
                        Text(locationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tint)
            } compactTrailing: {
                Text(context.attributes.metadata?.prayerName ?? "")
                    .font(.caption)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tint)
            }
        }
    }
}
#endif
