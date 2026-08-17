//
//  MacSettingsView.swift
//  Athan Utility (Mac Catalyst)
//
//  A native grouped Form for the Mac Settings detail pane, replacing the custom gradient
//  scroll UI on Mac. Changes apply immediately to AthanManager and reschedule notifications,
//  matching the rest of the Mac surfaces.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import Adhan

@available(iOS 16.0, *)
struct MacSettingsView: View {
    @State private var method: CalculationMethod
    @State private var madhab: Madhab
    @State private var latRule: HighLatitudeRule
    @State private var sound: NotificationSettings.Sounds
    @State private var isDynamic: Bool
    @State private var bellVersion = 0
    @State private var isPreviewingSound = false

    private let methods = CalculationMethod.usefulCases()

    init() {
        let ps = AthanManager.shared.prayerSettings
        _method = State(initialValue: ps.calculationMethod)
        _madhab = State(initialValue: ps.madhab)
        _latRule = State(initialValue: ps.latitudeRule ?? .middleOfTheNight)
        _sound = State(initialValue: AthanManager.shared.notificationSettings.selectedSound)
        _isDynamic = State(initialValue: AthanManager.shared.appearanceSettings.isDynamic)
    }

    var body: some View {
        // Two earlier attempts at "scroll from the side margins too" both broke
        // something worse: per-row .listRowInsets only inset row CONTENT (not the
        // grouped-style background card, which stayed full-width — ugly stretched
        // cells), and nesting the Form in an outer ScrollView with its own
        // scrolling disabled + fixedSize(vertical:) collapsed to zero height on
        // Mac Catalyst (a blank pane). Reverted to the plain, original structure:
        // the Form handles its own scrolling, over its own (narrower, centered)
        // width — the same as any inset content list in a native Mac app; hovering
        // the blank side margins simply isn't part of its scroll area, which is
        // standard AppKit/Catalyst list behavior, not a bug.
        Form {
                Section(NSLocalizedString("calc_section", value: "Calculation", comment: "")) {
                    Picker(NSLocalizedString("Calculation Method", value: "Method", comment: ""), selection: $method) {
                        ForEach(methods, id: \.self) { Text($0.localizedString()).tag($0) }
                    }
                    .onChange(of: method) { _ in applyPrayer() }

                    Picker(NSLocalizedString("madhab_asr", value: "Asr (Madhab)", comment: ""), selection: $madhab) {
                        ForEach(Madhab.allCases, id: \.self) { Text($0.stringValue()).tag($0) }
                    }
                    .onChange(of: madhab) { _ in applyPrayer() }

                    Picker(NSLocalizedString("High Latitude Rule", value: "High Latitude Rule", comment: ""), selection: $latRule) {
                        ForEach(HighLatitudeRule.allCases, id: \.self) { Text($0.localizedString()).tag($0) }
                    }
                    .onChange(of: latRule) { _ in applyPrayer() }
                }

                Section(NSLocalizedString("notif_section", value: "Notifications", comment: "")) {
                    HStack {
                        Text(NSLocalizedString("athan_sound", value: "Athan Sound", comment: ""))
                        Spacer()
                        Button(action: toggleSoundPreview) {
                            HStack(spacing: 4) {
                                Image(systemName: isPreviewingSound ? "stop.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text(isPreviewingSound
                                     ? NSLocalizedString("stop", value: "Stop", comment: "Button that stops the athan sound preview currently playing")
                                     : NSLocalizedString("preview", value: "Preview", comment: "Button that plays a short sample of the selected athan sound"))
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Picker("", selection: $sound) {
                            ForEach(NotificationSettings.Sounds.allCases, id: \.self) { Text($0.localizedString()).tag($0) }
                        }
                        .labelsHidden()
                        .onChange(of: sound) { _ in
                            // A different sound was picked — stop any in-flight preview of
                            // the OLD sound rather than let it keep playing under the new
                            // selection, which would desync the Preview/Stop button state.
                            if isPreviewingSound { NoteSoundPlayer.stopAudio(); isPreviewingSound = false }
                            applySound()
                        }
                        .fixedSize()
                    }
                }

                Section(NSLocalizedString("alerts_section", value: "Prayer Alerts", comment: "")) {
                    ForEach(0..<6, id: \.self) { i in
                        let p = Prayer(index: i)
                        Toggle(p.localizedOrCustomString(), isOn: bellBinding(p))
                    }
                }

                Section(NSLocalizedString("appearance_section", value: "Appearance", comment: "")) {
                    Toggle(NSLocalizedString("dynamic_colors", value: "Dynamic colors by prayer", comment: ""), isOn: $isDynamic)
                        .onChange(of: isDynamic) { _ in applyAppearance() }
                }

                // macOS 26 owns whether this app may appear in the menu bar: dragging the
                // icon out turns Athan Utility off under System Settings > Control Center >
                // "Allow in the Menu Bar", and from then on the system refuses to place any
                // status item we create. Nothing in here can undo that, so the only honest
                // control is one that creates the item and takes the user to the switch.
                Section(header: Text(NSLocalizedString("menubar_section", value: "Menu Bar", comment: "")),
                        footer: Text(NSLocalizedString("menubar_enable_subtitle", value: "To add Athan Utility back to your menu bar, enable Athan Utility in your macOS settings.", comment: ""))) {
                    // Plain accent-coloured row text, not a filled pill — the grouped
                    // Form row is already the button's container, and a capsule inside it
                    // reads as a button within a button.
                    Button(action: enableInMenuBar) {
                        Label(NSLocalizedString("menubar_enable_button", value: "Enable in Menu Bar", comment: ""),
                              systemImage: "menubar.arrow.up.rectangle")
                    }
                }

                Section {
                    HStack {
                        Text(NSLocalizedString("version", value: "Version", comment: ""))
                        Spacer()
                        Text(appVersion).foregroundColor(.secondary)
                    }
                }
            }
        .formStyle(.grouped)
        .frame(maxWidth: 600)                       // negative space on the sides; tighter rows
        .frame(maxWidth: .infinity, alignment: .center)
        // No navigationTitle: this is the split view's secondary controller now, so
        // Catalyst renders one as a title above the pane. The sidebar already says which
        // section you're in.
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return v
    }

    // MARK: - Apply

    private func applyPrayer() {
        guard let ps = AthanManager.shared.prayerSettings.copy() as? PrayerSettings else { return }
        ps.calculationMethod = method
        ps.madhab = madhab
        ps.latitudeRule = latRule
        AthanManager.shared.prayerSettings = ps
        AthanManager.shared.reloadSettingsAndNotifications()
    }

    private func applySound() {
        guard let ns = AthanManager.shared.notificationSettings.copy() as? NotificationSettings else { return }
        ns.selectedSound = sound
        AthanManager.shared.notificationSettings = ns
        AthanManager.shared.reloadSettingsAndNotifications()
    }

    /// Create the status item and open the macOS switch that decides whether it may be
    /// shown. Both halves are needed: flipping the switch does nothing if the app never
    /// vends an item, and vending one does nothing while the switch is off.
    private func enableInMenuBar() {
        MenuBarSettings.isHidden = false
        // restoreItem(), not ensureItem(): after a drag removal AppKit has detached that
        // NSStatusItem for good, so only a from-scratch recreate can work.
        MenuBarBridge.shared.restoreItem()
        if let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") {
            UIApplication.shared.open(url)
        }
    }

    private func toggleSoundPreview() {
        if isPreviewingSound {
            NoteSoundPlayer.stopAudio()
            isPreviewingSound = false
        } else {
            // Flip back to "Preview" automatically once the sample finishes on
            // its own (stopAudio() below is the manual-stop path and does NOT
            // trigger this — AVAudioPlayer's delegate only fires on natural
            // completion).
            NoteSoundPlayer.onFinishedPlaying = {
                DispatchQueue.main.async { isPreviewingSound = false }
            }
            NoteSoundPlayer.playPreviewAudio(for: sound.rawValue)
            isPreviewingSound = true
        }
    }

    private func applyAppearance() {
        guard let ap = AthanManager.shared.appearanceSettings.copy() as? AppearanceSettings else { return }
        ap.isDynamic = isDynamic
        AthanManager.shared.appearanceSettings = ap
    }

    private func bellBinding(_ p: Prayer) -> Binding<Bool> {
        Binding(
            get: {
                _ = bellVersion
                return AthanManager.shared.notificationSettings.settings[p]?.athanAlertEnabled ?? false
            },
            set: { newVal in
                guard let ns = AthanManager.shared.notificationSettings.copy() as? NotificationSettings,
                      let s = ns.settings[p] else { return }
                s.athanAlertEnabled = newVal
                AthanManager.shared.notificationSettings = ns
                AthanManager.shared.reloadSettingsAndNotifications()
                bellVersion += 1
            }
        )
    }
}
#endif
