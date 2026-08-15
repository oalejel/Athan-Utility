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
    @State private var showMenuBarIcon = !MenuBarSettings.isHidden
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

                Section(header: Text(NSLocalizedString("menubar_section", value: "Menu Bar", comment: "")),
                        footer: Text(NSLocalizedString("menubar_icon_footer", value: "Show the Athan Utility icon with the next-prayer countdown in the macOS menu bar. Turn this on to bring it back if it was removed.", comment: ""))) {
                    Toggle(NSLocalizedString("menubar_show_icon", value: "Show menu bar icon", comment: ""), isOn: $showMenuBarIcon)
                        .onChange(of: showMenuBarIcon) { on in
                            MenuBarSettings.isHidden = !on
                            if on { MenuBarBridge.shared.ensureItem() }
                            else { MenuBarBridge.shared.removeItem() }
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
        .navigationTitle(Strings.settings)
        // Re-sync the toggle with the status item's ACTUAL presence whenever
        // this pane appears — it can drift if the user ⌘-drags the icon out
        // of the menu bar without touching this toggle.
        .onAppear { showMenuBarIcon = MenuBarBridge.shared.isItemVisible }
        .onReceive(NotificationCenter.default.publisher(for: .athanMenuBarItemVisibilityChanged)) { note in
            if let visible = note.object as? Bool { showMenuBarIcon = visible }
        }
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
