//
//  PrayerSettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/2/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

/*
 Custom offset: 0 minutes
 Custom name: (Fajr)
 15 minute reminder [switch]
 normal reminder [switch]
 Play athan sound [switch] (if no, play no sound?)
 
 would be nice if users could run app 
 */

@available(iOS 13.0.0, *)
struct PrayerSettingsView: View {
    @Binding var setting: AlarmSetting
    var prayer: Prayer = .fajr
    // state to keep strings in view updated
    // commit this value to storage later if changed
    
    @State var customPrayerName: String = ""
    
    @Binding var activeSection: SettingsSectionType
    
    #warning("uncomment this once we're done with the sufti ui canvas debugger")
//    var step: Int = {
//        UIStepper.appearance().tintColor = .white
//       return 0
//    }()
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(customPrayerName == "" ? prayer.localizedString() : customPrayerName) settings")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding([.leading])
            
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: nil) {
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Athan Alarm")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
                            
                            VStack {
                                Toggle(isOn: .constant(setting.reminderAlarmEnabled), label: {
                                    Text("Enable Alerts")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        
                                    
                                })
                                .padding(.top, 12)
                                
                                Toggle(isOn: .constant(setting.reminderAlarmEnabled), label: {
                                    Text("Play Sound")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                })
                                
//                                ZStack {
//                                    Stepper(
//                                        onIncrement: { },
//                                        onDecrement: {  },
//                                        label: {
//                                            Text("Minute Offset")
//                                                .font(.headline)
//                                                .bold()
//                                                .foregroundColor(.white)
//        //                                        .padding([.bottom])
//                                        })
//                                        .accentColor(.white)
//
//
//                                    Text("1")
//                                        .foregroundColor(Color(.lightText))
//                                }
//                                .padding(.bottom, 12)
                                                                
                            }
                            .padding([.leading, .trailing])
                            .background(
                                Rectangle()
                                    .foregroundColor(Color.init(.sRGB, white: 1, opacity: 0.1))
                                    .cornerRadius(12)
                            )
                            .padding(.bottom)
                            
                            //                                Text("Increasing minute adjustments sets back athan times for cus")
                            //                                    .font(.subheadline)
                            
                            Text("Reminder Alarm")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
                            VStack {
                                Toggle(isOn: .constant(setting.reminderAlarmEnabled), label: {
                                    Text("Enable Alerts")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        
                                    
                                })
                                .padding(.top, 12)
                                                                
                                
                                ZStack {
                                    Stepper(
                                        onIncrement: { },
                                        onDecrement: {  },
                                        label: {
                                            Text("Minute offset")
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
        //                                        .padding([.bottom])
                                        })
                                        .accentColor(.white)

                                    
                                    Text("15")
                                        .foregroundColor(Color(.lightText))
                                }
                                .padding(.bottom, 12)

                            }
                            .padding([.leading, .trailing])
                            .background(
                                Rectangle()
                                    .foregroundColor(Color.init(.sRGB, white: 1, opacity: 0.1))
                                    .cornerRadius(12)
                            )
                            .padding(.bottom, 12)

                            
                        }
                    }
                }
            }
            .padding()
            
            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    // tap vibration
                    let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                    lightImpactFeedbackGenerator.impactOccurred()
                    withAnimation {
                        self.activeSection = .General
                    }
                }) {
                    Text("Done")
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
struct PrayerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            PrayerSettingsView(setting: .constant(AlarmSetting()), activeSection: .constant(.Prayer))
            
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone 12 mini")
    }
}
