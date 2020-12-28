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

@available(iOS 13.0.0, *)
struct GeneralSettingView: View {
    
    @EnvironmentObject var manager: ObservableAthanManager
    //    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    
    @Binding var tempLocationSettings: LocationSettings
    @Binding var tempNotificationSettings: NotificationSettings
    @Binding var tempPrayerSettings: PrayerSettings
    
    //    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
    //    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
    
    @Binding var fajrOverride: String
    @Binding var sunriseOverride: String
    @Binding var dhuhrOverride: String
    @Binding var asrOverride: String
    @Binding var maghribOverride: String
    @Binding var ishaOverride: String
    
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @Binding var activeSection: SettingsSectionType
    @Binding var dismissSounds: Bool
    @State var settingsState: SettingsSectionType
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    
    @State var contentOffset = CGFloat(0)
    @Binding var savedOffset: CGFloat
    @State var scrollHeight = CGFloat(300) // wills adjust on appear
    
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
                                
                                Text("Settings") // title
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                                    //                                .padding(.bottom)
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
                                            Text("Appearance")
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding(.top)
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        Button(action: {
                                            
                                        }, label: {
                                            HStack {
                                                Text("Colors")
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                                    .frame(maxWidth: .infinity)
                                                let c1 = Color.blue
                                                let c2 = Color.black
                                                
                                                GeometryReader { circleG in
                                                    HStack {
                                                        Spacer()
                                                        ZStack {
                                                            Circle()
                                                                .strokeBorder(Color(.sRGB, white: 1, opacity: 0.5), lineWidth: 1)
                                                                .background(Circle().foregroundColor(c1))
                                                                .frame(width: circleG.size.height, height: circleG.size.height)
                                                            
                                                            Circle()
                                                                .strokeBorder(Color(.sRGB, white: 1, opacity: 0.5), lineWidth: 1)
                                                                .background(Circle().foregroundColor(c2))
                                                                .offset(x: circleG.size.height / -2, y: 0)
                                                                .frame(width: circleG.size.height, height: circleG.size.height)
                                                            
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
                                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                        }, label: {
                                            HStack {
                                                Text("Change Language")
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
                                            Text("Calculation method")
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                            
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        Picker(selection: $tempPrayerSettings.calculationMethod, label: Text("Picker"), content: {
                                            ForEach(0..<calculationMethods.count) { mIndex in
                                                let method = calculationMethods[mIndex]
                                                Text(method.stringValue())
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
                                    } // calculation method group
                                    
                                    
                                    Group { // madhab group
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Madhab")
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
                                        Text("The Hanafi madhab uses later Asr times, taking place when the length of a shadow increases in length by double the length of an object since solar noon.")
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .font(.caption)
                                            .foregroundColor(Color(.lightText))
                                            .padding(.bottom)
                                    } // madhab group
                                    
                                    Group { // athan sounds group
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Athan sound")
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        ZStack {
                                            Button(action: {
                                                print("show athan sounds view")
                                                //                                            savedOffset = contentOffset
                                                //                                            print("SAVED: \(contentOffset)")
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
                                        }
                                    } // athan sounds group
                                    
                                    
                                    
                                    Group {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Notifications and customizations")
                                                .font(.headline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding(.top)
                                            Divider()
                                                .background(Color.white)
                                        }
                                        
                                        ForEach(0..<6) { pIndex in
                                            Button(action: {
                                                withAnimation {
                                                    activeSection = .Prayer
                                                }
                                            }, label: {
                                                HStack {
                                                    Text("\(Prayer(index: pIndex).stringValue())")
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
                                        }
                                    }
                                    
                                    HStack { // about the developer
                                        Spacer()
                                        VStack(alignment: .center) {
                                            Text("Developed by")
                                                .font(Font.headline.weight(.medium))
                                            Text("Omar Al-Ejel")
                                                .font(Font.headline.weight(.medium))
                                        }
                                        .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding([.top, .bottom])
                                    
                                    Button(action: { // rate the app
                                        SKStoreReviewController.requestReview()
                                    }, label: {
                                        VStack(spacing: 0) {
                                            HStack(spacing: 1) {
                                                ForEach(0..<5) { i in
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            HStack() {
                                                Spacer()
                                                Text("Rate Athan Utility!")
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(.blue)
                                                Spacer()
                                            }
                                        }.padding()
                                        
                                    })
                                    .buttonStyle(ScalingButtonStyle(color: .white))
                                    
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
                        
                        AthanManager.shared.considerRecalculations(force: true)
                        
                        withAnimation {
                            parentSession = .Main // tell parent to go back
                        }
                    }) {
                        Text("Done")
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
