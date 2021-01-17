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
    @ObservedObject var manager = ObservableAthanManager.shared
    @State var progress: Float = 30
    
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
            VStack(alignment: .leading, spacing: 3) {
                //                Text("\(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative) left")
                //                VStack {//(alignment: .firstTextBaseline) {
                ////                        .minimumScaleFactor(0.1)
                ////                    Spacer()
                //
                //                }
                if manager.currentPrayer.localizedOrCustomString().count > 5 {
                    Text(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative)
                    Text(manager.currentPrayer.localizedOrCustomString())
                        .font(Font.largeTitle.bold())
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        //                    .border(Color.red)
                        .padding([.top], -8)
                } else {
                    HStack(alignment: .lastTextBaseline) {
                        Text(manager.currentPrayer.localizedOrCustomString())
                            .font(Font.largeTitle.bold())
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: true)
                            //                    .border(Color.red)
                            .padding([.top], -8)
                        Spacer()
                        Text(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative)
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                    }
                }
                
                ProgressBar(progress: CGFloat(getPercentComplete()), lineWidth: 8,
                            outlineColor: Color(.sRGB, white: 1, opacity: 0.4),
                            colors: [.white])
            }
            .gradientForeground(colors: watchColorsForPrayer(manager.currentPrayer))
            //            .navigationTitle(manager.locationName)
            
            ScrollView {
                // show k = 6 - current prayers left over for today
                if manager.currentPrayer != .isha {
                    ForEach(manager.currentPrayer.rawValue()..<6, id: \.self) { pIndex in
                        let prayer = Prayer(index: pIndex)
                        HStack {
                            Text(prayer.localizedOrCustomString())
                            Spacer()
                            Text(manager.todayTimes.time(for: prayer), style: .time)
                        }
                        .foregroundColor(manager.currentPrayer.rawValue() == pIndex ? .green : .white)
                    }
                }
                
                // show k prayers for tomorrow
                //                ForEach(0..<(currentPrayer.rawValue() + 1), id: \.self) { pIndex in
                // if isha refer's to yesterday's isha, use today times
                if manager.currentPrayer == .isha && Date() < manager.todayTimes.isha {
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
                    Text(Strings.locationColon)
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
                Spacer()
            }
        }
    }
    
    
}

extension View {
    public func gradientForeground(colors: [Color], startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        self.overlay(LinearGradient(gradient: .init(colors: colors),
                                    startPoint: startPoint,
                                    endPoint: endPoint))
            .mask(self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("Apple Watch Series 6 - 40mm")
            ContentView()
                .previewDevice("Apple Watch Series 6 - 40mm")
        }
    }
}

func watchColorsForPrayer(_ p: Prayer) -> [Color] {
    switch p {
    case .fajr:
        return [.init(red: 208/255, green: 226/255 , blue: 1), .init(red: 0/255, green: 83/255 , blue: 233/255)]
    case .sunrise:
        return [.init(red: 229/255, green: 255/255, blue: 229/255), .init(red: 0/255, green: 136/255 , blue: 211/255)]
    case .dhuhr:
        return [.init(red: 216/255, green: 254/255, blue: 1), .init(red: 24/255, green: 109/255 , blue: 203/255)]
    case .asr:
        return [.init(red: 205/255, green: 238/255, blue: 255/255), .init(red: 0/255, green: 143/255 , blue: 205/255)]
    case .maghrib:
        return [.init(red: 254/255, green: 240/255, blue: 240/255), .init(red: 255/255, green: 97/255 , blue: 55/255)]
    case .isha:
        return [.init(red: 246/255, green: 237/255, blue: 255/255), .init(red: 77/255, green: 70/255 , blue: 255/255)]
    //            return [Color.white, .purple, .purple]
    }
}
