//
//  AthanMenuBarHelper.swift
//  AthanMenuBarHelper (native macOS AppKit bundle)
//
//  Principal class of the helper bundle. Runs as native AppKit code inside the Catalyst
//  process, so it CAN own an NSStatusItem + NSPopover. The Catalyst app loads this bundle at
//  runtime (see MenuBarBridge) and drives it through the shared `MenuBarHelping` protocol.
//
//  Left-click the status item -> gradient popover with today's times, a bell per row, and the
//  location at the bottom. Right-click -> a small menu (Open / Quit).
//

import AppKit
import SwiftUI

@objc(AthanMenuBarHelper)
public final class AthanMenuBarHelper: NSObject, MenuBarHelping, NSPopoverDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let model = PopoverModel()
    private weak var actionDelegate: MenuBarActionDelegate?

    public override init() { super.init() }

    // MARK: MenuBarHelping

    public func installStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            // A recognizable moon glyph makes the item easy to spot among other menu extras.
            if let img = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "Athan Utility") {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageLeading
                button.imageHugsTitle = true
            }
            button.title = "Athan"
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    public func updateTitle(_ title: String, urgent: Bool) {
        guard let button = statusItem?.button else { return }
        let color: NSColor = urgent ? .systemRed : .labelColor
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.foregroundColor: color]
        )
    }

    public func removeStatusItem() {
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
    }

    public func setActionDelegate(_ delegate: MenuBarActionDelegate) {
        self.actionDelegate = delegate
    }

    public func updateSnapshot(_ snapshot: MenuBarSnapshot) {
        model.snapshot = snapshot
    }

    // MARK: Click handling

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open Athan Utility", action: #selector(openApp), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Athan Utility", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil   // detach so left-click keeps opening the popover
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }
        let pop = popover ?? makePopover()
        if pop.isShown {
            pop.performClose(nil)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    private func makePopover() -> NSPopover {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.delegate = self
        let root = MenuBarPopoverView(
            model: model,
            onToggleBell: { [weak self] index in self?.actionDelegate?.menuBarToggleBell(prayerIndex: index) },
            onSetMethod: { [weak self] index in self?.actionDelegate?.menuBarSetMethod(index: index) },
            onSetSound: { [weak self] index in self?.actionDelegate?.menuBarSetSound(index: index) },
            onOpen: { [weak self] in self?.openApp() }
        )
        pop.contentViewController = NSHostingController(rootView: root)
        popover = pop
        return pop
    }

    @objc private func openApp() {
        popover?.performClose(nil)
        // If we're a menu-bar-only accessory, briefly become a regular app so the window
        // can take focus, then show it.
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
        // Re-hide the Dock icon shortly after if the user chose menu-bar-only.
        if dockIconHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                if self?.dockIconHidden == true { NSApp.setActivationPolicy(.accessory) }
            }
        }
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    // MARK: - Menu-bar-only mode

    private var dockIconHidden = false

    public func setDockIconHidden(_ hidden: Bool) {
        dockIconHidden = hidden
        if hidden {
            // Become a menu-bar accessory: no Dock icon, no ⌘-Tab entry; hide open windows.
            NSApp.setActivationPolicy(.accessory)
            for w in NSApp.windows where w.canBecomeMain { w.orderOut(nil) }
        } else {
            NSApp.setActivationPolicy(.regular)
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Popover content (SwiftUI, hosted in the bundle)

final class PopoverModel: ObservableObject {
    @Published var snapshot: MenuBarSnapshot?
}

struct MenuBarPopoverView: View {
    @ObservedObject var model: PopoverModel
    var onToggleBell: (Int) -> Void
    var onSetMethod: (Int) -> Void
    var onSetSound: (Int) -> Void
    var onOpen: () -> Void

    private var topColor: Color { model.snapshot.map { Color(cgColor: $0.topColor) } ?? .black }
    private var bottomColor: Color { model.snapshot.map { Color(cgColor: $0.bottomColor) } ?? .blue }
    static let gold = Color(red: 0.957, green: 0.835, blue: 0.553)   // #f4d58d — current-prayer accent

    var body: some View {
        VStack(spacing: 0) {
            if let snap = model.snapshot {
                ForEach(Array(snap.rows.enumerated()), id: \.offset) { pair in
                    let row = pair.element
                    HStack(spacing: 10) {
                        Text(row.name)
                            .fontWeight(row.isCurrent ? .bold : .regular)
                            .foregroundColor(row.isCurrent ? Self.gold : .white)
                        Spacer(minLength: 8)
                        Text(row.timeText)
                            .monospacedDigit()
                            .foregroundColor(row.isCurrent ? .white : .white.opacity(0.9))
                        Button(action: { onToggleBell(row.prayerIndex) }) {
                            Image(systemName: row.isBellOn ? "bell.fill" : "bell.slash")
                                .frame(width: 22, height: 22)
                                .contentShape(Rectangle())
                                .foregroundColor(row.isBellOn ? Self.gold : .white.opacity(0.45))
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(row.isCurrent ? 0.12 : 0))
                            if row.isCurrent {
                                Rectangle().fill(Self.gold).frame(width: 3)
                            }
                        }
                    )

                    if pair.offset < snap.rows.count - 1 {
                        Divider().overlay(Color.white.opacity(0.18)).padding(.leading, 14)
                    }
                }

                Divider().overlay(Color.white.opacity(0.25))

                // Interactive settings — calculation method + athan sound.
                settingsRow(icon: "slider.horizontal.3",
                            selection: snap.methodOptions.indices.contains(snap.methodIndex) ? snap.methodOptions[snap.methodIndex] : "—",
                            options: snap.methodOptions,
                            onSelect: onSetMethod)
                    .padding(.top, 9)

                Divider().overlay(Color.white.opacity(0.12)).padding(.leading, 14)

                settingsRow(icon: "speaker.wave.2.fill",
                            selection: snap.soundOptions.indices.contains(snap.soundIndex) ? snap.soundOptions[snap.soundIndex] : "—",
                            options: snap.soundOptions,
                            onSelect: onSetSound)
                    .padding(.bottom, 3)

                Divider().overlay(Color.white.opacity(0.15)).padding(.leading, 14)

                HStack(spacing: 6) {
                    Image(systemName: "location.fill").font(.system(size: 11))
                    Text(snap.locationText).font(.system(size: 12)).lineLimit(1).truncationMode(.tail)
                    Spacer(minLength: 8)
                    Button(action: onOpen) {
                        Text("Open").font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                Text("Athan Utility")
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .frame(width: 260)
        .background(
            LinearGradient(colors: [topColor, bottomColor], startPoint: .top, endPoint: .bottom)
        )
    }

    /// A tappable settings row that presents its options in a dropdown menu.
    private func settingsRow(icon: String, selection: String,
                             options: [String], onSelect: @escaping (Int) -> Void) -> some View {
        Menu {
            ForEach(Array(options.enumerated()), id: \.offset) { pair in
                Button(pair.element) { onSelect(pair.offset) }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 11))
                Text(selection).font(.system(size: 12)).lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).opacity(0.6)
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
