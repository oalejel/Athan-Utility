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
    
    @State var customPrayerName: String? = nil
    
    @Binding var activeSection: SettingsSectionType
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: nil) {
                                            
                    Text("\(customPrayerName ?? prayer.localizedString()) settings")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.bottom)
                        
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alarms")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Divider()
                                .background(Color.white)
                            
                            HStack {
                                Toggle(isOn: .constant(setting.reminderAlarmEnabled), label: {
                                    Text("Reminder alarm")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)

                                })
                            }
                            .padding()

                            
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
            .previewDevice("iPhone Xs")
    }
}
