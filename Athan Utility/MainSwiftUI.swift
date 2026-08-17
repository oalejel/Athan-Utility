//
//  MainSwiftUI.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 9/24/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan
import Combine
import StoreKit

// Top-level section state enum
enum PresentedSectionType {
    case Main, Settings, Location, IntroSettings
}

// Mac-only sidebar sections (NavigationSplitView). Each swaps the detail pane.
enum MacSection: Int, CaseIterable, Identifiable {
    case times, calendar, settings, discover
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .times:    return NSLocalizedString("mac_section_times", value: "Home", comment: "Mac sidebar section")
        case .calendar: return NSLocalizedString("mac_section_calendar", value: "Monthly Calendar", comment: "Mac sidebar section")
        case .settings: return NSLocalizedString("mac_section_settings", value: "Settings", comment: "Mac sidebar section")
        case .discover: return NSLocalizedString("mac_section_discover", value: "Discover Features", comment: "Mac sidebar section")
        }
    }
    var symbol: String {
        switch self {
        case .times:    return "house.fill"
        case .calendar: return "calendar"
        case .settings: return "gearshape.fill"
        case .discover: return "lightbulb.fill"
        }
    }
}

// State of user drag along solar curve
class DayProgressState: ObservableObject {
    // user input based publishers
    @Published var manualDayProgress: CGFloat = 0.0 // a changes b and c
    @Published var isDragging = false
    
    @Published var manualCurrentPrayerProgress: Double = 0
    @Published var truthCurrentPrayerProgress: Double = 0
    @Published var previewPrayerProgress: Double = 0 // changed by a if dragging
    
    @Published var manualPrayer: Prayer? = nil
    @Published var previewPrayer: Prayer? = nil // agreement between manager and user
    @Published var nonOptionalPreviewPrayer: Prayer = .fajr
}

struct MainSwiftUI: View {
    @EnvironmentObject var manager: ObservableAthanManager
    @Environment(\.horizontalSizeClass) var _horizontalSizeClass

    private var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }
    // Two-column (moon beside the times) only on iPad regular width. Mac keeps the
    // single-column iPhone layout, centered with growing spacers, per design.
    private var useTwoColumn: Bool { _horizontalSizeClass == .regular && !isMac }
    // MARK: - Combine Properties
    // necessary to allow ARC to throw out unused values
    var dragCancellable: AnyCancellable?
    
    // solar manual day progress publishes to our subscriber
    // subscriber combines that stream's data with the current prayer
    // to indicate the visible prayer via a visible prayer state
    var previewManualPrayerProgressCancellable: AnyCancellable?
    var previewConsensusPrayerProgressCancellable: AnyCancellable?
    
    var previewManualPrayerCancellable: AnyCancellable? // manual.prog -> intermediate manual.p
    var consensusPreviewPrayerCancellable: AnyCancellable? // manual.p + manager.p -> visible
    var nonOptionalPreviewPrayerCancellable: AnyCancellable?
    
    @ObservedObject var dayProgressState = DayProgressState()
    @ObservedObject var dayBrowse = DayBrowseState.shared
    @ObservedObject var hijriCallout = HijriCalloutState.shared
    @State var minuteTimer: Timer? = nil
    
    @State var settingsToggled = false
    @State var locationSettingsToggled = false
    @State var showCalendar = false
    @State var showDiscovery = false
    @State var discoverySeen = FeatureDiscovery.hasSeen
    // section that the Settings view should open to (e.g. deep-linked from the auto-method pill)
    @State var settingsInitialSection: SettingsSectionType = .General
    // ensures the launch-time method suggestion is only evaluated once per app session
    @State private var didEvaluateStartupSuggestion = false
    
    @State var currentView: PresentedSectionType
    /// Mac-only: true when this instance is the split view's detail pane rather than the
    /// whole window, in which case the body renders `macDetail` and the sidebar is hosted
    /// separately by MacRootBuilder. Always false elsewhere.
    let macDetailOnly: Bool
    #if targetEnvironment(macCatalyst)
    // Which sidebar section is showing. Window-level rather than `@State`, because the
    // sidebar and the detail pane are separate hosting controllers under the root split
    // view controller and can't share view state. See MacRootHost.swift.
    @ObservedObject private var macRoot = MacRootState.shared
    private var macSection: MacSection {
        get { macRoot.section }
        nonmutating set { macRoot.section = newValue }
    }
    #endif
    // Mac Times pane progress (driven off the per-second timer; the iOS layout uses its own).
    @State private var macProgress: CGFloat = 0

    @State var nextRoundMinuteTimer: Timer?
    //    @State var percentComplete: Double = 0.0
    let secondsTimer = Timer.publish(
        every: 1, // second
        on: .main,
        in: .common
    ).autoconnect()
    //    @State var relativeDate: Date = AthanManager.shared.guaranteedNextPrayerTime()
    @State var relativeTimeStr: String = ""
    @State var relativeDateId: Int = 0
    func relativeTime() -> String { // used for ios 13
        let comps = Calendar.current.dateComponents([.hour, .minute], from: athanNow(),
                                                    to: AthanManager.shared.guaranteedNextPrayerTime())
        
        if let prefLang = Locale.preferredLanguages.first, prefLang.hasPrefix("en") {
            // 1h 2m | 1h | 53m | 10s
            if comps.hour == 0 && comps.minute == 0 {
                return "<1m left"
            } else if comps.minute == 0 { // only
                return "\(comps.hour!)h left"
            } else if comps.hour == 0 { // only mins
                return "\(comps.minute!)m left"
            }
            return "\(comps.hour!)h \(comps.minute!)m left"
        } else {
            if comps.hour == 0 && comps.minute == 0 {
                return "<1m"
            } else if comps.minute == 0 { // only
                return "\(comps.hour!)h"
            } else if comps.hour == 0 { // only mins
                return "\(comps.minute!)m"
            }
            
            return "\(comps.hour!)h \(comps.minute!)m"
        }
    }
    
    func getPercentComplete() -> Double {
        var currentTime: Date?
        if let currentPrayer = ObservableAthanManager.shared.todayTimes.currentPrayer(at: athanNow()) {
            currentTime = ObservableAthanManager.shared.todayTimes.time(for: currentPrayer)
        } else { // if current prayer nil (post midnight, before fajr), set current time to approximately today's isha, subtracting by a day
            currentTime = ObservableAthanManager.shared.todayTimes.time(for: .isha).addingTimeInterval(-86400)
        }
        
        var nextTime: Date?
        if ObservableAthanManager.shared.todayTimes.currentPrayer(at: athanNow()) == .isha { // if currently isha, use TOMORROW fajr
            nextTime = ObservableAthanManager.shared.tomorrowTimes.time(for: .fajr)
        } else if let nextPrayer = ObservableAthanManager.shared.todayTimes.nextPrayer(at: athanNow()) { // if prayer is non-nil (known not isha), calculate next prayer naturally
            nextTime = ObservableAthanManager.shared.todayTimes.time(for: nextPrayer)
        } else { // if next prayer is nil (i.e. we are on yesterday isha) use today fajr
            nextTime = ObservableAthanManager.shared.todayTimes.time(for: .fajr)
        }
        return athanNow().timeIntervalSince(currentTime!) / nextTime!.timeIntervalSince(currentTime!)
    }
    
    static func hijriDateString(date: Date, isAccessibilityLabel: Bool) -> String {
        let hijri = HijriSettings.shared
        let df = DateFormatter()
        df.calendar = hijri.calendar()
        df.dateStyle = isAccessibilityLabel ? .full : .medium
//        print("here")
        #warning("this gets called too often on stage changes. change later for performance.")
        
        // if arabic, always use arabic numerals
        if Locale.preferredLanguages.first?.hasPrefix("ar") ?? false {
            df.locale = Locale(identifier: "ar_SY")
        }
        return df.string(from: hijri.adjusted(date))
    }
    
    let weakImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    let strongImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    init(macDetailOnly: Bool = false) {
        self.macDetailOnly = macDetailOnly
        _currentView = State(initialValue: SnapshotSupport.showsIntro ? PresentedSectionType.Location : ((AthanManager.shared.locationSettings.locationName.isEmpty) ? PresentedSectionType.Location : PresentedSectionType.Main))
        
        // for calculating progress of CURRENT prayer
        previewManualPrayerProgressCancellable = dayProgressState.$manualDayProgress
            .receive(on: RunLoop.main)
            .combineLatest(dayProgressState.$manualPrayer)
            .map { tuple in
                let manualProg = Double(tuple.0)
                
                var currentTime: Date?
                if let currentPrayer = tuple.1 {
                    currentTime = ObservableAthanManager.shared.todayTimes.time(for: currentPrayer)
                } else { // if current prayer nil (post midnight, before fajr), set current time to approximately today's isha, subtracting by a day
                    currentTime = ObservableAthanManager.shared.todayTimes.time(for: .isha).addingTimeInterval(-86400)
                }
                
                var nextTime: Date?
                if tuple.1 == .isha { // if currently isha, use TOMORROW fajr
                    nextTime = ObservableAthanManager.shared.tomorrowTimes.time(for: .fajr)
                } else if let nextPrayer = tuple.1?.next()  { // if prayer is non-nil (known not isha), calculate next prayer naturall
                    nextTime = ObservableAthanManager.shared.todayTimes.time(for: nextPrayer)
                } else { // if next prayer is nil (i.e. we are on yesterday isha) use today fajr
                    nextTime = ObservableAthanManager.shared.todayTimes.time(for: .fajr)
                }
                let inputDate = ObservableAthanManager.shared.todayTimes.dhuhr.addingTimeInterval(-86400 / 2 + TimeInterval(manualProg * 86400))
                return inputDate.timeIntervalSince(currentTime!) / nextTime!.timeIntervalSince(currentTime!)
            }
            .assign(to: \.manualCurrentPrayerProgress, on: dayProgressState)
        
        // assign to previewCurrentPrayerProgress
        previewConsensusPrayerProgressCancellable = Publishers.CombineLatest(dayProgressState.$manualCurrentPrayerProgress, dayProgressState.$truthCurrentPrayerProgress)
            .receive(on: RunLoop.main)
            .combineLatest(dayProgressState.$isDragging, dayProgressState.$previewPrayer)
            .map { tuple in
                if tuple.1 { // if is dragging, use manual prayer
                    return tuple.0.0
                }
                return tuple.0.1 // return real world truth
            }
            .assign(to: \.previewPrayerProgress, on: dayProgressState)
        
        // publish preview prayer for given date and dragging state
        previewManualPrayerCancellable = dayProgressState.$manualDayProgress
            .receive(on: RunLoop.main)
            .map { manualProg in
                // reference point dhuhr changes based on which day is closer.
                // if we are 51% away from "today dhuhr," that's because we still
                // haven't reached yesterday's solar midnight
                
                let inputDate = ObservableAthanManager.shared.todayTimes.dhuhr.addingTimeInterval(TimeInterval((86400 / -2) + manualProg * 86400))
                return ObservableAthanManager.shared.todayTimes.currentPrayer(at: inputDate)
            }
            .assign(to: \.manualPrayer, on: dayProgressState)
        
        // merge manual prayer with ground truth pubs and pick truth if not dragging
        consensusPreviewPrayerCancellable = Publishers.CombineLatest(dayProgressState.$manualPrayer, ObservableAthanManager.shared.$currentPrayer)
            .receive(on: RunLoop.main)
            .combineLatest(dayProgressState.$isDragging)
            .map { tuple in
                if tuple.1 {// if dragging, use calculated current prayer based on drag
                    return tuple.0.0
                }
                return tuple.0.1 // else, return ground truth
            }
            .assign(to: \.previewPrayer, on: dayProgressState)
        
        // read from consensus
        nonOptionalPreviewPrayerCancellable = dayProgressState.$previewPrayer
            .receive(on: RunLoop.main)
            .map { $0 ?? .isha }
            .assign(to: \.nonOptionalPreviewPrayer, on: dayProgressState)
    }
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        if macDetailOnly {
            // Detail pane of the root split view controller.
            macDetail
        } else {
            // Whole window: the location / intro flow. Report when it finishes so the
            // scene can swap the root over to the split view controller.
            coreBody
                .onAppear { MacRootState.shared.isOnboarding = (currentView != .Main) }
                .onChange(of: currentView) { newValue in
                    MacRootState.shared.isOnboarding = (newValue != .Main)
                }
        }
        #else
        coreBody
        #endif
    }

    #if targetEnvironment(macCatalyst)
    /// Binds the sheet-style CalendarView's `showCalendar` to the sidebar section so its
    /// close button returns to the Times pane.
    private var calendarBinding: Binding<Bool> {
        Binding(get: { macSection == .calendar },
                set: { if !$0 { macSection = .times } })
    }

    @ViewBuilder private var macDetail: some View {
        if #available(macCatalyst 16.0, *) {
            ZStack(alignment: .bottomTrailing) {
                macDetailContent
                MacToastView()
            }
        } else {
            macDetailContent
        }
    }

    @ViewBuilder private var macDetailContent: some View {
        switch macSection {
        case .times:
            coreBody
        case .calendar:
            CalendarView(showCalendar: calendarBinding)
                .equatable()
                .background(Color(.systemBackground).ignoresSafeArea())
                .preferredColorScheme(.dark)
        case .settings:
            if #available(iOS 16.0, *) {
                MacSettingsView()   // native grouped Form on Mac
            } else {
                ZStack {
                    GradientView(currentPrayer: $dayProgressState.nonOptionalPreviewPrayer, appearance: $manager.appearance)
                        .equatable()
                        .ignoresSafeArea()
                    SettingsView(parentSession: $currentView, initialSection: settingsInitialSection)
                }
            }
        case .discover:
            // Sidebar section, not a modal — the sidebar itself is how you leave, so a
            // close button here would be a second, redundant exit.
            FeatureDiscoveryView()
                .preferredColorScheme(.dark)
        }
    }
    #endif

    // Clean Mac Times pane: progress bar pinned at top, a large centered moon, and the
    // solar arc at the bottom. Prayer times + Qibla live in the sidebar, so they're omitted here.
    @ViewBuilder private func macTimesLayout(_ g: GeometryProxy) -> some View {
        let nameSize = min(120, g.size.width * 0.12)
        let moonSize = nameSize * 1.6
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 28) {
                // Big current prayer name, descriptive countdown, then the loader below it.
                VStack(alignment: .leading, spacing: 18) {
                    Text(dayProgressState.nonOptionalPreviewPrayer.localizedOrCustomString())
                        .font(.system(size: nameSize, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .animation(.linear, value: dayProgressState.nonOptionalPreviewPrayer)

                    macCountdownText()
                        .font(.system(size: 17.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)   // stay on one line; shrink only if truly needed
                        .opacity(dayProgressState.isDragging ? 0.25 : 1)

                    ProgressBar(progress: max(0, min(1, macProgress)), lineWidth: 13,
                                outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])
                        .frame(width: g.size.width * 0.5)   // half the pane width
                        .padding(.top, 4)
                }

                Spacer(minLength: 12)

                MoonView3D()
                    .frame(width: moonSize, height: moonSize)
                    .shadow(radius: 4)
                    .flipsForRightToLeftLayoutDirection(false)
            }

            Spacer(minLength: 8)

            macSolarArc(g)
                .frame(height: max(96, g.size.height * 0.12))
                .padding(.horizontal, 4)
                .padding(.bottom, 54)   // arc sits 20pt further off the bottom
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 44)
        .padding(.top, 8)               // whole group rides 20pt higher with it
        .onAppear { if manager.todayTimes != nil { macProgress = CGFloat(getPercentComplete()) } }
        .onReceive(secondsTimer) { _ in
            relativeDateId += 1   // refresh the countdown subtitle each second
            if manager.todayTimes != nil, !dayProgressState.isDragging {
                macProgress = CGFloat(getPercentComplete())
            }
        }
    }

    /// "3 hr 12 min until <Asr> · begins 3:38 PM" — next prayer name in gold.
    private func macCountdownText() -> Text {
        let gold = Color(red: 0.957, green: 0.835, blue: 0.553)
        let next = AthanManager.shared.guaranteedNextPrayer()
        let nextTime = AthanManager.shared.guaranteedNextPrayerTime()
        let remaining = max(0, nextTime.timeIntervalSinceNow)
        Self.macClockFormatter.timeZone = LocationSettings.shared.timeZone
        let clock = Self.macClockFormatter.string(from: nextTime)
        return Text(Self.durationPhrase(remaining) + " " + NSLocalizedString("until_prayer", value: "until", comment: "before a prayer name") + " ")
                .foregroundColor(.white.opacity(0.72))
            + Text(next.localizedOrCustomString())
                .foregroundColor(gold).fontWeight(.semibold)
            + Text("  ·  " + NSLocalizedString("begins_at", value: "begins", comment: "before a clock time") + " " + clock)
                .foregroundColor(.white.opacity(0.45))
    }

    static func durationPhrase(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600, m = (total % 3600) / 60
        if h > 0 && m > 0 { return String(format: NSLocalizedString("dur_hr_min", value: "%d hr %d min", comment: ""), h, m) }
        if h > 0 { return String(format: NSLocalizedString("dur_hr", value: "%d hr", comment: ""), h) }
        if m > 0 { return String(format: NSLocalizedString("dur_min", value: "%d min", comment: ""), m) }
        return NSLocalizedString("dur_lt_min", value: "less than a minute", comment: "")
    }

    static let macClockFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }()

    @ViewBuilder private func macSolarArc(_ g: GeometryProxy) -> some View {
        if manager.todayTimes != nil {
            let dayProg: CGFloat = {
                var r = CGFloat(0.5 + athanNow().timeIntervalSince(manager.todayTimes.dhuhr) / 86400)
                if r < 0 { r += 1 }
                return r
            }()
            SolarView(dayProgress: .constant(dayProg),
                      manualDayProgress: $dayProgressState.manualDayProgress,
                      isDragging: $dayProgressState.isDragging,
                      sunlightFraction: CGFloat(manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400),
                      hidingCircle: true,
                      dhuhrTime: manager.todayTimes.dhuhr,
                      sunriseTime: manager.todayTimes.sunrise)
                .equatable()
                .onDisappear {
                    dayProgressState.manualDayProgress = 0
                    dayProgressState.isDragging = false
                }
        }
    }

    var coreBody: some View {
        ZStack {
            GeometryReader { g in
                GradientView(currentPrayer: $dayProgressState.nonOptionalPreviewPrayer, appearance: $manager.appearance)
                    .equatable()
                
                if dayProgressState.nonOptionalPreviewPrayer == .isha {
                    StarView(starCount: max(45, Int(g.size.width * g.size.height / 6000)))
                        .equatable()
                        .transition(.opacity)
                }

                // Tap-anywhere-else dismissal for the Hijri callout. It has to be a
                // full-bleed layer at the root: a backdrop inside the solar view would
                // only catch the thin strip around the date itself. It sits UNDER the
                // content, so taps on the callout still reach the callout.
                if hijriCallout.isPresented {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { hijriCallout.dismiss() }
                        .transition(.identity)
                }
                
                VStack(alignment: .leading) {
                    switch currentView {
                    case .Location:
                        LocationSettingsView(parentSession: $currentView, locationPermissionGranted: $manager.locationPermissionsGranted)
                            .equatable()
                            .transition(.opacity)
                        
                    case .IntroSettings:
                        // collect basic preferences for calculation method and prayer angle
                        IntroSettingsView(parentSession: $currentView)
                        
                    case .Settings:
                        SettingsView(parentSession: $currentView, initialSection: settingsInitialSection)
                            .transition(.opacity)
                    case .Main:
                        Group {
                        if isMac {
                            macTimesLayout(g)
                        } else {
                        HStack {
                            if useTwoColumn {
                                HStack(alignment: .center, spacing: 0) {
                                    Spacer()
                                    MoonView3D()
                                        .frame(width: g.size.width / 3, height: g.size.width / 3, alignment: .center)
                                        .offset(y: 12)
                                        .shadow(radius: 3)
                                        .flipsForRightToLeftLayoutDirection(false)
                                    Spacer()
                                }
                            }
                            if isMac { Spacer(minLength: 0) }   // center the iPhone-style column on Mac
                            VStack(alignment: .leading, spacing: 0) {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !useTwoColumn {
                                        HStack(alignment: .center, spacing: 0) {

                                            Spacer()
                                            MoonView3D()
                                                .frame(width: g.size.width / 3, height: g.size.width / 3, alignment: .center)
                                                .offset(y: 18)
                                                .shadow(radius: 3)
                                                .flipsForRightToLeftLayoutDirection(false)
                                            Spacer()
                                        }
                                    }
                                    
                                    HStack(alignment: .lastTextBaseline) {
                                        VStack(alignment: .leading) {
                                            PrayerSymbol(prayerType: dayProgressState.nonOptionalPreviewPrayer)
                                                .foregroundColor(.white)
                                                .font(Font.system(.title).weight(.medium))
                                            
                                            Text(dayProgressState.nonOptionalPreviewPrayer.localizedOrCustomString())
                                                .font(.largeTitle)
                                                .bold()
                                                .foregroundColor(.white)
                                                .id("title" + dayProgressState.nonOptionalPreviewPrayer.stringValue())
                                        }
                                        .animation(.linear, value: dayProgressState.nonOptionalPreviewPrayer)
                                        
                                        Spacer() // space title | qibla
                                        
                                        VStack(alignment: .trailing, spacing: 0) {
                                            QiblaPointerView(angle: $manager.currentHeading,
                                                             qiblaAngle: $manager.qiblaHeading)
                                                .frame(width: g.size.width * 0.2, height: g.size.width * 0.2, alignment: .center)
                                                .offset(x: g.size.width * 0.03, y: 0) // offset to let pointer go out
                                            
                                            // for now, time remaining will only show seconds on ios >=14
                                            if #available(iOS 14.0, *) {
                                                // for now, only allow english to use "x minutes left". others will just have time stated
                                                TimeLeftView(id: $relativeDateId)
                                                    .opacity(dayProgressState.isDragging ? 0.2 : 1)
                                                    .onReceive(secondsTimer) { _ in
                                                        relativeDateId += 1
                                                    }
                                            } else {
                                                // Fallback on earlier versions
                                                Text("\(relativeTimeStr)")
                                                    .fontWeight(.bold)
                                                    .autocapitalization(.none)
                                                    .foregroundColor(Color(.lightText))
                                                    .multilineTextAlignment(.trailing)
                                                    .minimumScaleFactor(0.01)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .lineLimit(1)
                                                    .opacity(dayProgressState.isDragging ? 0.2 : 1)
                                                    .onReceive(secondsTimer) { _ in
//                                                        print("fire second timer")
                                                        relativeTimeStr = relativeTime()
                                                    }
                                            }
                                        }
                                    }
                                    
                                    ProgressBar(progress: CGFloat(dayProgressState.previewPrayerProgress), lineWidth: 10,
                                                outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])
                                        .onAppear(perform: { // wake update timers that will update progress
                                            dayProgressState.truthCurrentPrayerProgress = getPercentComplete()
                                            nextRoundMinuteTimer = {
                                                // this gets called again when the view appears -- have it invalidated on appear
                                                let comps = Calendar.current.dateComponents([.second], from: Date())
                                                let secondsTilNextMinute = 60 - comps.second!
                                                return Timer.scheduledTimer(withTimeInterval: TimeInterval(secondsTilNextMinute),
                                                                            repeats: false) { _ in
                                                    dayProgressState.truthCurrentPrayerProgress = getPercentComplete()
                                                    minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
                                                        dayProgressState.truthCurrentPrayerProgress = getPercentComplete()
                                                    })
                                                }
                                            }()
                                            
                                            if !IntroSetupFlags.hasCompletedCalculationSetup {
                                                withAnimation {
                                                    currentView = .IntroSettings
                                                }
                                            }
                                        })
                                        .onDisappear {
                                            minuteTimer?.invalidate()
                                            nextRoundMinuteTimer?.invalidate()
                                            minuteTimer?.invalidate()
                                        }
                                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                                            minuteTimer?.invalidate()
                                            nextRoundMinuteTimer?.invalidate()
                                            minuteTimer?.invalidate()
                                            print("moving to background!")
                                        }
                                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                                            print("Moving back to the foreground!")
                                            
                                            // if user has entered the app from a blank state exactly 5 times, ask them if they are willing to review the app
                                            let checkCount = UserDefaults.standard.integer(forKey: "rating-req-ct")
                                            if checkCount == 3 {
                                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { t in
                                                    SKStoreReviewController.requestReview()
                                                }
                                                UserDefaults.standard.setValue(checkCount + 1, forKey: "rating-req-ct")
                                            } else if checkCount < 3 {
                                                UserDefaults.standard.setValue(checkCount + 1, forKey: "rating-req-ct")
                                            }

                                            
                                            dayProgressState.truthCurrentPrayerProgress = getPercentComplete()
                                            nextRoundMinuteTimer = {
                                                // this gets called again when the view appears -- have it invalidated on appear
                                                let comps = Calendar.current.dateComponents([.second], from: Date())
                                                let secondsTilNextMinute = 60 - comps.second!
                                                return Timer.scheduledTimer(withTimeInterval: TimeInterval(secondsTilNextMinute),
                                                                            repeats: false) { _ in
                                                    dayProgressState.truthCurrentPrayerProgress = getPercentComplete()
                                                    minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
                                                        dayProgressState.truthCurrentPrayerProgress = getPercentComplete()
                                                    })
                                                }
                                            }()
                                        }
                                    
                                    let cellFont = Font.system(size: min(50, g.size.width * 0.06))
                                    let timeFormatter: DateFormatter = {
                                        let df = DateFormatter()
                                        df.timeStyle = .short
                                        if Locale.preferredLanguages.first?.hasPrefix("ar") ?? false {
                                            df.locale = Locale(identifier: "ar_SY")
                                        }
                                        df.timeZone = LocationSettings.shared.timeZone
                                        return df
                                    }()
                                    
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(.init(.sRGB, white: 1, opacity: 0.000001)) // to allow gestures from middle of box
                                            // Tapping anywhere in the times box reveals the day
                                            // arrows beside the Hijri date; tapping again puts
                                            // it back on today.
                                            .onTapGesture { dayBrowse.toggle() }

                                        VStack(alignment: .leading, spacing: 0) { // bottom of prayer names
                                            ForEach(0..<6) { pIndex in
                                                let p = Prayer(index: pIndex)
                                                let highlight: PrayerHighlightType = {
                                                    var h = PrayerHighlightType.present
                                                    if p == dayProgressState.previewPrayer {
                                                        h = .present
                                                    } else if dayProgressState.previewPrayer == nil {
                                                        h = .future
                                                    } else {
                                                        h = p.rawValue() < manager.currentPrayer.rawValue() ? .past : .future
                                                    }
                                                    return h
                                                }()
                                                
                                                // While peeking at another day every row reads
                                                // the same muted gray — the current/past/future
                                                // highlight is about *now*, and would be a lie
                                                // on a day that isn't today.
                                                let browsedTimes: PrayerTimes = dayBrowse.times ?? manager.todayTimes
                                                let rowColor: Color = dayBrowse.offset != 0
                                                    ? Color.gray.opacity(0.8)
                                                    : highlight.color()

                                                HStack {
                                                    Text(p.localizedOrCustomString())
                                                        .foregroundColor(rowColor)
                                                        .font(cellFont)
                                                        .bold()

                                                    Spacer()
                                                    Text(timeFormatter.string(from: browsedTimes.time(for: p)))
                                                        // replace 3 with current prayer index
                                                        .foregroundColor(rowColor)
                                                        .font(cellFont)
                                                        .bold()
                                                }
                                                .animation(.linear(duration: 0.2), value: manager.currentPrayer)
                                                .accessibilityElement(children: .combine)
                                                    Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding([.leading, .trailing])
                                .padding([.leading, .trailing])
                                // The name -> progress bar gap is the enclosing VStack's
                                // spacing of 12; below the bar it was 0, so the bar sat
                                // noticeably closer to Fajr than to the prayer name.
                                .padding(.top, isMac ? 0 : 10)
                                ZStack() {
                                    // calculate progress of day
                                    let _dayProg: CGFloat = {
                                        var todayDhuhrReference = CGFloat(0.5 + athanNow().timeIntervalSince(manager.todayTimes.dhuhr) / 86400)
                                        if todayDhuhrReference < 0 {
                                            todayDhuhrReference += 1
                                        }
                                        return todayDhuhrReference
                                    }()
                                    SolarView(dayProgress: .constant(_dayProg),
                                              manualDayProgress: $dayProgressState.manualDayProgress,
                                              isDragging: $dayProgressState.isDragging,
                                              sunlightFraction: CGFloat(manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400),
                                              hidingCircle: true,
                                              dhuhrTime: manager.todayTimes.dhuhr,
                                              sunriseTime: manager.todayTimes.sunrise)
                                        .equatable()
                                        .onDisappear {
                                            dayProgressState.manualDayProgress = 0
                                            dayProgressState.isDragging = false
                                        }
                                }
                                .frame(height: max(80, g.size.height * 0.1))

                                // 20pt more clearance below the arc than above it, so the
                                // graph sits off the bottom of the stack rather than on it.
                                .padding(.top, 12)
                                .padding(.bottom, 32)
                                ZStack {
                                    VStack {
//                                        Spacer()
                                        // On Mac these live in the sidebar, so hide the in-content nav row.
                                        if !isMac {
                                        HStack(alignment: .center) {
                                            // Location button
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                withAnimation {
                                                    currentView = (currentView != .Main) ? .Main : .Location
                                                }
                                            }) {
                                                HStack(spacing: 1) {
                                                    Image(systemName: manager.locationPermissionsGranted && LocationSettings.shared.useCurrentLocation ? "location.fill" : "location.slash")
                                                        .foregroundColor(Color(.lightText))
                                                        .font(Font.body)
                                                    
                                                    // Use "Edit Location" string if location name empty
                                                    Text("\(manager.locationName.isEmpty ? Strings.editLocationButtonTitle : manager.locationName)")
                                                        .foregroundColor(Color(.lightText))
                                                        .font(Font.body.weight(.bold))
                                                        .lineLimit(1)
                                                }
                                            }
                                            .padding(12)
                                            .offset(x: -14, y: 12)
                                            .accessibilityLabel("acc_location_settings")
                                            .accessibilityIdentifier("locationButton")
                                            
                                            Spacer()
                                            
                                            HStack {
                                                // calendar button
                                                Button(action: {
                                                    let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                                    lightImpactFeedbackGenerator.impactOccurred()
                                                    withAnimation {
                                                        showCalendar = true
                                                    }
                                                }) {
                                                    Image(systemName: "calendar")
                                                }
                                                .foregroundColor(Color(.lightText))
                                                .font(Font.body.weight(.bold))
                                                .accessibilityLabel("acc_calendar")
                                                .accessibilityIdentifier("calendarButton")
                                                
                                                // Settings button
                                                Button(action: {
                                                    let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                                    lightImpactFeedbackGenerator.impactOccurred()
                                                    settingsInitialSection = .General // normal gear tap opens General
                                                    withAnimation {
                                                        currentView = (currentView != .Main) ? .Main : .Settings // if we were in location, go back to main
                                                    }
                                                }) {
                                                    Image(systemName: "gear")
                                                        .padding(12)
                                                }
                                                .foregroundColor(Color(.lightText))
                                                .font(Font.body.weight(.bold))
                                                .accessibilityLabel("acc_settings")
                                                .accessibilityIdentifier("settingsButton")
                                            }
                                            
                                            
                                            .offset(x: 12, y: 12)
                                        }
                                        .padding([.leading, .trailing, .bottom])
                                        .padding([.leading, .trailing, .bottom])
                                        } // if !isMac
                                    }
                                }
                            }
                            // cap the reading column on iPad/Mac so prayer rows don't stretch edge-to-edge
                            .frame(maxWidth: _horizontalSizeClass == .regular ? 620 : .infinity)
                            .padding(_horizontalSizeClass == .regular ? 24 : 0)

                        }
                        } // else (iOS/iPad layout)
                        } // Group
                        .transition(.opacity)
                        .sheet(isPresented: $showCalendar) { // set highest progress back to 0 when we know the view disappeared
                            CalendarView(showCalendar: $showCalendar)
                                .equatable()
                                .background(Color(.systemBackground).ignoresSafeArea())
                                .preferredColorScheme(.dark) // sheets don't inherit the app's forced dark scheme
                        }

                    }
                }
                
                // top right corner gets a sound control button
                VStack {
                    HStack(spacing: 10) {
                        Spacer()
                        // Feature-discovery hint — only until the user opens it once.
                        // On Mac, Discover lives in the sidebar, so skip the hint there.
                        if currentView == .Main, !discoverySeen, !isMac {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                FeatureDiscovery.hasSeen = true
                                discoverySeen = true // hide the hint from the main UI immediately
                                showDiscovery = true
                            }) {
                                Image(systemName: "lightbulb.fill")
                                    .font(Font.body.weight(.bold))
                                    .foregroundColor(Color(.lightText))
                            }
                            .accessibilityLabel(Text(Strings.discoverFeatures))
                            .accessibilityIdentifier("discoverButton")
                        }
                        AthanPlayView(currentPrayer: $manager.currentPrayer)
                            .equatable()
                    }
                    .padding()
                    .padding()
                    .offset(x: g.size.width * 0.03) // right-edge align with the Qibla compass
                    Spacer()
                }
                .sheet(isPresented: $showDiscovery) {
                    // Presented modally (light bulb, or the new-features notification),
                    // so it needs its own way out. On iOS that's the nav bar's Done; on
                    // Mac the grid has no nav bar, hence the explicit close.
                    FeatureDiscoveryView(macOnDismiss: { showDiscovery = false })
                        .preferredColorScheme(.dark)
                }
            }

            // "Updated Calculation Method" popup — floats up from the bottom of the main
            // screen. The method has already changed; the popup lets the user Undo or OK.
            if currentView == .Main, let notice = manager.methodUpdateNotice {
                VStack {
                    Spacer()
                    MethodUpdatePopup(
                        notice: notice,
                        onUndo: {
                            AthanManager.shared.undoMethodUpdate(notice)
                            withAnimation { manager.methodUpdateNotice = nil }
                        },
                        onOK: {
                            AthanManager.shared.acknowledgeMethodUpdate()
                            withAnimation { manager.methodUpdateNotice = nil }
                        }
                    )
                    .id(notice.id)
                    .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .onAppear {
            // Ask for notifications a few seconds from now, once the user has actually
            // seen their prayer times — not during the location flow. See
            // NotificationPermission for why this moved.
            NotificationPermission.promptAfterMainUIAppears()

            guard !didEvaluateStartupSuggestion else { return }
            didEvaluateStartupSuggestion = true
            // Surface any update that already happened in the background (e.g. a widget
            // refresh auto-updated the method while the app was closed).
            if manager.methodUpdateNotice == nil,
               let pending = AthanManager.shared.loadPendingMethodUpdateNotice() {
                manager.methodUpdateNotice = pending
            }
            // Carry the pre-8.0 per-process record into the shared one before evaluating,
            // so an upgrade doesn't read as "no country ever handled" and pop immediately.
            AthanManager.shared.migrateHandledSuggestionCountryIfNeeded()
            // Evaluate the best country we can infer — GPS if shared, otherwise device region —
            // and auto-update the method if it warrants a change.
            AthanManager.shared.autoUpdateMethodIfNeeded(for: AthanManager.shared.bestAvailableCountryCode())

            // Cold-launch from tapping the new-features notification: the live
            // .athanOpenFeatureDiscovery post (below) has no subscriber yet at
            // launch time, so it's lost. This persisted flag survives that gap.
            if NewFeaturesAnnouncement.consumePendingOpen() {
                currentView = .Main
                FeatureDiscovery.hasSeen = true
                discoverySeen = true
                showDiscovery = true
            }
        }
        // The menu-bar popover's gear (AthanShowMacSettings) is handled by MacRootState,
        // not here: this body only exists while the Times pane is on screen, so a handler
        // here did nothing whenever the user was already in Calendar or Discover.
        // Tapping the one-time new-features local notification → open Discover
        // Features directly. Also flips the light-bulb hint's local state (not
        // just the persisted flag) since it may have been set before this view's
        // @State was initialized this session.
        .onReceive(NotificationCenter.default.publisher(for: .athanOpenFeatureDiscovery)) { _ in
            currentView = .Main
            FeatureDiscovery.hasSeen = true
            discoverySeen = true
            showDiscovery = true
        }
    }
}

@available(iOS 13.0.0, *)
struct ProgressBar: View {
    var progress: CGFloat
    @State var lineWidth: CGFloat = 7
    @State var outlineColor: Color
    
    var colors: [Color] = [Color.white, Color.white]
    
    var body: some View {
        GeometryReader { g in
        ZStack {
            Rectangle()
                .foregroundColor(outlineColor)
                .frame(height: lineWidth)
                .cornerRadius(lineWidth * 0.5)
            
                ZStack(alignment: .leading) {
                    HStack {
                    Rectangle()
                        .foregroundColor(colors.first)
                        .frame(width: min(g.size.width, max(lineWidth, progress * g.size.width)), height: lineWidth)
                        .cornerRadius(lineWidth * 0.5)
                    Spacer()
                    }
                    .frame(width: g.size.width)
                }
            }
        }
        .padding(.zero)
        .frame(height: lineWidth)

    }
}

// MARK: - Calculation-method update popup

/// Compact rounded-rect popup that floats up from the bottom of the main screen to tell
/// the user their calculation method was auto-updated for their country. Top line reads
/// "Updated Calculation Method"; the line under it shows "<old> → <new>" (SF Symbol arrow,
/// truncated so it never spills). An Undo button reverts the change; OK (to its right)
/// acknowledges it. Both buttons use the same rounded-rect style.
@available(iOS 13.0.0, *)
struct MethodUpdatePopup: View {
    let notice: MethodUpdateNotice
    var onUndo: () -> Void
    var onOK: () -> Void

    private var transitionRow: some View {
        HStack(spacing: 6) {
            Text(notice.oldMethod.localizedString())
                .foregroundColor(.white.opacity(0.6))
            Image(systemName: "arrow.right")
                .imageScale(.small)
                .foregroundColor(.white.opacity(0.6))
                .flipsForRightToLeftLayoutDirection(true) // point in the reading direction (RTL)
            Text(notice.newMethod.localizedString())
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .font(.footnote)
        .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Strings.updatedCalculationMethod)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                transitionRow
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 6)

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onUndo()
            }) {
                Text(Strings.undo)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.14))
                    )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onOK()
            }) {
                Text(Strings.ok)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.24))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MainSwiftUI()
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
}
