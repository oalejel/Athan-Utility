//
//  AthanMenuBarHelper.swift
//  AthanMenuBarHelper (native macOS AppKit bundle)
//
//  Principal class of the helper bundle. Runs as native AppKit code inside the Catalyst
//  process, so it CAN own an NSStatusItem + NSPopover.
//
//  IMPORTANT: this bundle must NOT use SwiftUI. It is a native-macOS binary loaded into a
//  Mac Catalyst (iOSSupport) process; SwiftUI symbols like NSHostingController resolve against
//  the iOSSupport SwiftUI, which doesn't export them, and the whole bundle fails to dlopen.
//  The popover is therefore built entirely in AppKit views.
//

import AppKit
import ObjectiveC

private let kGold = NSColor(red: 0.957, green: 0.835, blue: 0.553, alpha: 1)

@objc(AthanMenuBarHelper)
public final class AthanMenuBarHelper: NSObject, MenuBarHelping, NSPopoverDelegate {

    private var statusItem: NSStatusItem?
    private weak var actionDelegate: MenuBarActionDelegate?
    private var snapshot: MenuBarSnapshot?
    private var popover: NSPopover?
    private var popoverVC: MenuBarPopoverController?
    // Watches for the user ⌘-dragging the item out of (or back into) the menu
    // bar — that only flips isVisible, it doesn't tear down the NSStatusItem
    // object, so installStatusItem()'s "already exists" guard would otherwise
    // silently no-op and never notice.
    private var visibilityObservation: NSKeyValueObservation?

    public override init() { super.init() }

    // MARK: MenuBarHelping

    /// Idempotent + cheap: this is what the per-second title tick calls. If the item
    /// exists and is showing, do nothing. If it exists but is hidden, LEAVE IT hidden —
    /// that means the user ⌘-dragged it out, and the tick must not fight that choice.
    /// Restoring after a drag-out is an explicit user action; see `restoreStatusItem()`.
    public func installStatusItem() {
        if let existing = statusItem {
            if !existing.isVisible {
                NSLog("ATHAN-MB-HELPER: installStatusItem() - item exists but hidden (drag-removed); leaving it to restoreStatusItem()")
            }
            return
        }
        NSLog("ATHAN-MB-HELPER: installStatusItem() - creating a brand new NSStatusItem")
        createStatusItem()
    }

    /// Explicit "user asked for the icon back" path (the Settings toggle).
    ///
    /// Setting `isVisible = true` on a ⌘-drag-removed NSStatusItem does NOT bring it
    /// back — AppKit detaches that object from the status bar permanently, so the old
    /// code's un-hide-in-place was a silent no-op. The only reliable restore is to
    /// destroy the stale item and vend a brand new one, which is what this does.
    public func restoreStatusItem() {
        NSLog("ATHAN-MB-HELPER: restoreStatusItem() - tearing down stale item (%@) and recreating",
              statusItem == nil ? "none" : "present")
        // Clear ONLY the visibility record for our own name — that is the thing that
        // re-hides a freshly created item. The *preferred position* for the same name is
        // deliberately kept: a status item with no remembered position is appended at the
        // leftmost slot, which on a notched display is exactly where it cannot be seen.
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("NSStatusItem Visible") {
            NSLog("ATHAN-MB-HELPER: clearing persisted visibility key '%@'", key)
            defaults.removeObject(forKey: key)
        }
        visibilityObservation?.invalidate()
        visibilityObservation = nil
        if let existing = statusItem { NSStatusBar.system.removeStatusItem(existing) }
        statusItem = nil
        createStatusItem()
    }

    /// One stable autosave name, always. A per-restore unique name does dodge AppKit's
    /// persisted "the user removed this" record, but it also throws away the remembered
    /// position, so the item is appended at the leftmost slot — under the notch on the
    /// laptops where this matters. Keeping the name and deleting just the visibility
    /// record (see restoreStatusItem) gets the un-hide without losing the position.
    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "AthanUtilityStatusItem"
        // Let the user ⌘-drag the item off the menu bar (matches every other
        // menu-bar app); we detect that via the isVisible KVO below instead of
        // relying on AppKit to tell the app to quit or anything like that.
        //
        // Order matters: assigning autosaveName (above) can apply that name's stored
        // visibility, so isVisible is set AFTER it, never before.
        item.behavior = [.removalAllowed]
        item.isVisible = true
        if let button = item.button {
            if let img = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "Athan Utility") {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageLeading
            }
            button.title = "Athan"
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        keepRunningWhileInMenuBar()
        keepRunningThroughCommandQ()
        NSLog("ATHAN-MB-HELPER: installStatusItem() - new item created, isVisible=%@, button=%@",
              item.isVisible ? "true" : "false",
              item.button == nil ? "nil" : "present")

        visibilityObservation = item.observe(\.isVisible, options: [.new]) { [weak self] _, change in
            guard let self, let visible = change.newValue else { return }
            NSLog("ATHAN-MB-HELPER: KVO isVisible changed -> %@", visible ? "true" : "false")
            self.actionDelegate?.menuBarVisibilityChanged(visible)
        }

        // AppKit can flip isVisible back a runloop turn later off its own persisted
        // state. Check, log it, and insist once — so a silent re-hide is both visible
        // in the log and corrected instead of just losing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, let current = self.statusItem, current === item else { return }
            NSLog("ATHAN-MB-HELPER: post-create check, isVisible=%@, autosave=%@",
                  current.isVisible ? "true" : "false", current.autosaveName ?? "nil")
            if !current.isVisible {
                NSLog("ATHAN-MB-HELPER: AppKit re-hid the fresh item — forcing visible again")
                current.isVisible = true
            }
            // isVisible == true only means AppKit accepted the item; it does not mean the
            // user can see it. A crowded menu bar (very easy to hit on a notched display)
            // places new items where there is no room to draw them, so log where this one
            // actually landed relative to the screen.
            let frame = current.button?.window?.frame ?? .zero
            let screen = NSScreen.main?.frame ?? .zero
            NSLog("ATHAN-MB-HELPER: item frame=%@ screenWidth=%.0f length=%.1f title='%@' image=%@",
                  NSStringFromRect(frame), screen.width, current.length,
                  current.button?.title ?? "nil",
                  current.button?.image == nil ? "nil" : "set")
            if frame.width < 1 {
                NSLog("ATHAN-MB-HELPER: WARNING item has no width — nothing to draw")
            }
        }

        // The 0.35s sample above is often taken before AppKit has positioned the status
        // window, so it reports a placeholder origin either way and can't tell a placed
        // item from an unplaced one. Sample again once layout has settled: a healthy item
        // sits at the top of a screen (y near the screen height); one that never got a
        // slot — because the menu bar is full, which is easy to hit on a notched display —
        // stays unplaced or has no screen at all.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self, let current = self.statusItem, current === item,
                  let window = current.button?.window else {
                NSLog("ATHAN-MB-HELPER: settled check - no status window")
                return
            }
            let f = window.frame
            let onScreen = window.screen != nil
            NSLog("ATHAN-MB-HELPER: settled check frame=%@ onScreen=%@ windowVisible=%@ screen=%@",
                  NSStringFromRect(f),
                  onScreen ? "yes" : "NO",
                  window.isVisible ? "yes" : "NO",
                  NSStringFromRect(NSScreen.main?.frame ?? .zero))
            if !onScreen || !window.isVisible || f.origin.y < 0 {
                NSLog("ATHAN-MB-HELPER: WARNING item never got a menu bar slot — the menu bar is full")
                self.actionDelegate?.menuBarPlacementFailed()
            }
        }
    }


    /// Keep the process alive when the user closes the window.
    ///
    /// The obvious hook — applicationShouldTerminateAfterLastWindowClosed: — is never
    /// called in a Catalyst app: termination comes from UIKit tearing down the scene when
    /// its window closes, not from AppKit's last-window logic. Measured, not assumed:
    /// closing only the UINSWindow killed the process without that selector ever firing.
    ///
    /// So don't let the window close. Graft windowShouldClose: onto the window delegate's
    /// class, order the window out instead of closing it, and the scene is never destroyed
    /// — which is exactly what a menu bar app does. The window comes back with
    /// makeKeyAndOrderFront from the popover, no scene recreation needed.
    private func keepRunningWhileInMenuBar() {
        installWindowCloseInterceptor(attempt: 1)
    }

    /// Keep the menu bar item alive through ⌘Q.
    ///
    /// Closing the window with the red X goes through windowShouldClose: (see below), which
    /// we already intercept. ⌘Q does not touch the window at all — it is
    /// NSApplication.terminate:, which tears the process down and takes the status item
    /// with it. So intercept the termination too: hide the windows, drop to .accessory, and
    /// answer .terminateCancel, exactly as the close path does.
    ///
    /// The status menu's own Quit item stays a real quit — it sets `userAskedToQuit` first,
    /// which is the only way out of the app now.
    private func keepRunningThroughCommandQ() {
        guard let delegate = NSApp.delegate else { return }
        let cls: AnyClass = type(of: delegate)
        let sel = NSSelectorFromString("applicationShouldTerminate:")
        let block: @convention(block) (AnyObject, AnyObject) -> UInt = { [weak self] _, _ in
            let terminateNow: UInt = 1   // NSApplication.TerminateReply.terminateNow
            let cancel: UInt = 0         // .terminateCancel
            guard let self, self.statusItem != nil, !AthanMenuBarHelper.userAskedToQuit else {
                return terminateNow
            }
            NSLog("ATHAN-MB-HELPER: ⌘Q intercepted — hiding to the menu bar instead of quitting")
            for window in NSApp.windows where NSStringFromClass(type(of: window)) != "NSStatusBarWindow" {
                window.orderOut(nil)
            }
            NSApp.setActivationPolicy(.accessory)
            self.verifyStatusItemSurvivedPolicyChange(attempt: 1)
            return cancel
        }
        let imp = imp_implementationWithBlock(block)
        if !class_addMethod(cls, sel, imp, "Q@:@") {
            class_replaceMethod(cls, sel, imp, "Q@:@")
        }
        NSLog("ATHAN-MB-HELPER: intercepting ⌘Q on %@", NSStringFromClass(cls))
    }

    private func installWindowCloseInterceptor(attempt: Int) {
        // The app's window may not exist yet when the status item is created.
        guard let window = NSApp.windows.first(where: {
            NSStringFromClass(type(of: $0)) != "NSStatusBarWindow" && $0.delegate != nil
        }), let delegate = window.delegate else {
            if attempt < 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.installWindowCloseInterceptor(attempt: attempt + 1)
                }
            } else {
                NSLog("ATHAN-MB-HELPER: no app window found to intercept closing")
            }
            return
        }

        let cls: AnyClass = type(of: delegate)
        let sel = NSSelectorFromString("windowShouldClose:")
        let block: @convention(block) (AnyObject, AnyObject) -> Bool = { [weak self] _, win in
            guard let self, self.statusItem != nil else { return true }
            NSLog("ATHAN-MB-HELPER: window close intercepted — hiding instead of closing")
            (win as? NSWindow)?.orderOut(nil)
            // Out of the Dock too, now that nothing is on screen.
            NSApp.setActivationPolicy(.accessory)
            self.verifyStatusItemSurvivedPolicyChange(attempt: 1)
            return false
        }
        let imp = imp_implementationWithBlock(block)
        if !class_addMethod(cls, sel, imp, "B@:@") {
            class_replaceMethod(cls, sel, imp, "B@:@")
        }
        NSLog("ATHAN-MB-HELPER: intercepting close on %@ (delegate %@)",
              NSStringFromClass(type(of: window)), NSStringFromClass(cls))
    }

    /// The status item does not reliably survive an activation-policy change: AppKit
    /// rebuilds the app's UI presence around the new policy, and an item vended under the
    /// old one can be dropped. Poll a few times before concluding it's gone — placement is
    /// asynchronous, so a single early check reports false negatives — then vend a fresh
    /// one. Closing a window must never cost the user their menu bar icon.
    private func verifyStatusItemSurvivedPolicyChange(attempt: Int) {
        let maxAttempts = 4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            if self.statusItem?.button?.window?.screen != nil {
                NSLog("ATHAN-MB-HELPER: item survived the policy change (attempt %d)", attempt)
                return
            }
            if attempt < maxAttempts {
                self.verifyStatusItemSurvivedPolicyChange(attempt: attempt + 1)
            } else {
                NSLog("ATHAN-MB-HELPER: item lost to the policy change — recreating")
                self.restoreStatusItem()
            }
        }
    }

    public func isStatusItemVisible() -> Bool {
        let v = statusItem?.isVisible ?? false
        NSLog("ATHAN-MB-HELPER: isStatusItemVisible() -> %@ (statusItem is %@)", v ? "true" : "false", statusItem == nil ? "nil" : "set")
        return v
    }

    public func updateTitle(_ title: String, urgent: Bool, glyph: String) {
        guard let button = statusItem?.button else { return }
        let color: NSColor = urgent ? .systemRed : .labelColor
        button.attributedTitle = NSAttributedString(string: title, attributes: [.foregroundColor: color])
        if let img = NSImage(systemSymbolName: glyph, accessibilityDescription: "Athan Utility") {
            img.isTemplate = true
            button.image = img
        }
    }

    public func removeStatusItem() {
        NSLog("ATHAN-MB-HELPER: removeStatusItem() called, statusItem is %@", statusItem == nil ? "nil" : "set")
        visibilityObservation?.invalidate()
        visibilityObservation = nil
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
    }

    public func setActionDelegate(_ delegate: MenuBarActionDelegate) {
        self.actionDelegate = delegate
    }

    public func updateSnapshot(_ snapshot: MenuBarSnapshot) {
        self.snapshot = snapshot
        if popover?.isShown == true {
            popoverVC?.update(snapshot: snapshot)
            applyArrowGradient()   // keep the arrow tint in sync with color changes
        }
    }

    // MARK: - Click handling

    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMiniMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }
        let pop = popover ?? makePopover()
        if pop.isShown {
            pop.performClose(nil)
        } else {
            if let snap = snapshot { popoverVC?.update(snapshot: snap) }
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
            // Tint the popover's frame — including the connector arrow, which
            // NSPopover otherwise fills with a flat system color — with the same
            // gradient. Apply now and again next runloop once the frame has its
            // final size.
            applyArrowGradient()
            DispatchQueue.main.async { [weak self] in self?.applyArrowGradient() }
        }
    }

    /// Inject a gradient-filled view behind the popover's content so the arrow
    /// (part of the popover's window-frame shape) shows the gradient too.
    private func applyArrowGradient() {
        guard let snap = snapshot,
              let frameView = popover?.contentViewController?.view.window?.contentView?.superview
        else { return }
        let gv: PopoverGradientView
        if let existing = frameView.subviews.compactMap({ $0 as? PopoverGradientView }).first {
            gv = existing
        } else {
            gv = PopoverGradientView(frame: frameView.bounds)
            gv.autoresizingMask = [.width, .height]
            frameView.addSubview(gv, positioned: .below, relativeTo: nil)
        }
        gv.frame = frameView.bounds
        gv.setColors(top: snap.topColor, bottom: snap.bottomColor)
    }

    private func makePopover() -> NSPopover {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.delegate = self
        let vc = MenuBarPopoverController()
        vc.onToggleBell     = { [weak self] i in self?.actionDelegate?.menuBarToggleBell(prayerIndex: i) }
        vc.onSetMethod      = { [weak self] i in self?.actionDelegate?.menuBarSetMethod(index: i) }
        vc.onSetSound       = { [weak self] i in self?.actionDelegate?.menuBarSetSound(index: i) }
        vc.onSetDisplayMode = { [weak self] m in self?.actionDelegate?.menuBarSetDisplayMode(m) }
        vc.onSetSilentMode  = { [weak self] s in self?.actionDelegate?.menuBarSetSilentMode(s) }
        vc.onOpenSettings   = { [weak self] in
            self?.openApp()
            self?.actionDelegate?.menuBarOpenSettings()
        }
        vc.onOpenLocationSettings = { [weak self] in
            self?.openApp()
            self?.actionDelegate?.menuBarOpenLocationSettings()
        }
        pop.contentViewController = vc
        popoverVC = vc
        popover = pop
        return pop
    }

    private func showMiniMenu() {
        let menu = NSMenu()
        let open = NSMenuItem(title: NSLocalizedString("open_app", value: "Open Athan Utility", comment: ""),
                              action: #selector(openApp), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: NSLocalizedString("quit_app", value: "Quit Athan Utility", comment: ""),
                              action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil   // reset so left-click toggles the popover next time
    }

    @objc private func openApp() {
        popover?.performClose(nil)
        // Back into the Dock first, then find a window. If the user closed the last one
        // the scene is gone with it, and AppKit can't create a Catalyst scene — so ask
        // the app side, which has UIKit, to vend one.
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSLog("ATHAN-MB-HELPER: no window to show — asking the app for a new scene")
            actionDelegate?.menuBarOpenWindow()
        }
    }

    @objc private func quitApp() {
        // The one path that is allowed to actually end the process.
        AthanMenuBarHelper.userAskedToQuit = true
        NSApp.terminate(nil)
    }

    /// Set only by the status menu's Quit item, so applicationShouldTerminate: can tell a
    /// deliberate quit from ⌘Q.
    fileprivate static var userAskedToQuit = false
}

// MARK: - Popover frame gradient

/// A gradient-filled view placed behind the popover content so the popover's
/// connector arrow (part of its window-frame shape) is tinted with the same
/// top→bottom gradient instead of NSPopover's flat default background.
final class PopoverGradientView: NSView {
    private let grad = CAGradientLayer()
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = grad
        grad.startPoint = CGPoint(x: 0.5, y: 1)   // top
        grad.endPoint   = CGPoint(x: 0.5, y: 0)   // bottom
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func setColors(top: CGColor, bottom: CGColor) { grad.colors = [top, bottom] }
}

// MARK: - Popover content (pure AppKit)

final class MenuBarPopoverController: NSViewController {
    var onToggleBell: ((Int) -> Void)?
    var onSetMethod: ((Int) -> Void)?
    var onSetSound: ((Int) -> Void)?
    var onSetDisplayMode: ((Int) -> Void)?
    var onSetSilentMode: ((Bool) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenLocationSettings: (() -> Void)?

    private let gradient = CAGradientLayer()
    private let stack = NSStackView()
    private var snapshot: MenuBarSnapshot?
    private let contentWidth: CGFloat = 284

    override func loadView() {
        let v = NSView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 320))
        v.wantsLayer = true
        // Dark-themed controls so the segmented control / buttons stay legible on the gradient.
        v.appearance = NSAppearance(named: .darkAqua)
        gradient.frame = v.bounds
        gradient.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        gradient.startPoint = CGPoint(x: 0.5, y: 1)   // top
        gradient.endPoint   = CGPoint(x: 0.5, y: 0)   // bottom
        v.layer?.addSublayer(gradient)

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 5
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            stack.topAnchor.constraint(equalTo: v.topAnchor),
            stack.bottomAnchor.constraint(equalTo: v.bottomAnchor),
            v.widthAnchor.constraint(equalToConstant: contentWidth)
        ])
        self.view = v
    }

    func update(snapshot: MenuBarSnapshot) {
        self.snapshot = snapshot
        _ = self.view   // ensure the view is loaded
        gradient.colors = [snapshot.topColor, snapshot.bottomColor]
        rebuild()
        view.layoutSubtreeIfNeeded()
        preferredContentSize = NSSize(width: contentWidth, height: view.fittingSize.height)
    }

    private func rebuild() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let snap = snapshot else { return }
        let inset = contentWidth - 32

        stack.addArrangedSubview(locationHeader(snap.locationText, width: inset))
        stack.addArrangedSubview(spacer(6))

        for row in snap.rows { stack.addArrangedSubview(prayerRow(row)) }

        stack.addArrangedSubview(spacer(6))
        stack.addArrangedSubview(divider())
        stack.addArrangedSubview(spacer(6))

        stack.addArrangedSubview(silentModeRow(isOn: snap.silentMode, width: inset))
        stack.addArrangedSubview(spacer(6))

        // Display-mode toggle — no label, full width.
        let seg = NSSegmentedControl(
            labels: [NSLocalizedString("mb_countdown", value: "Countdown", comment: ""),
                     NSLocalizedString("mb_starttime", value: "Start time", comment: "")],
            trackingMode: .selectOne, target: self, action: #selector(displayModeChanged(_:)))
        seg.selectedSegment = snap.displayMode
        seg.segmentDistribution = .fillEqually
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.widthAnchor.constraint(equalToConstant: inset).isActive = true
        stack.addArrangedSubview(seg)

    }

    // MARK: - Row builders

    private func locationHeader(_ text: String, width: CGFloat) -> NSView {
        let pin = NSImageView()
        pin.image = NSImage(systemSymbolName: "location.fill", accessibilityDescription: nil)
        pin.contentTintColor = NSColor.white.withAlphaComponent(0.8)
        pin.translatesAutoresizingMaskIntoConstraints = false
        pin.widthAnchor.constraint(equalToConstant: 13).isActive = true
        // A button that still looks exactly like the label it replaces: borderless, no
        // bezel, no key-equivalent chrome. Clicking it opens the app's location settings.
        let label = NSButton(title: text, target: self, action: #selector(locationTapped))
        label.isBordered = false
        label.bezelStyle = .inline
        label.setButtonType(.momentaryChange)
        label.contentTintColor = NSColor.white.withAlphaComponent(0.9)
        label.font = .systemFont(ofSize: 12.5, weight: .semibold)
        label.alignment = .left
        label.toolTip = NSLocalizedString("open_location_settings", value: "Open location settings", comment: "")
        // Hug the text so the gap sits between the label and the gear rather than inside
        // the button's own tracking area, and truncate instead of shoving the gear off-row.
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        (label.cell as? NSButtonCell)?.lineBreakMode = .byTruncatingTail

        // Gear in the top-right, on the same line as the location.
        let gear = NSButton(title: "", target: self, action: #selector(settingsTapped))
        gear.isBordered = false
        gear.bezelStyle = .inline
        gear.setButtonType(.momentaryChange)
        gear.imagePosition = .imageOnly
        if let g = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription:
                            NSLocalizedString("settings", value: "Settings", comment: "")) {
            gear.image = g
        }
        gear.contentTintColor = NSColor.white.withAlphaComponent(0.75)
        gear.translatesAutoresizingMaskIntoConstraints = false
        gear.widthAnchor.constraint(equalToConstant: 15).isActive = true

        // Flexible gap so the gear stays pinned to the trailing edge with breathing room
        // after the location text instead of butting up against it.
        let gap = NSView()
        gap.translatesAutoresizingMaskIntoConstraints = false
        gap.setContentHuggingPriority(.init(1), for: .horizontal)
        gap.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        gap.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true

        let hs = NSStackView(views: [pin, label, gap, gear])
        hs.orientation = .horizontal
        hs.spacing = 6
        hs.alignment = .centerY
        hs.translatesAutoresizingMaskIntoConstraints = false
        hs.widthAnchor.constraint(equalToConstant: width).isActive = true
        return hs
    }

    private func prayerRow(_ row: MenuBarPrayerRow) -> NSView {
        let name = makeLabel(row.name, size: 13.5, weight: row.isCurrent ? .bold : .regular,
                             color: row.isCurrent ? kGold : .white)
        let time = makeLabel(row.timeText, size: 13, weight: .regular,
                             color: row.isCurrent ? .white : NSColor.white.withAlphaComponent(0.85))
        time.alignment = .right

        let bell = NSButton(title: "", target: self, action: #selector(bellTapped(_:)))
        bell.isBordered = false
        bell.tag = row.prayerIndex
        bell.imagePosition = .imageOnly
        if let img = NSImage(systemSymbolName: row.isBellOn ? "bell.fill" : "bell.slash", accessibilityDescription: nil) {
            img.isTemplate = true
            bell.image = img
        }
        bell.contentTintColor = row.isBellOn ? kGold : NSColor.white.withAlphaComponent(0.4)
        bell.translatesAutoresizingMaskIntoConstraints = false
        bell.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let spacerV = NSView()
        spacerV.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let hs = NSStackView(views: [name, spacerV, time, bell])
        hs.orientation = .horizontal
        hs.alignment = .centerY
        hs.spacing = 8
        hs.translatesAutoresizingMaskIntoConstraints = false
        hs.widthAnchor.constraint(equalToConstant: contentWidth - 32).isActive = true
        return hs
    }

    /// Athan recording vs. the system notification sound. Sits below the divider, above the
    /// display-mode control, at the same inset width as everything else in the popover.
    private func silentModeRow(isOn: Bool, width: CGFloat) -> NSView {
        let label = makeLabel(NSLocalizedString("silent_mode", value: "Silent mode", comment:
                                "Popover toggle: notify with the system sound instead of playing the athan"),
                              size: 13, weight: .regular, color: .white)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(silentModeToggled(_:)))
        box.state = isOn ? .on : .off
        box.controlSize = .large
        box.translatesAutoresizingMaskIntoConstraints = false
        box.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Flexible gap so the box stays on the trailing edge and the label truncates
        // rather than pushing it off the row.
        let gap = NSView()
        gap.translatesAutoresizingMaskIntoConstraints = false
        gap.setContentHuggingPriority(.init(1), for: .horizontal)
        gap.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        gap.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true

        let hs = NSStackView(views: [label, gap, box])
        hs.orientation = .horizontal
        hs.spacing = 6
        hs.alignment = .centerY
        hs.translatesAutoresizingMaskIntoConstraints = false
        hs.widthAnchor.constraint(equalToConstant: width).isActive = true
        hs.toolTip = NSLocalizedString("silent_mode_help",
                                       value: "Notify with the system sound instead of playing the athan.",
                                       comment: "")
        return hs
    }

    @objc private func silentModeToggled(_ sender: NSButton) {
        onSetSilentMode?(sender.state == .on)
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.lineBreakMode = .byTruncatingTail
        l.maximumNumberOfLines = 1
        return l
    }

    private func divider() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.18).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        v.widthAnchor.constraint(equalToConstant: contentWidth - 32).isActive = true
        return v
    }

    private func spacer(_ h: CGFloat) -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: h).isActive = true
        return v
    }

    // MARK: - Actions

    @objc private func bellTapped(_ sender: NSButton) { onToggleBell?(sender.tag) }
    @objc private func methodChanged(_ sender: NSPopUpButton) { onSetMethod?(sender.indexOfSelectedItem) }
    @objc private func soundChanged(_ sender: NSPopUpButton) { onSetSound?(sender.indexOfSelectedItem) }
    @objc private func displayModeChanged(_ sender: NSSegmentedControl) { onSetDisplayMode?(sender.selectedSegment) }
    @objc private func settingsTapped() { onOpenSettings?() }
    @objc private func locationTapped() { onOpenLocationSettings?() }
}
