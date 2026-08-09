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

private let kGold = NSColor(red: 0.957, green: 0.835, blue: 0.553, alpha: 1)

@objc(AthanMenuBarHelper)
public final class AthanMenuBarHelper: NSObject, MenuBarHelping, NSPopoverDelegate {

    private var statusItem: NSStatusItem?
    private weak var actionDelegate: MenuBarActionDelegate?
    private var snapshot: MenuBarSnapshot?
    private var dockIconHidden = false
    private var popover: NSPopover?
    private var popoverVC: MenuBarPopoverController?

    public override init() { super.init() }

    // MARK: MenuBarHelping

    public func installStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
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
    }

    public func updateTitle(_ title: String, urgent: Bool) {
        guard let button = statusItem?.button else { return }
        let color: NSColor = urgent ? .systemRed : .labelColor
        button.attributedTitle = NSAttributedString(string: title, attributes: [.foregroundColor: color])
    }

    public func removeStatusItem() {
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
    }

    public func setActionDelegate(_ delegate: MenuBarActionDelegate) {
        self.actionDelegate = delegate
    }

    public func updateSnapshot(_ snapshot: MenuBarSnapshot) {
        self.snapshot = snapshot
        if popover?.isShown == true { popoverVC?.update(snapshot: snapshot) }
    }

    public func setDockIconHidden(_ hidden: Bool) {
        dockIconHidden = hidden
        if hidden {
            NSApp.setActivationPolicy(.accessory)
            for w in NSApp.windows where w.canBecomeMain { w.orderOut(nil) }
        } else {
            NSApp.setActivationPolicy(.regular)
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
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
        }
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
        vc.onOpen           = { [weak self] in self?.openApp() }
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
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
        if dockIconHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                if self?.dockIconHidden == true { NSApp.setActivationPolicy(.accessory) }
            }
        }
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}

// MARK: - Popover content (pure AppKit)

final class MenuBarPopoverController: NSViewController {
    var onToggleBell: ((Int) -> Void)?
    var onSetMethod: ((Int) -> Void)?
    var onSetSound: ((Int) -> Void)?
    var onSetDisplayMode: ((Int) -> Void)?
    var onOpen: (() -> Void)?

    private let gradient = CAGradientLayer()
    private let stack = NSStackView()
    private var snapshot: MenuBarSnapshot?
    private let contentWidth: CGFloat = 268

    override func loadView() {
        let v = NSView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 320))
        v.wantsLayer = true
        gradient.frame = v.bounds
        gradient.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        gradient.startPoint = CGPoint(x: 0.5, y: 1)   // top
        gradient.endPoint   = CGPoint(x: 0.5, y: 0)   // bottom
        v.layer?.addSublayer(gradient)

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 3
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
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

        stack.addArrangedSubview(makeLabel(snap.locationText, size: 12, weight: .semibold,
                                           color: NSColor.white.withAlphaComponent(0.9)))
        stack.addArrangedSubview(spacer(4))

        for row in snap.rows { stack.addArrangedSubview(prayerRow(row)) }

        stack.addArrangedSubview(divider())

        let seg = NSSegmentedControl(
            labels: [NSLocalizedString("mb_countdown", value: "Countdown", comment: ""),
                     NSLocalizedString("mb_starttime", value: "Start time", comment: "")],
            trackingMode: .selectOne, target: self, action: #selector(displayModeChanged(_:)))
        seg.selectedSegment = snap.displayMode
        seg.segmentDistribution = .fillEqually
        stack.addArrangedSubview(fieldRow(NSLocalizedString("mb_show", value: "Show", comment: ""), control: seg))

        let methodPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        methodPopup.addItems(withTitles: snap.methodOptions)
        if snap.methodOptions.indices.contains(snap.methodIndex) { methodPopup.selectItem(at: snap.methodIndex) }
        methodPopup.target = self; methodPopup.action = #selector(methodChanged(_:))
        stack.addArrangedSubview(fieldRow(NSLocalizedString("Calculation Method", value: "Method", comment: ""), control: methodPopup))

        let soundPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        soundPopup.addItems(withTitles: snap.soundOptions)
        if snap.soundOptions.indices.contains(snap.soundIndex) { soundPopup.selectItem(at: snap.soundIndex) }
        soundPopup.target = self; soundPopup.action = #selector(soundChanged(_:))
        stack.addArrangedSubview(fieldRow(NSLocalizedString("athan_sound", value: "Sound", comment: ""), control: soundPopup))

        stack.addArrangedSubview(divider())

        let open = NSButton(title: NSLocalizedString("open_app", value: "Open Athan Utility", comment: ""),
                            target: self, action: #selector(openTapped))
        open.bezelStyle = .rounded
        open.translatesAutoresizingMaskIntoConstraints = false
        let openRow = NSStackView(views: [open])
        openRow.orientation = .horizontal
        openRow.translatesAutoresizingMaskIntoConstraints = false
        openRow.widthAnchor.constraint(equalToConstant: contentWidth - 28).isActive = true
        open.widthAnchor.constraint(equalTo: openRow.widthAnchor).isActive = true
        stack.addArrangedSubview(openRow)
    }

    // MARK: - Row builders

    private func prayerRow(_ row: MenuBarPrayerRow) -> NSView {
        let name = makeLabel(row.name, size: 13, weight: row.isCurrent ? .bold : .regular,
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
        hs.widthAnchor.constraint(equalToConstant: contentWidth - 28).isActive = true
        return hs
    }

    private func fieldRow(_ title: String, control: NSView) -> NSView {
        let label = makeLabel(title, size: 12, weight: .regular, color: NSColor.white.withAlphaComponent(0.85))
        control.translatesAutoresizingMaskIntoConstraints = false
        let hs = NSStackView(views: [label, control])
        hs.orientation = .horizontal
        hs.alignment = .centerY
        hs.spacing = 8
        hs.distribution = .fill
        control.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        hs.translatesAutoresizingMaskIntoConstraints = false
        hs.widthAnchor.constraint(equalToConstant: contentWidth - 28).isActive = true
        return hs
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
        v.widthAnchor.constraint(equalToConstant: contentWidth - 28).isActive = true
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
    @objc private func openTapped() { onOpen?() }
}
