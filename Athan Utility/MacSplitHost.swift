//
//  MacSplitHost.swift
//  Athan Utility (Mac Catalyst)
//
//  Hosts the sidebar and detail inside a real UISplitViewController so the sidebar gets
//  the system's native treatment: macOS vibrancy, full window height, and the window's
//  traffic lights sitting INSIDE the sidebar the way Photos and Mail have them.
//
//  Why not NavigationSplitView: it is backed by a UISplitViewController on Catalyst but
//  never exposes `primaryBackgroundStyle`, and reaching in to set it on the controller it
//  creates does not produce the native behaviour — SwiftUI has already laid the column out
//  below the title bar by then. Owning the controller is the documented way round this.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

struct MacSplitHost<Sidebar: View, Detail: View>: UIViewControllerRepresentable {
    let sidebar: Sidebar
    let detail: Detail

    func makeUIViewController(context: Context) -> UISplitViewController {
        let split = UISplitViewController(style: .doubleColumn)

        // The one property that matters. Applies the real sidebar material and lets the
        // column run the full height of the window, which is what the traffic lights
        // need in order to sit in it.
        split.primaryBackgroundStyle = .sidebar

        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredSplitBehavior = .tile
        split.minimumPrimaryColumnWidth = 236
        split.preferredPrimaryColumnWidth = 260
        split.maximumPrimaryColumnWidth = 320

        let sidebarVC = UIHostingController(rootView: AnyView(sidebar))
        // Clear, so the system's sidebar material shows through rather than being covered
        // by the hosting controller's own opaque background.
        sidebarVC.view.backgroundColor = .clear

        let detailVC = UIHostingController(rootView: AnyView(detail))

        split.setViewController(sidebarVC, for: .primary)
        split.setViewController(detailVC, for: .secondary)
        return split
    }

    func updateUIViewController(_ split: UISplitViewController, context: Context) {
        // SwiftUI hands us fresh views whenever state changes; push them into the existing
        // hosting controllers rather than rebuilding the split view, which would drop the
        // column widths and the user's collapsed/expanded state.
        (split.viewController(for: .primary) as? UIHostingController<AnyView>)?
            .rootView = AnyView(sidebar)
        (split.viewController(for: .secondary) as? UIHostingController<AnyView>)?
            .rootView = AnyView(detail)
    }
}
#endif
