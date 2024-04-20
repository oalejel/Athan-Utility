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


enum SettingsSectionType {
    case General, Sounds, Prayer(Prayer), CalculationMethod, CustomNames, Colors
}

@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
    
    // settings state held at top level, saved to athan manager by general view
    @State var tempLocationSettings: LocationSettings = AthanManager.shared.locationSettings.copy() as! LocationSettings
    @State var tempNotificationSettings = AthanManager.shared.notificationSettings.copy() as! NotificationSettings
    @State var tempPrayerSettings = AthanManager.shared.prayerSettings.copy() as! PrayerSettings
    @State var tempAppearanceSettings = AthanManager.shared.appearanceSettings.copy() as! AppearanceSettings
    
    @Binding var parentSession: PresentedSectionType // used to trigger transition back
    
    @State var activeSection = SettingsSectionType.General
    @State var dismissSounds = false
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    @State var savedOffset = CGFloat(0)
        
    var body: some View {
        GeometryReader { g in
            switch activeSection {
            case .General:
                ScrollViewReader { proxy in
                    GeneralSettingView(tempLocationSettings: $tempLocationSettings, tempNotificationSettings: $tempNotificationSettings, tempPrayerSettings: $tempPrayerSettings, tempAppearanceSettings: $tempAppearanceSettings, parentSession: $parentSession, activeSettingsSection: $activeSection, dismissSounds: $dismissSounds, settingsState: activeSection,
                                       savedOffset: $savedOffset, proxy: proxy)
                }
            case .Sounds:
                SoundSettingView(tempNotificationSettings: $tempNotificationSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            case .Prayer(let p):
                #warning("change binding")
                PrayerSettingsView(noteSettings: $tempNotificationSettings, prayer: p, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            case .Colors:
                ColorsView(tempAppearanceSettings: $tempAppearanceSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            case .CustomNames:
                NameOverridesView(tempPrayerSettings: $tempPrayerSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            case .CalculationMethod:
                CalculationMethodView(tempPrayerSettings: $tempPrayerSettings, viewSelectedMethod: tempPrayerSettings.calculationMethod, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
        SettingsView(parentSession: .constant(.Settings))
    }
    .environmentObject(ObservableAthanManager.shared)
}
