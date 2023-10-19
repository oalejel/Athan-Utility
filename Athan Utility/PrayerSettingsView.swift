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
//    @State var overrideMuteSwitch = false
    @State var play30Seconds = false
    @State var athanMinutesOffset = 0
    
    let x: Int = {
        UIStepper.appearance().tintColor = .white
        return 0
    }()
    
    var body: some View {
        // intermediate bindings that depend on each other
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
                    // Initialize states based on current settings
                    // TODO: move to dedicated helper
                    athanAlertEnabled = noteSettings.settings[prayer]?.athanAlertEnabled ?? true
                    athanSoundEnabled = noteSettings.settings[prayer]?.athanSoundEnabled ?? true
                    reminderAlertEnabled = noteSettings.settings[prayer]?.reminderAlertEnabled ?? true
                    reminderOffset = noteSettings.settings[prayer]?.reminderOffset ?? 15
                    athanMinutesOffset = noteSettings.settings[prayer]?.athanOffset ?? 0
                    play30Seconds = noteSettings.settings[prayer]?.playExtendedSound ?? false
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
//                                    .padding(.bottom, 12)
                                
                                // Play 30 seconds of audio
                                Toggle(isOn: $play30Seconds, label: {
                                    Text(Strings.play30Seconds)
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                })
                                
                                Text(Strings.playLimitDescription)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .font(.caption)
                                    .foregroundColor(Color(.lightText))
                                    .padding(.bottom, 0) // fix for all-caps text bug


                                // TODO: enable when we have critical alert entitlement
//                                Toggle(isOn: $overrideMuteSwitch, label: {
//                                    Text("Override mute switch")
//                                        .font(.headline)
//                                        .bold()
//                                        .foregroundColor(.white)
//                                })
//                                Text(Strings.playSoundDescription)
//                                    .fixedSize(horizontal: false, vertical: true)
//                                    .lineLimit(nil)
//                                    .font(.caption)
//                                    .foregroundColor(Color(.lightText))
//                                    .padding(.bottom, 12)
                                
//                                UNUserNotificationCenter.current().requestAuthorization(
//                                    options: [.alert, .sound, .badge, .criticalAlert]
//                                ) { granted, error in
//                                ...
//                                }
                                // NOTE: should save whether the user has enabled these before requesting


                                ZStack {
                                    HStack {
                                        Text("\(String(format: Strings.athanMinuteOffset, NumberFormatter.localizedString(from: NSNumber(value: athanMinutesOffset), number: .none)))")
//                                        Text("Minute offset: \(reminderOffset)m")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
//                                            .fixedSize(horizontal: true, vertical: false)
//                                            .lineLimit(1)
                                        Spacer()
                                        
                                        Stepper("", value: $athanMinutesOffset, in: ClosedRange(-190..<190))
//                                            .accentColor(.white)
                                            .labelsHidden()
//                                            .background(Color.white)
//                                            .cornerRadius(8)
                                            
                                    }
                                }
                                .padding(.bottom, 12)
                                
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
                                        Text("\(String(format: Strings.reminderMinuteOffset, NumberFormatter.localizedString(from: NSNumber(value: reminderOffset), number: .none)))")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                        Spacer()
                                        
                                        Stepper("", value: $reminderOffset, in: ClosedRange(1..<120))
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
            
            // Done button - save settings upon tap
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
                    setting.athanOffset = athanMinutesOffset
                    setting.playExtendedSound = play30Seconds
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

//@available(iOS 13.0.0, *)
//struct PrayerSettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack {
//            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
//                .edgesIgnoringSafeArea(.all)
//            PrayerSettingsView(noteSettings: .constant(NotificationSettings(settings: [:], selectedSound: .makkah)), activeSection: .constant(.Prayer(.fajr)))
//            
//        }
//        .environmentObject(ObservableAthanManager.shared)
//        .previewDevice("iPhone 12 mini")
//    }
//}

