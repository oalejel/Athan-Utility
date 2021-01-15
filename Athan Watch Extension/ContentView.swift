//
//  ContentView.swift
//  Athan Watch Extension
//
//  Created by Omar Al-Ejel on 1/6/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan
//import SwiftFX


// note: if user has not set location,
// they should have the opportunity to use their
// current location on their watch and change settings

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



struct ContentView: View {
    let manager = ObservableAthanManager.shared
    @State var progress: Float = 30
    @State var colorSettings = AthanManager.shared.appearanceSettings
    @State var currentPrayer = AthanManager.shared.currentPrayer ?? .isha
    
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
    
    var body: some View {
        // user background gradient is not suitable for text with black background
        
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                //                Text("\(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative) left")
                HStack(alignment: .firstTextBaseline) {
                    Text(currentPrayer.localizedOrCustomString())
                        .font(Font.largeTitle.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                    Spacer()
                    Text("\(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative) left")
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                }
                
                ProgressBar(progress: CGFloat(getPercentComplete()), lineWidth: 8,
                            outlineColor: Color(.sRGB, white: 1, opacity: 0.4),
                            colors: [.white])
                //                ProgressView("", value: getPercentComplete() * 100, total: 100)
                //                    .font(Font.largeTitle.bold())
                //                    .lineLimit(1)
                //                    .minimumScaleFactor(0.1)
                //                    .progressViewStyle(CircularProgressViewStyle(tint: Color.red))
                
            }
            .gradientForeground(colors: watchColorsForPrayer(currentPrayer))
//            .navigationTitle(manager.locationName)
            
            ScrollView {
                
                // show k = 6 - current prayers left over for today
                if currentPrayer != .isha {
                    ForEach(currentPrayer.rawValue()..<6, id: \.self) { pIndex in
                        let prayer = Prayer(index: pIndex)
                        HStack {
                            Text(prayer.localizedOrCustomString())
                            Spacer()
                            Text(manager.todayTimes.time(for: prayer), style: .time)
                        }
                        .foregroundColor(currentPrayer.rawValue() == pIndex ? .green : .white)
                    }
                    HStack {
                        VStack {
                            Divider()
                        }
                        Text("Tomorrow")
                            .fixedSize()
                            .foregroundColor(.gray)
                        VStack {
                            Divider()
                        }
                    }
                }
                
                // show k prayers for tomorrow
                //                ForEach(0..<(currentPrayer.rawValue() + 1), id: \.self) { pIndex in
                // if isha refer's to yesterday's isha, use today times
                if currentPrayer == .isha && Date() < manager.todayTimes.isha {
                    ForEach(0..<6, id: \.self) { pIndex in
                        let prayer = Prayer(index: pIndex)
                        HStack {
                            Text(prayer.localizedOrCustomString())
                            Spacer()
                            Text(manager.todayTimes.time(for: prayer), style: .time)
                        }
                        .foregroundColor(.gray)
                    }
                } else { // case where it is same day that isha began
                    ForEach(0..<6, id: \.self) { pIndex in
                        let prayer = Prayer(index: pIndex)
                        HStack {
                            Text(prayer.localizedOrCustomString())
                            Spacer()
                            Text(manager.tomorrowTimes.time(for: prayer), style: .time)
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Location:")
                        .bold()
                    HStack {
                        Text(manager.locationName)
                        Spacer()
                        if AthanManager.shared.locationSettings.useCurrentLocation {
                            Image(systemName: "location.fill")
                        } else {
                            Image(systemName: "location.slash")
                        }
                    }
                }
            }
        }.padding(.top, -6)
    }
    
    func watchColorsForPrayer(_ p: Prayer) -> [Color] {
        switch p {
        case .fajr:
            return [Color.white, .blue]
        case .isha:
            return [Color.white, .purple, .purple]
        default:
            return [Color.white, .blue]
        }
    }
}

extension View {
    public func gradientForeground(colors: [Color]) -> some View {
        self.overlay(LinearGradient(gradient: .init(colors: colors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
            .mask(self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            ContentView()
                .previewDevice("Apple Watch Series 6 - 40mm")
        }
    }
}
