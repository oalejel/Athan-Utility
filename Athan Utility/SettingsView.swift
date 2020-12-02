//
//  SettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

/*
 Necessary features of setings:
 edit names of prayers
 custom offsets
 madhab (hanafi)
 calculation method
 arabic mode

 15 minute reminder?
 normal reminder?
 alarm sound for every prayer?

 siri shortcut
 
 ==========
 
 Calculation Method []
 -----
 Madhab []
 ---
 Alarm sound
 
 # Prayer Settings
 -------
 foreach prayer {
 Fajr
 ------
 Custom offset: 0 minutes
 Custom name: (Fajr)
 15 minute reminder [switch]
 normal reminder [switch]
 }
 */

enum SettingsSectionType {
    case General, Sounds, Prayer
}

@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
//    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
        
    var tempLocationSettings: LocationSettings = LocationSettings.shared.copy() as! LocationSettings
    @State var tempNotificationSettings = NotificationSettings.shared.copy() as! NotificationSettings
    var tempPrayerSettings = PrayerSettings.shared.copy() as! PrayerSettings
    
    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
    
    @State var fajrOverride: String = ""
    @State var sunriseOverride: String = ""
    @State var dhuhrOverride: String = ""
    @State var asrOverride: String = ""
    @State var maghribOverride: String = ""
    @State var ishaOverride: String = ""
    
    @State var activeSection = SettingsSectionType.General
    @State var dismissSounds = false
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    
    var x: Int = {
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        UITableView.appearance().backgroundColor = .clear
        
        return 0
    }()

    var body: some View {
        GeometryReader { g in
            switch activeSection {
            case .Sounds:
                SoundSettingView(tempNotificationSettings: $tempNotificationSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            case .Prayer:
                PrayerSettingsView()
                    .transition(.move(edge: .trailing))
            case .General:
                VStack(spacing: 0) {
                    Divider()
                        .foregroundColor(Color(.lightText))
                        .onAppear {
                            print(tempNotificationSettings.selectedSoundIndex)
                        }

                    ScrollView(showsIndicators: true) {
                        VStack(alignment: .leading, spacing: nil) {
                                                    
                            Text("Settings")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.bottom)
                                
                            VStack(alignment: .leading) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Calculation method")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)

                                    Divider()
                                        .background(Color.white)
                                }
                                
                                Picker(selection: $selectedMethod, label: Text("Picker"), content: {
                                    ForEach(0..<calculationMethods.count) { mIndex in
                                        let method = calculationMethods[mIndex]
                                        Text(method.stringValue())
                                            .foregroundColor(.white)
                                            .tag(method)
                                    }
                                })
                                .pickerStyle(WheelPickerStyle())
                                .labelsHidden()
                                .foregroundColor(.white)
                                .frame(width: g.size.width * 0.8)
                                .padding([.leading, .trailing])
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Madhab")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                    Divider()
                                        .background(Color.white)
                                }
                                
                                Picker(selection: $selectedMadhab, label: Text("Picker"), content: {
                                    ForEach(0..<madhabs.count) { mIndex in
                                        let madhab = madhabs[mIndex]
                                        Text(madhab.stringValue())
                                            .foregroundColor(.white)
                                            .autocapitalization(UITextAutocapitalizationType.words)
                                            .tag(madhab)
                                    }
                                })
                                .pickerStyle(SegmentedPickerStyle())
                                .labelsHidden()
                                .foregroundColor(.white)
                                
                                Text("The Hanafi madhab uses later Asr times, taking place when the length of a shadow increases in length by double the length of an object since solar noon.")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .font(.caption)
                                    .foregroundColor(Color(.lightText))
                                
                                
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Athan sounds")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                    Divider()
                                        .background(Color.white)
                                }
                                .padding(.top)
                                
                                ZStack {
                                    Button(action: {
                                        print("show athan sounds view")
                                        withAnimation {
                                            activeSection = .Sounds
                                        }
                                    }, label: {
                                        HStack {
                                            Text(NotificationSettings.noteSoundNames[tempNotificationSettings.selectedSoundIndex])
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding()
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white)
                                                .font(Font.headline.weight(.bold))
                                                .padding()
                                        }
                                    })
                                    .buttonStyle(GradientButtonStyle())
                                }

                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notifications and customizations")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding(.top)
                                    Divider()
                                        .background(Color.white)
                                }

                                ForEach(0..<6) { pIndex in
                                    ZStack {
                                        Button(action: {
                                            
                                        }, label: {
                                            HStack {
                                                Text("\(Prayer(index: pIndex).stringValue())")
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .padding()
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                                    .font(Font.headline.weight(.bold))
                                                    .padding()
                                            }
                                        })
                                        .buttonStyle(GradientButtonStyle())
                                    }
                                }
                                
                                
                                
                                

                                
                            }
                        }
                        .padding()
                        .padding()

                    }
                    
                    Divider()
                        .background(Color(.lightText))
    //                    Rectangle()
    //                        .frame(width: g.size.width, height: 1)
    //                        .foregroundColor(Color(.lightText))
                    
                    
                    
                    
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: {
                            // tap vibration
                            let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            lightImpactFeedbackGenerator.impactOccurred()
                        }) {
                            Text("Done")
                                .foregroundColor(Color(.lightText))
                                .font(Font.body.weight(.bold))
                        }
                    }
                    .padding()
                    .padding([.leading, .trailing, .bottom])
//                    .padding([.leading, .trailing, .bottom])

                }
                .transition(.opacity)
                .frame(width: g.size.width)
                .padding(.top)

            }
        }
    
        
    }
}

@available(iOS 13.0.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            SettingsView()
            
        }
            .environmentObject(ObservableAthanManager.shared)
            .previewDevice("iPhone Xs")
            
    }
}
