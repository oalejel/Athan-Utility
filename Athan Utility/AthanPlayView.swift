//
//  AthanPlayView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/1/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct AthanPlayView: View {
    
    
    @State var currentPrayer: Prayer?
    @State var currentPrayerDate: Date
    @State var startPlaying: Bool = false
    
    var body: some View {
        Image(systemName: "stop.fill")
            .foregroundColor(.white)
            .onValueChanged(currentPrayer) { x in
                
            }
//        Image(systemName: "pause.fill")
//        Image(systemName: "play.fill"
        
        
    }
}
