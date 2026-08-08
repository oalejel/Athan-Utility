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
        .sheet(item: $activeSheet) { sheetContent(for: $0) }
    }

    // Done features flow as compact pills, two per row, left-aligned.
    private var pillRows: some View {
        let rows = chunk(doneList, by: 2)
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row) { pill($0) }
                    Spacer(minLength: 0)
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
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(f.tint))
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
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundColor(.white)
                Text(f.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(f.tint))
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
