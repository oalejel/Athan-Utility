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



@available(iOS 13.0.0, *)
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

@available(iOS 13.0.0, *)
struct MyScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let offsetChanged: (CGPoint) -> Void
    let content: Content
    
    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        offsetChanged: @escaping (CGPoint) -> Void = { _ in },
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.offsetChanged = offsetChanged
        self.content = content()
    }
    
    var body: some View {
        SwiftUI.ScrollView(axes, showsIndicators: showsIndicators) {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scrollView")).origin
                )
            }.frame(width: 0, height: 0)
            content
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: offsetChanged)
    }
}






enum SettingsSectionType {
    case General, Sounds, Prayer
}

@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
    //    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    
    @State var tempLocationSettings: LocationSettings = LocationSettings.shared.copy() as! LocationSettings
    @State var tempNotificationSettings = NotificationSettings.shared.copy() as! NotificationSettings
    @State var tempPrayerSettings = PrayerSettings.shared.copy() as! PrayerSettings
    
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
            case .General:
                VStack(spacing: 0) {
                    Divider()
                        .foregroundColor(Color(.lightText))
                        .onAppear {
                            print(tempNotificationSettings.selectedSound)
                        }
                    
                    MyScrollView(axes: [.vertical], showsIndicators: true, offsetChanged: { _ in print("scroll") }) {
                        VStack(alignment: .leading, spacing: nil) {
                            
                            Text("Settings") // title
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.bottom)
                            
                            VStack(alignment: .leading) {
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
                                
                                Group {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Use Arabic Language")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding(.top)
                                        Divider()
                                            .background(Color.white)
                                    }
                                    
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
                                    
//                                    HStack {
//                                        Toggle(isOn: AthanDefaults.arabicMode, label: {
//                                            Text("Arabic Mode")
//                                                .font(.headline)
//                                                .bold()
//                                                .foregroundColor(.white)
//
//                                        })
//                                    }
//                                    .padding()

                                }

                                Button(action: {
                                     
                                }, label: {
                                    HStack() {
                                        Spacer()
                                        Text("Rate Athan Utility!")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding()
                                        Spacer()
                                    }
                                })
                                .buttonStyle(ScalingButtonStyle())
                            }
                            
                        }
                        .padding()
                        .padding()
                    }
                    .edgesIgnoringSafeArea(.all)
                    Divider()
                        .background(Color(.lightText))
                    
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: {
                            // tap vibration
                            let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            lightImpactFeedbackGenerator.impactOccurred()
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
