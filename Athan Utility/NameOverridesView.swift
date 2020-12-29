//
//  NameOverridesView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct NameOverridesView: View {
    
    #warning("make sure updating this value changes earlier settings?")
    @Binding var tempPrayerSettings: PrayerSettings
    @Binding var activeSection: SettingsSectionType
    
    @State var fajrOverride: String = ""
    @State var sunriseOverride: String = ""
    @State var dhuhrOverride: String = ""
    @State var asrOverride: String = ""
    @State var maghribOverride: String = ""
    @State var ishaOverride: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Custom Salah Names")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .onAppear {
                    // initial setup on first appearance
                }
                .padding([.leading, .trailing, .top])
            
            VStack {
                TextField("test", text: $fajrOverride)
                TextField("test", text: $sunriseOverride)
                TextField("test", text: $dhuhrOverride)
            }

            Spacer()
            
            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    // tap vibration
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

@available(iOS 13.0.0, *)
struct OverridesSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            NameOverridesView(tempPrayerSettings: .constant(PrayerSettings(method: .dubai, madhab: .shafi, customNames: [:])), activeSection: .constant(.Prayer(.fajr)))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
