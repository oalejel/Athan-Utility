//
//  MacSidebarView.swift
//  Athan Utility (Mac Catalyst only)
//
//  The sidebar column of the Mac NavigationSplitView: an inline location editor
//  (search + "use current location", stays put — no full-screen sheet that closes on
//  entry) plus the section nav that swaps the detail pane.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit
import CoreLocation

@available(macCatalyst 16.0, *)
struct MacSidebarView: View {
    @Binding var section: MacSection
    @EnvironmentObject var manager: ObservableAthanManager

    // Inline location-editor state.
    @State private var searchText = ""
    @State private var awaiting = false
    @State private var errored = false
    private let geocoder = CLGeocoder()

    var body: some View {
        List {
            // ---- Inline location settings ----
            Section {
                locationEditor
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            } header: {
                Text(NSLocalizedString("location_header", value: "Location", comment: "Mac sidebar section header"))
            }

            // ---- Section navigation ----
            Section {
                ForEach(MacSection.allCases) { s in
                    Button { section = s } label: {
                        Label(s.title, systemImage: s.symbol)
                            .foregroundColor(section == s ? Color.accentColor : Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(section == s ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Inline location editor

    private var locationEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: manager.locationPermissionsGranted && LocationSettings.shared.useCurrentLocation
                      ? "location.fill" : "location.slash")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(manager.locationName.isEmpty ? "—" : manager.locationName)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if awaiting { Spacer(minLength: 4); ProgressView().controlSize(.small) }
            }

            TextField(NSLocalizedString("search_city", value: "Search city or coordinates…", comment: "Mac location search placeholder"),
                      text: $searchText, onCommit: commitSearch)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
                .onChange(of: searchText) { _ in errored = false }

            if errored {
                Text(NSLocalizedString("location_not_found", value: "Couldn't find that place.", comment: "Mac location search error"))
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: useCurrentLocation) {
                Label(NSLocalizedString("use_current_location_short", value: "Use Current Location", comment: "Mac location button"),
                      systemImage: "location.fill")
                    .font(.callout)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func commitSearch() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        awaiting = true
        errored = false

        // "lat, lon" shorthand — save directly without geocoding a name.
        let cleaned = text.replacingOccurrences(of: "°", with: "").replacingOccurrences(of: " ", with: "")
        let parts = cleaned.split(separator: ",")
        if parts.count == 2, let lat = CLLocationDegrees(parts[0]), let lon = CLLocationDegrees(parts[1]) {
            geocoder.reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { placemarks, _ in
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let pm = placemarks?.first
                let tz = pm?.timeZone ?? Calendar.current.timeZone
                save(name: pm.map { Self.displayName(for: $0, coord: coord) }
                        ?? String(format: "%.2f°, %.2f°", lat, lon),
                     coord: coord, timeZone: tz, countryCode: pm?.isoCountryCode)
            }
            return
        }

        geocoder.geocodeAddressString(text) { placemarks, error in
            guard let pm = placemarks?.first, let coord = pm.location?.coordinate, error == nil else {
                awaiting = false
                errored = true
                return
            }
            let tz = pm.timeZone ?? AthanManager.shared.locationSettings.timeZone
            save(name: Self.displayName(for: pm, coord: coord),
                 coord: coord, timeZone: tz, countryCode: pm.isoCountryCode)
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
    }

    private func useCurrentLocation() {
        if manager.locationPermissionsGranted {
            // No capture closure → the manager auto-saves the fix, reloads, and updates the method.
            AthanManager.shared.attemptSingleLocationUpdate()
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
