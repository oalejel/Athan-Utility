//
//  MacSidebarView.swift
//  Athan Utility (Mac Catalyst only)
//
//  The sidebar column of the Mac NavigationSplitView, styled to match the design mockup:
//  a translucent dark column with a tappable location header (expands to an inline editor),
//  the day's prayer list (current prayer gold-railed, per-prayer bell toggles), and a pinned
//  section-nav footer (Calendar / Settings / Discover) that swaps the detail pane.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit
import CoreLocation
import Adhan

@available(macCatalyst 16.0, *)
struct MacSidebarView: View {
    @Binding var section: MacSection
    @EnvironmentObject var manager: ObservableAthanManager

    @State private var showLocationEditor = false
    @State private var searchText = ""
    @State private var awaiting = false
    @State private var errored = false
    @State private var bellVersion = 0          // forces the (non-published) bell state to refresh
    @State private var dayOffset = 0            // 0 = today; prev/next-day browsing
    private let geocoder = CLGeocoder()

    private let gold = Color(red: 0.957, green: 0.835, blue: 0.553)   // #f4d58d
    private let navSections: [MacSection] = [.calendar, .settings, .discover]

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                locationHeader
                if showLocationEditor { locationEditor.transition(.opacity.combined(with: .move(edge: .top))) }
                sectionLabel(dayOffset == 0
                             ? NSLocalizedString("today", value: "Today", comment: "Sidebar prayer list header")
                             : NSLocalizedString("prayer_times", value: "Prayer Times", comment: "Sidebar prayer list header, non-today"))
                prayerList
                    .id("\(bellVersion)-\(dayOffset)")
                dayNavigator
                Spacer(minLength: 12)
            }
            .padding(.top, 10)
            .padding(.horizontal, 8)
        }
        .safeAreaInset(edge: .bottom) { navFooter }
        .background(darkVibrancy)
    }

    // MARK: - Location header + inline editor

    private var locationHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { showLocationEditor.toggle() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: manager.locationPermissionsGranted && LocationSettings.shared.useCurrentLocation
                      ? "location.fill" : "location.slash")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
                Text(manager.locationName.isEmpty ? "—" : manager.locationName)
                    .font(.system(size: 14.5, weight: .semibold)).foregroundColor(.white)
                    .lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 6)
                Image(systemName: showLocationEditor ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 10).padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var locationEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                TextField(NSLocalizedString("search_city", value: "Search city or coordinates", comment: ""),
                          text: $searchText, onCommit: commitSearch)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .autocorrectionDisabled(true)
                    .onChange(of: searchText) { _ in errored = false }
                if awaiting { ProgressView().controlSize(.mini) }
            }
            .padding(.horizontal, 11).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.10)))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.white.opacity(errored ? 0.5 : 0.12), lineWidth: 1))

            if errored {
                Text(NSLocalizedString("location_not_found", value: "Couldn't find that place.", comment: ""))
                    .font(.caption).foregroundColor(.red.opacity(0.9))
            }

            Button(action: useCurrentLocation) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill").font(.system(size: 12))
                    Text(NSLocalizedString("use_current_location_short", value: "Use Current Location", comment: ""))
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.accentColor))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.bottom, 8).padding(.top, 2)
    }

    // MARK: - Prayer list

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11.5, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(.white.opacity(0.45))
            .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 4)
    }

    private var prayerList: some View {
        VStack(spacing: 1) {
            ForEach(0..<6, id: \.self) { i in
                prayerRow(Prayer(index: i))
            }
        }
    }

    /// Times for the browsed day: today's live times when offset == 0, otherwise computed.
    private var selectedTimes: PrayerTimes? {
        if dayOffset == 0 { return manager.todayTimes }
        return AthanManager.shared.calculateTimes(referenceDate: selectedDate,
                                                  adjustments: AthanManager.shared.notificationSettings.adjustments())
    }
    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }

    private func prayerRow(_ p: Prayer) -> some View {
        let isCurrent = dayOffset == 0 && manager.currentPrayer == p
        let bellOn = AthanManager.shared.notificationSettings.settings[p]?.athanAlertEnabled ?? false
        return HStack(spacing: 8) {
            Text(p.localizedOrCustomString())
                .font(.system(size: 16, weight: isCurrent ? .bold : .medium))
                .foregroundColor(.white)
            Spacer(minLength: 8)
            Text(timeString(selectedTimes?.time(for: p)))
                .font(.system(size: 15.5, weight: isCurrent ? .semibold : .regular)).monospacedDigit()
                .foregroundColor(isCurrent ? .white : .white.opacity(0.75))
            Button { toggleBell(p) } label: {
                Image(systemName: bellOn ? "bell.fill" : "bell.slash")
                    .font(.system(size: 15))
                    .foregroundColor(bellOn ? gold : .white.opacity(0.4))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(isCurrent ? 0.14 : 0))
                if isCurrent {
                    RoundedRectangle(cornerRadius: 2).fill(gold).frame(width: 3).padding(.vertical, 8)
                }
            }
        )
    }

    // MARK: - Day navigator (prev / next day around the Hijri date)

    private static let gregFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    private var dayNavigator: some View {
        HStack(spacing: 6) {
            navArrow("chevron.backward") { withAnimation(.easeInOut(duration: 0.15)) { dayOffset -= 1 } }

            Button {
                if dayOffset != 0 { withAnimation(.easeInOut(duration: 0.15)) { dayOffset = 0 } }
            } label: {
                VStack(spacing: 1) {
                    Text(MainSwiftUI.hijriDateString(date: selectedDate, isAccessibilityLabel: false))
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1).minimumScaleFactor(0.65)
                    if dayOffset != 0 {
                        Text(Self.gregFormatter.string(from: selectedDate))
                            .font(.system(size: 10.5))
                            .foregroundColor(gold.opacity(0.9))
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MainSwiftUI.hijriDateString(date: selectedDate, isAccessibilityLabel: true))
            .accessibilityHint(dayOffset == 0 ? "" : NSLocalizedString("tap_return_today", value: "Return to today", comment: ""))

            navArrow("chevron.forward") { withAnimation(.easeInOut(duration: 0.15)) { dayOffset += 1 } }
        }
        .padding(.horizontal, 6).padding(.top, 10).padding(.bottom, 2)
    }

    private func navArrow(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nav footer

    private var navFooter: some View {
        VStack(spacing: 1) {
            Divider().overlay(Color.white.opacity(0.10))
                .padding(.bottom, 4)
            ForEach(navSections) { s in navItem(s) }
        }
        .padding(.horizontal, 8).padding(.top, 4).padding(.bottom, 10)
        .background(darkVibrancy)
    }

    private func navItem(_ s: MacSection) -> some View {
        let selected = section == s
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { section = selected ? .times : s }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: s.symbol).font(.system(size: 15)).frame(width: 20)
                Text(s.title).font(.system(size: 14.5, weight: selected ? .semibold : .regular))
                Spacer()
            }
            .foregroundColor(selected ? gold : .white.opacity(0.72))
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(selected ? 0.14 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Style

    private var darkVibrancy: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Color.black.opacity(0.42)
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func timeString(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        Self.timeFormatter.timeZone = AthanManager.shared.locationSettings.timeZone
        return Self.timeFormatter.string(from: date)
    }

    private func toggleBell(_ p: Prayer) {
        let m = AthanManager.shared
        guard let updated = m.notificationSettings.copy() as? NotificationSettings,
              let setting = updated.settings[p] else { return }
        setting.athanAlertEnabled.toggle()
        m.notificationSettings = updated
        m.reloadSettingsAndNotifications()
        bellVersion += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Location actions

    private func commitSearch() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        awaiting = true; errored = false

        let cleaned = text.replacingOccurrences(of: "°", with: "").replacingOccurrences(of: " ", with: "")
        let parts = cleaned.split(separator: ",")
        if parts.count == 2, let lat = CLLocationDegrees(parts[0]), let lon = CLLocationDegrees(parts[1]) {
            geocoder.reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { placemarks, _ in
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let pm = placemarks?.first
                save(name: pm.map { Self.displayName(for: $0, coord: coord) } ?? String(format: "%.2f°, %.2f°", lat, lon),
                     coord: coord, timeZone: pm?.timeZone ?? Calendar.current.timeZone, countryCode: pm?.isoCountryCode)
            }
            return
        }

        geocoder.geocodeAddressString(text) { placemarks, error in
            guard let pm = placemarks?.first, let coord = pm.location?.coordinate, error == nil else {
                awaiting = false; errored = true; return
            }
            save(name: Self.displayName(for: pm, coord: coord),
                 coord: coord, timeZone: pm.timeZone ?? AthanManager.shared.locationSettings.timeZone,
                 countryCode: pm.isoCountryCode)
        }
    }

    private func save(name: String, coord: CLLocationCoordinate2D, timeZone: TimeZone, countryCode: String?) {
        AthanManager.shared.locationSettings = LocationSettings(locationName: name, coord: coord,
                                                                timeZone: timeZone,
                                                                useCurrentLocation: false,
                                                                countryCode: countryCode)
        AthanManager.shared.reloadSettingsAndNotifications()
        _ = AthanManager.shared.autoUpdateMethodIfNeeded(for: countryCode)
        awaiting = false
        searchText = ""
        withAnimation { showLocationEditor = false }
    }

    private func useCurrentLocation() {
        if manager.locationPermissionsGranted {
            AthanManager.shared.attemptSingleLocationUpdate()
            withAnimation { showLocationEditor = false }
        } else if AthanManager.shared.locationManager.authorizationStatus == .notDetermined {
            AthanManager.shared.requestLocationPermission()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private static func displayName(for pm: CLPlacemark, coord: CLLocationCoordinate2D) -> String {
        if let city = pm.locality, let state = pm.administrativeArea {
            return city == state ? city : "\(city), \(state)"
        }
        if let city = pm.locality { return city }
        if let state = pm.administrativeArea { return state }
        if let name = pm.name { return name }
        return String(format: "%.2f°, %.2f°", coord.latitude, coord.longitude)
    }
}
#endif
