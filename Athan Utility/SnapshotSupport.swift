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

    // MARK: - Backup / restore
    //
    // Seeding writes to the SAME defaults the real app uses, so running a capture
    // against a container that has real settings in it would quietly overwrite them.
    // Rather than hope nobody does that, back the affected keys up before the first
    // write and put them back on the next ordinary launch. Restore is deferred rather
    // than done on exit because UI tests kill the app — there is no reliable teardown.

    private static let backupKey = "snapshotStateBackup"
    private static let group = UserDefaults(suiteName: "group.athanUtil")

    /// Keys seeding overwrites. Standard defaults unless noted.
    private static let standardKeys = ["calculationSetupComplete", "seenFeatureDiscovery_v1"]
    private static let groupKeys = ["adoptedFeaturesV1"]

    private static func backupIfNeeded() {
        let d = UserDefaults.standard
        guard d.dictionary(forKey: backupKey) == nil else { return }   // already backed up
        var box: [String: Any] = [:]
        for k in standardKeys where d.object(forKey: k) != nil { box["std." + k] = d.object(forKey: k)! }
        for k in groupKeys { if let v = group?.object(forKey: k) { box["grp." + k] = v } }
        if let loc = unarchiveData(LocationSettings.archiveName) { box["loc"] = loc }
        d.set(box, forKey: backupKey)
    }

    /// Called on every ordinary launch. Puts back whatever a previous capture replaced.
    static func restoreIfNeeded() {
        guard !isActive else { return }
        let d = UserDefaults.standard
        guard let box = d.dictionary(forKey: backupKey) else { return }
        for k in standardKeys {
            if let v = box["std." + k] { d.set(v, forKey: k) } else { d.removeObject(forKey: k) }
        }
        for k in groupKeys {
            if let v = box["grp." + k] { group?.set(v, forKey: k) } else { group?.removeObject(forKey: k) }
        }
        if let loc = box["loc"] { archiveData(LocationSettings.archiveName, object: loc) }
        d.removeObject(forKey: backupKey)
        // Re-read the restored values into the live singletons.
        IntroSetupFlags.hasCompletedCalculationSetup = d.bool(forKey: "calculationSetupComplete")
        if let arch = LocationSettings.checkArchive() { AthanManager.shared.locationSettings = arch }
        print("SNAPSHOT: restored pre-capture settings")
    }

    /// Seeds a fixed location so times/recommendations are deterministic. In the
    /// default mode it also marks onboarding complete (opens on the main screen);
    /// in intro mode it leaves onboarding incomplete so the intro screen shows with
    /// a live country recommendation. Safe no-op outside snapshot runs.
    static func seedIfNeeded() {
        guard isActive else { return }
        backupIfNeeded()

        // Fixed location → no location-permission prompt, deterministic times.
        let city = demoLocation()
        let demo = LocationSettings(
            locationName: city.name,
            coord: city.coord,
            timeZone: TimeZone(identifier: city.tz) ?? .current,
            // Reads as "using my location" rather than the crossed-out location.slash
            // icon, which looks like something is switched off. Nothing actually asks
            // CoreLocation for a fix in snapshot mode — the coordinate above is fixed.
            useCurrentLocation: true,
            countryCode: city.country
        )
        // Provisional clock so the first times calculation has something sane to work
        // against; replaced below once the day's Maghrib for this city is known.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: city.tz) ?? .current
        snapshotFixedNow = cal.date(bySettingHour: 19, minute: 45, second: 0, of: Date())

        AthanManager.shared.locationSettings = demo // didSet archives + recalculates

        // Anchor to the city's OWN Maghrib rather than a fixed wall-clock hour, so every
        // localized set actually lands in Maghrib. A fixed time can't: Maghrib is 19:58 in
        // New York and 20:07 in İstanbul on the captured day, so 19:45 would still be Asr
        // in both — and it drifts by an hour or more across the year anyway.
        if let maghrib = AthanManager.shared.todayTimes?.maghrib {
            snapshotFixedNow = maghrib.addingTimeInterval(12 * 60)   // just into Maghrib
            AthanManager.shared.refreshTimes()                        // re-derive against it
        }
        // The location glyph needs BOTH of these to render as location.fill.
        AthanManager.shared.locationPermissionsGranted = true

        // Every Featured tile at full size. The grid collapses a tile to a compact pill
        // once its feature has been opened, and that state persists in the app group —
        // so a machine that had explored some features produced a half-shrunken grid in
        // the Settings screenshot. Reset it so the set is identical everywhere.
        AdoptedFeature.saveDone([])

        // A notice persisted by an earlier ordinary run would still surface on launch.
        AthanManager.shared.acknowledgeMethodUpdate()
        IntroSetupFlags.hasCompletedCalculationSetup = !showsIntro
        // Hidden by default: the light bulb sat on top of the main screenshot.
        FeatureDiscovery.hasSeen = !showsDiscoveryHint
    }
}
