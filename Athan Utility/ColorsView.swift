//
//  ColorsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct ColorsView: View {
    
    #warning("make sure updating this value changes earlier settings?")
    @Binding var tempAppearanceSettings: AppearanceSettings
    @Binding var activeSection: SettingsSectionType
    
    @State var isDynamic = false
    
    //    @State var dynamicDict: [Prayer:(UIColor, UIColor)] = [:]
    @State var nilColor1: Color = .white
    @State var nilColor2: Color = .white
    @State var fajrColor1: Color = .white
    @State var fajrColor2: Color = .white
    @State var sunriseColor1: Color = .white
    @State var sunriseColor2: Color = .white
    @State var dhuhrColor1: Color = .white
    @State var dhuhrColor2: Color = .white
    @State var asrColor1: Color = .white
    @State var asrColor2: Color = .white
    @State var maghribColor1: Color = .white
    @State var maghribColor2: Color = .white
    @State var ishaColor1: Color = .white
    @State var ishaColor2: Color = .white
    
    @State var selectedPreviewPrayer = AthanManager.shared.currentPrayer ?? .fajr
    @State var previewGradientOpacity = 0.0
    @State var previewGradient = Gradient(colors: [])
    
    @State private var firstPlane: Bool = true
    @State private var gradientA: [Color] = [.red, .purple]
    @State private var gradientB: [Color] = [.red, .purple]
    
    @State var ignoreOnChange1 = 0 // used to ignore first erronenous update of color pickers
    @State var ignoreOnChange2 = 0
    
//    let x: Int = {
//        UISegmentedControl.appearance().setTitleTextAttributes([:], for: .normal)
//        UISegmentedControl.appearance().setTitleTextAttributes([:], for: .selected)
//        return 0
//    }()
    
    func adjustGradient(gradient: [Color]) {
        gradientA = gradient
        gradientB = gradient
        //        if firstPlane {
        //            gradientA = gradient
        //        }
        //        else {
        //            gradientB = gradient
        //        }
    }
    
    func setGradient(gradient: [Color]) {
        if firstPlane {
            gradientB = gradient
        }
        else {
            gradientA = gradient
        }
        firstPlane = !firstPlane
    }
    
    func copyFromTempSettings() {
        isDynamic = tempAppearanceSettings.isDynamic
        
        // prepare preview gradient behind the picker
        let startColors = tempAppearanceSettings.colors(for: isDynamic ? selectedPreviewPrayer : nil)
        
        // copy current prayer last
        (nilColor1, nilColor2) = tempAppearanceSettings.colors(for: nil)
        (fajrColor1, fajrColor2) = tempAppearanceSettings.colors(for: .fajr)
        (sunriseColor1, sunriseColor2) = tempAppearanceSettings.colors(for: .sunrise)
        (dhuhrColor1, dhuhrColor2) = tempAppearanceSettings.colors(for: .dhuhr)
        (asrColor1, asrColor2) = tempAppearanceSettings.colors(for: .asr)
        (maghribColor1, maghribColor2) = tempAppearanceSettings.colors(for: .maghrib)
        (ishaColor1, ishaColor2) = tempAppearanceSettings.colors(for: .isha)
//        if isDynamic {
//            switch selectedPreviewPrayer {
//            case .fajr: fajrColor1 = tempAppearanceSettings.colors(for: .fajr).0.opacity(0.999999)
//            case .sunrise: sunriseColor1 = tempAppearanceSettings.colors(for: .sunrise).0.opacity(0.999999)
//            case .dhuhr: dhuhrColor1 = tempAppearanceSettings.colors(for: .dhuhr).0.opacity(0.999999)
//            case .asr: asrColor1 = .red
//            case .maghrib: maghribColor1 = tempAppearanceSettings.colors(for: .maghrib).0.opacity(0.999999)
//            case .isha: ishaColor1 = tempAppearanceSettings.colors(for: .isha).0.opacity(0.999999)
//            }
//        }
        
        gradientA = [startColors.0, startColors.1]
        gradientB = [startColors.0, startColors.1]
    }
    
    var body: some View {
        
        ZStack {
            LinearGradient(gradient: Gradient(colors: gradientA), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .opacity(previewGradientOpacity)
            LinearGradient(gradient: Gradient(colors: gradientB), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .opacity(previewGradientOpacity)
                .opacity(firstPlane ? 0 : 1)
            
            
            VStack(alignment: .leading) {
                Group {
                    VStack(alignment: .leading, spacing: 0) {
                    Text(Strings.colors)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding([.top])
                        .onAppear {
                            // initial setup on first appearance
                            copyFromTempSettings()
                            withAnimation(Animation.linear(duration: 0.5).delay(1)) {
                                previewGradientOpacity = 1
                            }
                        }
                        
                    Text(Strings.colorDescription)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .font(.caption)
                        .foregroundColor(Color(.lightText))
                        .padding(.bottom)

                    
                    Picker(selection: $isDynamic.animation(.linear), label: Text("Picker"), content: {
                        ForEach([true, false], id: \.self) { dynamic in
                            Text(dynamic ? Strings.dynamic : Strings.static)
                                .foregroundColor(.red)
                        }
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
                    
                    Divider()
                        .background(Color.white)
                }
                .padding([.leading, .trailing])
                .padding([.leading, .trailing])
                
                
                ScrollView(showsIndicators: true) {
                    Divider()
                        .background(Color.init(.sRGB, white: 1, opacity: 0.0000001))
                        .opacity(0)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        let color1Bindings = [$fajrColor1, $sunriseColor1, $dhuhrColor1, $asrColor1, $maghribColor1, $ishaColor1]
                        let color2Bindings = [$fajrColor2, $sunriseColor2, $dhuhrColor2, $asrColor2, $maghribColor2, $ishaColor2]
                        if #available(iOS 14.0, *) {
                            if isDynamic {
                                ForEach(Prayer.allCases, id: \.self) { p in
                                    let c1 = (color1Bindings[p.rawValue()]).wrappedValue
                                    let c2 = (color2Bindings[p.rawValue()]).wrappedValue
                                    
                                    HStack {
//                                        Image(systemName: "arrow.up.backward")
//                                            .foregroundColor(.white)
//                                            .padding(.leading)
                                            
                                        ZStack {
                                        
                                        ColorPicker(selection: color1Bindings[p.rawValue()], supportsOpacity: false) {}
                                            .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                            .labelsHidden()
                                            .padding()
                                            .onChange(of: c1) { v in
//                                                print("on change 1 \(p)")
                                                // if we dont get a suspicious start, do not worry about ignore count
                                                if ignoreOnChange1 < 8 { // threshold trick to avoid strange onChange calls when first appearing
                                                    let rgb = UIColor(c1).rgb
                                                    if rgb.0 + rgb.1 + rgb.2 < 2.8 {
                                                        ignoreOnChange1 = 8
                                                    } else {
                                                        ignoreOnChange1 += 1
                                                        return
                                                    }
                                                }
                                                selectedPreviewPrayer = p
                                                // using the local c1s onChange leads to using stale values
                                                let cc1 = (color1Bindings[p.rawValue()]).wrappedValue
                                                let cc2 = (color2Bindings[p.rawValue()]).wrappedValue
                                                
                                                if isDynamic {
                                                    adjustGradient(gradient: [cc1, cc2])
                                                }
                                            }
                                            .onAppear {
                                                if p == .fajr { // set the current gradient to fajr's
                                                    let c1 = (color1Bindings[selectedPreviewPrayer.rawValue()]).wrappedValue
                                                    let c2 = (color2Bindings[selectedPreviewPrayer.rawValue()]).wrappedValue

                                                    withAnimation(.easeIn) {
                                                        setGradient(gradient: [c1, c2])
                                                    }
                                                }
                                            }
                                            
//                                            Image(systemName: "pencil")
//                                                .foregroundColor(.white)
//                                                .font(.subheadline)
//                                                .allowsHitTesting(false)
                                        }
                                        
                                        Spacer()
                                        Text(p.localizedOrCustomString())
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding()
                                        Spacer()
                                        
                                        ZStack {
                                        ColorPicker(selection: color2Bindings[p.rawValue()], supportsOpacity: false) {}
                                            .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                            .labelsHidden()
                                            .padding()
                                            .onChange(of: c2) { v in
//                                                print("on change 2 \(p)")
                                                if ignoreOnChange2 < 8 {
                                                    let rgb = UIColor(c2).rgb
                                                    if rgb.0 + rgb.1 + rgb.2 < 2.8 {
                                                        ignoreOnChange2 = 8
                                                    } else {
                                                        ignoreOnChange2 += 1
                                                        return
                                                    }
                                                }
                                                selectedPreviewPrayer = p
                                                // using the local c1s onChange leads to using stale values
                                                let cc1 = (color1Bindings[p.rawValue()]).wrappedValue
                                                let cc2 = (color2Bindings[p.rawValue()]).wrappedValue
                                                if isDynamic {
                                                    adjustGradient(gradient: [cc1, cc2])
                                                }
                                            }
//                                            Image(systemName: "pencil")
//                                                .foregroundColor(.white)
//                                                .font(.subheadline)
//                                                .allowsHitTesting(false)

                                        }

                                        
//                                        Image(systemName: "arrow.down.right")
//                                            .foregroundColor(.white)
//                                            .padding(.trailing)
                                    }
                                    .background(
                                        Rectangle()
                                            .foregroundColor(Color.init(.sRGB, white: 1, opacity: 0.1))
                                            .cornerRadius(12)
                                            .onTapGesture {
                                                selectedPreviewPrayer = p
                                                withAnimation(.easeIn) {
                                                    setGradient(gradient: [c1, c2])
                                                }
                                            }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke((selectedPreviewPrayer == p) ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                }
                                .transition(.opacity)
                            } else {
                                HStack {
//                                    Image(systemName: "arrow.up.backward")
//                                        .foregroundColor(.white)
//                                        .padding(.leading)
                                    ZStack {
                                    ColorPicker(selection: $nilColor1, supportsOpacity: false) {}
                                        .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                        .labelsHidden()
                                        .padding()
                                        .onChange(of: nilColor1) { v in
                                            //                                            print("on change 1")
                                            // if we dont get a suspicious start, do not worry about ignore count
                                            if ignoreOnChange1 < 8 { // threshold trick to avoid strange onChange calls when first appearing
                                                let rgb = UIColor(nilColor1).rgb
                                                if rgb.0 + rgb.1 + rgb.2 < 2.8 {
                                                    ignoreOnChange1 = 8
                                                } else {
                                                    ignoreOnChange1 += 1
                                                    return
                                                }
                                            }
                                            
                                            // using the local c1s onChange leads to using stale values
                                            if !isDynamic {
                                                adjustGradient(gradient: [nilColor1, nilColor2])
                                            }
                                        }
//                                        Image(systemName: "pencil")
//                                            .foregroundColor(.white)
//                                            .font(.subheadline)
//                                            .allowsHitTesting(false)
                                    }
                                    
                                    Spacer()
                                    Text(Strings.allPrayers)
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding()
                                    Spacer()
                                    
                                    ZStack {
                                    ColorPicker(selection: $nilColor2, supportsOpacity: false) {}
                                        .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                        .labelsHidden()
                                        .padding()
                                        .onChange(of: nilColor2) { v in
                                            if ignoreOnChange2 < 8 {
                                                let rgb = UIColor(nilColor2).rgb
                                                if rgb.0 + rgb.1 + rgb.2 < 2.8 {
                                                    ignoreOnChange2 = 8
                                                } else {
                                                    ignoreOnChange2 += 1
                                                    return
                                                }
                                            }
                                            // using the local c1s onChange leads to using stale values
                                            if !isDynamic {
                                                adjustGradient(gradient: [nilColor1, nilColor2])
                                            }
                                        }
//                                        Image(systemName: "pencil")
//                                            .foregroundColor(.white)
//                                            .font(.subheadline)
//                                            .allowsHitTesting(false)
                                    }
                                        
                                    
//                                    Image(systemName: "arrow.down.right")
//                                        .foregroundColor(.white)
//                                        .padding(.trailing)
                                }
                                .flipsForRightToLeftLayoutDirection(false)
                                
                                .background(
                                    Rectangle()
                                        .foregroundColor(Color.init(.sRGB, white: 1, opacity: 0.1))
                                        .cornerRadius(12)
                                        .onAppear {
                                            withAnimation(.easeIn) {
                                                setGradient(gradient: [nilColor1, nilColor2])
                                            }
                                        }
                                )
                                .transition(.opacity)
                            }
                        } else {
                            // Fallback on earlier versions
                            Text(Strings.colorsiOSRequirement)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .font(.headline)
                                .foregroundColor(Color(.lightText))
                                .padding(.top)
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding([.leading, .trailing])
                }
                
                Button(action: {
                    DispatchQueue.main.async {
                        tempAppearanceSettings = AppearanceSettings.defaultSetting()
                        tempAppearanceSettings.isDynamic = isDynamic
                        copyFromTempSettings()
                    }
//                    selectedPreviewPrayer = isDynamic ? selectedPreviewPrayer.next() : nil
                }, label: {
                    HStack {
                        Spacer()
                        Text(Strings.restoreDefaults)
                            .foregroundColor(.white)
                            .bold()
                            .padding([.top, .bottom, .trailing])
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.01)
                        Spacer()
                    }
                    .background(
                        Rectangle()
                            .foregroundColor(.init(.sRGB, white: 1, opacity: 0.2))
                            .cornerRadius(12)
                    )
                })
                .buttonStyle(ScalingButtonStyle())
                .padding([.leading, .trailing])
                .padding([.leading, .trailing])
                
                Spacer()
                
                HStack(alignment: .center) {
                    Spacer()
                    
                    Button(action: {
                        // tap vibration
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        tempAppearanceSettings.isDynamic = isDynamic
                        tempAppearanceSettings.id = AthanManager.shared.appearanceSettings.id + Int(arc4random())
                        if #available(iOS 14.0, *) { #warning("ensure we want to limit this to ios 14+")
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: nil, color1: UIColor(nilColor1).rgbFloat, color2: UIColor(nilColor2).rgbFloat)
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: .fajr, color1: UIColor(fajrColor1).rgbFloat, color2: UIColor(fajrColor2).rgbFloat)
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: .sunrise, color1: UIColor(sunriseColor1).rgbFloat, color2: UIColor(sunriseColor2).rgbFloat)
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: .dhuhr, color1: UIColor(dhuhrColor1).rgbFloat, color2: UIColor(dhuhrColor2).rgbFloat)
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: .asr, color1: UIColor(asrColor1).rgbFloat, color2: UIColor(asrColor2).rgbFloat)
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: .maghrib, color1: UIColor(maghribColor1).rgbFloat, color2: UIColor(maghribColor2).rgbFloat)
                            tempAppearanceSettings.setRGBPairForContext(optionalPrayer: .isha, color1: UIColor(ishaColor1).rgbFloat, color2: UIColor(ishaColor2).rgbFloat)
                        }
                        
                        // user should be able to quickly check widgets to see that the interface changed
                        AthanManager.shared.appearanceSettings = tempAppearanceSettings
                        AthanManager.shared.resetWidgets()
                        withAnimation() {
                            self.activeSection = .General
                        }
                    }) {
                        Text(Strings.done)
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
                }
                .zIndex(3)
                .padding()
                .padding([.leading, .trailing, .bottom])
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct ColorsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            ColorsView(tempAppearanceSettings: .constant(AppearanceSettings.shared), activeSection: .constant(.Colors))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
