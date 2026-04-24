//
//  FajrAlarmSettingsView.swift
//  Athan Utility
//
//  Settings UI for configuring the iOS 26 AlarmKit-backed Fajr/Sunrise
//  wake-up alarm.
//

import SwiftUI
#if canImport(AlarmKit)
import AlarmKit
#endif

@available(iOS 14.0, *)
struct FajrAlarmSettingsView: View {

    @Binding var activeSection: SettingsSectionType

    // Local copies that are persisted on "Done".
    @State private var enabled: Bool = false
    @State private var target: FajrAlarmTarget = .fajr
    @State private var offsetMinutes: Int = 0
    @State private var weekdays: FajrAlarmWeekdayMask = .all
    @State private var snoozeEnabled: Bool = true
    @State private var snoozeMinutes: Int = 5
    @State private var daysAhead: Int = 7
    @State private var authState: FajrAlarmAuthorizationStatus = .notDetermined
    @Environment(\.scenePhase) private var scenePhase

    private let isOSVersionSupported: Bool = {
        if #available(iOS 26.0, *) { return true } else { return false }
    }()

    // Weekday abbreviations ordered Sunday-first to match FajrAlarmWeekdayMask.
    private let weekdayAbbreviations: [String] = {
        let formatter = DateFormatter()
        return formatter.veryShortStandaloneWeekdaySymbols ?? ["S","M","T","W","T","F","S"]
    }()

    // Full weekday names (Sunday-first) used for VoiceOver labels.
    private let weekdayFullNames: [String] = {
        let formatter = DateFormatter()
        return formatter.standaloneWeekdaySymbols ?? ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    }()

    var body: some View {
        VStack(alignment: .leading) {
            header
            scrollBody
            doneButton
        }
        // Re-read authorization state whenever we become active — this
        // catches the case where the user tapped "Open Settings",
        // flipped the AlarmKit toggle in system Settings, and returned
        // to the app. `onAppear` alone doesn't fire for that flow.
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                authState = FajrAlarmManager.shared.currentAuthorizationState()
            }
        }
    }

    // MARK: - Top-level sub-views

    private var header: some View {
        Text(Strings.fajrAlarm)
            .font(.largeTitle)
            .bold()
            .foregroundColor(.white)
            .padding([.leading, .top])
            .padding([.leading, .top])
            .onAppear(perform: loadFromSettings)
    }

    private var scrollBody: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                if !isOSVersionSupported { unavailableBanner }
                enableSection
                offsetSection
                daysSection
                snoozeSection
                scheduleWindowSection
                if authState == .denied && enabled && isOSVersionSupported {
                    deniedBanner
                }
            }
            .padding()
        }
    }

    private var doneButton: some View {
        HStack(alignment: .center) {
            Spacer()
            Button(action: saveAndExit) {
                Text(Strings.done)
                    .foregroundColor(Color(.lightText))
                    .font(Font.body.weight(.bold))
            }
        }
        .padding()
        .padding([.leading, .trailing, .bottom])
    }

    // MARK: - Sections

    private var enableSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $enabled) {
                    sectionTitle(Strings.enabled)
                }
                .disabled(!isOSVersionSupported)

                Text(Strings.fajrAlarmDescription)
                    .font(.caption)
                    .foregroundColor(Color(.lightText))
                    .fixedSize(horizontal: false, vertical: true)

                Divider().background(Color.white.opacity(0.3))

                Text(Strings.fajrAlarmAnchorPrayer)
                    .font(.subheadline).bold().foregroundColor(.white)

                Picker(selection: $target, label: Text(Strings.fajrAlarmAnchorPrayer)) {
                    ForEach(FajrAlarmTarget.allCases, id: \.rawValue) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(!enabled || !isOSVersionSupported)
            }
        }
    }

    private var offsetSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(Strings.fajrAlarmOffset)

                HStack {
                    Text(offsetDescription)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Stepper("", value: $offsetMinutes, in: -120...120, step: 1)
                        .labelsHidden()
                        .accessibilityLabel(Text(Strings.fajrAlarmOffset))
                        .accessibilityValue(Text(offsetDescription))
                }

                Text(Strings.fajrAlarmOffsetDescription)
                    .font(.caption)
                    .foregroundColor(Color(.lightText))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(!enabled || !isOSVersionSupported)
        }
    }

    private var daysSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(Strings.fajrAlarmDays)

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { idx in
                        weekdayChip(index: idx)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func weekdayChip(index: Int) -> some View {
        let isOn = weekdays.isOn(weekdayIndex: index)
        let fullName = weekdayFullNames[safe: index] ?? "?"
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            weekdays.toggle(weekdayIndex: index)
        }) {
            Text(weekdayAbbreviations[safe: index] ?? "?")
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(isOn
                            ? Color.white.opacity(0.6)
                            : Color.white.opacity(0.12))
                )
                .foregroundColor(isOn ? .black : .white)
        }
        .disabled(!enabled || !isOSVersionSupported)
        .accessibilityLabel(Text(fullName))
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var snoozeSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $snoozeEnabled) {
                    sectionTitle(Strings.fajrAlarmSnooze)
                }
                .disabled(!enabled || !isOSVersionSupported)

                HStack {
                    Text(snoozeDescription)
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Stepper("", value: $snoozeMinutes, in: 1...30, step: 1)
                        .labelsHidden()
                        .disabled(!enabled || !snoozeEnabled || !isOSVersionSupported)
                        .accessibilityLabel(Text(Strings.fajrAlarmSnooze))
                        .accessibilityValue(Text(snoozeDescription))
                }
            }
        }
    }

    private var scheduleWindowSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(Strings.fajrAlarmScheduleWindow)

                HStack {
                    Text(daysAheadDescription)
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Stepper("", value: $daysAhead, in: 1...14, step: 1)
                        .labelsHidden()
                        .disabled(!enabled || !isOSVersionSupported)
                        .accessibilityLabel(Text(Strings.fajrAlarmScheduleWindow))
                        .accessibilityValue(Text(daysAheadDescription))
                }

                Text(Strings.fajrAlarmScheduleDescription)
                    .font(.caption)
                    .foregroundColor(Color(.lightText))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Banners and helpers

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color(.sRGB, white: 1, opacity: 0.1))
            )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .bold()
            .foregroundColor(.white)
    }

    private var unavailableBanner: some View {
        Text(Strings.fajrAlarmIOS26Required)
            .font(.footnote)
            .foregroundColor(.yellow)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.yellow.opacity(0.15))
            )
    }

    private var deniedBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.fajrAlarmAuthDenied)
                .font(.footnote).bold().foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(Strings.fajrAlarmOpenSettings)
                    .font(.footnote).foregroundColor(.white).underline()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.red.opacity(0.2))
        )
    }

    // MARK: - Derived labels

    private var offsetDescription: String {
        if offsetMinutes == 0 {
            return String(format: Strings.fajrAlarmOffsetZero, target.displayName)
        } else if offsetMinutes > 0 {
            return String(format: Strings.fajrAlarmOffsetAfter, offsetMinutes, target.displayName)
        } else {
            return String(format: Strings.fajrAlarmOffsetBefore, abs(offsetMinutes), target.displayName)
        }
    }

    private var snoozeDescription: String {
        String(format: Strings.fajrAlarmSnoozeMinutes, snoozeMinutes)
    }

    private var daysAheadDescription: String {
        String(format: Strings.fajrAlarmDaysAhead, daysAhead)
    }

    // MARK: - Save/load

    private func loadFromSettings() {
        let s = FajrAlarmSettings.shared
        enabled = s.enabled
        target = s.target
        offsetMinutes = s.offsetMinutes
        weekdays = s.weekdays
        snoozeEnabled = s.snoozeEnabled
        snoozeMinutes = s.snoozeMinutes
        daysAhead = s.daysAhead
        authState = FajrAlarmManager.shared.currentAuthorizationState()
    }

    private func saveAndExit() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let s = FajrAlarmSettings.shared
        s.enabled = enabled
        s.target = target
        s.offsetMinutes = offsetMinutes
        s.weekdays = weekdays
        s.snoozeEnabled = snoozeEnabled
        s.snoozeMinutes = snoozeMinutes
        s.daysAhead = daysAhead
        s.sanitize()
        FajrAlarmSettings.archive()

        // If enabling the feature, prompt for authorization. `syncAlarms()`
        // handles both the authorized and denied cases internally (denied
        // → cancels any stale scheduled alarms). Wait for the auth result
        // before animating back so that when the user denies we stay on
        // this screen and render the `deniedBanner`; otherwise a slide-out
        // transition races the permission sheet and the user never sees
        // why their alarm isn't firing.
        if enabled && isOSVersionSupported {
            FajrAlarmManager.shared.requestAuthorization { granted in
                self.authState = granted ? .authorized : .denied
                FajrAlarmManager.shared.syncAlarms()
                if granted {
                    withAnimation { self.activeSection = .General }
                }
            }
        } else {
            FajrAlarmManager.shared.syncAlarms()
            withAnimation { activeSection = .General }
        }
    }
}

// Safe array subscripting.
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
