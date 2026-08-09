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
    /// Create and show the status item in the macOS menu bar.
    func installStatusItem()
    /// Update the menu bar title text. `urgent` renders it red (used when < 30 min remain).
    func updateTitle(_ title: String, urgent: Bool)
    /// Remove the status item from the menu bar.
    func removeStatusItem()
    /// The app registers itself to receive popover interactions (bell taps).
    func setActionDelegate(_ delegate: MenuBarActionDelegate)
    /// Push the latest prayer times / location / gradient for the popover to render.
    func updateSnapshot(_ snapshot: MenuBarSnapshot)
    /// Menu-bar-only mode: hide the Dock icon + windows (accessory) or restore the normal app.
    func setDockIconHidden(_ hidden: Bool)
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
    /// Open the main app on its Settings screen (gear button in the popover).
    func menuBarOpenSettings()
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
    public let topColor: CGColor
    public let bottomColor: CGColor
    public init(rows: [MenuBarPrayerRow], locationText: String,
                methodOptions: [String], methodIndex: Int,
                soundOptions: [String], soundIndex: Int,
                displayMode: Int,
                topColor: CGColor, bottomColor: CGColor) {
        self.rows = rows
        self.locationText = locationText
        self.methodOptions = methodOptions
        self.methodIndex = methodIndex
        self.soundOptions = soundOptions
        self.soundIndex = soundIndex
        self.displayMode = displayMode
        self.topColor = topColor
        self.bottomColor = bottomColor
    }
}
