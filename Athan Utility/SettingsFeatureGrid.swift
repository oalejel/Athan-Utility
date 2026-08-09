//
//  SettingsFeatureGrid.swift
//  Athan Utility
//
//  A 2x2 grid at the top of Settings advertising four key features. Tapping a tile opens
//  that feature and marks it "checked out" — the square then collapses into a compact
//  title + checkmark pill (matchedGeometry shrink), so the grid fills up as the user explores.
//

import SwiftUI

enum AdoptedFeature: String, CaseIterable, Identifiable {
    case widgets, lockWidgets, siri, calendar
    var id: String { rawValue }

    var title: String {
        switch self {
        case .widgets:     return NSLocalizedString("adopt_widgets_title", value: "Widgets", comment: "")
        case .lockWidgets: return NSLocalizedString("adopt_lock_title", value: "Lock Screen", comment: "")
        case .siri:        return NSLocalizedString("adopt_siri_title", value: "Siri Shortcut", comment: "")
        case .calendar:    return NSLocalizedString("adopt_calendar_title", value: "Calendar", comment: "")
        }
    }
    var subtitle: String {
        switch self {
        case .widgets:     return NSLocalizedString("adopt_widgets_sub", value: "Add to your Home Screen", comment: "")
        case .lockWidgets: return NSLocalizedString("adopt_lock_sub", value: "Glance without unlocking", comment: "")
        case .siri:        return NSLocalizedString("adopt_siri_sub", value: "Ask Siri for prayer times", comment: "")
        case .calendar:    return NSLocalizedString("adopt_calendar_sub", value: "Add Salah times to your calendar", comment: "")
        }
    }
    var icon: String {
        switch self {
        case .widgets:     return "square.grid.2x2.fill"
        case .lockWidgets: return "lock.fill"
        case .siri:        return "waveform"
        case .calendar:    return "calendar.badge.plus"
        }
    }
    var tint: Color {
        switch self {
        case .widgets:     return Color(.systemBlue)
        case .lockWidgets: return Color(.systemIndigo)
        case .siri:        return Color(.systemPurple)
        case .calendar:    return Color(.systemOrange)
        }
    }

    /// Vibrant 3-color gradient, unique per feature but all keyed off the app's blue-sky palette.
    var gradientColors: [Color] {
        switch self {
        case .widgets:     return [Self.c(0x2E6BFF), Self.c(0x27B6FF), Self.c(0x18D6C6)] // sky → cyan → teal
        case .lockWidgets: return [Self.c(0x4B5CFF), Self.c(0x7A4BFF), Self.c(0x2E9BFF)] // indigo → violet → blue
        case .siri:        return [Self.c(0x8A4BFF), Self.c(0xE24BC0), Self.c(0x4B7BFF)] // purple → magenta → blue
        case .calendar:    return [Self.c(0xFF9A3D), Self.c(0xFFC24D), Self.c(0xFF5D7A)] // amber → gold → coral
        }
    }

    private static func c(_ hex: UInt) -> Color {
        Color(.sRGB,
              red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }

    // Persistence (shared app-group defaults so it survives relaunches).
    private static let defaultsKey = "adoptedFeaturesV1"
    private static var store: UserDefaults? { UserDefaults(suiteName: "group.athanUtil") }
    static func loadDone() -> Set<AdoptedFeature> {
        let raw = store?.stringArray(forKey: defaultsKey) ?? []
        return Set(raw.compactMap { AdoptedFeature(rawValue: $0) })
    }
    static func saveDone(_ s: Set<AdoptedFeature>) {
        store?.set(s.map { $0.rawValue }, forKey: defaultsKey)
    }
}

@available(iOS 14.0, *)
struct SettingsFeatureGrid: View {
    @State private var done: Set<AdoptedFeature>
    @State private var activeSheet: AdoptedFeature?
    @Namespace private var ns

    init() { _done = State(initialValue: AdoptedFeature.loadDone()) }

    private var undone: [AdoptedFeature] { AdoptedFeature.allCases.filter { !done.contains($0) } }
    private var doneList: [AdoptedFeature] { AdoptedFeature.allCases.filter { done.contains($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !doneList.isEmpty {
                pillRows
            }
            if !undone.isEmpty {
                squareRows
            }
        }
        // Force dark so the detail sheets stay readable regardless of system light/dark.
        .sheet(item: $activeSheet) { sheetContent(for: $0).preferredColorScheme(.dark) }
    }

    private func tileBackground(_ f: AdoptedFeature) -> some View {
        GlowingTileBackground(colors: f.gradientColors)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // Done features become half-width tiles (2 per row) with a right disclosure on the far edge.
    private var pillRows: some View {
        let rows = chunk(doneList, by: 2)
        return VStack(spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { pill($0) }
                    if row.count == 1 { Color.clear.frame(maxWidth: .infinity) }
                }
            }
        }
    }

    // Undone features are square tiles, two per row filling the width.
    private var squareRows: some View {
        let rows = chunk(undone, by: 2)
        return VStack(spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { square($0) }
                    if row.count == 1 { Color.clear.frame(maxWidth: .infinity) }
                }
            }
        }
    }

    private func square(_ f: AdoptedFeature) -> some View {
        Button { activate(f) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: f.icon).font(.system(size: 22, weight: .semibold)).foregroundColor(.white)
                Spacer(minLength: 6)
                Text(f.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(f.subtitle).font(.system(size: 11.5)).foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(14)
            .background(tileBackground(f))
            .overlay(
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(10),
                alignment: .topTrailing
            )
        }
        .buttonStyle(PlainButtonStyle())
        .matchedGeometryEffect(id: f.id, in: ns)
    }

    private func pill(_ f: AdoptedFeature) -> some View {
        Button { activate(f) } label: {
            HStack(spacing: 8) {
                Text(f.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                Spacer(minLength: 6)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.92))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.vertical, 15)
            .background(tileBackground(f))
        }
        .buttonStyle(PlainButtonStyle())
        .matchedGeometryEffect(id: f.id, in: ns)
    }

    private func activate(_ f: AdoptedFeature) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            done.insert(f)
        }
        AdoptedFeature.saveDone(done)
        ExploreSettingsNudge.cancel() // user explored a feature — no need for the nudge anymore
        activeSheet = f
    }

    private func chunk(_ items: [AdoptedFeature], by n: Int) -> [[AdoptedFeature]] {
        stride(from: 0, to: items.count, by: n).map { Array(items[$0..<min($0 + n, items.count)]) }
    }

    @ViewBuilder private func sheetContent(for f: AdoptedFeature) -> some View {
        switch f {
        case .calendar:    CalendarExportView()
        case .siri:        SiriShortcutSheet()
        case .widgets:     WidgetHowToView(kind: .home)
        case .lockWidgets: WidgetHowToView(kind: .lock)
        }
    }
}

// MARK: - Glowing tile background

/// Three soft, slowly-moving colored glows over a dark base — a calm "lava lamp" fill that
/// keeps white text legible (not a flat, over-bright linear gradient).
@available(iOS 14.0, *)
private struct GlowingTileBackground: View {
    let colors: [Color]
    @State private var animate = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color(.sRGB, red: 0.05, green: 0.08, blue: 0.15, opacity: 1)   // dark base
                blob(color(0), w: w, h: h, from: CGPoint(x: 0.22, y: 0.28), to: CGPoint(x: 0.68, y: 0.16))
                blob(color(1), w: w, h: h, from: CGPoint(x: 0.82, y: 0.72), to: CGPoint(x: 0.34, y: 0.86))
                blob(color(2), w: w, h: h, from: CGPoint(x: 0.5,  y: 0.95), to: CGPoint(x: 0.55, y: 0.42))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) { animate = true }
        }
    }

    private func color(_ i: Int) -> Color { colors.indices.contains(i) ? colors[i] : (colors.first ?? .blue) }

    private func blob(_ c: Color, w: CGFloat, h: CGFloat, from: CGPoint, to: CGPoint) -> some View {
        let d = max(w, h) * 0.95
        let p = animate ? to : from
        return Circle()
            .fill(RadialGradient(gradient: Gradient(colors: [c.opacity(0.55), c.opacity(0)]),
                                 center: .center, startRadius: 0, endRadius: d * 0.5))
            .frame(width: d, height: d)
            .position(x: p.x * w, y: p.y * h)
            .blur(radius: 16)
    }
}

// MARK: - Widget how-to sheet

@available(iOS 14.0, *)
struct WidgetHowToView: View {
    enum Kind { case home, lock }
    let kind: Kind
    @Environment(\.presentationMode) private var presentationMode

    private var title: String {
        kind == .home
        ? NSLocalizedString("widgets_home_title", value: "Home Screen Widgets", comment: "")
        : NSLocalizedString("widgets_lock_title", value: "Lock Screen Widgets", comment: "")
    }
    private var steps: [String] {
        if kind == .home {
            return [
                NSLocalizedString("widgets_home_1", value: "Touch and hold an empty area of your Home Screen until the apps jiggle.", comment: ""),
                NSLocalizedString("widgets_home_2", value: "Tap the + button in the top corner.", comment: ""),
                NSLocalizedString("widgets_home_3", value: "Search for “Athan Utility” and pick a widget size.", comment: ""),
                NSLocalizedString("widgets_home_4", value: "Tap Add Widget, then Done.", comment: "")
            ]
        } else {
            return [
                NSLocalizedString("widgets_lock_1", value: "Touch and hold the Lock Screen, then tap Customize.", comment: ""),
                NSLocalizedString("widgets_lock_2", value: "Tap the area below the clock to add widgets.", comment: ""),
                NSLocalizedString("widgets_lock_3", value: "Choose “Athan Utility” to see the next prayer at a glance.", comment: "")
            ]
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: kind == .home ? "square.grid.2x2.fill" : "lock.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.accentColor))
                            Text(step).font(.body).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("done", value: "Done", comment: "")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Siri shortcut sheet

@available(iOS 14.0, *)
struct SiriShortcutSheet: View {
    @Environment(\.presentationMode) private var presentationMode

    private let phrases = [
        NSLocalizedString("siri_phrase_1", value: "“Next prayer time”", comment: ""),
        NSLocalizedString("siri_phrase_2", value: "“When is Maghrib?”", comment: ""),
        NSLocalizedString("siri_phrase_3", value: "“Athan times today”", comment: "")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "waveform")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(.purple)
                        .padding(.top, 10)
                    Text(NSLocalizedString("siri_sheet_title", value: "Ask Siri for prayer times", comment: ""))
                        .font(.title2.weight(.bold)).multilineTextAlignment(.center)
                    Text(NSLocalizedString("siri_sheet_body", value: "Add a shortcut, then just ask Siri hands-free.", comment: ""))
                        .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)

                    IntentIntegratedController()
                        .frame(height: 60)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(phrases, id: \.self) { p in
                            HStack(spacing: 8) {
                                Image(systemName: "quote.bubble.fill").foregroundColor(.purple.opacity(0.7))
                                Text(p).font(.callout)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                    .padding(.horizontal)

                    Spacer(minLength: 10)
                }
                .padding(.bottom)
            }
            .navigationBarTitle(NSLocalizedString("siri_sheet_nav", value: "Siri Shortcut", comment: ""), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("done", value: "Done", comment: "")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
