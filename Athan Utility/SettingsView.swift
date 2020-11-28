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


@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
//    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
        
    var tempLocationSettings: LocationSettings = LocationSettings.shared.copy() as! LocationSettings
    var tempNotificationSettings = NotificationSettings.shared.copy() as! NotificationSettings
    var tempPrayerSettings = PrayerSettings.shared.copy() as! PrayerSettings
    
    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
    
    @State var fajrOverride: String = ""
    @State var sunriseOverride: String = ""
    @State var dhuhrOverride: String = ""
    @State var asrOverride: String = ""
    @State var maghribOverride: String = ""
    @State var ishaOverride: String = ""
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    
    @State var dummy = false
    
        
    var x: Int = {
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        UITableView.appearance().backgroundColor = .clear
        
        return 0
    }()

    var body: some View {
        
//        NavigationView {
//            Form {
//                Section(footer: Text("Note: Enabling logging may slow down the app")) {
//                    Picker(selection: $selectedMadhab, label: Text("Select a color")) {
//                        ForEach(0..<2) { i in
//                            Text("test").tag(madhabs[i])
//                        }
//                    }.pickerStyle(SegmentedPickerStyle())
//
//                }
//
//                Section {
//                    Button(action: {
//                    // activate theme!
//                    }) {
//                        Text("Save changes")
//                    }
//                }
//            }
//            .foregroundColor(Color.blue)
//            .background(
//                LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
//                                .edgesIgnoringSafeArea(.all)
//            )
////            .navigationBarTitle("Settings")
////            .foregroundColor(Color.red)
//
//
//
//        }
        

        
        ZStack {
            GeometryReader { g in
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                    .edgesIgnoringSafeArea(.all)
                
                
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: nil) {
                                                
                        Text("Settings")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.bottom)
                            
                        VStack(alignment: .leading) {
                            Text("Calculation method")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
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
                            
                            Text("Madhab")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
                            
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
                            .frame(width: g.size.width * 0.8)
                            
                            Text("Fajr Settings")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.top)
                            
                            
                                
                            Divider()
                                .background(Color.white)
                            ZStack {
//                                Rectangle()
//                                    .foregroundColor(.init(.sRGB, white: 1, opacity: 0.1))
//                                    .cornerRadius(8)
                                VStack {
                                    Toggle(isOn: .constant(true), label: {
                                        Text("New prayer alarm")
                                    })
                                        .font(Font.headline)
                                        .foregroundColor(.white)
                                        .padding([.top, .leading, .trailing], 12)
                                    
                                    Toggle(isOn: .constant(true), label: {
                                            Text("15 minute alarm")
                                    })
                                        .font(Font.headline)
                                        .foregroundColor(.white)
                                        .padding([.top, .leading, .trailing], 12)

//                                    [$fajrOverrideString, $sunriseOverrideString, $dhuhrOverrideString, $asrOverrideString, $maghribOverrideString, $ishaOverrideString][pIndex]
                                    HStack {
                                        Text("Custom name")
                                            .font(Font.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        TextField("Fajr", text: $fajrOverride)
                                            .disableAutocorrection(true)
                                            .foregroundColor(Color.red)
                                            
//                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        

//                                        TextField("Fajr", text: $fajrOverride) { (change) in
//
//                                        } onCommit: {
//
//                                        }
                                    }
                                        .padding([.top, .leading, .trailing], 12)
                                    

                                }
                            }
                        }

                    }
                    .padding()
                    .padding()

                }
                .frame(width: g.size.width)
            }
        }
        
    }
}

@available(iOS 13.0.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ObservableAthanManager.shared)
            .previewDevice("iPhone Xs")
            
    }
}
