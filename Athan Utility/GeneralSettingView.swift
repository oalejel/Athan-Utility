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
    
    //    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
    //    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
    
    //    @Binding var fajrOverride: String
    //    @Binding var sunriseOverride: String
    //    @Binding var dhuhrOverride: String
    //    @Binding var asrOverride: String
    //    @Binding var maghribOverride: String
    //    @Binding var ishaOverride: String
    //
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @Binding var activeSection: SettingsSectionType
    @Binding var dismissSounds: Bool
    @State var settingsState: SettingsSectionType
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    
    @State var contentOffset = CGFloat(0)
    @Binding var savedOffset: CGFloat
    @State var scrollHeight = CGFloat(300) // wills adjust on appear
    @State var showPrivacyView = false
    
    // contact developer
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false

    
    @available(iOS 14.0, *)
    @State var proxy: ScrollViewProxy?
    
    var body: some View {
        GeometryReader { g in
            VStack(spacing: 0) {
                Divider()
                    .foregroundColor(Color(.lightText))
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
                                            proxy?.scrollTo(id, anchor: .top)
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
                                                activeSection = .Colors
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
                                                activeSection = .CustomNames
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
                                                activeSection = .CalculationMethod
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
                                            print("show athan sounds view")
                                            withAnimation {
                                                activeSection = .Sounds
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
                                                    activeSection = .Prayer(p)
                                                }
                                            }, label: {
                                                HStack {
                                                    
//                                                    VStack {
//                                                        Spacer()
//                                                        PrayerSymbol(prayerType: p)
//                                                            .foregroundColor(.white)
//                                                            .padding([.leading, .top, .bottom])
//                                                            .frame(width: 26)
//                                                        Spacer()
//                                                    }
                                                    
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
//                                                                    Image(systemName: "arrow.right")
//                                                                    Text("\(setting.reminderOffset)")
//                                                                        .fixedSize(horizontal: true, vertical: true)
//                                                                        .lineLimit(1)
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
                                    
                                    Divider()
                                        .background(Color.white)
                                    
                                    let intent: NextPrayerIntent = {
                                        let _intent = NextPrayerIntent()
                                        _intent.suggestedInvocationPhrase = "Next prayer time"
                                        return _intent
                                    }()
                                    
                                    IntentView(intent: intent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.bottom)
                                    
                                    Divider()
                                        .background(Color.white)

                                    
                                    Group {

                                    HStack { // about the developer
                                        Spacer()
                                        VStack(alignment: .center) {
                                            Text(Strings.developedBy)
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
                                        MailView(result: $result) { composer in
                                            composer.setSubject("Feedback for Athan Utility")
                                            composer.title = "Email Developer"
                                            composer.setToRecipients(["omalsecondary@gmail.com"])
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
                                        PrivacyInfoView()
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
                                    //                                (i % 2 == 0 ? Color.red : Color.green)
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
                    .background(Color(.lightText))
                
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
                        AthanManager.shared.prayerSettings = tempPrayerSettings
                        AthanManager.shared.notificationSettings = tempNotificationSettings
                        AthanManager.shared.locationSettings = tempLocationSettings // unnecessary but will keep for now
                        
                        // appearance settings already get saved when we leave the colors view
                        AthanManager.shared.appearanceSettings = tempAppearanceSettings
                        
                        AthanManager.shared.considerRecalculations(force: true)
                        
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
                //                    .padding([.leading, .trailing, .bottom])
            }
            //                .edgesIgnoringSafeArea(.all)
            //                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            .frame(width: g.size.width)
            .padding([.top])
            .transition(.opacity)
        }
    }
}
