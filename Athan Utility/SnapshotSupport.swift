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

    /// Seeds a fixed location so times/recommendations are deterministic. In the
    /// default mode it also marks onboarding complete (opens on the main screen);
    /// in intro mode it leaves onboarding incomplete so the intro screen shows with
    /// a live country recommendation. Safe no-op outside snapshot runs.
    static func seedIfNeeded() {
        guard isActive else { return }

        // Fixed location → no location-permission prompt, deterministic times.
        let demo = LocationSettings(
            locationName: "Makkah",
            coord: CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262),
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            useCurrentLocation: false,
            countryCode: "SA"
        )
        AthanManager.shared.locationSettings = demo // didSet archives + recalculates
        IntroSetupFlags.hasCompletedCalculationSetup = !showsIntro
        FeatureDiscovery.hasSeen = false // always show the discovery hint in snapshot runs (deterministic)
    }
}
