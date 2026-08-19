//
//  DayBrowseState.swift
//  Athan Utility
//
//  The main screen's temporary "peek at another day" mode.
//
//  Tapping the prayer-times box reveals arrows either side of the Hijri date; the
//  arrows step the whole screen forward or back a day. It is deliberately transient —
//  it times out on its own and resets to today — because it's a glance, not a
//  navigation state the user should be able to get stranded in.
//

import Foundation
import SwiftUI
import Adhan

final class DayBrowseState: ObservableObject {

    static let shared = DayBrowseState()

    /// Arrows are showing.
    @Published private(set) var isActive = false
    /// Days from today. Zero means we're showing today, even while active.
    @Published private(set) var offset = 0
    /// Times for the browsed day, recomputed only on a step (not on every body pass).
    @Published private(set) var times: PrayerTimes?

    /// How long an untouched browse lasts before snapping back to today.
    private static let timeout: TimeInterval = 5
    private var timer: Timer?

    private init() {}

    /// The date being shown — used for the Hijri line so it moves with the times.
    ///
    /// Adds a calendar *day* in the location's own time zone, not 86400 seconds: on a
    /// DST boundary the day is 23 or 25 hours long, and stepping by a fixed interval
    /// there either repeats or skips a date. This is the same rule the times themselves
    /// go through (AthanManager.adjacentDayReference), so the date line and the times
    /// can't disagree about which day is being shown.
    var displayDate: Date {
        guard offset != 0 else { return Date() }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = AthanManager.shared.locationSettings.timeZone
        return cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    }

    /// "+2" / "−1". Empty at zero so callers can just check isEmpty.
    var offsetLabel: String {
        guard offset != 0 else { return "" }
        return offset > 0 ? "+\(offset)" : "\u{2212}\(abs(offset))"
    }

    /// Tap on the prayer-times box: open if closed, dismiss if already open.
    func toggle() {
        tap()
        if isActive {
            dismiss(haptic: false)
        } else {
            withAnimation(.easeOut(duration: 0.25)) { isActive = true }
            restartTimeout()
        }
    }

    func step(_ delta: Int) {
        tap()
        offset += delta
        times = AthanManager.shared.times(daysFromToday: offset)
        restartTimeout()
    }

    func dismiss(haptic: Bool = true) {
        if haptic { tap() }
        timer?.invalidate()
        timer = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            isActive = false
            offset = 0
        }
        times = nil
    }

    // MARK: - Private

    private func restartTimeout() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.timeout, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    private func tap() {
        #if !os(watchOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
