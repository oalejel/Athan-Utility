//
//  GeneralSettingView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/26/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan
import StoreKit
import MessageUI

@available(iOS 13.0.0, *)
struct GeneralSettingView: View {
    @EnvironmentObject var manager: ObservableAthanManager
    
    @Binding var tempLocationSettings: LocationSettings
    @Binding var tempNotificationSettings: NotificationSettings
    @Binding var tempPrayerSettings: PrayerSettings
    @Binding var tempAppearanceSettings: AppearanceSettings
    @State var selectedLatitudeRule = AthanManager.shared.prayerSettings.latitudeRule ?? .middleOfTheNight
    
    // used to trigger transition back
    @Binding var parentSession: PresentedSectionType
    
    @Binding var activeSettingsSection: SettingsSectionType
    @Binding var dismissSounds: Bool
    @State var settingsState: SettingsSectionType
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    let latitudeRules = HighLatitudeRule.allCases
    
    @State var contentOffset = CGFloat(0)
    @Binding var savedOffset: CGFloat
    @State var scrollHeight = CGFloat(300) // to be adjusted on appearance
    @State var showPrivacyView = false
    
    // Developer contact properties
    @State private var mailCompositionResult: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false
    
    @State var proxy: Any? = nil
    
    var body: some View {
        GeometryReader { g in
            VStack(spacing: 0) {
                Divider()
                    .background(Color.white)
                    .onAppear {
                        print(tempNotificationSettings.selectedSound)
                    }
                
                TrackableScrollView(contentOffset: $contentOffset) {
                    ZStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: nil) {
                            VStack(alignment: .leading, spacing: 0) {
                                
                                Text(Strings.settings) // title
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                                    .onDisappear {
                                        savedOffset = contentOffset
                                    }
                                    .onAppear {
                                        print("SAVED OFFSET: \(savedOffset)")
                                        
                                        if #available(iOS 14.0, *) {
                                            let id = Int((savedOffset / scrollHeight) * 100)
                                            (proxy as? ScrollViewProxy)?.scrollTo(id, anchor: .top)
                                        }
                                    }
                                
                                VStack(alignment: .leading) { // stack of each settings selector
                                    Group { // Color picker
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Strings.appearance)
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding(.top)
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        
                                        
                                        Button(action: {
                                            withAnimation {
                                                activeSettingsSection = .Colors
                                            }
                                        }, label: {
                                            HStack {
                                                Text(Strings.colors)
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                    .frame(maxWidth: .infinity)
                                                
                                                
                                                
                                                
                                                GeometryReader { circleG in
                                                    let colorPairs: [(Color, Color)] = tempAppearanceSettings.isDynamic ? Prayer.allCases.reversed().map { tempAppearanceSettings.colors(for: $0) } : [tempAppearanceSettings.colors(for: nil)]
                                                    
                                                    HStack {
                                                        Spacer()
                                                        ZStack {
                                                            ForEach(0..<colorPairs.count) { cIndex in
                                                                let gradPair = colorPairs[cIndex]
                                                                Circle()
                                                                    .strokeBorder(Color(.sRGB, white: 1, opacity: 0.5), lineWidth: 1)
                                                                    .background(
                                                                        LinearGradient(gradient: Gradient(colors: [gradPair.0, gradPair.1]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                                                            .mask(Circle())
                                                                        //                                                                        Circle().foregroundColor(.white)
                                                                    )
                                                                    .frame(width: circleG.size.height, height: circleG.size.height)
                                                                    .offset(x: CGFloat(cIndex) * circleG.size.height / -2, y: 0)
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                                    .font(Font.headline.weight(.bold))
                                                    .flipsForRightToLeftLayoutDirection(true)
                                                //                                                .padding()
                                            }
                                            .padding()
                                        })
                                        .buttonStyle(ScalingButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation {
                                                activeSettingsSection = .CustomNames
                                            }
                                        }, label: {
                                            HStack {
                                                Text(Strings.customPrayerNames)
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                                    .font(Font.headline.weight(.bold))
                                                    .flipsForRightToLeftLayoutDirection(true)
                                            }
                                            .padding()
                                        })
                                        .buttonStyle(ScalingButtonStyle())
                                        
                                        Button(action: {
                                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                        }, label: {
                                            HStack {
                                                Text(Strings.changeLanguage)
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .padding()
                                                Spacer()
                                                Image(systemName: "globe")
                                                    .foregroundColor(.white)
                                                    .font(Font.headline.weight(.bold))
                                                    .padding()
                                            }
                                        })
                                        .buttonStyle(ScalingButtonStyle())
                                        .padding(.bottom)
                                    }
                                    
                                    
                                    Group { // calculation method group
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Strings.calculationMethod)
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                            
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        Button(action: { // calculation method button
                                            withAnimation {
                                                activeSettingsSection = .CalculationMethod
                                            }
                                        }, label: {
                                            HStack {
                                                Text(tempPrayerSettings.calculationMethod.localizedString())
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                                    .font(Font.headline.weight(.bold))
                                                    .flipsForRightToLeftLayoutDirection(true)
                                            }
                                            .padding()
                                        })
                                        .buttonStyle(ScalingButtonStyle())
                                        
                                        Text(Strings.calculationDescription)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .font(.caption)
                                            .foregroundColor(Color(.lightText))
                                            .padding(.bottom)
                                        
                                        /*
                                         Picker(selection: $tempPrayerSettings.calculationMethod, label: Text("Picker"), content: {
                                         ForEach(0..<calculationMethods.count) { mIndex in
                                         let method = calculationMethods[mIndex]
                                         Text(method.localizedString())
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
                                         */
                                        
                                        
                                        
                                    } // calculation method group
                                    
                                    
                                    Group { // madhab group
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Strings.madhab)
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
                                        
                                        Text(Strings.methodDescription)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .font(.caption)
                                            .foregroundColor(Color(.lightText))
                                            .padding(.bottom)
                                    } // madhab group
                                    
                                    Group { // latitude adjustment group
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Strings.highLatitudeRuleTitle)
                                                .font(.headline)
                                                .bold()
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
                                        
                                        Text(Strings.highLatitudeExplanation + "\"\(HighLatitudeRule.recommended(for: tempLocationSettings.locationCoordinate).localizedString())\"")
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .font(.caption)
                                            .foregroundColor(Color(.lightText))
                                            .padding(.bottom, 6)
                                    } // high lat rule group
                                    
                                    Group { // athan sounds group
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Strings.athanSound)
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        Button(action: {
                                            withAnimation {
                                                activeSettingsSection = .Sounds
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
                                                    .flipsForRightToLeftLayoutDirection(true)
                                                    .padding()
                                            }
                                        })
                                        .buttonStyle(ScalingButtonStyle())
                                    } // athan sounds group
                                    
                                    Text(Strings.athanSoundDescription)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                        .font(.caption)
                                        .foregroundColor(Color(.lightText))
                                    
                                    Group {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Strings.notifications)
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding(.top)
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        let prayers = Prayer.allCases
                                        ForEach(prayers, id: \.self) { p in
                                            Button(action: {
                                                withAnimation {
                                                    activeSettingsSection = .Prayer(p)
                                                }
                                            }, label: {
                                                HStack {
                                                    
                                                    PrayerSymbol(prayerType: p)
                                                        .padding([.leading, .top, .bottom])
                                                        .foregroundColor(.white)
                                                        .frame(width: 26)
                                                    
                                                    Text("\(p.localizedOrCustomString())")
                                                        .font(.headline)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                        .padding(.leading, 2)
                                                    
                                                    Spacer()
                                                    
                                                    HStack(spacing: 0) {
                                                        Group { // tags to preview settings
                                                            if let setting = tempNotificationSettings.settings[p] {
                                                                Image(systemName: setting.athanSoundEnabled ? "bell.circle" : "bell.slash.circle")
                                                                Image(systemName: setting.athanSoundEnabled ? "speaker.wave.2.circle" : "speaker.slash.circle")
                                                                if setting.reminderAlertEnabled {
                                                                    Image(systemName: "clock.arrow.circlepath")
                                                                }
                                                            }
                                                        }
                                                        .foregroundColor(.white)
                                                        .font(Font.headline)
                                                        .flipsForRightToLeftLayoutDirection(true)
                                                    }
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.white)
                                                        .font(Font.headline.weight(.bold))
                                                        .flipsForRightToLeftLayoutDirection(true)
                                                        .padding()
                                                }
                                            })
                                            .buttonStyle(ScalingButtonStyle())
                                            .padding(.top, 1)
                                        }
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Divider()
                                            .background(Color.white)
                                        
                                        IntentIntegratedController()
                                            .frame(height: 50)
                                        Divider()
                                            .background(Color.white)
                                    }
                                    
                                    
                                    
                                    Group {
                                        
                                        HStack { // about the developer
                                            Spacer()
                                            VStack(alignment: .center) {
                                                Text(Strings.developedBy)
                                                    .font(Font.headline.weight(.medium))
                                                Text("Free Palestine 🇵🇸")
                                                    .font(Font.headline.weight(.medium))
                                            }
                                            .foregroundColor(.white)
                                            Spacer()
                                        }
                                        .padding([.top, .bottom])
                                        
                                        Button(action: { // send feedback
                                            self.isShowingMailView.toggle()
                                        }, label: {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "envelope")
                                                    .font(Font.headline.weight(.medium))
                                                    .foregroundColor(.white)
                                                Text(Strings.sendFeedback)
                                                    .font(Font.headline.weight(.medium))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding()
                                        })
                                        .buttonStyle(ScalingButtonStyle(color: Color(.sRGB, white: 1, opacity: 0.2)))
                                        .sheet(isPresented: $isShowingMailView) {
                                            if MFMailComposeViewController.canSendMail() {
                                                MailView(result: $mailCompositionResult) { composer in
                                                    composer.setSubject("Feedback for Athan Utility")
                                                    composer.title = "Email Developer"
                                                    composer.setToRecipients(["athan.utility@gmail.com"])
                                                }
                                            }
                                        }
                                        
                                        Button(action: { // send feedback
                                            showPrivacyView.toggle()
                                        }, label: {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "hand.raised.fill")
                                                    .font(Font.headline.weight(.medium))
                                                    .foregroundColor(.white)
                                                Text(Strings.privacyNotes)
                                                    .font(Font.headline.weight(.medium))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding()
                                        })
                                        .buttonStyle(ScalingButtonStyle(color: Color(.sRGB, white: 1, opacity: 0.2)))
                                        .sheet(isPresented: $showPrivacyView) {
                                            PrivacyInfoView(isVisible: $showPrivacyView)
                                        }
                                        
                                        Button(action: { // rate the app
                                            SKStoreReviewController.requestReview()
                                        }, label: {
                                            VStack(spacing: 0) {
                                                HStack(spacing: 1) {
                                                    ForEach(0..<5) { i in
                                                        Image(systemName: "star.fill")
                                                            .foregroundColor(.orange)
                                                            .font(Font.headline.weight(.medium))
                                                    }
                                                }
                                                HStack() {
                                                    Spacer()
                                                    Text(Strings.rateAthanUtility)
                                                        .font(Font.headline.weight(.medium))
                                                        .foregroundColor(.white)
                                                    Spacer()
                                                }
                                            }.padding()
                                            
                                        })
                                        .buttonStyle(ScalingButtonStyle(color: Color(.sRGB, white: 1, opacity: 0.2)))
                                    }
                                }
                            }
                            .padding()
                            .padding()
                            .overlay(
                                GeometryReader { contentG in
                                    Color.clear.onAppear {
                                        scrollHeight = contentG.size.height
                                    }
                                }
                            )
                        }
                        
                        // scroll reference points trick
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            ForEach(0..<100) { i in
                                Color.clear
                                    .frame(height: 1)
                                    .id(Int(i))
                                Spacer()
                            }
                        }
                    }
                    .frame(width: g.size.width)
                }
                .edgesIgnoringSafeArea(.all)
                
                // footer divider
                Divider()
                    .background(Color.white)
                
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: { // DONE button
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        
                        print(tempPrayerSettings.calculationMethod)
                        print(tempPrayerSettings.madhab)
                        print(tempPrayerSettings.customNames)
                        
                        print(tempLocationSettings.locationCoordinate)
                        print(tempLocationSettings.locationName)
                        
                        print(tempNotificationSettings.selectedSound)
                        print(tempNotificationSettings.settings)
                        print("^settings")
                        
                        // update all settings unconditionally in case we change components of
                        // the settings
                        tempPrayerSettings.latitudeRule = selectedLatitudeRule
                        AthanManager.shared.prayerSettings = tempPrayerSettings
                        
                        // MUST also save here because multiple views can modify this setting
                        AthanManager.shared.notificationSettings = tempNotificationSettings // saving this in other view
                        AthanManager.shared.locationSettings = tempLocationSettings // unnecessary but will keep for now
                        
                        // appearance settings already get saved when we leave the colors view
                        AthanManager.shared.appearanceSettings = tempAppearanceSettings
                        
                        AthanManager.shared.reloadSettingsAndNotifications()
                        
                        withAnimation {
                            parentSession = .Main // tell parent to go back
                        }
                    }) {
                        Text(Strings.done)
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
                }
                .padding()
                .padding([.leading, .trailing, .bottom])
                .frame(width: g.size.width)
                .padding([.top])
                .transition(.opacity)
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
