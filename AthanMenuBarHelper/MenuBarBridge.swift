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

extension Notification.Name {
    /// Posted when the menu-bar popover's gear button is tapped; MainSwiftUI shows Settings.
    static let athanShowMacSettings = Notification.Name("AthanShowMacSettings")
}

func mbDebug(_ s: String) { NSLog("ATHAN-MB: %@", s) }

final class MenuBarBridge {
    static let shared = MenuBarBridge()
    private var helper: MenuBarHelping?

    /// Load the helper bundle (if not already) and show the menu bar item.
    func start() {
        mbDebug("start() called")
        guard helper == nil else { mbDebug("helper already set"); return }
        guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
            mbDebug("no PlugIns URL")
            return
        }
        let bundleURL = pluginsURL.appendingPathComponent("AthanMenuBarHelper.bundle")
        mbDebug(String(format: "bundle path = %@", bundleURL.path))
        guard let bundle = Bundle(url: bundleURL) else {
            mbDebug(String(format: "helper bundle NOT FOUND at %@", bundleURL.path))
            return
        }
        do {
            try bundle.loadAndReturnError()
        } catch {
            mbDebug("bundle.load ERROR: \(error)")
            return
        }
        guard let cls = bundle.principalClass as? NSObject.Type else {
            mbDebug(String(format: "principalClass is not NSObject.Type (%@)", String(describing: bundle.principalClass)))
            return
        }
        let instance = cls.init()
        // MenuBarHelperProtocol.swift is compiled into BOTH the app and the loaded bundle, so a
        // plain `as? MenuBarHelping` (and even objc protocol-object comparison) fails across the
        // dlopen boundary. Verify the instance implements the @objc methods via the ObjC method
        // list (reliable), then bridge the single-pointer @objc class-protocol existential.
        guard instance.responds(to: Selector(("installStatusItem"))) else {
            mbDebug("instance does not respond to installStatusItem")
            return
        }
        let helper = unsafeBitCast(instance, to: MenuBarHelping.self)
        self.helper = helper
        helper.installStatusItem()
        helper.updateTitle("Athan", urgent: false)
        mbDebug("installStatusItem + updateTitle done")
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

    /// Menu-bar-only mode: hide the Dock icon + windows (accessory) or restore the normal app.
    func setDockIconHidden(_ hidden: Bool) {
        helper?.setDockIconHidden(hidden)
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
    private static let menuBarOnlyKey = "MenuBarOnly"

    static var mode: MenuBarDisplayMode {
        get { MenuBarDisplayMode(rawValue: suite?.integer(forKey: modeKey) ?? 0) ?? .timeLeft }
        set { suite?.set(newValue.rawValue, forKey: modeKey) }
    }
    static var isHidden: Bool {
        get { suite?.bool(forKey: hiddenKey) ?? false }
        set { suite?.set(newValue, forKey: hiddenKey) }
    }
    /// Menu-bar-only mode: no Dock icon, window hidden, popover as the primary UI.
    static var menuBarOnly: Bool {
        get { suite?.bool(forKey: menuBarOnlyKey) ?? false }
        set { suite?.set(newValue, forKey: menuBarOnlyKey) }
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
        let methods = CalculationMethod.usefulCases()
        let sounds = NotificationSettings.Sounds.allCases
        let nextTime = m.guaranteedNextPrayerTime()
        let countdownLabel = "-\(Self.countdownString(nextTime.timeIntervalSinceNow))"   // "-6h 1m"
        let startTimeLabel = Self.clockFormatter.string(from: nextTime)                   // "3:38 PM"
        return MenuBarSnapshot(rows: rows,
                               locationText: m.locationSettings.locationName,
                               methodOptions: methods.map { $0.localizedString() },
                               methodIndex: methods.firstIndex(of: m.prayerSettings.calculationMethod) ?? 0,
                               soundOptions: sounds.map { $0.localizedString() },
                               soundIndex: m.notificationSettings.selectedSound.rawValue,
                               displayMode: MenuBarSettings.mode.rawValue,
                               countdownLabel: countdownLabel,
                               startTimeLabel: startTimeLabel,
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

    func menuBarSetMethod(index: Int) {
        let m = AthanManager.shared
        let methods = CalculationMethod.usefulCases()
        guard methods.indices.contains(index),
              let updated = m.prayerSettings.copy() as? PrayerSettings else { return }
        updated.calculationMethod = methods[index]
        m.prayerSettings = updated             // didSet archives + recalculates
        m.reloadSettingsAndNotifications()
        pushSnapshot()
    }

    func menuBarSetSound(index: Int) {
        let m = AthanManager.shared
        guard let sound = NotificationSettings.Sounds(rawValue: index),
              let updated = m.notificationSettings.copy() as? NotificationSettings else { return }
        updated.selectedSound = sound
        m.notificationSettings = updated
        m.reloadSettingsAndNotifications()
        pushSnapshot()
    }

    func menuBarSetDisplayMode(_ mode: Int) {
        MenuBarSettings.mode = MenuBarDisplayMode(rawValue: mode) ?? .timeLeft
        tick()          // refresh the title immediately
    }

    func menuBarOpenSettings() {
        NotificationCenter.default.post(name: .athanShowMacSettings, object: nil)
    }

    func menuBarLaunchWindow() {
        // Opening the window is an intentional exit from menu-bar-only mode.
        MenuBarSettings.menuBarOnly = false
    }

    /// "1:23:45" (H:MM:SS) when ≥ 1h remains, otherwise "23:45" (MM:SS).
    /// "6h 1m" / "43m" / "<1m" — hours + minutes only, never a ticking seconds counter.
    static func countdownString(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let h = total / 3600, m = (total % 3600) / 60
        if total < 60 { return "<1m" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
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
