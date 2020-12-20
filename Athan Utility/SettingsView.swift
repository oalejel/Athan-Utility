//
//  SettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan
import StoreKit

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
        
    @State var tempLocationSettings: LocationSettings = LocationSettings.shared.copy() as! LocationSettings
    @State var tempNotificationSettings = NotificationSettings.shared.copy() as! NotificationSettings
    @State var tempPrayerSettings = PrayerSettings.shared.copy() as! PrayerSettings
    
//    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
//    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
    
    @State var fajrOverride: String = ""
    @State var sunriseOverride: String = ""
    @State var dhuhrOverride: String = ""
    @State var asrOverride: String = ""
    @State var maghribOverride: String = ""
    @State var ishaOverride: String = ""
    
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @State var activeSection = SettingsSectionType.General
    @State var dismissSounds = false
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    
    var x: Int = {
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        UITableView.appearance().backgroundColor = .clear
//        UITableView.appearance().tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Double.leastNonzeroMagnitude))
//        UITableView.appearance().tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Double.leastNonzeroMagnitude))
        
        return 0
    }()

    var body: some View {
        GeometryReader { g in
            switch activeSection {
            case .Sounds:
                SoundSettingView(tempNotificationSettings: $tempNotificationSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            case .Prayer:
                #warning("change binding")
                PrayerSettingsView(setting: .constant(AlarmSetting()))
                    .transition(.move(edge: .trailing))
            case .General:
                VStack(spacing: 0) {
                    Divider()
                        .foregroundColor(Color(.lightText))
                        .onAppear {
                            print(tempNotificationSettings.selectedSound)
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
                                
                                Picker(selection: $tempPrayerSettings.calculationMethod, label: Text("Picker"), content: {
                                    ForEach(0..<calculationMethods.count) { mIndex in
                                        let method = calculationMethods[mIndex]
                                        Text(method.stringValue())
                                            .foregroundColor(.white)
                                            .tag(method)
                                            .listRowInsets(EdgeInsets())
                                    }
                                })
                                
                                .pickerStyle(WheelPickerStyle())
                                .labelsHidden()
                                .scaledToFit()
                                .foregroundColor(.white)
//                                .frame(width: g.size.width * 0.8)
//                                .padding([.leading, .trailing])
                                
                                Text("Calculation methods primarily differ in Fajr and Isha sun angles.")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .font(.caption)
                                    .foregroundColor(Color(.lightText))
                                    .padding(.bottom)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Madhab")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                    Divider()
                                        .background(Color.white)
                                }
                                
                                Picker(selection: $tempPrayerSettings.madhab, label: Text("Picker"), content: {
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
                                    .padding(.bottom)
                                
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Athan sound")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                    Divider()
                                        .background(Color.white)
                                }
                                
                                ZStack {
                                    Button(action: {
                                        print("show athan sounds view")
                                        withAnimation {
                                            activeSection = .Sounds
                                        }
                                    }, label: {
                                        HStack {
                                            Text(tempNotificationSettings.selectedSound.localizedString())
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
                                
//                                Button(action: {
//
//                                }, label: {
//                                    HStack() {
//                                        Spacer()
//                                        Text("Rate Athan Utility!")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//                                            .padding()
//                                        Spacer()
//                                    }
//                                })
//                                .buttonStyle(GradientButtonStyle())
                                

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
                            withAnimation {
                                parentSession = .Main // tell parent to go back
                            }
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
            SettingsView(parentSession: .constant(.Settings))
            
        }
            .environmentObject(ObservableAthanManager.shared)
            .previewDevice("iPhone Xs")
    }
}
