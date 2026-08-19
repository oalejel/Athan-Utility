# Athan Utility — macOS (Menu Bar + Desktop App) Plan

Living design doc for adding a Mac desktop presence. Update as we iterate.
Last updated: 2026-07-04.

---

## 1. Goal (from the feature request)

Add a **desktop target** for Athan Utility with:

1. **Menu bar item** showing either the **next athan time** OR the **time left** until it
   (user-selectable), updating live.
2. **Menu bar popup** (click the menu bar item) that:
   - Lists **today's prayer times**, each row with a **bell** toggle next to it.
   - Shows **location at the bottom**.
   - **No moon / no other art.**
   - **Keeps the user's preferred gradient** as the background.
3. **Full app window** ("open the app") that reuses the **current UI**, but on Mac:
   - **Settings open as a sidebar** (split view), not a full-screen view swap.
   - Settings sidebar has **no gradient** — a plain settings background.
   - Settings are shown as **collapsible groups** (not the iOS one-section-at-a-time
     presentation).
   - **Hide settings that don't make sense on Mac.**
   - Add a new **"Menu Bar / Toolbar" settings section** at the top (configures #1: next
     time vs. time left, show/hide, etc.).

---

## 2. Current architecture (facts gathered)

- **Lifecycle:** UIKit. `AppDelegate` (`@main`, `UIApplicationDelegate`) + `SceneDelegate`
  + `UIWindow` hosting SwiftUI via `UIHostingController`. **Not** the SwiftUI `App`
  lifecycle. (`Athan Utility/AppDelegate.swift`, `SceneDelegate.swift`)
- **Targets today:** iOS app (`com.omaralejel.Athan-Utility`), Widget extension
  (`.Athan-Widget`), iMessage Stickers (`.Athan-Stickers`), Siri Intents
  (`.AthanSiriIntents`), Watch app + Watch extension (`.watchkitapp`), UITests. Vendored
  SPM-ish targets built in-project: **Adhan**, **TPPDF**, **WhatsNewKit**.
- **Device family:** `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad). **No Mac Catalyst,
  no macOS target yet.** Deployment target iOS 14 (some pieces 16.1).
- **UIKit / iOS-only deps in shared UI:** ~27 hits across `UIImpactFeedbackGenerator`,
  `CMMotionManager` (parallax), `UIScreen.main`, **SceneKit** (`MoonView3D`),
  `UIApplication.shared.open`, `isIdleTimerDisabled`, `UNNotificationSound`, etc.
  **All of these are available under Mac Catalyst.** They would NOT compile in a native
  AppKit target without heavy `#if canImport(UIKit)` surgery.
- **Settings presentation:** `MainSwiftUI` switches a `@State currentView`
  (`PresentedSectionType`) between `.Main` and `.Settings`, i.e. a **whole-view swap**.
  `SettingsView(parentSession:initialSection:)` already supports deep-linking to a
  `SettingsSectionType` (`.General, .Sounds, .Prayer, .CalculationMethod, .CustomNames,
  .Colors`). This is what becomes the Mac sidebar.
- **Data sharing:** App group **`group.athanUtil`** already exists (used by widget). Good
  for menu-bar-helper ↔ app state sharing too.
- **Models are UI-agnostic enough to reuse:** `AthanManager` (times, location, settings),
  `SettingsModels` (`PrayerSettings`, `NotificationSettings`, `LocationSettings`,
  `AppearanceSettings`), `Adhan` (times), appearance **gradient** via
  `AppearanceSettings.colors(for:)`.

---

## 3. Approach decision: **Mac Catalyst** (not native macOS)

**Chosen: Mac Catalyst** (enable "Mac" on the existing app target) **+ a small AppKit
helper bundle** for the menu bar.

Why:
- The request explicitly says **"open the app with the current UI."** Catalyst runs the
  entire existing UIKit+SwiftUI app on Mac with near-zero UI rewrite. Native macOS would
  mean rebuilding every screen in AppKit-compatible SwiftUI and porting all 27 UIKit deps
  (SceneKit moon, CoreMotion parallax, haptics, etc.). Weeks vs. days.
- All current dependencies are Catalyst-compatible.

The one Catalyst tax — **the menu bar**:
- **`MenuBarExtra` (SwiftUI) and `NSStatusItem` are NOT directly available in Catalyst.**
  Catalyst hides AppKit.
- Standard solution: build a **separate macOS AppKit bundle** ("plugin") that owns the
  `NSStatusItem` + its popover, and have the Catalyst app **load it at runtime**
  (`Bundle(url:).principalClass`), communicating through a **shared @objc protocol**.
  This is the documented technique (Apple "UIKit ↔ AppKit"; Troughton-Smith pattern).
  The bundle is embedded in the app; only loaded on `macCatalyst`.

Rejected alternative — **native macOS SwiftUI target with `MenuBarExtra`:** cleanest menu
bar, but fails the "reuse current UI" requirement and is a massive port. Revisit only if
we later want a fully native Mac look.

### Catalyst constraints to plan around
- Catalyst apps **cannot embed** the **Watch app** or **iMessage Stickers** extension —
  Xcode auto-excludes them from the Mac build. Fine.
- **Widgets DO work** on Mac (Notification Center / Desktop). Keep.
- Siri Intents extension: exclude if it fights the Mac build.
- Signing: Mac build needs a **Mac App Store provisioning** path (Developer ID / Mac App
  Store). Personal team `DL7989H5XT`. Separate from iOS submission plumbing.
- Consider **`LSUIElement`/Agent** behavior: we want a normal windowed app *plus* a menu
  bar item, so NOT agent-only. Menu bar item is additive via the helper bundle.

---

## 4. Implementation phases (each ends in a green `xcodebuild` for Catalyst)

Build/verify command (no simulator boot needed):
```
xcodebuild -scheme "Athan Utility" \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath /tmp/AthanDerivedData build
```

### Phase 0 — Enable Mac Catalyst, get a clean Mac build
- Add `SUPPORTS_MACCATALYST = YES` (and decide `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD =
  NO`) to the **app target** (Debug+Release).
- Set a Mac deployment target (macOS 13+ recommended so modern SwiftUI is available;
  the helper bundle can require 13+).
- Add Mac app category + Catalyst signing settings.
- Fix any Catalyst compile breaks (guard truly-unavailable APIs with
  `#if targetEnvironment(macCatalyst)`).
- **Gate:** app launches as a Mac window showing the current UI.

### Phase 1 — AppKit helper bundle (menu bar item plumbing)
- New **macOS bundle target** `AthanMenuBarHelper` (AppKit), embedded in the app,
  loaded only on `macCatalyst`.
- Shared `@objc protocol MenuBarHelper` (create status item, set title, provide popover
  content view, callbacks for bell toggles / "open app").
- App loads it in `SceneDelegate`/`AppDelegate` on Catalyst, retains it.
- **Gate:** a static menu bar item appears when the Mac app runs.

### Phase 2 — Menu bar title: next time vs. time left
- New setting (see Phase 4) `menuBarDisplay: .nextTime | .timeLeft` (+ maybe `.hidden`).
- Helper updates `NSStatusItem.button.title` on a timer (every 1s for countdown, or
  every minute for clock) pulling from `AthanManager.shared.guaranteedNextPrayerTime()`.
- Localized, respects 12/24h + the app's time formatting.
- **Gate:** title live-updates and flips with the setting.

### Phase 3 — Menu bar popover content (SwiftUI hosted in the bundle)
- SwiftUI view: **today's 6 times**, each row = prayer name + time + **bell toggle**
  (writes `NotificationSettings.settings[p].athanAlertEnabled` / sound, archives, reloads
  notifications). **Location label at bottom.** **User gradient background**
  (`AppearanceSettings.colors(for:)`), **no moon/art.**
- Host SwiftUI in the AppKit bundle via `NSHostingController`. Share `AthanManager` state
  through the app group / a bridge.
- Buttons: "Open Athan Utility" (activates the main window).
- **Gate:** clicking the item shows the gradient popover with working bells + location.

### Phase 4 — "Menu Bar" settings section (top of Settings)
- New `SettingsSectionType.menuBar` (Mac-only). UI to pick next-time vs time-left,
  show/hide the item, and (optional) 12/24h for the item.
- Persist in `AppearanceSettings` or a small dedicated settings model in app group so the
  helper bundle reads it.
- **Gate:** changing it updates the live menu bar.

### Phase 5 — Settings as a Mac sidebar with collapsible groups
- On Catalyst, replace the `currentView == .Settings` full swap with a
  **`NavigationSplitView`**: sidebar lists the settings sections as **collapsible groups**;
  detail pane shows the selected group. Main content (times UI) stays visible.
- Sidebar/detail use a **plain settings background (no gradient)**; the times UI keeps the
  gradient.
- Keep iOS behavior unchanged (`#if targetEnvironment(macCatalyst)` fork in `MainSwiftUI`).
- **Gate:** on Mac, settings live in a sidebar; iPhone/iPad unaffected.

### Phase 6 — Hide Mac-irrelevant settings
- Audit `SettingsView` sections; hide on Catalyst: e.g. **haptics**, **motion/parallax**,
  anything device-sensor or iOS-notification-only that has no Mac meaning. Keep
  calculation method, madhab, sounds, colors, location, custom names, high-latitude rule.
- **Gate:** Mac settings show only relevant items.

---

## 5. Key technical notes / gotchas

- **Menu bar in Catalyst = AppKit bundle, loaded at runtime.** No `MenuBarExtra`, no
  direct `NSStatusItem`. Budget time here; it's the riskiest part.
- **Bell toggles** in the popover must write through the same
  `NotificationSettings`/`AthanManager` path the app uses, then `reloadSettings...` +
  `WidgetCenter.reloadAllTimelines()`; share via `group.athanUtil` so app + helper agree.
- **Gradient reuse:** both the popover (Phase 3) and main UI pull from
  `AppearanceSettings.colors(for:)`. Settings sidebar deliberately does NOT.
- **Watch app & Stickers auto-excluded** from the Mac build — expect Xcode warnings, not
  errors.
- **Two products, one app record?** A Catalyst app ships under the **same** app on App
  Store Connect (iOS + Mac) — no separate app id. Good.
- **App group entitlement** must be present in the Mac build + helper bundle for shared
  state.
- **Time formatting:** reuse existing 12/24h + localized formatting so the menu bar
  matches in-app.

---

## 6. Code location map

| Concern | File |
|---|---|
| App entry (UIKit) | `Athan Utility/AppDelegate.swift`, `SceneDelegate.swift` |
| Root UI + view switch | `Athan Utility/MainSwiftUI.swift` (`currentView`) |
| Settings host + deep-link | `Athan Utility/SettingsView.swift` (`SettingsSectionType`) |
| Settings sub-views | `GeneralSettingView.swift`, `SoundSettingView.swift`, `PrayerSettingsView.swift`, `LocationSettingsView.swift` |
| Times / location / gradient | `Athan Utility/AthanManager.swift` |
| Settings models + app group | `Athan Utility/SettingsModels.swift` (`group.athanUtil`) |
| Notifications (bells) | `Athan Utility/NotificationsManager.swift` |
| Moon/art (exclude in popover) | `MoonView3D` / SceneKit views |
| Widget (works on Mac) | `Athan Widget/` |
| Project settings | `Athan Utility.xcodeproj/project.pbxproj` |

---

## 7. Decisions (locked 2026-07-04)

1. **macOS deployment target: macOS 13 (Ventura).**
2. **Menu bar item stays alive when the window is closed** — classic menu-bar utility
   behavior; app keeps running in the background. **Menu bar is the priority — build it
   first.**
3. **Distribution: same app on the Mac App Store** (single App Store Connect record, iOS +
   Mac Catalyst build, universal). No separate app id / no DMG.
4. **Menu bar title format** (both modes prefix the prayer name):
   - **Time-left mode:** `<PrayerName> -<countdown>` — name, space, minus, then the
     countdown (e.g. `Asr -1:23:45`).
   - **Next-time mode:** `<PrayerName>: <clock time>` — name, colon, the next prayer's
     clock time (e.g. `Asr: 3:41`).
   - **Turn the title red when < 30 minutes remain** until the next prayer (both modes).
5. (Resolved by #4 — prayer name always shown.)

---

## 8. Status

- [x] Investigation complete; approach chosen (Mac Catalyst + AppKit helper bundle).
- [x] **Phase 0: Mac Catalyst enabled; clean Mac build (BUILD SUCCEEDED, signing-disabled
      compile verified).**
- [x] **Phase 1: AppKit helper bundle for the menu bar item — builds on Catalyst (bundle
      embedded in `.app/Contents/PlugIns/`) and iOS still green.**
- [x] **Phase 2: live menu bar title (next-time vs time-left, red < 30 min) — Catalyst
      build green.**
- [x] **Phase 3: gradient popover (today's times + bell per row + location) — Catalyst +
      iOS builds green.**
- [ ] Phase 4: "Menu Bar" settings section.
- [ ] Phase 5: settings sidebar (collapsible groups, no gradient).
- [ ] Phase 6: hide Mac-irrelevant settings.

### Phase 0 — what was done (2026-07-04)
- `project.pbxproj` app target (Debug+Release): added `SUPPORTS_MACCATALYST = YES`,
  `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`, `DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER = NO`.
- **Live Activities** unavailable on Catalyst → wrapped `SuhoorActivityTrigger.swift`,
  `SuhoorActivity.swift`, `SuhoorActivityAttributes.swift` in `#if !targetEnvironment(macCatalyst)`,
  and guarded the `cleanupSuhoorActivity()` call in `AthanManager.swift`.
- `NotificationsManager.swift`: added explicit `import UserNotifications` (was relying on
  `import NotificationCenter` re-exporting UN* on iOS; doesn't on Catalyst).
- **Embedded extensions excluded on Mac** via `platformFilter = ios;` on the embed build
  files for: Widget, Stickers, SiriIntents, Watch app, Watch extension. (Widget-on-Mac can
  be re-enabled later by giving the widget target Catalyst support instead of filtering.)

### Signing note (for running/distribution, not compilation)
- Local run needs the Mac registered in the dev account + a Mac Catalyst dev profile
  (`-allowProvisioningUpdates`), or "Omar's Macbook Pro" added to the account.
- Compilation verified with `CODE_SIGNING_ALLOWED=NO`.
- All Catalyst builds must run with `/usr/bin` first on `PATH` (Homebrew rsync 3.1.3 in
  `/usr/local/bin` breaks Xcode's export/copy — same issue hit during the iOS submission).

### Phase 1 — what was done (2026-07-04)
- New native-macOS **loadable-bundle target `AthanMenuBarHelper`** (macOS 13, `mh_bundle`,
  `-framework Cocoa`). Added via the `xcodeproj` Ruby gem (ships with fastlane) rather than
  hand-editing pbxproj — script at
  `scratchpad/add_menubar_target.rb` (load paths for xcodeproj+deps under fastlane libexec).
- New files under `AthanMenuBarHelper/`:
  - `MenuBarHelperProtocol.swift` — `@objc protocol MenuBarHelping` (installStatusItem /
    updateTitle(_:urgent:) / removeStatusItem). Compiled into **both** app + bundle.
  - `AthanMenuBarHelper.swift` — `@objc(AthanMenuBarHelper)` principal class; creates the
    `NSStatusItem`, a menu (Open / Quit), `updateTitle` (red via `.systemRed` when urgent).
  - `Info.plist` — `NSPrincipalClass = AthanMenuBarHelper`.
  - `MenuBarBridge.swift` — app side, `#if targetEnvironment(macCatalyst)`; loads
    `Bundle.main.builtInPlugInsURL/AthanMenuBarHelper.bundle`, instantiates the principal
    class, casts to `MenuBarHelping`, calls `installStatusItem()`.
- `AppDelegate.didFinishLaunching` calls `MenuBarBridge.shared.start()` (Catalyst only).
- Wiring: app **depends on** the bundle and **embeds** it into `Contents/PlugIns`, both with
  `platformFilters = [maccatalyst]` so iOS builds ignore the macOS bundle.
- Verified: `AthanMenuBarHelper.bundle` is copied into
  `Athan Utility.app/Contents/PlugIns/` on Catalyst; iOS build unaffected.
- **Not yet runnable on this machine** (Mac not registered for a dev profile) — visual
  confirmation of the item in the menu bar is pending a signed local run.

### Adding future targets/build-phase edits
Use the `xcodeproj` gem pattern (see `scratchpad/add_menubar_target.rb`): load its lib +
deps (`nanaimo, colored2, claide, CFPropertyList, atomos`) from
`/usr/local/Cellar/fastlane/2.236.1/libexec/gems/*/lib` on system Ruby, then manipulate and
`project.save`. Back up `project.pbxproj` first.

### Phase 2 — what was done (2026-07-04)
- `AthanManager.guaranteedNextPrayer()` added (mirrors `guaranteedNextPrayerTime()`'s
  branching so name + time always agree; handles rollover / late isha).
- In `MenuBarBridge.swift` (Catalyst-only), added:
  - `MenuBarDisplayMode { timeLeft, nextTime }` and `MenuBarSettings` (mode + isHidden),
    persisted in the **`group.athanUtil`** app group (default = `timeLeft`).
  - `MenuBarController` — 1s `Timer` on the main run loop (`.common` mode) that reads
    `AthanManager.shared`, builds the title, and pushes it to the helper:
    - time-left: `"<Name> -<countdown>"`, countdown `H:MM:SS` (≥1h) or `M:SS`.
    - next-time: `"<Name>: <short clock>"` (locale 12/24h via `DateFormatter`).
    - `urgent = remaining ≤ 30 min` → helper renders red.
    - guards for nil times (pre-refresh) and the hidden setting.
  - `MenuBarBridge.ensureItem()` / `removeItem()` for show/hide.
- `AppDelegate` (Catalyst) starts `MenuBarController.shared.start()` after the bridge.
- Prayer name via `Prayer.localizedOrCustomString()` (respects custom names).
- Verified: Catalyst `BUILD SUCCEEDED`. (Live visual still pending a signed local run.)

### Phase 3 — what was done (2026-07-04)
- **Cross-boundary contract** (in `MenuBarHelperProtocol.swift`, both targets): the popover
  can't see AthanManager/Adhan, so the app pushes a plain snapshot:
  - `MenuBarPrayerRow` (name, timeText, isBellOn, isCurrent, prayerIndex),
    `MenuBarSnapshot` (rows, locationText, top/bottom `CGColor`).
  - `MenuBarHelping` gained `setActionDelegate(_:)` + `updateSnapshot(_:)`.
  - `MenuBarActionDelegate` (app implements): `menuBarToggleBell(prayerIndex:)`.
- **Bundle** (`AthanMenuBarHelper.swift`): status item now uses a click handler
  (`sendAction(on: [.leftMouseUp, .rightMouseUp])`): left-click toggles an **NSPopover**
  hosting a SwiftUI `MenuBarPopoverView`; right-click shows a small Open/Quit menu.
  - `MenuBarPopoverView`: gradient background (`LinearGradient` of the two snapshot CGColors),
    one row per prayer (name, monospaced time, **bell** button toggling
    `bell.fill`/`bell.slash`), current prayer bold, **location + "Open"** footer. White text,
    260pt wide, **no moon/art**. Driven by `PopoverModel: ObservableObject`.
- **App side** (`MenuBarController` in `MenuBarBridge.swift`, now `NSObject` +
  `MenuBarActionDelegate`): each tick builds a snapshot from `AthanManager.shared`
  (times, `colorTuplesForContext` gradient using current prayer when dynamic, bell =
  `AlarmSetting.athanAlertEnabled`, location) and pushes it. `menuBarToggleBell` flips the
  alert, archives + `reloadSettingsAndNotifications()`, and re-pushes the snapshot.
- `MenuBarBridge.swift` needed `import UIKit` (UIColor→CGColor) + `import Adhan` (`Prayer`).
- Verified: Catalyst + iOS both `BUILD SUCCEEDED`. (Live visual pending a signed local run.)

**Next step:** Phase 4 — the "Menu Bar" settings section (mode: time-left vs next-time,
show/hide) writing to `MenuBarSettings`; then Phase 5 (settings sidebar) + Phase 6 (hide
Mac-irrelevant settings).
