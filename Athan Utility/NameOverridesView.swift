//
//  NameOverridesView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct NameOverridesView: View {
    #warning("make sure updating this value changes earlier settings?")
    @Binding var tempPrayerSettings: PrayerSettings
    @Binding var activeSection: SettingsSectionType
    
    @State var fajrOverride: String = ""
    @State var sunriseOverride: String = ""
    @State var dhuhrOverride: String = ""
    @State var asrOverride: String = ""
    @State var maghribOverride: String = ""
    @State var ishaOverride: String = ""
    
    let x: Int = {
        UITextField.appearance().clearButtonMode = .always
        UITextField.appearance().tintColor = .white
        AthanManager.shared.requestLocationPermission()
        return 0
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.customPrayerNames)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .onAppear {
                    // initial setup on first appearance
                    fajrOverride = tempPrayerSettings.customNames[.fajr] ?? ""
                    sunriseOverride = tempPrayerSettings.customNames[.sunrise] ?? ""
                    dhuhrOverride = tempPrayerSettings.customNames[.dhuhr] ?? ""
                    asrOverride = tempPrayerSettings.customNames[.asr] ?? ""
                    maghribOverride = tempPrayerSettings.customNames[.maghrib] ?? ""
                    ishaOverride = tempPrayerSettings.customNames[.isha] ?? ""
                }
                .padding([.leading, .trailing, .top])
                .padding([.leading, .trailing, .top])
            
            GeometryReader { g in
                ScrollView {
                    VStack(alignment: .leading) {
                        let bindings = [$fajrOverride, $sunriseOverride, $dhuhrOverride, $asrOverride, $maghribOverride, $ishaOverride]
                        
                        ForEach(Prayer.allCases, id: \.self) { p in
                            //                            GeometryReader { g2 in
                            HStack(alignment: .center) {
                                
                                VStack {
                                    Spacer()
                                    PrayerSymbol(prayerType: p)
                                        .foregroundColor(.white)
                                        .frame(width: 26)
                                    Spacer()
                                }
                                
                                
                                // DO NOT USE CUSTOM STRING IN THIS LABEL
                                Text(p.localizedString())
                                    .bold()
                                    .foregroundColor(.white)
                                    .font(Font.system(size: 22))
                                    .fixedSize(horizontal: true, vertical: true)
                                
                                
                                Spacer()
                                
                                TextField(" \(p.localizedString())", text: bindings[p.rawValue()])
                                    .font(Font.body.italic())
                                    .padding([.leading])
                                    .frame(width: g.size.width / 2)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        Text(Strings.customNamesDescription)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .font(.caption)
                            .foregroundColor(Color(.lightText))
                            .padding(.top)
                    }
                    .padding(.top, 12)
                    .padding([.leading, .trailing])
                    .padding([.leading, .trailing])
                }
            }
            .padding(.top)
            
            Spacer()
            
            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    // tap vibration
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    tempPrayerSettings.customNames[.fajr] = fajrOverride
                    tempPrayerSettings.customNames[.sunrise] = sunriseOverride
                    tempPrayerSettings.customNames[.dhuhr] = dhuhrOverride
                    tempPrayerSettings.customNames[.asr] = asrOverride
                    tempPrayerSettings.customNames[.maghrib] = maghribOverride
                    tempPrayerSettings.customNames[.isha] = ishaOverride
                    withAnimation {
                        self.activeSection = .General
                    }
                }) {
                    Text(Strings.done)
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))
                }
            }
            .padding()
            .padding([.leading, .trailing, .bottom])
        }
    }
}

@available(iOS 13.0.0, *)
struct OverridesSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            NameOverridesView(tempPrayerSettings: .constant(PrayerSettings(method: .dubai, madhab: .shafi, customNames: [:])), activeSection: .constant(.Prayer(.fajr)))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
