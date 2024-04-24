//
//  IntroSettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/16/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import SwiftUI

import Adhan

// helper to update localized prayers given new settings
fileprivate func computePreviewTimes(method: CalculationMethod, madhab: Madhab, latitudeRule: HighLatitudeRule) -> PrayerTimes? {
    let locationSettings = AthanManager.shared.locationSettings
    let prayerSettings = PrayerSettings(method: method, madhab: madhab, customNames: [:], latitudeRule: latitudeRule)
    let times = AthanManager.shared.calculateTimes(
        referenceDate: Date(),
        customCoordinate: locationSettings.locationCoordinate,
        customTimeZone: locationSettings.timeZone,
        adjustments: AthanManager.shared.notificationSettings.adjustments(),
        prayerSettingsOverride: prayerSettings)
    return times
}

// A condensed settings view for setting calculation times
// upon first entry into the app
struct IntroSettingsView: View {
    // used to trigger transition back
    @Binding var parentSession: PresentedSectionType
    
    // Temporary settings copy
    @State var selectedCalcMethod = AthanManager.shared.prayerSettings.calculationMethod
    @State var selectedMadhab = AthanManager.shared.prayerSettings.madhab
    @State var selectedLatitudeRule = AthanManager.shared.prayerSettings.latitudeRule ?? .middleOfTheNight
    @State var locationPreference = AthanManager.shared.locationSettings.locationCoordinate
    @State var previewPrayerTimes = computePreviewTimes(method:  AthanManager.shared.prayerSettings.calculationMethod, madhab: AthanManager.shared.prayerSettings.madhab, latitudeRule: AthanManager.shared.prayerSettings.latitudeRule ?? .middleOfTheNight)
    
    // Other settings UI state properties
    let madhabs = Madhab.allCases
    let calculationMethods = CalculationMethod.usefulCases()
    let latitudeRules = HighLatitudeRule.allCases
    
    // Gradient background appearance state
    @State var localizedCurrentPrayer: Prayer = ObservableAthanManager.shared.todayTimes.currentPrayer(at: Date()) ?? .isha
    @State var appearanceCopy = ObservableAthanManager.shared.appearance
    
    var body: some View {
        ZStack {
            GradientView(currentPrayer: $localizedCurrentPrayer, appearance: $appearanceCopy)
                .equatable()
            VStack(alignment: .leading) {
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(Strings.calculationPreferences)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.01)
                    
                    Text(Strings.calculationPreferencesAdvice)
                        .bold()
                        .foregroundColor(Color(.lightText))
                }
                
                Spacer()
                
                OptionalScrollView {
                    VStack(alignment: .leading) {
                        Group { // calc method group
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 2) {
                                    Image(systemName: "1.circle.fill")
                                        .font(.callout)
                                    Text(Strings.calculationMethod)
                                        .font(.headline)
                                        .bold()
                                }
                                .foregroundColor(.white)
                                Divider()
                                    .background(Color.white)
                            }
                            
                            HStack {
                                Spacer(minLength: 0)
                                Picker("Calculation Method Picker", selection: $selectedCalcMethod, content: {
                                    ForEach(calculationMethods, id: \.self.rawValue) { method in
                                        Text(method.localizedString())
                                            .tag(method)
                                    }
                                })
                                .lineLimit(1)
                                .labelsHidden()
                                .accentColor(.white)
                                .minimumScaleFactor(0.6)
                                
                                Spacer(minLength: 0)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(.init(.sRGB, white: 1, opacity: 0.1))
                            )
                            
                            Text(Strings.calculationDescription)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .font(.caption)
                                .foregroundColor(Color(.lightText))
                                .padding(.bottom, 6)
                        }
                        Group { // madhab group
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 2) {
                                    Image(systemName: "2.circle.fill")
                                        .font(.callout)
                                    Text(Strings.madhab)
                                        .font(.headline)
                                        .bold()
                                }
                                .foregroundColor(.white)
                                Divider()
                                    .background(Color.white)
                            }
                            
                            Picker(selection: $selectedMadhab, label: Text("Picker"), content: {
                                ForEach(madhabs, id: \.self) { madhab in
                                    Text(madhab.stringValue())
                                        .foregroundColor(.white)
                                        .autocapitalization(UITextAutocapitalizationType.words)
                                        .tag(madhab)
                                }
                            })
                            .pickerStyle(SegmentedPickerStyle())
                            .labelsHidden()
                            .foregroundColor(.white)
                            
                            Text(Strings.methodDescription)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .font(.caption)
                                .foregroundColor(Color(.lightText))
                                .padding(.bottom, 6)
                        } // madhab group
                        
                        Group { // latitude adjustment group
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 2) {
                                    Image(systemName: "3.circle.fill")
                                        .font(.callout)
                                    Text(Strings.highLatitudeRuleTitle)
                                        .font(.headline)
                                        .bold()
                                }
                                .foregroundColor(.white)
                                Divider()
                                    .background(Color.white)
                            }
                            
                            HStack {
                                Spacer()
                                Picker(selection: $selectedLatitudeRule, label: Text("Latitude Rule Picker"), content: {
                                    ForEach(latitudeRules, id: \.self.rawValue) { latRule in
                                        Text(latRule.localizedString())
                                            .tag(latRule)
                                            .foregroundColor(.white)
                                            .autocapitalization(UITextAutocapitalizationType.words)
                                    }
                                })
                                .labelsHidden()
                                .accentColor(.white)
                                Spacer()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(.init(.sRGB, white: 1, opacity: 0.1))
                            )
                            
                            Text(Strings.highLatitudeExplanation + HighLatitudeRule.recommended(for: locationPreference).localizedString())
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .font(.caption)
                                .foregroundColor(Color(.lightText))
                                .padding(.bottom, 6)
                        } // high lat rule group
                        .onChange(of: selectedCalcMethod) { method in
                            previewPrayerTimes = computePreviewTimes(method: selectedCalcMethod, madhab: selectedMadhab, latitudeRule: selectedLatitudeRule)
                        }
                        .onChange(of: selectedMadhab) { madhab in
                            previewPrayerTimes = computePreviewTimes(method: selectedCalcMethod, madhab: selectedMadhab, latitudeRule: selectedLatitudeRule)
                        }
                        .onChange(of: selectedLatitudeRule) { rule in
                            previewPrayerTimes = computePreviewTimes(method: selectedCalcMethod, madhab: selectedMadhab, latitudeRule: selectedLatitudeRule)
                        }
                    }
                }
                .mask(
                    LinearGradient(colors: [.white, .white, .white, .white, .white, .white, .clear], startPoint: .top, endPoint: .bottom)
                )
                
                Spacer(minLength: 0)
                
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Strings.athanPreviewTitle)
                        .bold()
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize()
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
                
                if let prayers = previewPrayerTimes {
                    let times = Prayer.allCases.map { prayers.time(for: $0) }
                    VStack(spacing: 4) {
                        HStack {
                            VStack(alignment: .leading) {
                                ForEach(0..<3) { i in
                                    Text(Prayer(index: i).localizedOrCustomString())
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                        .minimumScaleFactor(0.5)
//                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                ForEach(0..<3) { i in
                                    Text(times[i], style: .time)
                                }
                            }
                            .fixedSize()
                            
                            Rectangle()
                                .frame(width: 1, height: 70)
                                .opacity(0.5)
                                .foregroundColor(Color(.lightText))
                            
                            VStack(alignment: .leading) {
                                ForEach(3..<6) { i in
                                    Text(Prayer(index: i).localizedOrCustomString())
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                        .minimumScaleFactor(0.5)
//                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                ForEach(3..<6) { i in
                                    Text(times[i], style: .time)
                                }
                            }
                            .fixedSize()
                        }
                    }
                    .padding(12)
                    .foregroundColor(Color(.gray))
                    .background(RoundedRectangle(cornerRadius: 18 ).fill(.white))
                }
                
                Spacer()
                
                HStack(alignment: .center) {
                    Button(action: { // BACK BUTTON
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation {
                            self.parentSession = .Location
                        }
                    }) {
                        Text(Strings.editLocationButtonTitle)
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
                    
                    Spacer()
                    Button(action: { // DONE BUTTON
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        writeIntroSettingsToGlobal()
                        // force athan manager to recalculate
                        AthanManager.shared.reloadSettingsAndNotifications()
                        withAnimation {
                            self.parentSession = .Main
                        }
                    }) {
                        Text(Strings.done)
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 4)
        }
    }
    
    func writeIntroSettingsToGlobal() {
        // should ONLY write prayer settings that are handlded in this view
        //  without overwriting things like custom prayer names, since this
        //  view will be allowed to appear for existing users.
        IntroSetupFlags.hasCompletedCalculationSetup = true
        let prayerSettings = AthanManager.shared.prayerSettings
        prayerSettings.madhab = selectedMadhab
        prayerSettings.calculationMethod = selectedCalcMethod
        prayerSettings.latitudeRule = selectedLatitudeRule
        AthanManager.shared.prayerSettings = prayerSettings
    }
}

#Preview {
    IntroSettingsView(parentSession: .constant(PresentedSectionType.Main))
}
