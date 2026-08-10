//
//  DebugSettingsView.swift
//  Athan Utility
//
//  Developer-only tools, reachable from Settings in DEBUG builds:
//  flush caches, refresh user settings, and reset local UI state.
//

import SwiftUI
import WidgetKit

@available(iOS 13.0.0, *)
struct DebugSettingsView: View {
    @Binding var isVisible: Bool
    @State private var lastAction: String = ""

    private let bg = Color(.sRGB, red: 0.06, green: 0.09, blue: 0.16, opacity: 1)

    var body: some View {
        ZStack {
            bg.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { isVisible = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(Font.system(size: 25).bold())
                    }
                }
                .padding([.leading, .trailing, .top])

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "ladybug.fill")
                            .font(Font.largeTitle.bold())
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                        Text("Debug Tools")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)

                        if !lastAction.isEmpty {
                            Text(lastAction)
                                .font(.footnote)
                                .foregroundColor(.green)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        row("Flush Caches", "trash.fill", "Clears URL cache + reloads all widget timelines.") {
                            URLCache.shared.removeAllCachedResponses()
                            WidgetCenter.shared.reloadAllTimelines()
                            return "Flushed URL cache and reloaded widgets."
                        }

                        row("Refresh User Settings", "arrow.clockwise", "Reloads settings from disk and reschedules notifications.") {
                            AthanManager.shared.reloadSettingsAndNotifications()
                            return "Reloaded settings and rescheduled notifications."
                        }

                        row("Reschedule Fajr Alarms", "alarm.fill", "Rebuilds the AlarmKit window (iOS 26+).") {
                            FajrAlarmManager.shared.syncAlarms()
                            return "Requested a Fajr alarm resync."
                        }

                        row("Reset “Featured” Tiles", "square.grid.2x2.fill", "Marks all feature tiles unexplored again.") {
                            AdoptedFeature.saveDone([])
                            return "Reset explored feature tiles. Reopen Settings to see them."
                        }

                        row("Reload Widgets", "rectangle.3.group.fill", "Forces every widget timeline to refresh now.") {
                            WidgetCenter.shared.reloadAllTimelines()
                            return "Reloaded all widget timelines."
                        }

                        // Quick read-out of the current state — handy while debugging.
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current State").font(.headline).foregroundColor(.white).padding(.top, 8)
                            Text("Location: \(AthanManager.shared.locationSettings.locationName)")
                            Text("Method: \(AthanManager.shared.prayerSettings.calculationMethod.localizedString())")
                            Text("Fajr alarm enabled: \(FajrAlarmSettings.shared.enabled ? "yes" : "no")")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            }
        }
    }

    private func row(_ title: String, _ icon: String, _ subtitle: String, _ action: @escaping () -> String) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            lastAction = action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.white)
                    Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.white.opacity(0.08)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
