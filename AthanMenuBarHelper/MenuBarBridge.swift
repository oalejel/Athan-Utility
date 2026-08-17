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
    /// Posted whenever the status item's actual visibility changes (e.g. the user
    /// ⌘-dragged it out of, or back into, the menu bar). object is the new Bool.
    /// MacSettingsView listens so its "Show menu bar icon" toggle stays truthful.
    static let athanMenuBarItemVisibilityChanged = Notification.Name("AthanMenuBarItemVisibilityChanged")
    /// Posted when macOS accepted the status item but gave it no slot — a full menu bar.
    static let athanMenuBarPlacementFailed = Notification.Name("AthanMenuBarPlacementFailed")
    /// Posted when the popover's location row is clicked; the sidebar opens its editor.
    static let athanShowMacLocationSettings = Notification.Name("AthanShowMacLocationSettings")
    /// Posted when silent mode is toggled anywhere, so the sidebar and the popover — which
    /// both show it and neither of which observes NotificationSettings — stay in step.
    static let athanSilentModeChanged = Notification.Name("AthanSilentModeChanged")
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
        helper.updateTitle("Athan", urgent: false, glyph: "moon.stars.fill")
        mbDebug("installStatusItem + updateTitle done")
    }

    /// Update the menu bar title + leading glyph (driven by `MenuBarController`).
    func updateTitle(_ title: String, urgent: Bool, glyph: String) {
        helper?.updateTitle(title, urgent: urgent, glyph: glyph)
    }

    /// Make sure the status item exists. Called every tick, so it's deliberately
    /// passive: it will NOT re-show an item the user drag-removed (see restoreItem).
    func ensureItem() {
        if helper == nil { start(); return }
        helper?.installStatusItem()
    }

    /// Explicit user request (the Settings toggle) to bring the icon back — recreates
    /// the status item from scratch, which is the only thing that works after a
    /// ⌘-drag removal.
    func restoreItem() {
        mbDebug("restoreItem() called, helper is \(helper == nil ? "nil" : "set")")
        // Always finish through restoreStatusItem(), even on the path where we had to
        // load the bundle first. start()'s plain install reuses the stable autosave
        // name, and after a drag-out in an EARLIER run that name still carries AppKit's
        // "user removed this" record — so the item would be created and then quietly
        // hidden. restoreStatusItem() vends one with an identity AppKit has never seen.
        if helper == nil { start() }
        helper?.restoreStatusItem()
        mbDebug("restoreItem() done, isItemVisible now \(isItemVisible)")
    }

    /// Hide the status item but keep the helper loaded so it can be re-added.
    func removeItem() {
        mbDebug("removeItem() called")
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

    /// Whether the status item is actually showing right now — false if the
    /// user ⌘-dragged it out, even though the helper/item object still exists.
    var isItemVisible: Bool {
        helper?.isStatusItemVisible() ?? false
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
        // The user removed the icon by dragging it out. Do nothing at all — in
        // particular do NOT call removeItem() here. This tick runs every second, and
        // having it tear the item down meant it was racing the one thing that puts the
        // icon back; a freshly created item could be destroyed within the second.
        // Removal is the drag itself; restoring is the explicit Add button.
        if MenuBarSettings.isHidden { return }

        // Ensure the item exists (e.g. first tick after launch).
        MenuBarBridge.shared.ensureItem()

        let manager = AthanManager.shared
        guard manager.todayTimes != nil, manager.tomorrowTimes != nil, manager.yesterdayTimes != nil else {
            MenuBarBridge.shared.updateTitle("Athan", urgent: false, glyph: "moon.stars.fill")
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
        // Glyph reflects the CURRENT time of day (the prayer we're inside now),
        // not the upcoming one — e.g. during Shuruq it should read as daytime,
        // not a moon.
        // currentPrayer is nil pre-Fajr (deep night) → fall back to the night glyph.
        MenuBarBridge.shared.updateTitle(title, urgent: urgent, glyph: Self.glyph(for: manager.currentPrayer ?? .isha))
        pushSnapshot()
    }

    /// SF Symbol reflecting the time of day for the current prayer period.
    static func glyph(for prayer: Prayer) -> String {
        switch prayer {
        case .fajr:    return "moon.stars.fill"     // pre-dawn
        case .sunrise: return "sunrise.fill"        // Shuruq
        case .dhuhr:   return "sun.max.fill"         // midday
        case .asr:     return "sun.min.fill"         // afternoon
        case .maghrib: return "sunset.fill"          // sunset
        case .isha:    return "moon.stars.fill"     // night
        }
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
                               silentMode: m.notificationSettings.silentMode,
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
        MacToast.shared.show(Strings.bellToastMessage(prayerName: p.localizedOrCustomString(), enabled: setting.athanAlertEnabled))
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

    func menuBarSetSilentMode(_ silent: Bool) {
        let m = AthanManager.shared
        guard let updated = m.notificationSettings.copy() as? NotificationSettings else { return }
        updated.silentMode = silent
        m.notificationSettings = updated       // didSet archives
        m.reloadSettingsAndNotifications()      // reschedule with the new sound
        pushSnapshot()
        MacToast.shared.show(Strings.silentModeToastMessage(silenced: silent))
        // The sidebar reads the same setting and has no way to know it changed.
        NotificationCenter.default.post(name: .athanSilentModeChanged, object: silent)
    }

    func menuBarSetDisplayMode(_ mode: Int) {
        MenuBarSettings.mode = MenuBarDisplayMode(rawValue: mode) ?? .timeLeft
        tick()          // refresh the title immediately
    }

    func menuBarOpenWindow() {
        DispatchQueue.main.async {
            let options = UIScene.ActivationRequestOptions()
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil,
                                                               options: options, errorHandler: nil)
        }
    }

    func menuBarOpenLocationSettings() {
        NotificationCenter.default.post(name: .athanShowMacLocationSettings, object: nil)
    }

    func menuBarOpenSettings() {
        NotificationCenter.default.post(name: .athanShowMacSettings, object: nil)
    }

    func menuBarPlacementFailed() {
        NotificationCenter.default.post(name: .athanMenuBarPlacementFailed, object: nil)
    }

    func menuBarVisibilityChanged(_ visible: Bool) {
        // Keep the persisted preference truthful: a drag-out is functionally
        // the same as the user turning the Settings toggle off, and a drag-back-in
        // is the same as turning it on — so the next launch (and the Settings
        // toggle right now) both reflect what's actually showing.
        MenuBarSettings.isHidden = !visible
        NotificationCenter.default.post(name: .athanMenuBarItemVisibilityChanged, object: visible)
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
