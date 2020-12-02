//
//  PrayerSettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/2/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct PrayerSettingsView: View {
        
    var body: some View {
        Text("test")
    
    }
}

@available(iOS 13.0.0, *)
struct PrayerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            PrayerSettingsView()
            
        }
            .environmentObject(ObservableAthanManager.shared)
            .previewDevice("iPhone Xs")
    }
}
