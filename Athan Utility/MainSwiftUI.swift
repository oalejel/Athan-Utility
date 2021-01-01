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

enum CurrentView {
    case Main, Settings, Location
}

@available(iOS 13.0.0, *)
extension View {
    func onValueChanged<Value: Equatable>(_ value: Value, completion: (Value) -> Void) -> some View {
        completion(value)
        return self
    }
}


@available(iOS 13.0.0, *)
class CalendarDragState: ObservableObject {
    @Published var progress: Double = 0
    @Published var dragIncrement: Int = 0
    @Published var showCalendar: Bool = false
}

@available(iOS 13.0.0, *)
class DayProgressState: ObservableObject {
    @Published var manualDayProgress: CGFloat = 0.0 // a changes b and c
    @Published var previewCurrentPrayerProgress: Double = 0 // changed by a if dragging
    @Published var previewPrayer: Prayer? = nil
    @Published var nonOptionalPreviewPrayer: Prayer = .fajr
    @Published var isDragging = false
}

@available(iOS 13.0.0, *)
struct MainSwiftUI: View {
    
    @EnvironmentObject var manager: ObservableAthanManager

    @ObservedObject var dragState = CalendarDragState()
    @ObservedObject var dayProgressState = DayProgressState()
    @State var minuteTimer: Timer? = nil
    
    @State var settingsToggled = false
    @State var locationSettingsToggled = false
    
    @State var currentView = CurrentView.Main
    
    @State var todayHijriString = hijriDateString(date: Date())
//    @State var tomorrowHijriString = hijriDateString(date: Date().addingTimeInterval(86400))
    
    @State var nextRoundMinuteTimer: Timer?
    @State var percentComplete: Double = 0.0
    
    func getPercentComplete() -> Double {
        var currentTime: Date?
        if let currentPrayer = manager.todayTimes.currentPrayer() {
            currentTime = manager.todayTimes.time(for: currentPrayer)
        } else { // if current prayer nil (post midnight, before fajr), set current time to approximately today's isha, subtracting by a day
            currentTime = manager.todayTimes.time(for: .isha).addingTimeInterval(-86400)
        }
        
        var nextTime: Date?
        if let nextPrayer = manager.todayTimes.nextPrayer() {
            nextTime = manager.todayTimes.time(for: nextPrayer)
        } else { // if next prayer is nil (i.e. we are on isha) use tomorrow fajr
            nextTime = manager.tomorrowTimes.time(for: .fajr)
        }
        
        return Date().timeIntervalSince(currentTime!) / nextTime!.timeIntervalSince(currentTime!)
    }
    
    static func hijriDateString(date: Date) -> String {
        let hijriCal = Calendar(identifier: .islamic)
        let df = DateFormatter()
        df.calendar = hijriCal
        df.dateStyle = .medium
        print("here")
        if Locale.preferredLanguages.first?.hasPrefix("ar") ?? false {
            df.locale = Locale(identifier: "ar_SY")
        }
        
        return df.string(from: date)
    }
    
    let weakImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    let strongImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    // MARK: - Combine Properties
    // necessary to allow ARC to throw out unused values
    var dragCancellable: AnyCancellable?
    
    // solar manual day progress publishes to our subscriber
    // subscriber combines that stream's data with the current prayer
    // to indicate the visible prayer via a visible prayer state
    var previewPrayerCancellable: AnyCancellable?
    var previewCurrentPrayerProgressCancellable: AnyCancellable?
    var nonOptionalPreviewPrayerCancellable: AnyCancellable?
    
    init() {
        dragCancellable = dragState.$progress
            .receive(on: RunLoop.main)
            // pass along last value, and whether we had an increase
            .scan((0.0, 0), { [self] (tup, new) -> (Double, Int) in
                let r1 = Int(tup.0 / 0.33)
                let r2 = Int(new / 0.33)
                
                if r1 != r2 {
                    print(r1, r2)
                    if r2 > r1 {
                        if r2 == 3 {
                            DispatchQueue.main.async {
                                self.strongImpactGenerator.impactOccurred()
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.weakImpactGenerator.impactOccurred()
                            }
                        }
                    }
                }
                
                return (new, r2)
            })
            .map { v in
                return v.1
            }
            .assign(to: \.dragIncrement, on: dragState)
        
        
        // for calculating progress of CURRENT prayer
        previewCurrentPrayerProgressCancellable = dayProgressState.$manualDayProgress
            .receive(on: RunLoop.main)
            .combineLatest(dayProgressState.$isDragging, dayProgressState.$previewPrayer)
            .map { [self] tuple in
                if tuple.1 { // if is dragging, compute current prayer
                    let manualProg = Double(tuple.0)

                    var currentTime: Date?
                    if let currentPrayer = tuple.2 {
                        currentTime = ObservableAthanManager.shared.todayTimes.time(for: currentPrayer)
                    } else { // if current prayer nil (post midnight, before fajr), set current time to approximately today's isha, subtracting by a day
                        currentTime = ObservableAthanManager.shared.todayTimes.time(for: .isha).addingTimeInterval(-86400)
                    }
                    
                    var nextTime: Date?
                    if tuple.2 != .isha, let nextPrayer = tuple.2?.next()  {
                        nextTime = ObservableAthanManager.shared.todayTimes.time(for: nextPrayer)
                    } else { // if next prayer is nil (i.e. we are on isha) use tomorrow fajr
                        nextTime = ObservableAthanManager.shared.tomorrowTimes.time(for: .fajr)
                    }
                    let inputDate = ObservableAthanManager.shared.todayTimes.dhuhr.addingTimeInterval(-86400 / 2 + TimeInterval(manualProg * 86400))
                    return inputDate.timeIntervalSince(currentTime!) / nextTime!.timeIntervalSince(currentTime!)
                }
                return self.percentComplete // return real world truth
            }
            .assign(to: \.previewCurrentPrayerProgress, on: dayProgressState)
                
        // publish preview prayer for given date and dragging state
        previewPrayerCancellable = dayProgressState.$manualDayProgress
            .receive(on: RunLoop.main)
            .combineLatest(dayProgressState.$isDragging)
            .map { [self] tuple in
                if tuple.1 { // if dragging, calculate current prayer based on time
                    let inputDate = ObservableAthanManager.shared.todayTimes.dhuhr.addingTimeInterval(-86400 / 2 + TimeInterval(tuple.0 * 86400))
                    return ObservableAthanManager.shared.todayTimes.currentPrayer(at: inputDate)
                }
                return ObservableAthanManager.shared.currentPrayer // else, return ground truth
            }
            .assign(to: \.previewPrayer, on: dayProgressState)
        
        nonOptionalPreviewPrayerCancellable = dayProgressState.$previewPrayer
            .receive(on: RunLoop.main)
            .map { $0 ?? .isha }
            .assign(to: \.nonOptionalPreviewPrayer, on: dayProgressState)
    }
    
    @GestureState private var dragOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            GeometryReader { g in
                let timeRemainingString: String = {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: Date(),
                                                                to: AthanManager.shared.guaranteedNextPrayerTime())
                    // 1h 2m | 1h | 53m | 10s
                    if comps.hour == 0 && comps.minute == 0 {
                        return "<1m left"
                    } else if comps.minute == 0 { // only
                        return "\(comps.hour!)h left"
                    } else if comps.hour == 0 { // only mins
                        return "\(comps.minute!)m left"
                    }
                    return "\(comps.hour!)h \(comps.minute!)m left"
                }()
                

                
                GradientView(currentPrayer: $dayProgressState.nonOptionalPreviewPrayer, appearance: $manager.appearance)
                    .equatable()
                
                VStack(alignment: .leading) {
                    switch currentView {
                    case .Location:
                        LocationSettingsView(parentSession: $currentView, locationPermissionGranted: $manager.locationPermissionsGranted)
                            .equatable()
                            .transition(.opacity)
                        
                    case .Settings:
                        SettingsView(parentSession: $currentView)
                            .transition(.opacity)
                    case .Main:
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .center, spacing: 0) {
                                    Spacer()
                                    MoonView3D()
                                        .frame(width: g.size.width / 3, height: g.size.width / 3, alignment: .center)
                                        .offset(y: 12)
                                        .shadow(radius: 3)
                                        .flipsForRightToLeftLayoutDirection(false)
                                    Spacer()
                                }
                                .opacity(1 - 0.8 * dragState.progress)
                                
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading) {
                                        
                                        PrayerSymbol(prayerType: dayProgressState.previewPrayer ?? .isha)
                                            .foregroundColor(.white)
                                            .font(Font.system(.title).weight(.medium))
                                        
                                        Text((dayProgressState.previewPrayer ?? .isha).localizedOrCustomString())
                                            .font(.largeTitle)
                                            .bold()
                                            .foregroundColor(.white)
                                    }
                                    .opacity(1 - 0.8 * dragState.progress)
                                    
                                    Spacer() // space title | qibla
                                    
                                    VStack(alignment: .trailing, spacing: 0) {
                                        QiblaPointerView(angle: $manager.currentHeading,
                                                         qiblaAngle: $manager.qiblaHeading)
                                            .frame(width: g.size.width * 0.2, height: g.size.width * 0.2, alignment: .center)
                                            .offset(x: g.size.width * 0.03, y: 0) // offset to let pointer go out
                                            .opacity(1 - 0.8 * dragState.progress)
                                        
                                        
                                        // for now, time remaining will only show seconds on ios >=14
                                        if #available(iOS 14.0, *) {
                                            Text("\(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative) \(NSLocalizedString("left", comment: ""))")
                                                .fontWeight(.bold)
                                                .autocapitalization(.none)
                                                .foregroundColor(Color(.lightText))
                                                .multilineTextAlignment(.trailing)
                                                .minimumScaleFactor(0.01)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .lineLimit(1)
                                                .opacity(dayProgressState.isDragging ? 0.2 : 1)
                                                .opacity(1 - 0.8 * dragState.progress)
                                        } else {
                                            // Fallback on earlier versions
                                            Text("\(timeRemainingString)")
                                                .fontWeight(.bold)
                                                .autocapitalization(.none)
                                                .foregroundColor(Color(.lightText))
                                                .multilineTextAlignment(.trailing)
                                                .minimumScaleFactor(0.01)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .lineLimit(1)
                                                .opacity(dayProgressState.isDragging ? 0 : 1)
                                                .opacity(1 - 0.8 * dragState.progress)
                                        }
                                    }
                                }
                                
                                ProgressBar(progress: CGFloat(dayProgressState.previewCurrentPrayerProgress), lineWidth: 10,
                                            outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])
                                    .onAppear(perform: { // wake update timers that will update progress
                                        nextRoundMinuteTimer = {
                                            // this gets called again when the view appears -- have it invalidated on appear
                                            let comps = Calendar.current.dateComponents([.second], from: Date())
                                            let secondsTilNextMinute = 60 - comps.second!
                                            return Timer.scheduledTimer(withTimeInterval: TimeInterval(secondsTilNextMinute),
                                                                        repeats: false) { _ in
                                                percentComplete = getPercentComplete()
                                                minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
                                                    percentComplete = getPercentComplete()
                                                    todayHijriString = MainSwiftUI.hijriDateString(date: Date())
//                                                    tomorrowHijriString = MainSwiftUI.hijriDateString(date: Date().addingTimeInterval(86400))
                                                })
                                            }
                                        }()
                                        percentComplete = getPercentComplete()
                                    })
                                    .onDisappear {
                                        minuteTimer?.invalidate()
                                        nextRoundMinuteTimer?.invalidate()
                                        minuteTimer?.invalidate()
                                    }
                                    .opacity(1 - 0.8 * dragState.progress)
                                
                                let cellFont = Font.system(size: g.size.width * 0.06)
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
                                    
                                    VStack(alignment: .leading, spacing: 18) { // bottom of prayer names
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
                                            .opacity(min(1, 1 - 0.8 * dragState.progress))
                                            .rotation3DEffect(
                                                Angle(degrees: dragState.progress * 90 - 0.001),
                                                axis: (x: 1, y: 0, z: 0.0),
                                                anchor: .top,
                                                anchorZ: 0,
                                                perspective: 0.1
                                            )
                                            .animation(.linear(duration: 0.2))
                                        }
                                    }
                                    
                                    VStack(alignment: .center, spacing: 18) {
                                        ActivityIndicator(isAnimating: $dragState.showCalendar, style: .medium)
                                            .foregroundColor(dragState.showCalendar ? Color(.lightText) : Color.clear)

                                        Text(Strings.showCalendar)
                                            .font(Font.body.bold())
                                            .scaleEffect(dragState.progress > 0.999 ? 1.3 : 1)
                                            .animation(.spring())
                                        
                                        Image(systemName: dragState.dragIncrement > 2 ? "arrow.up.circle.fill" : "arrow.up.circle")
                                            .font(.title)
                                        Image(systemName: dragState.dragIncrement > 1 ? "circle.fill" : "circle")
                                            .font(Font.body.bold())
                                        Image(systemName: dragState.dragIncrement > 0 ? "circle.fill" : "circle")
                                            .font(Font.body.bold())
                                    }
                                    .foregroundColor(Color(.lightText))
                                    .opacity(max(0, dragState.progress * 1.3 - 0.3))
                                    .animation(.linear(duration: 0.2))
                                    
                                    //                                    HStack {
                                    //                                        Text("text")
                                    //                                            .foregroundColor(PrayerHighlightType.future.color())
                                    //                                            .font(cellFont)
                                    //                                            .bold()
                                    //                                        Spacer()
                                    //                                    }
                                    //                                    .opacity(max(0, tomorrowPeekProgress * 1.3 - 0.3))
                                    //                                    .rotation3DEffect(
                                    //                                        Angle(degrees: max(0, tomorrowPeekProgress - 0.3) * 100 - 90),
                                    //                                        axis: (x: 1, y: 0, z: 0.0),
                                    //                                        anchor: .bottom,
                                    //                                        anchorZ: 0,
                                    //                                        perspective: 0.1
                                    //                                    )
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0.1, coordinateSpace: .global)
                                        .onEnded({ _ in
                                            if dragState.progress > 0.999 {
                                                dragState.showCalendar = true
                                                Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { t in
                                                    // if still on max after half a second, go back to zero
                                                    // this is necessary because swiftui has a bug where onEnded is
                                                    // not called if a sheet apepars
                                                    if dragState.progress > 0.999 {
                                                        dragState.progress = 0
                                                    }
                                                }
                                            } else {
                                                withAnimation {
                                                    dragState.progress = 0
                                                }
                                            }
                                        })
                                        .updating($dragOffset, body: { (value, state, transaction) in
                                            //                                            state = value.translation
                                            //                                            dragState.showCalendar = false
//                                            if dragState.progress < 0.999 {
                                            dragState.progress = Double(max(0.0, min(1.0, value.translation.height / -140)))
//                                            }
                                        })
                                )
                            }
                            .padding([.leading, .trailing])
                            .padding([.leading, .trailing])
                            
                            ZStack {
                                
                                VStack {
                                    Spacer()
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
                                                
                                                Text("\(manager.locationName)")
                                                    .foregroundColor(Color(.lightText))
                                                    .font(Font.body.weight(.bold))
                                                
                                            }
                                        }
                                        .padding(12)
                                        .offset(x: -14, y: 12)
                                        
                                        Spacer()
                                        
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
                                        .offset(x: 12, y: 12)
                                    }
                                    .padding([.leading, .trailing, .bottom])
                                    .padding([.leading, .trailing, .bottom])
                                }
                                .opacity(1 - 0.8 * dragState.progress)
                                
                                
                                VStack {
                                    ZStack() {
                                        Text("\(todayHijriString)")
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding([.trailing, .leading])
                                            .foregroundColor(Color(.lightText))
                                            .offset(y: 24)
//                                        VStack(alignment: .center) {
//                                            ZStack {
//                                                    .opacity(min(1, 1 - 0.8 * dragState.progress))
//                                                    .rotation3DEffect(
//                                                        Angle(degrees: dragState.progress * 90 - 0.001),
//                                                        axis: (x: 1, y: 0, z: 0.0),
//                                                        anchor: .top,
//                                                        anchorZ: 0,
//                                                        perspective: 0.1
//                                                    )
//                                                    .animation(.linear(duration: 0.05))
                                                
//                                                Text("\(tomorrowHijriString)")
//                                                    .fontWeight(.bold)
//                                                    .lineLimit(1)
//                                                    .fixedSize(horizontal: false, vertical: true)
//                                                    .padding([.trailing, .leading])
//                                                    .foregroundColor(.white)
//                                                    .opacity(max(0, dragState.progress * 1.3 - 0.3))
//                                                    .rotation3DEffect(
//                                                        Angle(degrees: max(0, dragState.progress - 0.3) * 90 - 90),
//                                                        axis: (x: 1, y: 0, z: 0.0),
//                                                        anchor: .bottom,
//                                                        anchorZ: 0,
//                                                        perspective: 0.1
//                                                    )
//                                                    .animation(.linear(duration: 0.05))
                                                
//                                            }
                                            //                                            Text("Tap the Hijri date to view\nan athan times table.")
                                            //                                                .foregroundColor(.white)
                                            //                                                .font(.subheadline)
                                            
//                                        }
                                        
                                        // include percentComplete * 0 to trigger refresh based on Date()
                                        
                                        
                                        
//                                SolarView(
//                                    dayProgress: CGFloat(0 * percentComplete) + CGFloat(0.5 + Date().timeIntervalSince(manager.todayTimes.dhuhr) / 86400),
//                                          sunlightFraction: CGFloat(manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400),
//                                    manualDayProgress: dayProgressState.manualDayProgress,
//                                    isDragging: dayProgressState.isDragging,
//                                    dhuhrTime: manager.todayTimes.dhuhr,
//                                    sunriseTime: manager.todayTimes.sunrise
//                                )
//                                    .equatable()
                                        SolarView(dayProgress: CGFloat(0 * percentComplete) + CGFloat(0.5 + Date().timeIntervalSince(manager.todayTimes.dhuhr) / 86400),
                                                  manualDayProgress: $dayProgressState.manualDayProgress,
                                                  isDragging: $dayProgressState.isDragging,
                                                  sunlightFraction: CGFloat(manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400),
                                                  hidingCircle: true,
                                                  dhuhrTime: manager.todayTimes.dhuhr,
                                                  sunriseTime: manager.todayTimes.sunrise)

                                        
                                            
                                    }
                                    .opacity(1 - 0.8 * dragState.progress)
                                    
                                    // dummy stack used for proper offset
                                    HStack(alignment: .center) {
                                        Text("Spacer")
                                            .font(Font.body.weight(.bold))
                                        Spacer()
                                        Image(systemName: "gear")
                                            .font(Font.body.weight(.bold))
                                    }
                                    .opacity(0)
                                    .padding([.leading, .trailing, .bottom])
                                    .padding([.leading, .trailing, .bottom])
                                }
                            }
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $dragState.showCalendar) { // set highest progress back to 0 when we know the view disappeared
                            CalendarView(showCalendar: $dragState.showCalendar)
                                .equatable()
                        }
                    //                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                    }
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
        ZStack {
            Rectangle()
                .foregroundColor(outlineColor)
                .frame(height: lineWidth)
                .cornerRadius(lineWidth * 0.5)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(colors.first)
                        .frame(width: max(lineWidth, progress * g.size.width), height: lineWidth)
                        .cornerRadius(lineWidth * 0.5)
                }
            }
            .padding(.zero)
            .frame(height: lineWidth)
        }
    }
}

@available(iOS 13.0.0, *)
struct MainSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        MainSwiftUI()
            .environmentObject(ObservableAthanManager.shared)
            .previewDevice("iPhone Xs")
        
    }
}
