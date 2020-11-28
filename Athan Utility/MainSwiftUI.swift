//
//  MainSwiftUI.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 9/24/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct MainSwiftUI: View {
    
    @EnvironmentObject var manager: ObservableAthanManager
//    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    
    @State var tomorrowPeekProgress: Double = 0.0
    @State var minuteTimer: Timer? = nil
    
    @State var fajrOverrideString: String = ""
    @State var sunriseOverrideString: String = ""
    @State var dhuhrOverrideString: String = ""
    @State var asrOverrideString: String = ""
    @State var maghribOverrideString: String = ""
    @State var ishaOverrideString: String = ""
    
    @State var settingsToggled = false
    
    var nextRoundMinuteTimer: Timer {
        let comps = Calendar.current.dateComponents([.second], from: Date())
        let secondsTilNextMinute = comps.second!
        return Timer.scheduledTimer(withTimeInterval: TimeInterval(secondsTilNextMinute),
                              repeats: false) { _ in
            percentComplete = getPercentComplete()
            minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
                percentComplete = getPercentComplete()
            })
         }
    }

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
    
    func hijriDateString(date: Date) -> String {
        let hijriCal = Calendar(identifier: .islamic)
        let df = DateFormatter()
        df.calendar = hijriCal
        df.dateStyle = .medium
        return df.string(from: date)
    }

    var body: some View {
        ZStack {
            GeometryReader { g in
                
                let timeRemainingString: String = {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: Date(),
                                                            to: AthanManager.shared.guaranteedNextPrayerTime())
                    if comps.hour == 0 {
                        return "\(comps.minute!)m left"
                    } else if comps.minute == 0 {
                        return "\(comps.hour!)h left"
                    }
                    return "\(comps.hour!)h \(comps.minute!)m left"
                }()
                
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                    .edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 0) {
                            Spacer()
                            MoonView(percentage: 0.3)
                                .frame(width: g.size.width / 3, height: g.size.width / 3, alignment: .center)
                                .offset(y: 12)
                            Spacer()
                        }
                        .opacity(1 - 0.8 * tomorrowPeekProgress)
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading) {
                                
                                PrayerSymbol(prayerType: manager.currentPrayer)
                                    .foregroundColor(.white)
                                    .font(Font.system(.title).weight(.medium))
                                Text(manager.currentPrayer.localizedString())
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .opacity(1 - 0.8 * tomorrowPeekProgress)

                            Spacer() // space title | qibla
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                QiblaPointerView(angle: self.manager.qiblaHeading - self.manager.currentHeading,
                                                 qiblaAngle: self.manager.qiblaHeading)
                                    .frame(width: g.size.width * 0.2, height: g.size.width * 0.2, alignment: .center)
                                    .offset(x: g.size.width * 0.03, y: 0) // offset to let pointer go out

                                Text("\(timeRemainingString)")
                                    .fontWeight(.bold)
                                    .autocapitalization(.none)
                                    .foregroundColor(Color(.lightText))
                                    .multilineTextAlignment(.center)
                                    .opacity(1 - 0.8 * tomorrowPeekProgress)
                            }
                        }
                        
                        ProgressBar(progress: CGFloat(percentComplete), lineWidth: 10,
                                    outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])
                            .onAppear(perform: { // wake update timers that will update progress
                                let _ = nextRoundMinuteTimer
                                let _ = minuteTimer
                                percentComplete = getPercentComplete()
                            })
                            .opacity(1 - 0.8 * tomorrowPeekProgress)

                        let cellFont = Font.system(size: g.size.width * 0.06)
                        let timeFormatter: DateFormatter = {
                            let df = DateFormatter()
                            df.timeStyle = .short
                            return df
                        }()
                        
                        ZStack {
                            Rectangle()
                                .foregroundColor(.clear) // to allow gestures from middle of box
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(0..<6) { pIndex in
                                    let p = Prayer(index: pIndex)
                                    let highlight: PrayerRowContent.Highlight = {
                                        var h = PrayerRowContent.Highlight.present
                                        if p == manager.todayTimes.currentPrayer() {
                                            h = .present
                                        } else if manager.todayTimes.currentPrayer() == nil {
                                            h = .future
                                        } else {
                                            h = p.rawValue() < manager.currentPrayer.rawValue() ? .past : .future
                                        }
                                        return h
                                    }()

                                    ZStack { // stack of today and tomorrow times
                                        HStack {
                                            Text(p.localizedString())
//                                            TextField(p.localizedString(), text: [$fajrOverrideString, $sunriseOverrideString, $dhuhrOverrideString, $asrOverrideString, $maghribOverrideString, $ishaOverrideString][pIndex], onEditingChanged: { _ in
//
//                                            }, onCommit: {
//                                                print("committed overwrite prayer name")
//                                            })
//                                                .disableAutocorrection(true)
                                                .foregroundColor(highlight.color())
                                                .font(cellFont)
                                                .bold()
    //                                            .rotation3DEffect(.degrees(tomorrowPeekProgress * 90), axis: (x: 1, y: 0, z: 0))

                                            Spacer()
                                            Text(timeFormatter.string(from: manager.todayTimes.time(for: p)))
                                                // replace 3 with current prayer index
                                                .foregroundColor(highlight.color())
                                                .font(cellFont)
                                                .bold()
    //                                            .rotation3DEffect(.degrees(tomorrowPeekProgress * 90), axis: (x: 1, y: 0, z: 0))
                                        }
    //                                    .border(Color.green)
                                        .opacity(min(1, 1 - 0.8 * tomorrowPeekProgress))
                                        .rotation3DEffect(
                                                    Angle(degrees: min(tomorrowPeekProgress * 100, 90)),
                                                    axis: (x: 1, y: 0, z: 0.0),
                                                    anchor: .top,
                                                    anchorZ: 0,
                                            perspective: 0.1
                                                )
                                        .animation(.linear(duration: 0.2))
                                        
                                        
                                        HStack {
                                            Text(p.localizedString())
                                                .foregroundColor(PrayerRowContent.Highlight.future.color())
                                                .font(cellFont)
                                                .bold()
    //                                            .rotation3DEffect(.degrees(tomorrowPeekProgress * 90 - 90), axis: (x: 1, y: 0, z: 0))
                                            Spacer()
                                            Text(timeFormatter.string(from: manager.tomorrowTimes.time(for: p)))
                                                // replace 3 with current prayer index
                                                .foregroundColor(PrayerRowContent.Highlight.future.color())
                                                .font(cellFont)
                                                .bold()
    //                                            .rotation3DEffect(.degrees(tomorrowPeekProgress * 90 - 90), axis: (x: 1, y: 0, z: 0))
                                        }
    //                                    .border(Color.red)
                                        .opacity(max(0, tomorrowPeekProgress * 1.3 - 0.3))
                                        .rotation3DEffect(
                                            Angle(degrees: max(0, tomorrowPeekProgress - 0.3) * 100 - 90),
                                                    axis: (x: 1, y: 0, z: 0.0),
                                                    anchor: .bottom,
                                                    anchorZ: 0,
                                            perspective: 0.1
                                                )
                                        .animation(.linear(duration: 0.2))
                                    }
                                    
                                }
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                                .onChanged({ value in
                                    // percent of drag in progress
                                    tomorrowPeekProgress = Double(max(0.0, min(1.0, value.translation.height / -80)))
                                })
                                .onEnded({ _ in
                                    withAnimation {
                                        tomorrowPeekProgress = 0
                                    }
                                })
                                
                        )
                        
                        
//                        let todayContent: [PrayerRowContent] = Prayer.allCases.map {
//                            var highlight = PrayerRowContent.Highlight.present
//                            if $0 == manager.todayTimes.currentPrayer() {
//                                highlight = .present
//                            } else if manager.todayTimes.currentPrayer() == nil {
//                                highlight = .future
//                            } else {
//                                highlight = $0.rawValue() < manager.currentPrayer.rawValue() ? .past : .future
//                            }
//                            return PrayerRowContent(date: manager.todayTimes.time(for: $0),
//                                                    prayer: $0,
//                                                    highlight: highlight)
//                        }
//                        let tomorrowContent: [PrayerRowContent] = Prayer.allCases.map {
//                            PrayerRowContent(date: manager.tomorrowTimes.time(for: $0),
//                                             prayer: $0,
//                                             highlight: .future)
//
//                        }


                        
                        
                    }
                    .padding([.leading, .trailing])
                    .padding([.leading, .trailing])
                    
                    ZStack() {
                        ZStack {
                            Text("\(hijriDateString(date: Date()))")
                                .fontWeight(.bold)
                                .foregroundColor(Color(.lightText))
                                .opacity(min(1, 1 - 0.8 * tomorrowPeekProgress))
                                .rotation3DEffect(
                                            Angle(degrees: min(tomorrowPeekProgress * 100, 90)),
                                            axis: (x: 1, y: 0, z: 0.0),
                                            anchor: .top,
                                            anchorZ: 0,
                                    perspective: 0.1
                                        )
                                .animation(.linear(duration: 0.2))
                            
                            Text("\(hijriDateString(date: Date().addingTimeInterval(86400)))")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(max(0, tomorrowPeekProgress * 1.3 - 0.3))
                                .rotation3DEffect(
                                    Angle(degrees: max(0, tomorrowPeekProgress - 0.3) * 100 - 90),
                                            axis: (x: 1, y: 0, z: 0.0),
                                            anchor: .bottom,
                                            anchorZ: 0,
                                    perspective: 0.1
                                        )
                                .animation(.linear(duration: 0.2))
                        }
                        .offset(y: 24)
                        SolarView(progress: CGFloat(0.5 + Date().timeIntervalSince(manager.todayTimes.dhuhr) / 86400),
                                  sunlightFraction: CGFloat(manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400))
                            .opacity(1 - 0.8 * tomorrowPeekProgress)
                    }
                    
                    Spacer() // space footer
                    
                    
                    HStack(alignment: .center) {
                        Button(action: {
                            // tap vibration
                            let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            lightImpactFeedbackGenerator.impactOccurred()
                            AthanManager.shared.requestLocationPermission()
                        }) {
                            Text("\(manager.locationName)")
                        }
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))

                        Spacer()
                        
                        Button(action: {
                            // tap vibration
                            let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            lightImpactFeedbackGenerator.impactOccurred()
                            
                            settingsToggled.toggle()
                        }) {
                            settingsToggled ? Image(systemName: "xmark") : Image(systemName: "gear")
                            
                        }
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))
                    }
                    .padding([.leading, .trailing, .bottom])
                    .padding([.leading, .trailing, .bottom])
                    
//                    Spacer()
//                    Spacer()
                    
                }
//                .padding()
//                .padding()
                
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
                        .frame(width: progress * g.size.width, height: lineWidth)
                        .cornerRadius(lineWidth * 0.5)
                        .mask(
                            Rectangle()
                                .frame(width: g.size.width, height: lineWidth)
                                .cornerRadius(lineWidth * 0.5)
                        )
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
