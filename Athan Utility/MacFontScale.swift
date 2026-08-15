//
//  MacFontScale.swift
//  Athan Utility (Mac Catalyst)
//
//  A global, user-adjustable font-scale multiplier for the Mac app, driven by the
//  standard ⌘+ / ⌘- zoom shortcuts (wired in AppDelegate.buildMenu) and persisted
//  across launches. Views that want to respond multiply their own font sizes by
//  MacFontScale.shared.scale — there's no automatic app-wide Dynamic Type hook
//  here since this project isn't using SwiftUI's App/Scene lifecycle.
//

#if targetEnvironment(macCatalyst)
import Combine
import Foundation

final class MacFontScale: ObservableObject {
    static let shared = MacFontScale()

    private static let key = "macFontScaleV1"
    private static let minScale: CGFloat = 0.8
    private static let maxScale: CGFloat = 1.6
    private static let step: CGFloat = 0.1

    @Published private(set) var scale: CGFloat

    private init() {
        let stored = UserDefaults.standard.object(forKey: Self.key) as? Double
        scale = CGFloat(stored ?? 1.0)
    }

    func increase() { setScale(scale + Self.step) }
    func decrease() { setScale(scale - Self.step) }
    func reset() { setScale(1.0) }

    private func setScale(_ newValue: CGFloat) {
        let clamped = min(Self.maxScale, max(Self.minScale, newValue))
        guard clamped != scale else { return }
        scale = clamped
        UserDefaults.standard.set(Double(scale), forKey: Self.key)
    }
}
#endif
