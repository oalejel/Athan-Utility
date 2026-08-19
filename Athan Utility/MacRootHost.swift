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

/// A single transient toast in the corner of the detail pane, for settings that are
/// changed from the sidebar or the menu bar popover and would otherwise give no feedback.
///
/// Deliberately one instance with one message rather than a queue or a stack: bells and
/// silent mode are easy to click repeatedly, and stacked toasts would both crowd the
/// corner and animate over each other. Repeat shows replace the text in place and restart
/// the timer, so the toast never accumulates and never re-animates in.
final class MacToast: ObservableObject {
    static let shared = MacToast()

    @Published private(set) var message: String?

    private var dismissal: DispatchWorkItem?

    private init() {}

    func show(_ text: String) {
        dismissal?.cancel()
        message = text
        let work = DispatchWorkItem { [weak self] in self?.message = nil }
        dismissal = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }
}

@available(macCatalyst 16.0, *)
struct MacToastView: View {
    @ObservedObject private var toast = MacToast.shared

    var body: some View {
        ZStack {
            if let message = toast.message {
                Text(message)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.black.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.28), radius: 8, y: 2)
                    )
                    // Opacity only. A move/scale transition on a view whose text changes
                    // mid-flight is what produces the smearing on rapid clicks.
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: toast.message)
        .padding(20)
        .allowsHitTesting(false)
    }
}

/// Bridges the sidebar's `Binding<MacSection>` to the shared state, since the sidebar is
/// now hosted on its own rather than being handed a binding by MainSwiftUI.
@available(macCatalyst 16.0, *)
private struct MacSidebarHost: View {
    @ObservedObject private var root = MacRootState.shared
    var body: some View { MacSidebarView(section: $root.section) }
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
        let split = UISplitViewController(style: .doubleColumn)

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
        // `.colorScheme(.dark)` only dresses the SwiftUI content. The hosting controller's
        // own view resolves system colours against its trait collection, which on Catalyst
        // is light by default — so anything the content didn't cover came out pale.
        sidebarVC.overrideUserInterfaceStyle = .dark
        // Clear, so the system's sidebar material shows through rather than being
        // covered by the hosting controller's own opaque background.
        sidebarVC.view.backgroundColor = .clear

        let detailVC = UIHostingController(
            rootView: MainSwiftUI(macDetailOnly: true)
                .environmentObject(ObservableAthanManager.shared)
                .colorScheme(.dark)
        )
        // Same trait-collection problem, and this is where it showed: the Settings Form and
        // the Discover grid both lay out at a narrower, centred width, so the pane's own
        // background fills the side margins — and resolved light, it drew white pillars
        // either side of them. Fixed once here rather than per-view, and painted the
        // grouped background so the margins match the content sitting on them.
        detailVC.overrideUserInterfaceStyle = .dark
        detailVC.view.backgroundColor = .systemGroupedBackground

        split.setViewController(sidebarVC, for: .primary)
        split.setViewController(detailVC, for: .secondary)
        return split
    }

    /// Full-window onboarding (location picker / intro), with no sidebar.
    static func makeOnboardingController() -> UIViewController {
        let vc = UIHostingController(
            rootView: MainSwiftUI()
                .environmentObject(ObservableAthanManager.shared)
                .colorScheme(.dark)
        )
        vc.overrideUserInterfaceStyle = .dark
        return vc
    }

    /// Matches MainSwiftUI's own launch decision, so SceneDelegate can pick the right
    /// root before any view exists to report it.
    static var needsOnboarding: Bool {
        SnapshotSupport.showsIntro || AthanManager.shared.locationSettings.locationName.isEmpty
    }
}
#endif
