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
    /// Asset name of a screenshot to show under the description, for features that are
    /// easier to recognise than to describe.
    var screenshotAsset: String? = nil
}

enum FeatureDiscovery {
    private static let seenKey = "seenFeatureDiscovery_v1"

    /// Whether the user has ever opened the discovery list (drives the main-screen hint).
    static var hasSeen: Bool {
        get { UserDefaults.standard.bool(forKey: seenKey) }
        set { UserDefaults.standard.set(newValue, forKey: seenKey) }
    }

    static let features: [DiscoveryFeature] = [
        // Impressive / most-loved first
        DiscoveryFeature(
            icon: "square.grid.2x2.fill",
            tint: Color(red: 0.60, green: 0.45, blue: 0.95),
            title: NSLocalizedString("feature_widgets_title", value: "Home & Lock Screen Widgets", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_widgets_subtitle", value: "The next prayer at a glance", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_widgets_detail", value: "Add widgets to your Home Screen and Lock Screen to see the next prayer and time remaining without opening the app.", comment: "Discovery feature detail"),
            showsWidgetPreviews: true
        ),
        DiscoveryFeature(
            icon: "bell.badge.fill",
            tint: Color(red: 0.95, green: 0.40, blue: 0.45),
            title: NSLocalizedString("feature_earlyReminder_title", value: "Early Reminders Before Salah", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_earlyReminder_subtitle", value: "A heads-up so you're never rushed", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_earlyReminder_detail", value: "Get an optional reminder a set number of minutes before each prayer — enough time to make wudu and be ready when the athan sounds. Adjustable for every prayer.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "applewatch",
            tint: Color(red: 0.35, green: 0.78, blue: 0.85),
            title: NSLocalizedString("feature_watch_title", value: "Apple Watch App", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_watch_subtitle", value: "Prayer times on your wrist", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_watch_detail", value: "A native watchOS app plus complications for every watch face, so the next prayer and the time remaining are always a glance away.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "menubar.rectangle",
            tint: Color(red: 0.55, green: 0.60, blue: 0.98),
            title: NSLocalizedString("feature_mac_title", value: "Native Mac App", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_mac_subtitle", value: "A sidebar and a menu bar item", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_mac_detail", value: "Athan Utility on Mac, redesigned with a native sidebar — plus a menu bar item that shows the next prayer countdown at a glance, with its own popover for quick actions.", comment: "Discovery feature detail"),
            screenshotAsset: "mac_app_shot"
        ),
        DiscoveryFeature(
            icon: "globe.americas.fill",
            tint: Color(red: 0.30, green: 0.55, blue: 0.95),
            title: NSLocalizedString("feature_autoMethod_title", value: "Automatic Calculation Method", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_autoMethod_subtitle", value: "Matches your country's authority", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_autoMethod_detail", value: "When you travel, Athan Utility switches to the calculation method used by the local authority — Umm al-Qura in Saudi Arabia, Diyanet in Turkey, ISNA in North America, and more — and lets you undo it with a single tap.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "speaker.wave.2.fill",
            tint: Color(red: 0.96, green: 0.55, blue: 0.22),
            title: NSLocalizedString("feature_notifications_title", value: "Per-Prayer Athan & Sounds", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_notifications_subtitle", value: "Full athan, a reminder, or silence", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_notifications_detail", value: "Choose a full athan, a short reminder, or silence for each prayer independently — and pick from multiple muezzin voices in 5- or 30-second lengths.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "circle.righthalf.filled",
            tint: Color(red: 0.95, green: 0.70, blue: 0.25),
            title: NSLocalizedString("feature_highLat_title", value: "High-Latitude Rule", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_highLat_subtitle", value: "Sensible times far from the equator", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_highLat_detail", value: "Where the sun barely sets in summer, a high-latitude rule keeps Fajr and Isha reasonable. Athan Utility recommends the right rule for your location automatically.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "location.north.line.fill",
            tint: Color(red: 0.10, green: 0.62, blue: 0.62),
            title: NSLocalizedString("feature_qibla_title", value: "Qibla Compass", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_qibla_subtitle", value: "Point toward the Kaaba", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_qibla_detail", value: "The built-in compass points to the Qibla and gives a gentle haptic tap when you're aligned. If it seems off, move your phone in a figure-eight to recalibrate.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "accessibility",
            tint: Color(red: 0.12, green: 0.52, blue: 0.96),
            title: NSLocalizedString("feature_accessibility_title", value: "Made for Everyone", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_accessibility_subtitle", value: "VoiceOver labels & haptic Qibla", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_accessibility_detail", value: "Every control is labeled for VoiceOver, and the Qibla compass vibrates as you align with the Kaaba — so you can find the direction of prayer without looking.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "paintbrush.pointed.fill",
            tint: Color(red: 0.25, green: 0.75, blue: 0.50),
            title: NSLocalizedString("feature_custom_title", value: "Custom Names, Colors & Sounds", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_custom_subtitle", value: "Make the app yours", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_custom_detail", value: "Rename prayers, pick your athan sound, and customize the gradient colors for each time of day.", comment: "Discovery feature detail")
        ),
        DiscoveryFeature(
            icon: "calendar",
            tint: Color(red: 0.40, green: 0.45, blue: 0.88),
            title: NSLocalizedString("feature_calendar_title", value: "Monthly Calendar & Export", comment: "Discovery feature title"),
            subtitle: NSLocalizedString("feature_calendar_subtitle", value: "A full month, exportable", comment: "Discovery feature subtitle"),
            detail: NSLocalizedString("feature_calendar_detail", value: "See the whole month's prayer times in a calendar, and export them to CSV to open in Numbers or Excel.", comment: "Discovery feature detail")
        ),
    ]
}

struct FeatureDiscoveryView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var macSelected: DiscoveryFeature?
    /// Mac only: this view is a NavigationSplitView detail pane, not a sheet, so
    /// there's no default way back. Set to return to the Home section.
    /// Non-nil only when presented modally on Mac (light bulb / notification), where the
    /// grid has no navigation bar to close from. Left nil for the sidebar section, which
    /// is navigated away from rather than dismissed.
    var macOnDismiss: (() -> Void)? = nil

    private var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }

    private let footerText = NSLocalizedString("feature_discovery_footer", value: "Everything here lives in the app — this is just a quick tour.", comment: "Discovery list footer")

    var body: some View {
        Group {
            if isMac {
                macGrid
            } else {
                NavigationView {
                    iosList
                        .navigationBarTitle(Text(Strings.discoverFeatures), displayMode: .inline)
                        .navigationBarItems(trailing:
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Text(Strings.done).fontWeight(.semibold)
                            }
                            .accessibilityIdentifier("discoverDone")
                        )
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .onAppear { FeatureDiscovery.hasSeen = true }
    }

    private var iosList: some View {
        List {
            Section {
                DiscoveryIconHeader()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 4, trailing: 0))
            }
            Section(footer: Text(footerText).font(.footnote)) {
                ForEach(FeatureDiscovery.features) { feature in
                    NavigationLink(destination: FeatureDetailView(feature: feature)) {
                        FeatureRow(feature: feature)
                    }
                    .accessibilityIdentifier(feature.showsWidgetPreviews ? "featureWidgetsRow" : "featureRow")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // Wide, grid-based layout that fills the Mac detail pane. Title sits top-left; a card
    // opens its detail as a sheet (with a Done button) so there's always a clear way back.
    private var macGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Text(Strings.discoverFeatures)
                        .font(.system(size: 30, weight: .bold))
                    Spacer()
                    if let macOnDismiss {
                        Button(action: macOnDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(Strings.done))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250, maximum: 360), spacing: 16)],
                          alignment: .leading, spacing: 16) {
                    ForEach(FeatureDiscovery.features) { feature in
                        Button { macSelected = feature } label: {
                            FeatureCard(feature: feature)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier(feature.showsWidgetPreviews ? "featureWidgetsRow" : "featureRow")
                    }
                }
                .padding(.horizontal, 24)

                Text(footerText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .sheet(item: $macSelected) { feature in
            NavigationView {
                FeatureDetailView(feature: feature)
                    .navigationBarTitle(Text(feature.title), displayMode: .inline)
                    .navigationBarItems(trailing: Button(NSLocalizedString("done", value: "Done", comment: "")) {
                        macSelected = nil
                    })
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .frame(minWidth: 460, minHeight: 500)
        }
    }
}

/// A vertical feature card for the Mac grid.
private struct FeatureCard: View {
    let feature: DiscoveryFeature
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(feature.tint)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: feature.icon)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                if let asset = feature.screenshotAsset {
                    Image(asset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                        .padding(.top, 12)
                        .accessibilityLabel(Text(feature.title))
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
