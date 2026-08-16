//
//  HijriCalloutView.swift
//  Athan Utility
//
//  The compact panel that drops out of the Hijri date line on the main screen.
//
//  Deliberately small: a label, a calendar picker, and — only when it's actually
//  useful — a ±1 day nudge for Ramadan. The Gregorian date capsule above it is
//  unchanged; this appears alongside it, not instead of it.
//

import SwiftUI

@available(iOS 14.0, *)
struct HijriCalloutView: View {

    /// Called after any change, so the caller can re-render the date line and widgets.
    var onChange: () -> Void

    @State private var mode: HijriCalendarMode = HijriSettings.shared.mode
    @State private var dayOffset: Int = HijriSettings.shared.dayOffset
    @State private var showsRamadanAdjustment: Bool = HijriSettings.shared.isRamadanAdjustmentRelevant()

    private var offsetLabel: String {
        dayOffset > 0 ? "+\(dayOffset)" : "\(dayOffset)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(NSLocalizedString("hijri_mode_subtitle", value: "Hijri calendar", comment: "Subtitle over the Hijri calendar picker"))
                .font(.caption2)
                .textCase(.uppercase)
                .foregroundColor(Color(.lightText).opacity(0.7))

            Menu {
                ForEach(HijriCalendarMode.allCases) { option in
                    Button {
                        select(option)
                    } label: {
                        if option == mode {
                            Label(option.localizedName, systemImage: "checkmark")
                        } else {
                            Text(option.localizedName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(mode.localizedName)
                        .font(.footnote).fontWeight(.semibold)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(Color(.lightText))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.14)))
            }

            // Only in Ramadan and on the eve of it — the rest of the year a day
            // offset is noise, and an always-visible stepper invites people to
            // desync their calendar for no reason.
            if showsRamadanAdjustment {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("hijri_ramadan_adjust", value: "Ramadan day", comment: "Label for the ±1 day Ramadan correction"))
                        .font(.footnote)
                        .foregroundColor(Color(.lightText).opacity(0.85))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    stepButton(systemName: "minus",
                               enabled: dayOffset > HijriSettings.offsetRange.lowerBound) { adjust(-1) }

                    Text(offsetLabel)
                        .font(.footnote.monospacedDigit()).fontWeight(.semibold)
                        .foregroundColor(Color(.lightText))
                        .frame(minWidth: 24)

                    stepButton(systemName: "plus",
                               enabled: dayOffset < HijriSettings.offsetRange.upperBound) { adjust(1) }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.38))
        )
        .frame(maxWidth: 260)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.lightText))
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(enabled ? 0.14 : 0.05)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: - Actions

    private func select(_ option: HijriCalendarMode) {
        guard option != mode else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        mode = option
        HijriSettings.shared.mode = option
        commit()
    }

    private func adjust(_ delta: Int) {
        let next = dayOffset + delta
        guard HijriSettings.offsetRange.contains(next) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dayOffset = next
        HijriSettings.shared.dayOffset = next
        commit()
    }

    private func commit() {
        HijriSettings.archive()
        // Changing the calendar or the offset can move today in or out of the
        // Ramadan window, so re-evaluate rather than leaving a stale stepper.
        showsRamadanAdjustment = HijriSettings.shared.isRamadanAdjustmentRelevant()
        onChange()
    }
}
