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
    
    @Binding var noteSettings: NotificationSettings
    @State var prayer: Prayer = .fajr
    @Binding var activeSection: SettingsSectionType
    
    // adjust setting object on disappear
    @State var athanAlertEnabled = false
    @State var athanSoundEnabled = false
    @State var reminderAlertEnabled = false
    @State var reminderOffset = 15
    
    var body: some View {
        // intermediate bindings taht depend on each other
        let athanOn = Binding<Bool>(get: { athanAlertEnabled }, set: {
            athanAlertEnabled = $0
            if !athanAlertEnabled { // power to switch off reminder
                reminderAlertEnabled = false
                athanSoundEnabled = false
            }
        })
        let soundOn = Binding<Bool>(get: { athanSoundEnabled }, set: {
            athanSoundEnabled = $0
            if athanSoundEnabled { // power to switch on regular
                athanAlertEnabled = true
            }
        })
        let reminderOn = Binding<Bool>(get: { reminderAlertEnabled }, set: {
            reminderAlertEnabled = $0
            if reminderAlertEnabled { // power to switch on regular
                athanAlertEnabled = true
            }
        })
        
        
        VStack(alignment: .leading) {
            Text("\(prayer.localizedOrCustomString()) \(Strings.settings)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding([.leading, .top])
                .padding([.leading, .top])
                .onAppear {
                    athanAlertEnabled = noteSettings.settings[prayer]?.athanAlertEnabled ?? true
                    athanSoundEnabled = noteSettings.settings[prayer]?.athanSoundEnabled ?? true
                    reminderAlertEnabled = noteSettings.settings[prayer]?.reminderAlertEnabled ?? true
                    reminderOffset = noteSettings.settings[prayer]?.reminderOffset ?? 15
                }
            
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: nil) {
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(Strings.athanNotification)
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
                            
                            VStack(alignment: .leading) {
                                Toggle(isOn: athanOn, label: {
                                    Text(Strings.enabled)
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                })
                                .padding(.top, 12)
                                
                                Toggle(isOn: soundOn, label: {
                                    Text(Strings.playSound)
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                })
                                
                                Text(Strings.playSoundDescription)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .font(.caption)
                                    .foregroundColor(Color(.lightText))
                                    .padding(.bottom, 12)
                                
                                
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
                            
                            Text(Strings.reminderNotification)
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
                            VStack(alignment: .leading) {
                                Toggle(isOn: reminderOn, label: {
                                    Text(Strings.enabled)
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                })
                                .padding(.top, 12)
                                
                                ZStack {
                                    HStack {
                                        Text("\(String(format: Strings.minuteOffset, NumberFormatter.localizedString(from: NSNumber(value: reminderOffset), number: .none)))")
//                                        Text("Minute offset: \(reminderOffset)m")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
//                                            .fixedSize(horizontal: true, vertical: false)
//                                            .lineLimit(1)
                                        Spacer()
                                        
                                        Stepper("", value: $reminderOffset, in: ClosedRange(1..<120))
                                            .accentColor(.white)
                                            .labelsHidden()
                                    }
                                }
                                
                                Text(String(format: Strings.offsetDescription, prayer.previous().localizedOrCustomString(), prayer.localizedOrCustomString()))
//                                Text("When minute offsets are longer than the time between \(prayer.localizedString()) and \(prayer.next().localizedString()), reminders will default to 15 minutes.")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .font(.caption)
                                    .foregroundColor(Color(.lightText))
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
            .padding([.leading, .trailing])
            
            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // save settings
                    let setting = AlarmSetting()
                    setting.athanAlertEnabled = athanAlertEnabled
                    setting.athanSoundEnabled = athanSoundEnabled
                    setting.reminderAlertEnabled = reminderAlertEnabled
                    setting.reminderOffset = reminderOffset
                    noteSettings.settings[prayer] = setting
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
struct PrayerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            PrayerSettingsView(noteSettings: .constant(NotificationSettings(settings: [:], selectedSound: .makkah)), activeSection: .constant(.Prayer(.fajr)))
            
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone 12 mini")
    }
}
