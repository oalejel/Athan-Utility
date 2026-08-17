//
//  WidgetPreviews.swift
//  Athan Utility
//
//  Faithful, live SwiftUI previews of the app's widgets, shown in the
//  "Home & Lock Screen Widgets" discovery detail page so users can see what
//  they'd get. These mirror the real widget layouts using live prayer data;
//  they are illustrations, not the WidgetKit views themselves.
//

import SwiftUI
import Adhan

private struct WidgetPreviewData {
    let current: Prayer
    let next: Prayer
    let nextDate: Date

    static var live: WidgetPreviewData {
        let m = AthanManager.shared
        let cur = m.currentPrayer ?? .dhuhr
        let nxt = cur.next()
        let nd = m.todayTimes?.time(for: nxt) ?? Date().addingTimeInterval(60 * 73)
        return WidgetPreviewData(current: cur, next: nxt, nextDate: nd)
    }
}

private let widgetNightGradient = LinearGradient(
    colors: [Color(red: 0.09, green: 0.13, blue: 0.34),
             Color(red: 0.20, green: 0.13, blue: 0.42)],
    startPoint: .topLeading, endPoint: .bottomTrailing)

/// Formats a time in the location's timezone (not the device's) so previews look
/// right even when the demo/preview location differs from the device.
private func widgetPreviewTime(_ date: Date) -> String {
    let df = DateFormatter()
    df.timeStyle = .short
    df.timeZone = AthanManager.shared.locationSettings.timeZone
    return df.string(from: date)
}

/// Horizontal gallery of widget previews for the discovery detail page.
struct WidgetPreviewGallery: View {
    private let data = WidgetPreviewData.live

    var body: some View {
        // A collection rather than a horizontal strip: every widget is visible at once,
        // so the sizes can be compared without scrolling and nothing hides off-screen.
        // Adaptive columns mean this works both in the narrow Settings sheet and in the
        // wider discovery detail without separate layouts.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)],
                  alignment: .center, spacing: 20) {
            shot("widget_home_small_shot",
                 NSLocalizedString("widget_preview_home_small", value: "Home Screen", comment: ""))
            shot("widget_home_medium_shot",
                 NSLocalizedString("widget_preview_home_medium", value: "Home Screen", comment: ""))
            shot("widget_lock_wide_shot",
                 NSLocalizedString("widget_preview_lock", value: "Lock Screen", comment: ""))
            shot("widget_lock_small_shot",
                 NSLocalizedString("widget_preview_lock", value: "Lock Screen", comment: ""))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private func shot(_ asset: String, _ label: String) -> some View {
        labeled(label) {
            Image(asset)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                .accessibilityLabel(Text(label))
        }
    }

    @ViewBuilder
    private func labeled<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 10) {
            content()
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

private struct SmallWidgetPreview: View {
    let data: WidgetPreviewData
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                (Text(data.nextDate, style: .relative) + Text(" \(Strings.left)"))
                    .foregroundColor(Color(.lightText))
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
            PrayerSymbol(prayerType: data.current)
                .foregroundColor(.white)
                .font(.subheadline)
            Text(data.current.localizedOrCustomString())
                .foregroundColor(.white)
                .font(.title2).fontWeight(.bold)
                .lineLimit(1).minimumScaleFactor(0.5)
            HStack(spacing: 0) {
                Text(data.next.localizedOrCustomString())
                    .foregroundColor(Color(.lightText))
                Text("  ")
                Text(widgetPreviewTime(data.nextDate))
                    .foregroundColor(Color(.lightText))
            }
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1).minimumScaleFactor(0.5)
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(widgetNightGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MediumWidgetPreview: View {
    let data: WidgetPreviewData
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .lastTextBaseline) {
                Text(data.current.localizedOrCustomString())
                    .foregroundColor(.white).font(.title2).fontWeight(.bold)
                (Text(data.nextDate, style: .relative) + Text(" \(Strings.left)"))
                    .foregroundColor(Color(.lightText))
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                Spacer()
                PrayerSymbol(prayerType: data.current)
                    .foregroundColor(.white).font(.subheadline)
            }
            HStack(alignment: .top, spacing: 18) {
                column(0..<3)
                column(3..<6)
            }
            .font(.system(size: 15, weight: .bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(widgetNightGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func column(_ range: Range<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(range, id: \.self) { i in
                let p = Prayer(index: i)
                HStack {
                    Text(p.localizedOrCustomString())
                    Spacer()
                    Text(widgetPreviewTime(AthanManager.shared.todayTimes?.time(for: p) ?? Date()))
                }
                .foregroundColor(color(for: i))
                .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for i: Int) -> Color {
        let cur = data.current.rawValue()
        if i == cur { return .green }
        return i < cur ? Color(.lightText) : .white
    }
}

private struct LockRectangularPreview: View {
    let data: WidgetPreviewData
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(data.current.localizedOrCustomString())
                    .fontWeight(.bold).lineLimit(1)
                PrayerSymbol(prayerType: data.current).font(.footnote)
                Spacer()
            }
            HStack(spacing: 0) {
                Text(data.next.localizedOrCustomString())
                Text(" ")
                Text(widgetPreviewTime(data.nextDate))
            }
            .font(.footnote.weight(.bold)).lineLimit(1)
            (Text(data.nextDate, style: .relative) + Text(" \(Strings.left)"))
                .font(.caption2.weight(.bold)).lineLimit(1)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
