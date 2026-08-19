//
//  HijriCalloutView.swift
//  Athan Utility
//
//  The callout that pops up when the Hijri date on the main screen is tapped.
//
//  It is an overlay, not a layout participant: it floats above the date line with a
//  tail pointing down at it and nothing underneath moves. Each calendar option shows
//  the date it would produce right now, so choosing between them is a comparison
//  rather than a guess.
//

import SwiftUI

/// Whether the Hijri callout is open. Shared, because the tap-to-dismiss backdrop has
/// to live at the root of the main screen — a backdrop confined to the solar view would
/// only catch taps in the small strip around the date.
final class HijriCalloutState: ObservableObject {
    static let shared = HijriCalloutState()
    @Published var isPresented = false
    private init() {}

    func dismiss() {
        guard isPresented else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isPresented = false }
    }
}

// MARK: - Bubble shape

/// A rounded rectangle with a downward tail centred on the bottom edge — the classic
/// iOS callout silhouette, pointing at whatever it was opened from.
struct HijriCalloutBubble: Shape {
    var cornerRadius: CGFloat = 16
    var tailWidth: CGFloat = 20
    var tailHeight: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        // One continuous outline — body and tail are a single subpath. Drawing the
        // rounded rect and the triangle separately leaves the rect's bottom edge
        // running straight across the tail's mouth, which a stroke then renders as a
        // line cutting the tail off from the bubble.
        let body = CGRect(x: rect.minX, y: rect.minY,
                          width: rect.width, height: max(0, rect.height - tailHeight))
        let r = min(cornerRadius, min(body.width, body.height) / 2)
        let midX = body.midX
        let tailHalf = min(tailWidth / 2, max(0, (body.width / 2) - r - 1))

        var path = Path()
        path.move(to: CGPoint(x: body.minX + r, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.minY),
                    tangent2End: CGPoint(x: body.maxX, y: body.minY + r), radius: r)
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.maxY),
                    tangent2End: CGPoint(x: body.maxX - r, y: body.maxY), radius: r)
        // bottom edge, right of the tail
        path.addLine(to: CGPoint(x: midX + tailHalf, y: body.maxY))
        // the tail itself
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: midX - tailHalf, y: body.maxY))
        // bottom edge, left of the tail
        path.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.maxY),
                    tangent2End: CGPoint(x: body.minX, y: body.maxY - r), radius: r)
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.minY),
                    tangent2End: CGPoint(x: body.minX + r, y: body.minY), radius: r)
        path.closeSubpath()
        return path
    }
}

/// Reports the callout's measured height so the caller can lift it clear of the date.
struct HijriCalloutHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Callout

@available(iOS 14.0, *)
struct HijriCalloutView: View {

    /// Called after any change, so the caller can re-render the date line and widgets.
    var onChange: () -> Void
    /// Called when the user taps Done.
    var onDone: () -> Void

    private static let tailHeight: CGFloat = 9

    @State private var mode: HijriCalendarMode = HijriSettings.shared.mode
    @State private var dayOffset: Int = HijriSettings.shared.dayOffset
    @State private var showsRamadanAdjustment: Bool = HijriSettings.shared.isRamadanAdjustmentRelevant()

    private var offsetLabel: String { dayOffset > 0 ? "+\(dayOffset)" : "\(dayOffset)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(NSLocalizedString("hijri_mode_subtitle", value: "Hijri calendar", comment: "Title of the Hijri calendar callout"))
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.65))
                Spacer(minLength: 12)
                Button(action: onDone) {
                    Text(NSLocalizedString("done", value: "Done", comment: ""))
                        .font(.footnote).fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(HijriCalendarMode.allCases) { option in
                    modeRow(option)
                }
            }

            // Only in Ramadan and on the eve of it — the rest of the year a day offset
            // is noise, and an always-visible stepper invites people to desync their
            // calendar for no reason.
            if showsRamadanAdjustment {
                ramadanRow
            }

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)

            HStack {
                Text(Self.gregorianString())
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 12 + Self.tailHeight)
        .frame(width: 268)
        .background(
            ZStack {
                // Dark blur, clipped to the bubble so the tail is frosted too — the
                // gradient behind the date line is bright enough that a flat scrim
                // alone left the text hard to read.
                Blur(style: .systemThickMaterialDark)
                    .clipShape(HijriCalloutBubble(tailHeight: Self.tailHeight))
                HijriCalloutBubble(tailHeight: Self.tailHeight)
                    .fill(Color.black.opacity(0.55))
                HijriCalloutBubble(tailHeight: Self.tailHeight)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
        )
    }

    // MARK: - Rows

    private func modeRow(_ option: HijriCalendarMode) -> some View {
        Button {
            select(option)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: option == mode ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 13))
                    .foregroundColor(option == mode ? .white : .white.opacity(0.45))

                Text(option.localizedName)
                    .font(.footnote)
                    .fontWeight(option == mode ? .semibold : .regular)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer(minLength: 10)

                // What this calendar says the date is right now — the whole point of
                // showing the options together instead of one at a time.
                Text(HijriSettings.shared.previewString(mode: option, dayOffset: dayOffset))
                    .font(.caption)
                    .foregroundColor(.white.opacity(option == mode ? 0.9 : 0.6))
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var ramadanRow: some View {
        HStack(spacing: 8) {
            Text(NSLocalizedString("hijri_ramadan_adjust", value: "Ramadan day", comment: "Label for the ±1 day Ramadan correction"))
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer(minLength: 4)

            stepButton(systemName: "minus",
                       enabled: dayOffset > HijriSettings.offsetRange.lowerBound) { adjust(-1) }

            Text(offsetLabel)
                .font(.footnote.monospacedDigit()).fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(minWidth: 24)

            stepButton(systemName: "plus",
                       enabled: dayOffset < HijriSettings.offsetRange.upperBound) { adjust(1) }
        }
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(enabled ? 0.16 : 0.06)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: - Helpers

    private static func gregorianString(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.calendar = Calendar(identifier: .gregorian)
        return df.string(from: date)
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
        // Changing the calendar or the offset can move today in or out of the Ramadan
        // window, so re-evaluate rather than leaving a stale stepper.
        showsRamadanAdjustment = HijriSettings.shared.isRamadanAdjustmentRelevant()
        onChange()
    }
}
