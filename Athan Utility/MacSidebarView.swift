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
    @State private var locating = false
    @State private var locationStatus: String?
    @State private var bellVersion = 0          // forces the (non-published) bell state to refresh
    @State private var dayOffset = 0            // 0 = today; prev/next-day browsing
    @State private var silentVersion = 0        // same trick as bellVersion, for silent mode
    private let geocoder = CLGeocoder()
    // The sidebar's own fonts run small, so it's the primary consumer of the
    // user-adjustable ⌘+/⌘- zoom (see MacFontScale / AppDelegate.buildMenu).
    @ObservedObject private var fontScale = MacFontScale.shared

    private let gold = Color(red: 0.957, green: 0.835, blue: 0.553)   // #f4d58d
    private let navSections: [MacSection] = [.times, .settings, .calendar, .discover]

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }()

    // Font size helper: a flat +10% baseline bump (these labels ran a bit
    // small) times the user's ⌘+/⌘- zoom level (1.0 = no adjustment).
    private func fs(_ base: CGFloat) -> CGFloat {
        base * 1.1 * fontScale.scale
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                sectionLabel(dayOffset == 0
                             ? NSLocalizedString("today", value: "Today", comment: "Sidebar prayer list header")
                             : NSLocalizedString("prayer_times", value: "Prayer Times", comment: "Sidebar prayer list header, non-today"))
                prayerList
                    .id("\(bellVersion)-\(dayOffset)")
                dayNavigator
                Spacer(minLength: 12)
            }
            // No top padding: the sidebar's own inset already clears the window edge, and
            // the extra 10pt pushed TODAY well below the collapse button sitting in the
            // top-right corner. They read as one row now.
            .padding(.horizontal, 8)
        }
        .safeAreaInset(edge: .bottom) { navFooter }
        .background(darkVibrancy)
        // The footer is pinned with safeAreaInset so it cannot literally overlap, but a
        // short window collapses the scroll area until the prayer list is a sliver under
        // it. Claim a minimum height instead — and derive it from fs(), because ⌘+ makes
        // every row taller and a fixed number would be wrong at any other zoom level.
        .frame(minHeight: minimumSidebarHeight)
        // The menu bar popover's location row opens the editor here, so the click lands
        // somewhere useful rather than just raising the window.
        .onReceive(NotificationCenter.default.publisher(for: .athanShowMacLocationSettings)) { _ in
            section = .times
            withAnimation { showLocationEditor = true }
        }
        // The menu bar popover toggles the same setting; re-read it when it does.
        .onReceive(NotificationCenter.default.publisher(for: .athanSilentModeChanged)) { _ in
            silentVersion += 1
        }
    }

    /// Enough room for the six prayer rows, the day navigator, the location row and the
    /// nav footer, at the CURRENT font scale.
    private var minimumSidebarHeight: CGFloat {
        // Row heights were underestimated, so shrinking the window clipped the scroll
        // area until Isha ran into the Hijri date in the day navigator below it. These
        // track the real laid-out heights, with headroom for the taller scripts.
        let sectionHeader = fs(24)
        let prayerRows = 6 * fs(32)
        let navigator = fs(44)          // arrows + Hijri date
        // Location moved into the footer, so it counts against the pinned chrome.
        let footer = fs(34) + fs(32) + CGFloat(navSections.count) * fs(32) + 34   // location + silent mode + nav
        return sectionHeader + prayerRows + navigator + footer + 52
    }

    // MARK: - Location header + inline editor

    private var locationHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { showLocationEditor.toggle() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: manager.locationPermissionsGranted && LocationSettings.shared.useCurrentLocation
                      ? "location.fill" : "location.slash")
                    .font(.system(size: fs(12))).foregroundColor(.white.opacity(0.85))
                Text(manager.locationName.isEmpty ? "—" : manager.locationName)
                    .font(.system(size: fs(14.5), weight: .semibold)).foregroundColor(.white)
                    .lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 6)
                Image(systemName: showLocationEditor ? "chevron.down" : "chevron.right")
                    .font(.system(size: fs(11), weight: .semibold)).foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 10).padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Athan recording vs. the system notification sound. Distinct from the per-prayer
    /// bells above, which decide whether a notification arrives at all — this only decides
    /// what it sounds like, so it reads as a checkbox rather than another bell.
    private var silentModeRow: some View {
        Button {
            toggleSilentMode()
        } label: {
            HStack(spacing: 8) {
                Text(NSLocalizedString("silent_mode", value: "Silent mode", comment: "Sidebar toggle: notify with the system sound instead of playing the athan"))
                    .font(.system(size: fs(13.5), weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 6)
                Image(systemName: silentMode ? "checkmark.square.fill" : "square")
                    .font(.system(size: fs(18), weight: .regular))
                    .foregroundColor(silentMode ? gold : .white.opacity(0.5))
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(NSLocalizedString("silent_mode_help",
                                value: "Notify with the system sound instead of playing the athan.",
                                comment: ""))
    }

    /// `silentVersion` is only there to re-read it: NotificationSettings isn't observable,
    /// so the same trick the bells use applies here.
    private var silentMode: Bool {
        _ = silentVersion
        return AthanManager.shared.notificationSettings.silentMode
    }

    private func toggleSilentMode() {
        let m = AthanManager.shared
        guard let updated = m.notificationSettings.copy() as? NotificationSettings else { return }
        updated.silentMode.toggle()
        m.notificationSettings = updated
        m.reloadSettingsAndNotifications()
        silentVersion += 1
        MacToast.shared.show(Strings.silentModeToastMessage(silenced: updated.silentMode))
        NotificationCenter.default.post(name: .athanSilentModeChanged, object: updated.silentMode)
    }

    private var locationEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").font(.system(size: fs(12))).foregroundColor(.white.opacity(0.5))
                TextField(Strings.searchCity, text: $searchText, onCommit: commitSearch)
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
                    if locating { ProgressView().controlSize(.small) }
                    else { Image(systemName: "location.fill").font(.system(size: fs(12))) }
                    Text(locating
                         ? NSLocalizedString("loc_locating", value: "Locating…", comment: "")
                         : Strings.useCurrentLocation)
                        .font(.system(size: fs(12.5), weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.accentColor))
            }
            .buttonStyle(.plain)
            .disabled(locating)

            if let status = locationStatus {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 8).padding(.bottom, 8).padding(.top, 2)
    }

    // MARK: - Prayer list

    /// Left-aligned, small uppercase and tracked, sitting directly over the list.
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: fs(11.5), weight: .semibold))
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
                .font(.system(size: fs(16), weight: isCurrent ? .bold : .medium))
                .foregroundColor(.white)
            Spacer(minLength: 8)
            Text(timeString(selectedTimes?.time(for: p)))
                .font(.system(size: fs(15.5), weight: isCurrent ? .semibold : .regular)).monospacedDigit()
                .foregroundColor(isCurrent ? .white : .white.opacity(0.75))
            Button { toggleBell(p) } label: {
                Image(systemName: bellOn ? "bell.fill" : "bell.slash")
                    .font(.system(size: fs(15)))
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
                    HStack(spacing: 5) {
                        if dayOffset != 0 {
                            Text(dayOffset > 0 ? "(+\(dayOffset))" : "(\(dayOffset))")
                                .font(.system(size: fs(12), weight: .bold))
                                .foregroundColor(gold)
                        }
                        Text(MainSwiftUI.hijriDateString(date: selectedDate, isAccessibilityLabel: false))
                            .font(.system(size: fs(12.5), weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1).minimumScaleFactor(0.65)
                    }
                    if dayOffset != 0 {
                        Text(Self.gregFormatter.string(from: selectedDate))
                            .font(.system(size: fs(10.5)))
                            .foregroundColor(.white.opacity(0.5))
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
                .font(.system(size: fs(13), weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nav footer

    private var navFooter: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Location sits with the pinned footer, above the separator, rather than
            // scrolling away with the prayer times. It's a persistent setting, not part
            // of the day's list, and it stays reachable however far the times scroll.
            locationHeader
            if showLocationEditor { locationEditor.transition(.opacity) }
            silentModeRow

            Divider().overlay(Color.white.opacity(0.10))
                .padding(.top, 6)
                .padding(.bottom, 4)
            ForEach(navSections) { s in navItem(s) }
        }
        .padding(.horizontal, 8).padding(.top, 4).padding(.bottom, 10)
        .background(darkVibrancy)
    }

    private func navItem(_ s: MacSection) -> some View {
        let selected = section == s
        return Button {
            // Every item toggles back to Home on a second tap EXCEPT Home
            // itself, which has no "away" state to toggle to.
            withAnimation(.easeInOut(duration: 0.15)) { section = (selected && s != .times) ? .times : s }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: s.symbol).font(.system(size: fs(15))).frame(width: 20)
                Text(s.title).font(.system(size: fs(14.5), weight: selected ? .semibold : .regular))
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

    /// The app's dark ground tone, used wherever a Mac surface needs to read as part of
    /// the app rather than as an unstyled system background.
    static let fill = Color(red: 12 / 255, green: 27 / 255, blue: 56 / 255)

    /// Opaque, one flat tone. This used to be a translucent material, which was fine while
    /// the system ignored `primaryBackgroundStyle` — the sidebar simply read as dark navy.
    /// Now that the split view is the window's root the style applies for real, and the
    /// system's own sidebar material sits UNDERNEATH this: a translucent fill let that pale,
    /// desaturated material through, so the scrolling upper portion came out noticeably
    /// lighter than the pinned footer. A flat fill keeps the whole column one colour.
    private var darkVibrancy: some View {
        Self.fill.ignoresSafeArea()
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
        MacToast.shared.show(Strings.bellToastMessage(prayerName: p.localizedOrCustomString(), enabled: setting.athanAlertEnabled))
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
        _ = AthanManager.shared.autoUpdateMethodIfNeeded(for: countryCode, userChangedLocation: true)
        awaiting = false
        searchText = ""
        withAnimation { showLocationEditor = false }
    }

    private func useCurrentLocation() {
        let status = AthanManager.shared.locationManager.authorizationStatus
        if manager.locationPermissionsGranted {
            locating = true
            locationStatus = nil
            AthanManager.shared.attemptSingleLocationUpdate { settings in
                locating = false
                if let s = settings {
                    AthanManager.shared.locationSettings = s
                    AthanManager.shared.reloadSettingsAndNotifications()
                    _ = AthanManager.shared.autoUpdateMethodIfNeeded(for: s.countryCode, userChangedLocation: true)
                    locationStatus = nil
                    withAnimation { showLocationEditor = false }
                } else {
                    locationStatus = NSLocalizedString("loc_failed", value: "Couldn't get your location. Please try again.", comment: "")
                }
            }
        } else if status == .notDetermined {
            locating = true
            locationStatus = NSLocalizedString("loc_requesting", value: "Requesting location access — approve the prompt.", comment: "")
            // Pre-set "use current location" so AthanManager's authorization-grant
            // callback (didChangeAuthorization) auto-fetches once the user approves.
            if let updated = LocationSettings.shared.copy() as? LocationSettings {
                updated.useCurrentLocation = true
                AthanManager.shared.locationSettings = updated
            }
            // Install the capture closure WITHOUT starting location yet. On
            // macOS, calling startUpdatingLocation() before authorization can
            // suppress the system prompt; requestWhenInUseAuthorization() alone
            // shows it. On grant, didChangeAuthorization → attemptSingleLocationUpdate()
            // starts the fix and this closure delivers it.
            AthanManager.shared.captureLocationUpdateClosure = { settings in
                DispatchQueue.main.async {
                    locating = false
                    if let s = settings {
                        AthanManager.shared.locationSettings = s
                        AthanManager.shared.reloadSettingsAndNotifications()
                        _ = AthanManager.shared.autoUpdateMethodIfNeeded(for: s.countryCode, userChangedLocation: true)
                        locationStatus = nil
                        withAnimation { showLocationEditor = false }
                    }
                }
            }
            AthanManager.shared.requestLocationPermission()
        } else {
            locationStatus = NSLocalizedString("loc_denied", value: "Location access is off. Turn it on in System Settings › Privacy & Security › Location Services.", comment: "")
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
