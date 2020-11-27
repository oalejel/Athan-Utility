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
struct PrayerSymbol: View {
    var prayerType: Prayer
    var body: some View {
        switch prayerType {
        case .fajr:
            Image(systemName: "light.max")
        case .sunrise:
            Image(systemName: "sunrise")
        case .dhuhr:
            Image(systemName: "sun.min")
        case .asr:
            Image(systemName: "sun.max")
        case .maghrib:
            Image(systemName: "sunset")
        case .isha:
            Image(systemName: "moon.stars")
        }
    }
}


@available(iOS 13.0.0, *)
struct MainSwiftUI: View {
    
    @EnvironmentObject var manager: ObservableAthanManager
    
    var body: some View {
        ZStack {
            GeometryReader { g in
                
                let hijriCal = Calendar(identifier: .islamic)
                let dateString: String = {
                    let df = DateFormatter()
                    df.calendar = hijriCal
                    df.dateStyle = .medium
                    return df.string(from: Date())
                }()
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
                let percentComplete: Double = {
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

                            Spacer() // space title | qibla
                            
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                QiblaPointerView(angle: self.manager.qiblaHeading - self.manager.currentHeading,
                                                 qiblaAngle: self.manager.qiblaHeading)
                                    .frame(width: g.size.width * 0.2, height: g.size.width * 0.2, alignment: .center)
                                    .offset(x: g.size.width * 0.03, y: 0) // offset to let pointer go out

                                HStack {
                                    Text("\(timeRemainingString)")
                                        .fontWeight(.bold)
                                        .autocapitalization(.none)
                                        .foregroundColor(Color(.lightText))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        
                        ProgressBar(progress: CGFloat(percentComplete), lineWidth: 10,
                                    outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])

                        let cellFont = Font.system(size: g.size.width * 0.06)
                        let timeFormatter: DateFormatter = {
                            let df = DateFormatter()
                            df.timeStyle = .short
                            return df
                        }()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(0..<6) { i in
                                HStack {
                                    let cellPrayer = Prayer(index: i)
                                    let highlightColor: Color = {
                                        if cellPrayer == manager.todayTimes.currentPrayer() {
                                            return Color.green
                                        } else if manager.todayTimes.currentPrayer() == nil {
                                            return Color.white
                                        }
                                        return i < manager.currentPrayer.rawValue() ? Color(UIColor.lightText) : Color.white
                                    }()
                                    
                                    Text(cellPrayer.localizedString())
                                        .foregroundColor(highlightColor)
                                        .font(cellFont)
                                        .bold()
                                    Spacer()
                                    Text(timeFormatter.string(from: manager.todayTimes.time(for: cellPrayer)))
                                        // replace 3 with current prayer index
                                        .foregroundColor(highlightColor)
                                        .foregroundColor(.white)
                                        .font(cellFont)
                                        .bold()
                                }
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding([.leading, .trailing])
                    
                    ZStack() {
                        SolarView(progress: 0.5 + Date().timeIntervalSince(manager.todayTimes.dhuhr) / 86400,
                                  sunlightFraction: manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400)
                        Text("\(dateString)")
                            .fontWeight(.bold)
                            .foregroundColor(Color(.lightText))
                            .offset(y: 24)

                    }
                    
//                        .frame(width: g.size.width, height: g.size.height * 0.2, alignment: .center)

                    Spacer() // space footer
                    
                    
                    HStack(alignment: .center) {
                        Button(action: {
                            AthanManager.shared.requestLocationPermission()
                        }) {
                            Text("\(manager.locationName)")
                        }
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))

                        Spacer()
                        
                        Button(action: {
                            print("here")
                        }) {
                            Image(systemName: "gear")
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
