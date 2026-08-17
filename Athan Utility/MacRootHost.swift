//
//  MacRootHost.swift
//  Athan Utility (Mac Catalyst)
//
//  Owns the Mac window's root view controller.
//
//  Catalyst only runs the sidebar column up under the window's title bar — putting the
//  traffic lights inside it, the way Finder and Photos have them — when the split view
//  controller IS the window's root. Nested inside a UIHostingController, which is what
//  happens with NavigationSplitView or with a UIViewControllerRepresentable wrapper,
//  AppKit has already laid the title bar out above the content and the lights stay in
//  the chrome above the sidebar.
//
//  Owning the controller means the sidebar and the detail pane are separate hosting
//  controllers, so the section they share can no longer be `@State` inside MainSwiftUI.
//  MacRootState holds it instead.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

final class MacRootState: ObservableObject {
    static let shared = MacRootState()

    /// Which sidebar section the detail pane is showing.
    @Published var section: MacSection = .times

    /// True while the location / intro flow owns the whole window. The sidebar is
    /// meaningless before there's a location, so SceneDelegate swaps the window's root
    /// between a plain hosting controller and the split view on this.
    @Published var isOnboarding: Bool = false

    private init() {
        // Handled here rather than on MainSwiftUI's body: the body's `.onReceive` only
        // exists while the Times pane is on screen, so the menu-bar gear did nothing
        // whenever the user happened to be in Calendar or Discover.
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AthanShowMacSettings"), object: nil, queue: .main
        ) { [weak self] _ in
            self?.isOnboarding = false
            self?.section = .settings
        }
    }
}

/// Bridges the sidebar's `Binding<MacSection>` to the shared state, since the sidebar is
/// now hosted on its own rather than being handed a binding by MainSwiftUI.
@available(macCatalyst 16.0, *)
private struct MacSidebarHost: View {
    @ObservedObject private var root = MacRootState.shared
    var body: some View { MacSidebarView(section: $root.section) }
}

/// Publishes where the sidebar card actually is, so the AppKit side can drop the window's
/// traffic lights into its corner.
///
/// macOS 26 lays the Catalyst sidebar out as a rounded card inset from the window, but the
/// lights keep their usual position relative to the WINDOW, so they end up above the card
/// on the detail pane. Maps and Photos put them in the card's own corner. There is no API
/// for the lights on the UIKit side and no way to see the card from the AppKit side, so the
/// two halves talk: this reports the card's origin and the helper re-frames the buttons by
/// it (see AthanMenuBarHelper.insetTrafficLightsIntoSidebar).
///
/// Reporting `visible: false` when the sidebar is collapsed puts the lights back in the
/// window's corner, which keeps them off the sidebar-toggle button that takes their place.
@available(macCatalyst 16.0, *)
final class MacSplitViewController: UISplitViewController {

    static let cardGeometryDidChange = Notification.Name("AthanSidebarCardGeometryDidChange")
    /// The helper installs its observer only once the window exists, by which time the
    /// layout has usually settled and the change-only post has already gone out. It asks
    /// with this; we answer by forgetting what we last sent and laying out again.
    static let cardGeometryRequested = Notification.Name("AthanSidebarCardGeometryRequested")

    private var lastPayload: [String: CGFloat] = [:]
    private var lastVisible: Bool?
    private var requestObservation: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        requestObservation = NotificationCenter.default.addObserver(
            forName: Self.cardGeometryRequested, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.lastVisible = nil
            self.lastPayload = [:]
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var payload: [String: CGFloat] = [:]
        var visible = false

        if displayMode != .secondaryOnly,
           let primary = viewController(for: .primary)?.view,
           let uiWindow = primary.window, !primary.isHidden, primary.alpha > 0 {
            // Climb to the column view — the ancestor whose superview is the split's own
            // column container, which is itself a direct child of our view.
            var column: UIView = primary
            while let parent = column.superview, parent.superview !== view { column = parent }
            if let container = column.superview, container.superview === view, !column.isHidden {
                let origin = column.convert(CGPoint.zero, to: nil)
                payload = ["x": origin.x, "y": origin.y, "windowHeight": uiWindow.bounds.height]
                visible = true
            }
        }

        guard visible != lastVisible || payload != lastPayload else { return }
        lastVisible = visible
        lastPayload = payload
        var info: [String: Any] = payload
        info["visible"] = visible
        NotificationCenter.default.post(name: Self.cardGeometryDidChange, object: nil, userInfo: info)
    }
}

enum MacRootBuilder {

    /// The window's root: the split view on macOS 13+, otherwise the plain full-window
    /// layout (the sidebar's controls need Catalyst 16 APIs).
    static func makeRoot(onboarding: Bool) -> UIViewController {
        if !onboarding, #available(macCatalyst 16.0, *) {
            return makeSplitViewController()
        }
        return makeOnboardingController()
    }

    @available(macCatalyst 16.0, *)
    static func makeSplitViewController() -> UISplitViewController {
        let split = MacSplitViewController(style: .doubleColumn)

        // The floating, inset, rounded sidebar Maps and Photos use on macOS 26: the
        // system's own sidebar material, with the secondary running full-bleed
        // underneath it. This only takes effect because the split view is the window's
        // root — nested in a hosting controller the system ignores it entirely.
        split.primaryBackgroundStyle = .sidebar

        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredSplitBehavior = .tile
        split.minimumPrimaryColumnWidth = 236
        split.preferredPrimaryColumnWidth = 260
        split.maximumPrimaryColumnWidth = 320

        let sidebarVC = UIHostingController(
            rootView: MacSidebarHost()
                .environmentObject(ObservableAthanManager.shared)
                .colorScheme(.dark)
        )
        // Clear, so the system's sidebar material shows through rather than being
        // covered by the hosting controller's own opaque background.
        sidebarVC.view.backgroundColor = .clear

        let detailVC = UIHostingController(
            rootView: MainSwiftUI(macDetailOnly: true)
                .environmentObject(ObservableAthanManager.shared)
                .colorScheme(.dark)
        )
        // The detail pane is now full-bleed under the floating sidebar, and the Settings
        // Form doesn't fill it edge to edge — without this the hosting controller's own
        // default background showed as pale pillars either side of the form.
        detailVC.view.backgroundColor = UIColor(MacSidebarView.fill)

        split.setViewController(sidebarVC, for: .primary)
        split.setViewController(detailVC, for: .secondary)
        return split
    }

    /// Full-window onboarding (location picker / intro), with no sidebar.
    static func makeOnboardingController() -> UIViewController {
        UIHostingController(
            rootView: MainSwiftUI()
                .environmentObject(ObservableAthanManager.shared)
                .colorScheme(.dark)
        )
    }

    /// Matches MainSwiftUI's own launch decision, so SceneDelegate can pick the right
    /// root before any view exists to report it.
    static var needsOnboarding: Bool {
        SnapshotSupport.showsIntro || AthanManager.shared.locationSettings.locationName.isEmpty
    }
}
#endif
