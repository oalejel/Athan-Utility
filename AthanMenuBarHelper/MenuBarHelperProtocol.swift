//
//  MenuBarHelperProtocol.swift
//  Athan Utility — shared between the Mac Catalyst app and the AppKit helper bundle.
//
//  Mac Catalyst can't create an NSStatusItem directly (AppKit is hidden), so the menu bar
//  item + popover live in a native-macOS bundle (`AthanMenuBarHelper.bundle`) that the
//  Catalyst app loads at runtime. Both targets compile this file so they agree on the
//  interface. The popover can't see AthanManager/Adhan (different module), so the app pushes
//  a plain `MenuBarSnapshot` across this boundary and receives bell taps via the delegate.
//

import Foundation
import CoreGraphics

/// Implemented by the native-macOS helper bundle; called from the Catalyst app.
@objc public protocol MenuBarHelping: NSObjectProtocol {
    /// Create the status item if absent. Idempotent and cheap (called on a timer);
    /// deliberately does NOT un-hide an item the user drag-removed.
    func installStatusItem()
    /// Explicit user request to bring the icon back: destroys any stale/drag-removed
    /// item and vends a fresh visible one. (Un-hiding a drag-removed item in place
    /// does not work — AppKit detaches it from the status bar permanently.)
    func restoreStatusItem()
    /// Update the menu bar title text and its leading glyph (an SF Symbol name
    /// reflecting the current time of day). `urgent` renders the title red
    /// (used when < 30 min remain).
    func updateTitle(_ title: String, urgent: Bool, glyph: String)
    /// Remove the status item from the menu bar.
    func removeStatusItem()
    /// The app registers itself to receive popover interactions (bell taps).
    func setActionDelegate(_ delegate: MenuBarActionDelegate)
    /// Push the latest prayer times / location / gradient for the popover to render.
    func updateSnapshot(_ snapshot: MenuBarSnapshot)
    /// Whether the status item is actually showing in the menu bar right now —
    /// false if the user ⌘-dragged it out (the NSStatusItem object still exists
    /// with isVisible=false; it isn't fully torn down until removeStatusItem()).
    func isStatusItemVisible() -> Bool
}

/// Implemented by the app; called from the helper bundle when the user interacts with the popover.
@objc public protocol MenuBarActionDelegate: NSObjectProtocol {
    /// The user tapped the bell for the prayer at `prayerIndex` (0…5).
    func menuBarToggleBell(prayerIndex: Int)
    /// The user chose a calculation method (index into the snapshot's `methodOptions`).
    func menuBarSetMethod(index: Int)
    /// The user chose an athan sound (index into the snapshot's `soundOptions`).
    func menuBarSetSound(index: Int)
    /// The user picked how the menu-bar title shows time (0 = countdown, 1 = start time).
    func menuBarSetDisplayMode(_ mode: Int)
    /// The user flipped silent mode: notifications still arrive, they just use the system
    /// sound instead of the athan recording.
    func menuBarSetSilentMode(_ silent: Bool)
    /// Open the main app on its Settings screen (gear button in the popover).
    func menuBarOpenSettings()
    /// Open the app on its location settings (the location row in the popover).
    func menuBarOpenLocationSettings()
    /// Bring the main window back. Once the last window closes the scene is gone, and
    /// only UIKit can vend a new one — the AppKit helper has no way to do it.
    func menuBarOpenWindow()
    /// macOS accepted the status item but never gave it a slot in the menu bar — the
    /// bar is full (easy to hit on a notched display). The app surfaces this rather
    /// than letting the Add button look broken.
    func menuBarPlacementFailed()
    /// The status item's visibility changed outside of our own show/hide calls —
    /// concretely, the user ⌘-dragged it out of (or back into) the menu bar.
    func menuBarVisibilityChanged(_ visible: Bool)
}

/// One row of the popover: a prayer, its time, and whether its alert (bell) is on.
public final class MenuBarPrayerRow: NSObject {
    public let name: String
    public let timeText: String
    public let isBellOn: Bool
    public let isCurrent: Bool
    public let prayerIndex: Int
    public init(name: String, timeText: String, isBellOn: Bool, isCurrent: Bool, prayerIndex: Int) {
        self.name = name
        self.timeText = timeText
        self.isBellOn = isBellOn
        self.isCurrent = isCurrent
        self.prayerIndex = prayerIndex
    }
}

/// Everything the popover needs to render: rows, location, and the user's gradient (top/bottom).
public final class MenuBarSnapshot: NSObject {
    public let rows: [MenuBarPrayerRow]
    public let locationText: String
    public let methodOptions: [String]
    public let methodIndex: Int
    public let soundOptions: [String]
    public let soundIndex: Int
    public let displayMode: Int          // 0 = countdown, 1 = start time
    public let silentMode: Bool          // true = system sound instead of the athan
    public let countdownLabel: String    // e.g. "Fajr -6h 1m"  (the actual timeLeft title)
    public let startTimeLabel: String    // e.g. "Fajr: 3:38 PM" (the actual startTime title)
    public let topColor: CGColor
    public let bottomColor: CGColor
    public init(rows: [MenuBarPrayerRow], locationText: String,
                methodOptions: [String], methodIndex: Int,
                soundOptions: [String], soundIndex: Int,
                displayMode: Int, silentMode: Bool,
                countdownLabel: String, startTimeLabel: String,
                topColor: CGColor, bottomColor: CGColor) {
        self.rows = rows
        self.locationText = locationText
        self.methodOptions = methodOptions
        self.methodIndex = methodIndex
        self.soundOptions = soundOptions
        self.soundIndex = soundIndex
        self.displayMode = displayMode
        self.silentMode = silentMode
        self.countdownLabel = countdownLabel
        self.startTimeLabel = startTimeLabel
        self.topColor = topColor
        self.bottomColor = bottomColor
    }
}
