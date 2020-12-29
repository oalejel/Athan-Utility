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
    
    @State var selectedPreviewPrayer = AthanManager.shared.currentPrayer
    @State var previewGradientOpacity = 0.0
    @State var previewGradient = Gradient(colors: [])
    
    @State private var firstPlane: Bool = true
    @State private var gradientA: [Color] = [.red, .purple]
    @State private var gradientB: [Color] = [.red, .purple]
    
    @State var ignoreOnChange1 = 0 // used to ignore first erronenous update of color pickers
    @State var ignoreOnChange2 = 0
    
    func adjustGradient(gradient: [Color]) {
        if firstPlane {
            gradientA = gradient
        }
        else {
            gradientB = gradient
        }
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
    
    var body: some View {
        
        ZStack {
            LinearGradient(gradient: Gradient(colors: gradientA), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .opacity(previewGradientOpacity)
            LinearGradient(gradient: Gradient(colors: gradientB), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .opacity(firstPlane ? 0 : 1)
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Colors")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding([.leading, .trailing, .top])
                    .onAppear {
                        // initial setup on first appearance
                        isDynamic = tempAppearanceSettings.isDynamic
                        
                        (nilColor1, nilColor2) = tempAppearanceSettings.colors(for: nil)
                        (fajrColor1, fajrColor2) = tempAppearanceSettings.colors(for: .fajr)
                        (sunriseColor1, sunriseColor2) = tempAppearanceSettings.colors(for: .sunrise)
                        (dhuhrColor1, dhuhrColor2) = tempAppearanceSettings.colors(for: .dhuhr)
                        (asrColor1, asrColor2) = tempAppearanceSettings.colors(for: .asr)
                        (maghribColor1, maghribColor2) = tempAppearanceSettings.colors(for: .maghrib)
                        (ishaColor1, ishaColor2) = tempAppearanceSettings.colors(for: .isha)
                        
                        // prepare preview gradient behind the picker
                        let startColors = tempAppearanceSettings.colors(for: isDynamic ? selectedPreviewPrayer : nil)
                        gradientA = [startColors.0, startColors.1]
                        gradientB = [startColors.0, startColors.1]
                        
                        withAnimation(Animation.linear(duration: 0.5).delay(0.4)) {
                            previewGradientOpacity = 1
                        }
                    }
                    .padding([.leading, .trailing, .top])
                
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker(selection: $isDynamic, label: Text("Picker"), content: {
                            ForEach([true, false], id: \.self) { dynamic in
                                Text(dynamic ? "Dynamic" : "Static")
                            }
                        })
                        .pickerStyle(SegmentedPickerStyle())
                        .labelsHidden()
                        .foregroundColor(.white)
                        let color1Bindings = [$fajrColor1, $sunriseColor1, $dhuhrColor1, $asrColor1, $maghribColor1, $ishaColor1]
                        let color2Bindings = [$fajrColor2, $sunriseColor2, $dhuhrColor2, $asrColor2, $maghribColor2, $ishaColor2]
                        if #available(iOS 14.0, *) {
                            ForEach(Prayer.allCases, id: \.self) { p in
                                let c1 = (color1Bindings[p.rawValue()]).wrappedValue
                                let c2 = (color2Bindings[p.rawValue()]).wrappedValue
                                
                                HStack {
                                    Image(systemName: "arrow.up.backward")
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                    ColorPicker(selection: color1Bindings[p.rawValue()], supportsOpacity: false) {}
                                        .fixedSize()
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // flip to deal with annoying padding inconsistenncy
//                                        .onChange(color1Bindings[p.rawValue()]) { }
                                        .onChange(of: c1) { v in
                                            // if we dont get a suspicious start, do not worry about ignore count
                                            if ignoreOnChange1 < 8 { // threshold trick to avoid strange onChange calls when first appearing
                                                let rgb = UIColor(c1).rgba
                                                if rgb.0 + rgb.1 + rgb.2 < 2.8 {
                                                    ignoreOnChange1 = 8
                                                } else {
                                                    ignoreOnChange1 += 1
                                                    return
                                                }
                                            }
                                            adjustGradient(gradient: [c1, c2])
                                        }
                                    Spacer()
                                    Text(p.localizedString())
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding()
                                    Spacer()
                                    ColorPicker(selection: color2Bindings[p.rawValue()], supportsOpacity: false) {}
                                        .fixedSize()
                                        .onChange(of: c2) { v in
                                            if ignoreOnChange2 < 8 {
                                                let rgb = UIColor(c2).rgba
                                                if rgb.0 + rgb.1 + rgb.2 < 2.8 {
                                                    ignoreOnChange2 = 8
                                                } else {
                                                    ignoreOnChange2 += 1
                                                    return
                                                }
                                            }
                                            adjustGradient(gradient: [c1, c2])
                                        }
                                    
                                    Image(systemName: "arrow.down.right")
                                        .foregroundColor(.white)
                                        .padding(.trailing)
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
                        } else {
                            // Fallback on earlier versions
                            Text("Color customization only available on iOS 14+")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .font(.headline)
                                .foregroundColor(Color(.lightText))
                                .padding(.top)
                        }
                    }
                    .padding()
                    .padding([.leading, .trailing])
                }
                
                Spacer()
                
                HStack(alignment: .center) {
                    Spacer()
                    
                    Button(action: {
                        // tap vibration
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        tempAppearanceSettings.isDynamic = isDynamic
                        withAnimation {
                            self.activeSection = .General
                        }
                    }) {
                        Text("Done")
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
                }
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
