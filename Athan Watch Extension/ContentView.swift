//
//  ContentView.swift
//  Athan Watch Extension
//
//  Created by Omar Al-Ejel on 1/6/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan
//import SwiftFX


// note: if user has not set location,
// they should have the opportunity to use their
// current location on their watch and change settings



struct ContentView: View {
    let manager = AthanManager.shared
    @State var progress: Float = 30
    @State var colorSettings = AthanManager.shared.appearanceSettings
    @State var currentPrayer = AthanManager.shared.currentPrayer ?? .isha
    var body: some View {
        // user background gradient is not suitable for text with black background
//        let gradientColors = colorSettings.colors(for: currentPrayer)
        VStack {
            HStack {
                
                Text(currentPrayer.localizedOrCustomString())
                    .font(.largeTitle).bold()
                Spacer()
                ProgressView("", value: progress, total: 100)
                    .labelsHidden()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.red))
                    .foregroundColor(.red)
            }
            .gradientForeground(colors: watchColorsForPrayer(currentPrayer))

            
            Divider()
            List {
                Text("test")
                Text("test")
                Text("test")
            }
            
            Spacer()
        }
    }
    
    func watchColorsForPrayer(_ p: Prayer) -> [Color] {
        switch p {
        case .fajr:
            return [Color.white, .blue]
        case .isha:
            return [Color.white, .purple, .purple]
        default:
            return [Color.white, .blue]
        }
    }
}

extension View {
    public func gradientForeground(colors: [Color]) -> some View {
        self.overlay(LinearGradient(gradient: .init(colors: colors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
            .mask(self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
