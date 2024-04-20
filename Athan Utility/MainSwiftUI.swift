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
    @State var minuteTimer: Timer? = nil
    
    @State var settingsToggled = false
    @State var locationSettingsToggled = false
    @State var showCalendar = false
    
    @State var currentView: PresentedSectionType
        
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
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date(),
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
        if let currentPrayer = ObservableAthanManager.shared.todayTimes.currentPrayer() {
            currentTime = ObservableAthanManager.shared.todayTimes.time(for: currentPrayer)
        } else { // if current prayer nil (post midnight, before fajr), set current time to approximately today's isha, subtracting by a day
            currentTime = ObservableAthanManager.shared.todayTimes.time(for: .isha).addingTimeInterval(-86400)
        }
        
        var nextTime: Date?
        if ObservableAthanManager.shared.todayTimes.currentPrayer() == .isha { // if currently isha, use TOMORROW fajr
            nextTime = ObservableAthanManager.shared.tomorrowTimes.time(for: .fajr)
        } else if let nextPrayer = ObservableAthanManager.shared.todayTimes.nextPrayer() { // if prayer is non-nil (known not isha), calculate next prayer naturally
            nextTime = ObservableAthanManager.shared.todayTimes.time(for: nextPrayer)
        } else { // if next prayer is nil (i.e. we are on yesterday isha) use today fajr
            nextTime = ObservableAthanManager.shared.todayTimes.time(for: .fajr)
        }
        return Date().timeIntervalSince(currentTime!) / nextTime!.timeIntervalSince(currentTime!)
    }
    
    static func hijriDateString(date: Date) -> String {
        let hijriCal = Calendar(identifier: .islamicUmmAlQura)
        let df = DateFormatter()
        df.calendar = hijriCal
        df.dateStyle = .medium
//        print("here")
        #warning("this gets called too often on stage changes. change later for performance.")
        
        // if arabic, always use arabic numerals
        if Locale.preferredLanguages.first?.hasPrefix("ar") ?? false {
            df.locale = Locale(identifier: "ar_SY")
        }
        return df.string(from: date)
    }
    
    let weakImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    let strongImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    init() {
        _currentView = State(initialValue: (AthanManager.shared.locationSettings.locationName.isEmpty) ? PresentedSectionType.Location : PresentedSectionType.Main)
        
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
        ZStack {
            GeometryReader { g in
                GradientView(currentPrayer: $dayProgressState.nonOptionalPreviewPrayer, appearance: $manager.appearance)
                    .equatable()
                
                if dayProgressState.nonOptionalPreviewPrayer == .isha {
                    StarView(starCount: Int(g.size.width / 800))
                        .equatable()
                        .transition(.opacity)
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
                        SettingsView(parentSession: $currentView)
                            .transition(.opacity)
                    case .Main:
                        HStack {
                            if _horizontalSizeClass == .regular {
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
                            VStack(alignment: .leading, spacing: 0) {
                                VStack(alignment: .leading, spacing: 12) {
                                    if _horizontalSizeClass != .regular {
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
                                        .animation(.linear)
                                        
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
                                        return df
                                    }()
                                    
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(.init(.sRGB, white: 1, opacity: 0.000001)) // to allow gestures from middle of box
                                        
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
                                                
                                                HStack {
                                                    Text(p.localizedOrCustomString())
                                                        .foregroundColor(highlight.color())
                                                        .font(cellFont)
                                                        .bold()
                                                    
                                                    Spacer()
                                                    Text(timeFormatter.string(from: manager.todayTimes.time(for: p)))
                                                        // replace 3 with current prayer index
                                                        .foregroundColor(highlight.color())
                                                        .font(cellFont)
                                                        .bold()
                                                }
                                                .animation(.linear(duration: 0.2))
                                                    Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding([.leading, .trailing])
                                .padding([.leading, .trailing])
                                ZStack() {
                                    // calculate progress of day
                                    let _dayProg: CGFloat = {
                                        var todayDhuhrReference = CGFloat(0.5 + Date().timeIntervalSince(manager.todayTimes.dhuhr) / 86400)
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
                                
                                .padding([.top, .bottom], 12)
                                ZStack {
                                    VStack {
//                                        Spacer()
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
                                                
                                                // Settings button
                                                Button(action: {
                                                    let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                                    lightImpactFeedbackGenerator.impactOccurred()
                                                    withAnimation {
                                                        currentView = (currentView != .Main) ? .Main : .Settings // if we were in location, go back to main
                                                    }
                                                }) {
                                                    Image(systemName: "gear")
                                                        .padding(12)
                                                }
                                                .foregroundColor(Color(.lightText))
                                                .font(Font.body.weight(.bold))
                                            }
                                            
                                            
                                            .offset(x: 12, y: 12)
                                        }
                                        .padding([.leading, .trailing, .bottom])
                                        .padding([.leading, .trailing, .bottom])
                                    }
                                }
                            }
                            .padding(_horizontalSizeClass == .regular ? 24 : 0)
                            
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showCalendar) { // set highest progress back to 0 when we know the view disappeared
                            CalendarView(showCalendar: $showCalendar)
                                .equatable()
                        }
                    }
                }
                
                // top right corner gets a sound control button
                VStack {
                    HStack {
                        Spacer()
                        AthanPlayView(currentPrayer: $manager.currentPrayer)
                            .equatable()
                    }
                    .padding()
                    .padding()
                    Spacer()
                }
            }
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

#Preview {
    MainSwiftUI()
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
}
