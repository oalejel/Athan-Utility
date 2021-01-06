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
    case General, Sounds, Prayer(Prayer), CalculationMethod, CustomNames, Colors
}

@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
    //    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    
    // settings state held at top level, saved to athan manager by general view
    @State var tempLocationSettings: LocationSettings = AthanManager.shared.locationSettings.copy() as! LocationSettings
    @State var tempNotificationSettings = AthanManager.shared.notificationSettings.copy() as! NotificationSettings
    @State var tempPrayerSettings = AthanManager.shared.prayerSettings.copy() as! PrayerSettings
    @State var tempAppearanceSettings = AthanManager.shared.appearanceSettings.copy() as! AppearanceSettings
    
    //    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
    //    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
    
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @State var activeSection = SettingsSectionType.General
    @State var dismissSounds = false
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    @State var savedOffset = CGFloat(0)
    
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
                
            case .General:
                if #available(iOS 14.0, *) {
                    ScrollViewReader { proxy in
                        GeneralSettingView(tempLocationSettings: $tempLocationSettings, tempNotificationSettings: $tempNotificationSettings, tempPrayerSettings: $tempPrayerSettings, tempAppearanceSettings: $tempAppearanceSettings, parentSession: $parentSession, activeSection: $activeSection, dismissSounds: $dismissSounds, settingsState: activeSection,
                                           savedOffset: $savedOffset, proxy: proxy)
                    }
                } else { // pre-ios 13 wont have the scrollview offset adjusted back
                    GeneralSettingView(tempLocationSettings: $tempLocationSettings, tempNotificationSettings: $tempNotificationSettings, tempPrayerSettings: $tempPrayerSettings, tempAppearanceSettings: $tempAppearanceSettings, parentSession: $parentSession, activeSection: $activeSection, dismissSounds: $dismissSounds, settingsState: activeSection,
                                       savedOffset: $savedOffset)
                }
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            SettingsView(parentSession: .constant(.Settings))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
