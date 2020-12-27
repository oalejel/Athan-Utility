////
////  GeneralSettingsView.swift
////  Athan Utility
////
////  Created by Omar Al-Ejel on 12/26/20.
////  Copyright © 2020 Omar Alejel. All rights reserved.
////
//
//import SwiftUI
//import Adhan
//
//@available(iOS 13.0.0, *)
//struct GeneralSettingsView: View, Equatable {
//    static func == (lhs: GeneralSettingsView, rhs: GeneralSettingsView) -> Bool {
//        return true
//    }
//
//    @EnvironmentObject var manager: ObservableAthanManager
//    //    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
//
//    @Binding var tempLocationSettings: LocationSettings
//    @Binding var tempNotificationSettings: NotificationSettings
//    @Binding var tempPrayerSettings: PrayerSettings
//
//    //    @State var selectedMadhab: Madhab = PrayerSettings.shared.madhab
//    //    @State var selectedMethod: CalculationMethod = PrayerSettings.shared.calculationMethod
//
//    @Binding var fajrOverride: String
//    @Binding var sunriseOverride: String
//    @Binding var dhuhrOverride: String
//    @Binding var asrOverride: String
//    @Binding var maghribOverride: String
//    @Binding var ishaOverride: String
//
//    @Binding var parentSession: CurrentView // used to trigger transition back
//    
//    //    @Binding var activeSection: SettingsSectionType
//    @Binding var dismissSounds: Bool
//    @EnvironmentObject var settingsState: SettingsStateObject
//
//    let calculationMethods = CalculationMethod.usefulCases()
//    let madhabs = Madhab.allCases
//
//    var body: some View {
//        GeometryReader { g in
//
//            VStack(spacing: 0) {
//                Divider()
//                    .foregroundColor(Color(.lightText))
//                    .onAppear {
//                        print(tempNotificationSettings.selectedSound)
//                    }
//
//                //axes: [.vertical], showsIndicators: true, offsetChanged: { _ in print("scroll") }
//
//
//
//
//                ScrollView {
//                    GeometryReader { g2
//                        let offset = proxy.frame(in: .named("scroll")).minY
//                        Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
//
//                        VStack(alignment: .leading, spacing: nil) {
//
//                            Text("Settings") // title
//                                .font(.largeTitle)
//                                .bold()
//                                .foregroundColor(.white)
//                                .padding(.bottom)
//
//                            VStack(alignment: .leading) {
//                                Group { // calculation method group
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Calculation method")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//
//                                        Divider()
//                                            .background(Color.white)
//                                    }
//
//                                    Picker(selection: $tempPrayerSettings.calculationMethod, label: Text("Picker"), content: {
//                                        ForEach(0..<calculationMethods.count) { mIndex in
//                                            let method = calculationMethods[mIndex]
//                                            Text(method.stringValue())
//                                                .foregroundColor(.white)
//                                                .tag(method)
//                                                .listRowInsets(EdgeInsets())
//                                        }
//                                    })
//                                    .pickerStyle(WheelPickerStyle())
//                                    .labelsHidden()
//                                    .scaledToFit()
//                                    .foregroundColor(.white)
//                                    //                                .frame(width: g.size.width * 0.8)
//                                    //                                .padding([.leading, .trailing])
//                                    Text("Calculation methods primarily differ in Fajr and Isha sun angles.")
//                                        .fixedSize(horizontal: false, vertical: true)
//                                        .lineLimit(nil)
//                                        .font(.caption)
//                                        .foregroundColor(Color(.lightText))
//                                        .padding(.bottom)
//
//                                } // calculation method group
//
//                                Group { // madhab group
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Madhab")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//                                        Divider()
//                                            .background(Color.white)
//                                    }
//
//                                    Picker(selection: $tempPrayerSettings.madhab, label: Text("Picker"), content: {
//                                        ForEach(0..<madhabs.count) { mIndex in
//                                            let madhab = madhabs[mIndex]
//                                            Text(madhab.stringValue())
//                                                .foregroundColor(.white)
//                                                .autocapitalization(UITextAutocapitalizationType.words)
//                                                .tag(madhab)
//                                        }
//                                    })
//                                    .pickerStyle(SegmentedPickerStyle())
//                                    .labelsHidden()
//                                    .foregroundColor(.white)
//                                    Text("The Hanafi madhab uses later Asr times, taking place when the length of a shadow increases in length by double the length of an object since solar noon.")
//                                        .fixedSize(horizontal: false, vertical: true)
//                                        .lineLimit(nil)
//                                        .font(.caption)
//                                        .foregroundColor(Color(.lightText))
//                                        .padding(.bottom)
//
//                                } // madhab group
//
//                                Group { // athan sounds group
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Athan sound")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//                                        Divider()
//                                            .background(Color.white)
//                                    }
//
//                                    ZStack {
//                                        Button(action: {
//                                            print("show athan sounds view")
//
//                                            withAnimation {
//                                                //                                            activeSection = .Sounds
//                                                settingsState.activeState = .Sounds
//                                            }
//                                        }, label: {
//                                            HStack {
//                                                Text(tempNotificationSettings.selectedSound.localizedString())
//                                                    .font(.headline)
//                                                    .bold()
//                                                    .foregroundColor(.white)
//                                                    .padding()
//                                                Spacer()
//                                                Image(systemName: "chevron.right")
//                                                    .foregroundColor(.white)
//                                                    .font(Font.headline.weight(.bold))
//                                                    .flipsForRightToLeftLayoutDirection(true)
//                                                    .padding()
//                                            }
//                                        })
//                                        .buttonStyle(ScalingButtonStyle())
//                                    }
//                                } // athan sounds group
//
//
//
//                                Group {
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Notifications and customizations")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//                                            .padding(.top)
//                                        Divider()
//                                            .background(Color.white)
//                                    }
//
//                                    ForEach(0..<6) { pIndex in
//                                        Button(action: {
//                                            withAnimation {
//                                                //                                            activeSection = .Prayer
//                                                settingsState.activeState = .Prayer
//                                            }
//                                        }, label: {
//                                            HStack {
//                                                Text("\(Prayer(index: pIndex).stringValue())")
//                                                    .font(.headline)
//                                                    .bold()
//                                                    .foregroundColor(.white)
//                                                    .padding()
//                                                Spacer()
//                                                Image(systemName: "chevron.right")
//                                                    .foregroundColor(.white)
//                                                    .font(Font.headline.weight(.bold))
//                                                    .flipsForRightToLeftLayoutDirection(true)
//                                                    .padding()
//                                            }
//                                        })
//                                        .buttonStyle(ScalingButtonStyle())
//                                        .id("\(Prayer(index: pIndex).stringValue())")
//                                    }
//                                }
//
//                                Group {
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text("Use Arabic Language")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//                                            .padding(.top)
//                                        Divider()
//                                            .background(Color.white)
//                                    }
//
//                                    Button(action: {
//                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
//                                    }, label: {
//                                        HStack {
//                                            Text("Change Language")
//                                                .font(.headline)
//                                                .bold()
//                                                .foregroundColor(.white)
//                                                .padding()
//                                            Spacer()
//                                            Image(systemName: "globe")
//                                                .foregroundColor(.white)
//                                                .font(Font.headline.weight(.bold))
//                                                .padding()
//                                        }
//                                    })
//                                    .buttonStyle(ScalingButtonStyle())
//
//                                    //                                    HStack {
//                                    //                                        Toggle(isOn: AthanDefaults.arabicMode, label: {
//                                    //                                            Text("Arabic Mode")
//                                    //                                                .font(.headline)
//                                    //                                                .bold()
//                                    //                                                .foregroundColor(.white)
//                                    //
//                                    //                                        })
//                                    //                                    }
//                                    //                                    .padding()
//
//                                }
//
//                                Button(action: {
//
//                                }, label: {
//                                    HStack() {
//                                        Spacer()
//                                        Text("Rate Athan Utility!")
//                                            .font(.headline)
//                                            .bold()
//                                            .foregroundColor(.white)
//                                            .padding()
//                                        Spacer()
//                                    }
//                                })
//                                .buttonStyle(ScalingButtonStyle())
//                            }
//
//                        }
//                        .padding()
//                        .padding()
//                    }
//                }
//                .edgesIgnoringSafeArea(.all)
//
//
//
//
//
//                Divider()
//                    .background(Color(.lightText))
//
//                HStack(alignment: .center) {
//                    Spacer()
//                    Button(action: {
//                        // tap vibration
//                        let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//                        lightImpactFeedbackGenerator.impactOccurred()
//                        withAnimation {
//                            parentSession = .Main // tell parent to go back
//                            //                            settingsState.activeState = .Main
//                        }
//                    }) {
//                        Text("Done")
//                            .foregroundColor(Color(.lightText))
//                            .font(Font.body.weight(.bold))
//                    }
//                }
//                .padding()
//                .padding([.leading, .trailing, .bottom])
//                //                    .padding([.leading, .trailing, .bottom])
//            }
//            //                .edgesIgnoringSafeArea(.all)
//            //                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
//            .frame(width: g.size.width)
//            .padding([.top])
//        }
//    }
//}
