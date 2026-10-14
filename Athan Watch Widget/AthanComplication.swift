//
//  AthanComplication.swift
//  Athan Watch Widget
//
//  WidgetKit watch complications. These replace the ClockKit complication
//  (ComplicationController), which newer watchOS releases no longer render — faces
//  carrying it show placeholder dashes. ComplicationController's widgetMigrator maps
//  existing ClockKit complications onto `AthanComplication.kind` so they upgrade in place.
//

import WidgetKit
import SwiftUI
import Adhan

// MARK: - Timeline

struct AthanComplicationEntry: TimelineEntry {
    let date: Date
    /// The prayer whose time we are in, and when it began.
    let currentPrayer: Prayer
    let currentPrayerDate: Date
    /// The prayer coming up, and when it begins.
    let nextPrayer: Prayer
    let nextPrayerDate: Date
}

struct AthanComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> AthanComplicationEntry {
        entry(at: Date()) ?? Self.sample
    }

    func getSnapshot(in context: Context, completion: @escaping (AthanComplicationEntry) -> Void) {
        completion(entry(at: Date()) ?? Self.sample)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AthanComplicationEntry>) -> Void) {
        let now = Date()
        // One entry now, then one at every prayer for several days. Each entry is computed
        // around its own date, so a watch that misses reloads still shows the right prayer.
        let dates = [now] + futurePrayerTimes(after: now, days: 4)
        let entries = dates.compactMap { entry(at: $0) }
        // .atEnd asks for a fresh timeline once the last prayer passes; the watch app also
        // reloads timelines whenever its location or settings change.
        completion(Timeline(entries: entries.isEmpty ? [Self.sample] : entries, policy: .atEnd))
    }

    // MARK: Prayer math

    private static var sample: AthanComplicationEntry {
        let now = Date()
        return AthanComplicationEntry(date: now, currentPrayer: .asr, currentPrayerDate: now.addingTimeInterval(-3600),
                                      nextPrayer: .maghrib, nextPrayerDate: now.addingTimeInterval(5400))
    }

    private func times(for day: Date) -> PrayerTimes? {
        // Settings are re-read from the shared app group on every call: the watch app
        // writes them there, and this extension process can outlive several changes.
        let location = LocationSettings.checkArchive() ?? LocationSettings.shared
        let prayer = PrayerSettings.checkArchive() ?? PrayerSettings.shared
        let notes = NotificationSettings.checkArchive() ?? NotificationSettings.shared
        return calculatePrayerTimes(referenceDate: day,
                                    coordinate: location.locationCoordinate,
                                    timeZone: nil,
                                    prayerSettings: prayer,
                                    adjustments: notes.adjustments())
    }

    /// Prayer times strictly after `date`, covering `days` days forward.
    private func futurePrayerTimes(after date: Date, days: Int) -> [Date] {
        let calendar = Calendar.current
        var result: [Date] = []
        for offset in 0...days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date),
                  let dayTimes = times(for: day) else { continue }
            result += Prayer.allCases.map { dayTimes.time(for: $0) }
        }
        return result.filter { date < $0 }.sorted()
    }

    /// The current and next prayer at `date`. Yesterday and tomorrow are included so that
    /// before Fajr the current prayer is yesterday's Isha, and after Isha the next is
    /// tomorrow's Fajr.
    func entry(at date: Date) -> AthanComplicationEntry? {
        let calendar = Calendar.current
        var all: [Date] = []
        for offset in [-1, 0, 1] {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date),
                  let dayTimes = times(for: day) else { return nil }
            all += Prayer.allCases.map { dayTimes.time(for: $0) }
        }
        guard let nextIndex = all.firstIndex(where: { date < $0 }), nextIndex > 0 else { return nil }
        let next = Prayer.allCases[nextIndex % 6] // 6 per day, so % 6 maps back onto the cases
        return AthanComplicationEntry(date: date,
                                      currentPrayer: next.previous(),
                                      currentPrayerDate: all[nextIndex - 1],
                                      nextPrayer: next,
                                      nextPrayerDate: all[nextIndex])
    }
}

// MARK: - Views

struct AthanComplicationView: View {
    @Environment(\.widgetFamily) private var environmentFamily
    let entry: AthanComplicationEntry
    /// Lets a caller outside WidgetKit (where the environment family isn't set) pick the layout.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }
    /// True where the face draws a curved label around a circular complication.
    @Environment(\.showsWidgetLabel) private var environmentShowsLabel
    var showsLabelOverride: Bool? = nil
    private var showsWidgetLabel: Bool { showsLabelOverride ?? environmentShowsLabel }

    private var showsSymbol: Bool { entry.nextPrayer == .sunrise || entry.nextPrayer == .maghrib }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryCorner:
            corner
        case .accessoryInline:
            inline
        default:
            rectangular
        }
    }

    /// Next prayer's name (or a sunrise/sunset symbol) over its time. On faces that curve a
    /// label around the circle (Infograph's bezel), this switches to what the ClockKit bezel
    /// complication showed for years: the current prayer's symbol in the circle and
    /// "Maghrib 6:42 PM · 1 hr, 20 min" — including the time left — along the curve.
    @ViewBuilder private var circular: some View {
        if showsWidgetLabel {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.currentPrayer.sfSymbolName())
                    .font(.system(size: 18, weight: .bold))
                    .widgetAccentable()
            }
            .widgetLabel {
                Text("\(entry.nextPrayer.localizedOrCustomString()) \(Text(entry.nextPrayerDate, style: .time)) · \(Text(entry.nextPrayerDate, style: .relative))")
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    if showsSymbol {
                        Image(systemName: entry.nextPrayer == .sunrise ? "sunrise.fill" : "sunset.fill")
                            .font(.system(size: 14, weight: .semibold))
                    } else {
                        Text(entry.nextPrayer.localizedOrCustomString())
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Text(shortTime(entry.nextPrayerDate))
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .widgetAccentable()
                }
                .padding(2)
            }
        }
    }

    /// Current prayer in the corner, "Next at 4:30" along the curve.
    private var corner: some View {
        Text(entry.currentPrayer.localizedOrCustomString())
            .font(.system(size: 14, weight: .semibold))
            .widgetAccentable()
            .widgetLabel {
                Text("\(entry.nextPrayer.localizedOrCustomString()) \(Text(entry.nextPrayerDate, style: .time))")
            }
    }

    /// "Maghrib 6:42 PM"
    private var inline: some View {
        Text("\(entry.nextPrayer.localizedOrCustomString()) \(Text(entry.nextPrayerDate, style: .time))")
    }

    /// "Asr • 1 hr, 12 min left", a progress gauge through the current prayer, then the next prayer.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .font(.headline)
                    .widgetAccentable()
                Text(entry.nextPrayerDate, style: .timer)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            ProgressView(timerInterval: entry.currentPrayerDate...entry.nextPrayerDate, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(watchColorsForPrayer(entry.currentPrayer).last ?? .accentColor)
            .widgetAccentable()
            HStack(spacing: 4) {
                Text(entry.nextPrayer.localizedOrCustomString())
                Text(entry.nextPrayerDate, style: .time)
            }
            .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("j:mm")
        // Drop the AM/PM marker so the time fits inside the circle.
        f.amSymbol = ""
        f.pmSymbol = ""
        return f.string(from: date).trimmingCharacters(in: .whitespaces)
    }
}

private extension View {
    /// watchOS 10+ requires widgets to declare their background; 9 has no such API.
    @ViewBuilder func clearWidgetBackground() -> some View {
        if #available(watchOS 10.0, *) {
            containerBackground(for: .widget) { Color.clear }
        } else {
            self
        }
    }
}

// MARK: - Widget

struct AthanComplication: Widget {
    /// Referenced by ComplicationController's ClockKit → WidgetKit migration. Do not change.
    static let kind = "AthanComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: AthanComplicationProvider()) { entry in
            AthanComplicationView(entry: entry)
                .clearWidgetBackground()
        }
        .configurationDisplayName("Athan Utility")
        .description(NSLocalizedString("watch_complication_description",
                                       value: "The current prayer and the time of the next one.",
                                       comment: "Watch complication gallery description"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct AthanWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        AthanComplication()
    }
}
