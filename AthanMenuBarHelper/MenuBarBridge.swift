//
//  MenuBarBridge.swift
//  Athan Utility (app target, Mac Catalyst only)
//
//  Loads the native-macOS `AthanMenuBarHelper.bundle` at runtime and drives the menu bar
//  item through the shared `MenuBarHelping` protocol. No-op on iOS/iPadOS.
//

#if targetEnvironment(macCatalyst)
import Foundation
import UIKit
import Adhan

final class MenuBarBridge {
    static let shared = MenuBarBridge()
    private var helper: MenuBarHelping?

    /// Load the helper bundle (if not already) and show the menu bar item.
    func start() {
        guard helper == nil else { return }
        guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
            print("MenuBarBridge: no PlugIns URL")
            return
        }
        let bundleURL = pluginsURL.appendingPathComponent("AthanMenuBarHelper.bundle")
        guard let bundle = Bundle(url: bundleURL) else {
            print("MenuBarBridge: helper bundle not found at \(bundleURL.path)")
            return
        }
        guard bundle.load() else {
            print("MenuBarBridge: failed to load helper bundle")
            return
        }
        guard let cls = bundle.principalClass as? NSObject.Type,
              let instance = cls.init() as? MenuBarHelping else {
            print("MenuBarBridge: principal class is not a MenuBarHelping")
            return
        }
        helper = instance
        instance.installStatusItem()
        instance.updateTitle("Athan", urgent: false)
    }

    /// Update the menu bar title (driven by `MenuBarController`).
    func updateTitle(_ title: String, urgent: Bool) {
        helper?.updateTitle(title, urgent: urgent)
    }

    /// Make sure the status item is present (re-adds it after it was hidden). Loads the
    /// helper bundle first if needed.
    func ensureItem() {
        if helper == nil { start(); return }
        helper?.installStatusItem()
    }

    /// Hide the status item but keep the helper loaded so it can be re-added.
    func removeItem() {
        helper?.removeStatusItem()
    }

    /// Register the app object that receives popover interactions (bell taps).
    func setActionDelegate(_ delegate: MenuBarActionDelegate) {
        helper?.setActionDelegate(delegate)
    }

    /// Push the latest prayer/location/gradient snapshot for the popover.
    func updateSnapshot(_ snapshot: MenuBarSnapshot) {
        helper?.updateSnapshot(snapshot)
    }

    func stop() {
        helper?.removeStatusItem()
        helper = nil
    }
}

// MARK: - Menu bar display settings

/// How the menu bar item shows the next prayer.
enum MenuBarDisplayMode: Int {
    case timeLeft = 0   // "Asr -1:23:45"
    case nextTime = 1   // "Asr: 3:41 PM"
}

/// Persisted in the app group so the (future) popover in the helper bundle can read it too.
enum MenuBarSettings {
    private static let suite = UserDefaults(suiteName: "group.athanUtil")
    private static let modeKey = "MenuBarDisplayMode"
    private static let hiddenKey = "MenuBarHidden"

    static var mode: MenuBarDisplayMode {
        get { MenuBarDisplayMode(rawValue: suite?.integer(forKey: modeKey) ?? 0) ?? .timeLeft }
        set { suite?.set(newValue.rawValue, forKey: modeKey) }
    }
    static var isHidden: Bool {
        get { suite?.bool(forKey: hiddenKey) ?? false }
        set { suite?.set(newValue, forKey: hiddenKey) }
    }
}

// MARK: - Menu bar title driver

/// Recomputes the menu bar title + popover snapshot from the live prayer state on a
/// 1-second timer and pushes them to the helper bundle. Handles both display modes, the
/// < 30-minute red state, and bell toggles from the popover.
final class MenuBarController: NSObject, MenuBarActionDelegate {
    static let shared = MenuBarController()
    private var timer: Timer?

    /// Turn the title red when this many seconds or fewer remain until the next prayer.
    private let urgentThreshold: TimeInterval = 30 * 60

    func start() {
        MenuBarBridge.shared.setActionDelegate(self)
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    func refreshNow() { tick() }

    private func tick() {
        if MenuBarSettings.isHidden {
            MenuBarBridge.shared.removeItem()
            return
        }
        // Ensure the item exists (it may have been removed while hidden).
        MenuBarBridge.shared.ensureItem()

        let manager = AthanManager.shared
        guard manager.todayTimes != nil, manager.tomorrowTimes != nil, manager.yesterdayTimes != nil else {
            MenuBarBridge.shared.updateTitle("Athan", urgent: false)
            return
        }

        let prayer = manager.guaranteedNextPrayer()
        let date = manager.guaranteedNextPrayerTime()
        let name = prayer.localizedOrCustomString()
        let remaining = date.timeIntervalSinceNow
        let urgent = remaining > 0 && remaining <= urgentThreshold

        let title: String
        switch MenuBarSettings.mode {
        case .timeLeft:
            title = "\(name) -\(Self.countdownString(remaining))"
        case .nextTime:
            title = "\(name): \(Self.clockFormatter.string(from: date))"
        }
        MenuBarBridge.shared.updateTitle(title, urgent: urgent)
        pushSnapshot()
    }

    // MARK: - Popover snapshot

    private func pushSnapshot() {
        guard let snap = buildSnapshot() else { return }
        MenuBarBridge.shared.updateSnapshot(snap)
    }

    private func buildSnapshot() -> MenuBarSnapshot? {
        let m = AthanManager.shared
        guard m.todayTimes != nil else { return nil }

        let appearance = m.appearanceSettings
        let ctxPrayer: Prayer? = appearance.isDynamic ? (m.currentPrayer ?? .fajr) : nil
        let (c1, c2) = appearance.colorTuplesForContext(optionalPrayer: ctxPrayer)
        let top = UIColor(red: CGFloat(c1.0), green: CGFloat(c1.1), blue: CGFloat(c1.2), alpha: 1).cgColor
        let bottom = UIColor(red: CGFloat(c2.0), green: CGFloat(c2.1), blue: CGFloat(c2.2), alpha: 1).cgColor

        let currentIndex = m.currentPrayer?.rawValue()
        var rows: [MenuBarPrayerRow] = []
        for i in 0..<6 {
            let p = Prayer(index: i)
            let date = m.todayTimes.time(for: p)
            let bell = m.notificationSettings.settings[p]?.athanAlertEnabled ?? false
            rows.append(MenuBarPrayerRow(
                name: p.localizedOrCustomString(),
                timeText: Self.clockFormatter.string(from: date),
                isBellOn: bell,
                isCurrent: i == currentIndex,
                prayerIndex: i
            ))
        }
        return MenuBarSnapshot(rows: rows,
                               locationText: m.locationSettings.locationName,
                               topColor: top,
                               bottomColor: bottom)
    }

    // MARK: - MenuBarActionDelegate

    func menuBarToggleBell(prayerIndex: Int) {
        let m = AthanManager.shared
        let p = Prayer(index: prayerIndex)
        guard let updated = m.notificationSettings.copy() as? NotificationSettings,
              let setting = updated.settings[p] else { return }
        setting.athanAlertEnabled.toggle()
        m.notificationSettings = updated      // didSet archives
        m.reloadSettingsAndNotifications()     // reschedule with the new bell state
        pushSnapshot()                         // reflect it in the popover immediately
    }

    /// "1:23:45" (H:MM:SS) when ≥ 1h remains, otherwise "23:45" (MM:SS).
    static func countdownString(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }

    /// Locale-aware short time (respects 12/24-hour).
    static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
}
#endif
