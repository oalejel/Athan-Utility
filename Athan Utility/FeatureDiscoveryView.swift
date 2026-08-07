//
//  FeatureDiscoveryView.swift
//  Athan Utility
//
//  A Tips-style "Discover Features" list that educates users on the app's
//  less-obvious capabilities. Reached from the light-bulb hint on the main
//  screen (which hides once opened) and, permanently, from Settings.
//

import SwiftUI
import CoreMotion

struct DiscoveryFeature: Identifiable {
    let id = UUID()
    let icon: String       // SF Symbol
    let tint: Color
    let title: String
    let subtitle: String
    let detail: String
    var showsWidgetPreviews: Bool = false
}

enum FeatureDiscovery {
    private static let seenKey = "seenFeatureDiscovery_v1"

    /// Whether the user has ever opened the discovery list (drives the main-screen hint).
    static var hasSeen: Bool {
        get { UserDefaults.standard.bool(forKey: seenKey) }
        set { UserDefaults.standard.set(newValue, forKey: seenKey) }
    }

    static let features: [DiscoveryFeature] = [
        DiscoveryFeature(
            icon: "globe.americas.fill",
            tint: Color(red: 0.30, green: 0.55, blue: 0.95),
            title: NSLocalizedString("feature_autoMethod_title", value: "Automatic Calculation Method", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_autoMethod_subtitle", value: "Matches your country's authority", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_autoMethod_detail", value: "When you travel, Athan Utility switches to the calculation method used by the local authority — Umm al-Qura in Saudi Arabia, Diyanet in Turkey, ISNA in North America, and more — and lets you undo it with a single tap.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "circle.righthalf.filled",
            tint: Color(red: 0.95, green: 0.70, blue: 0.25),
            title: NSLocalizedString("feature_highLat_title", value: "High-Latitude Rule", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_highLat_subtitle", value: "Sensible times far from the equator", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_highLat_detail", value: "Where the sun barely sets in summer, a high-latitude rule keeps Fajr and Isha reasonable. Athan Utility recommends the right rule for your location automatically.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "bell.badge.fill",
            tint: Color(red: 0.95, green: 0.40, blue: 0.45),
            title: NSLocalizedString("feature_notifications_title", value: "Per-Prayer Notifications", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_notifications_subtitle", value: "Athan and reminders, tuned per prayer", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_notifications_detail", value: "Choose a full athan, a short reminder, or silence for each prayer independently — plus an optional heads-up a few minutes before each one.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "square.grid.2x2.fill",
            tint: Color(red: 0.60, green: 0.45, blue: 0.95),
            title: NSLocalizedString("feature_widgets_title", value: "Home & Lock Screen Widgets", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_widgets_subtitle", value: "The next prayer at a glance", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_widgets_detail", value: "Add widgets to your Home Screen and Lock Screen to see the next prayer and time remaining without opening the app.", comment: "Discovery feature detail"),
            showsWidgetPreviews: true
        ),
        DiscoveryFeature(
            icon: "location.north.line.fill",
            tint: Color(red: 0.10, green: 0.62, blue: 0.62),
            title: NSLocalizedString("feature_qibla_title", value: "Qibla Compass", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_qibla_subtitle", value: "Point toward the Kaaba", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_qibla_detail", value: "The built-in compass points to the Qibla and gives a gentle haptic tap when you're aligned. If it seems off, move your phone in a figure-eight to recalibrate.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "paintbrush.pointed.fill",
            tint: Color(red: 0.25, green: 0.75, blue: 0.50),
            title: NSLocalizedString("feature_custom_title", value: "Custom Names, Colors & Sounds", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_custom_subtitle", value: "Make the app yours", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_custom_detail", value: "Rename prayers, pick your athan sound, and customize the gradient colors for each time of day.", comment: "Discovery feature detail")
        ),
    ]
}

struct FeatureDiscoveryView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section {
                    DiscoveryIconHeader()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 4, trailing: 0))
                }
                Section(footer: Text(NSLocalizedString("feature_discovery_footer", value: "Everything here lives in the app — this is just a quick tour.", comment: "Discovery list footer")).font(.footnote)) {
                    ForEach(FeatureDiscovery.features) { feature in
                        NavigationLink(destination: FeatureDetailView(feature: feature)) {
                            FeatureRow(feature: feature)
                        }
                        .accessibilityIdentifier(feature.showsWidgetPreviews ? "featureWidgetsRow" : "featureRow")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text(Strings.discoverFeatures), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text(Strings.done).fontWeight(.semibold)
                }
                .accessibilityIdentifier("discoverDone")
            )
        }
        .onAppear { FeatureDiscovery.hasSeen = true }
    }
}

private struct FeatureRow: View {
    let feature: DiscoveryFeature
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(feature.tint)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: feature.icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}

private struct FeatureDetailView: View {
    let feature: DiscoveryFeature
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(feature.tint)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: feature.icon)
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .padding(.top, 28)
                Text(feature.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(feature.detail)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                if feature.showsWidgetPreviews {
                    WidgetPreviewGallery()
                        .padding(.top, 8)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 520)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Publishes clamped device tilt (roll/pitch) for the icon's parallax shine.
private final class TiltMotion: ObservableObject {
    private let manager = CMMotionManager()
    @Published var roll: Double = 0
    @Published var pitch: Double = 0

    init() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let a = motion?.attitude else { return }
            self?.roll = max(-0.6, min(0.6, a.roll))
            self?.pitch = max(-0.6, min(0.6, a.pitch))
        }
    }

    deinit { manager.stopDeviceMotionUpdates() }
}

/// The app icon at the top of Discover Features, with a specular shine that
/// sweeps across it as the device tilts (gyro), plus a subtle tilt parallax.
private struct DiscoveryIconHeader: View {
    @StateObject private var motion = TiltMotion()
    private let size: CGFloat = 96
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 22, style: .continuous) }

    var body: some View {
        Image("DiscoveryAppIcon")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .overlay(shine)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
            .padding(.vertical, 4)
            .accessibilityLabel(Text("Athan Utility"))
    }

    private var shine: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.0),  location: 0.08),
                    .init(color: .white.opacity(0.05), location: 0.34),
                    .init(color: .white.opacity(0.18), location: 0.50),
                    .init(color: .white.opacity(0.05), location: 0.66),
                    .init(color: .white.opacity(0.0),  location: 0.92),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: w * 2.8, height: w * 2.8)
            .rotationEffect(.degrees(22 + motion.roll * 6))
            .offset(x: -w * 0.9 + CGFloat(motion.roll) * w * 1.05,
                    y: -w * 0.9 + CGFloat(motion.pitch) * w * 1.05)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.12), value: motion.roll)
            .animation(.easeOut(duration: 0.12), value: motion.pitch)
        }
    }
}
