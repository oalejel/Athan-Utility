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
    case General, Sounds, Prayer, CalculationMethod
}

@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
    //    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    
    @State var tempLocationSettings: LocationSettings = AthanManager.shared.locationSettings.copy() as! LocationSettings
    @State var tempNotificationSettings = AthanManager.shared.notificationSettings.copy() as! NotificationSettings
    @State var tempPrayerSettings = AthanManager.shared.prayerSettings.copy() as! PrayerSettings
    
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
            case .Prayer:
                #warning("change binding")
                PrayerSettingsView(setting: .constant(AlarmSetting()), activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                
            case .CalculationMethod:
                CalculationMethodView(tempPrayerSettings: .constant(tempPrayerSettings), viewSelectedMethod: tempPrayerSettings.calculationMethod, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                
            case .General:
                if #available(iOS 14.0, *) {
                    ScrollViewReader { proxy in
                        GeneralSettingView(tempLocationSettings: $tempLocationSettings, tempNotificationSettings: $tempNotificationSettings, tempPrayerSettings: $tempPrayerSettings, fajrOverride: $fajrOverride, sunriseOverride: $sunriseOverride, dhuhrOverride: $dhuhrOverride, asrOverride: $asrOverride, maghribOverride: $maghribOverride, ishaOverride: $ishaOverride, parentSession: $parentSession, activeSection: $activeSection, dismissSounds: $dismissSounds, settingsState: activeSection,
                            savedOffset: $savedOffset, proxy: proxy)
                    }
                } else { // pre-ios 13 wont have the scrollview offset adjusted back
                    GeneralSettingView(tempLocationSettings: $tempLocationSettings, tempNotificationSettings: $tempNotificationSettings, tempPrayerSettings: $tempPrayerSettings, fajrOverride: $fajrOverride, sunriseOverride: $sunriseOverride, dhuhrOverride: $dhuhrOverride, asrOverride: $asrOverride, maghribOverride: $maghribOverride, ishaOverride: $ishaOverride, parentSession: $parentSession, activeSection: $activeSection, dismissSounds: $dismissSounds, settingsState: activeSection,
                        savedOffset: $savedOffset, proxy: nil)
                }
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
