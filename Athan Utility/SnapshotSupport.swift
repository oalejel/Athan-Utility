//
//  SnapshotSupport.swift
//  Athan Utility
//
//  Deterministic demo-state seeding for fastlane snapshot / UI tests.
//  Activated by the "-UITEST_DEMO" launch argument (set by the snapshot UI
//  test) so screenshots land on the real feature screens with a fixed
//  location and no onboarding / What's New sheet in the way.
//

import Foundation
import CoreLocation

enum SnapshotSupport {
    /// True when the app was launched by the snapshot UI test (either mode).
    static var isActive: Bool {
        CommandLine.arguments.contains("-UITEST_DEMO") || CommandLine.arguments.contains("-UITEST_INTRO")
    }

    /// True when we want to land on the first-launch intro settings screen.
    static var showsIntro: Bool {
        CommandLine.arguments.contains("-UITEST_INTRO")
    }

    /// True only for the run that captures the Discover screens. Everywhere else the
    /// light-bulb hint stays hidden so it doesn't sit over the main screenshot.
    static var showsDiscoveryHint: Bool {
        CommandLine.arguments.contains("-UITEST_DISCOVER")
    }

    /// A believable city for the language being captured. One hardcoded location meant
    /// every localized set showed Makkah, including en-US — a screenshot should look
    /// like the store it appears in.
    static func demoLocation() -> (name: String, coord: CLLocationCoordinate2D, tz: String, country: String) {
        let lang = Locale.preferredLanguages.first ?? "en"
        switch true {
        case lang.hasPrefix("ar"):      return ("Makkah",       .init(latitude: 21.4225, longitude: 39.8262), "Asia/Riyadh",     "SA")
        case lang.hasPrefix("tr"):      return ("İstanbul",     .init(latitude: 41.0082, longitude: 28.9784), "Europe/Istanbul", "TR")
        case lang.hasPrefix("de"):      return ("Berlin",       .init(latitude: 52.5200, longitude: 13.4050), "Europe/Berlin",   "DE")
        case lang.hasPrefix("fr"):      return ("Paris",        .init(latitude: 48.8566, longitude:  2.3522), "Europe/Paris",    "FR")
        case lang.hasPrefix("es-MX"):   return ("Ciudad de México", .init(latitude: 19.4326, longitude: -99.1332), "America/Mexico_City", "MX")
        case lang.hasPrefix("es"):      return ("Madrid",       .init(latitude: 40.4168, longitude: -3.7038), "Europe/Madrid",   "ES")
        case lang.hasPrefix("id"):      return ("Jakarta",      .init(latitude: -6.2088, longitude: 106.8456), "Asia/Jakarta",   "ID")
        case lang.hasPrefix("ms"):      return ("Kuala Lumpur", .init(latitude:  3.1390, longitude: 101.6869), "Asia/Kuala_Lumpur", "MY")
        case lang.hasPrefix("zh"):      return ("Ürümqi",       .init(latitude: 43.8256, longitude: 87.6168), "Asia/Shanghai",   "CN")
        case lang.hasPrefix("ur"):      return ("Lahore",       .init(latitude: 31.5204, longitude: 74.3587), "Asia/Karachi",    "PK")
        case lang.hasPrefix("bn"):      return ("Dhaka",        .init(latitude: 23.8103, longitude: 90.4125), "Asia/Dhaka",      "BD")
        case lang.hasPrefix("fa"):      return ("Tehran",       .init(latitude: 35.6892, longitude: 51.3890), "Asia/Tehran",     "IR")
        default:                        return ("New York, NY", .init(latitude: 40.7128, longitude: -74.0060), "America/New_York", "US")
        }
    }

    /// Seeds a fixed location so times/recommendations are deterministic. In the
    /// default mode it also marks onboarding complete (opens on the main screen);
    /// in intro mode it leaves onboarding incomplete so the intro screen shows with
    /// a live country recommendation. Safe no-op outside snapshot runs.
    static func seedIfNeeded() {
        guard isActive else { return }

        // Fixed location → no location-permission prompt, deterministic times.
        let city = demoLocation()
        let demo = LocationSettings(
            locationName: city.name,
            coord: city.coord,
            timeZone: TimeZone(identifier: city.tz) ?? .current,
            useCurrentLocation: false,
            countryCode: city.country
        )
        AthanManager.shared.locationSettings = demo // didSet archives + recalculates
        IntroSetupFlags.hasCompletedCalculationSetup = !showsIntro
        // Hidden by default: the light bulb sat on top of the main screenshot.
        FeatureDiscovery.hasSeen = !showsDiscoveryHint
    }
}
