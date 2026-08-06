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
            onOpen: { [weak self] in self?.openApp() }
        )
        pop.contentViewController = NSHostingController(rootView: root)
        popover = pop
        return pop
    }

    @objc private func openApp() {
        popover?.performClose(nil)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}

// MARK: - Popover content (SwiftUI, hosted in the bundle)

final class PopoverModel: ObservableObject {
    @Published var snapshot: MenuBarSnapshot?
}

struct MenuBarPopoverView: View {
    @ObservedObject var model: PopoverModel
    var onToggleBell: (Int) -> Void
    var onOpen: () -> Void

    private var topColor: Color { model.snapshot.map { Color(cgColor: $0.topColor) } ?? .black }
    private var bottomColor: Color { model.snapshot.map { Color(cgColor: $0.bottomColor) } ?? .blue }

    var body: some View {
        VStack(spacing: 0) {
            if let snap = model.snapshot {
                ForEach(Array(snap.rows.enumerated()), id: \.offset) { pair in
                    let row = pair.element
                    HStack(spacing: 10) {
                        Text(row.name)
                            .fontWeight(row.isCurrent ? .bold : .regular)
                        Spacer(minLength: 8)
                        Text(row.timeText)
                            .monospacedDigit()
                            .opacity(0.95)
                        Button(action: { onToggleBell(row.prayerIndex) }) {
                            Image(systemName: row.isBellOn ? "bell.fill" : "bell.slash")
                                .frame(width: 22, height: 22)
                                .contentShape(Rectangle())
                                .opacity(row.isBellOn ? 1.0 : 0.5)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    if pair.offset < snap.rows.count - 1 {
                        Divider().overlay(Color.white.opacity(0.18)).padding(.leading, 14)
                    }
                }

                Divider().overlay(Color.white.opacity(0.25))

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
}
