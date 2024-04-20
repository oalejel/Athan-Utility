//
//  AthanPlayView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/1/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

struct AthanPlayView: View, Equatable {
    static func == (lhs: AthanPlayView, rhs: AthanPlayView) -> Bool {
        return lhs.currentPrayer == rhs.currentPrayer && lhs.playing == rhs.playing
    }
    
    @Binding var currentPrayer: Prayer?
    @State var playing = false
    @State var lastPlayDate = Date().addingTimeInterval(-100)
        
    var body: some View {
        
        Button(action: {
            if playing {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { t1 in
                    playing = false
                    NoteSoundPlayer.fadeAndStopAudio()
                }
            }
        }, label: {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundColor(Color(.lightText))
        })
        .opacity(playing ? 1 : 0)
        .animation(.easeInOut)
        .onValueChanged(currentPrayer) { x in
            // if fajr happened 30 seconds ago, time interval since now will be -30
            // we want a time interval mag greater than 60 to return false
            
            // non-nil and not playing (not that it would be getting an update while playing in most circumstances
            
            let timeSinceLastPlay = Date().timeIntervalSince(lastPlayDate)
            if let current = currentPrayer, !playing, timeSinceLastPlay > 60 {
                // get date for newly begun prayer
                let date = AthanManager.shared.guaranteedCurrentPrayerTime()
                // if less than a second since start and allowing 0.5 seconds early, then
                let timeSince = -1 * date.timeIntervalSinceNow
                if timeSince < 60 && timeSince > -0.5 {
                    
                    // get duration of audio we start to play
                    let duration = NoteSoundPlayer.playFullAudio(for: NotificationSettings.shared.selectedSound.rawValue)
                    
                    // dont display controls for anything for very short beeps
                    if duration < 3 { return }
                    
                    // run timer to make visible in 0.05 seconds and save the fact that we just played this salah
                    // then another timer to hide the view after duration
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { t1 in
                        playing = true
                        lastPlayDate = Date()
                        Timer.scheduledTimer(withTimeInterval: TimeInterval(duration), repeats: false) { t2 in
                            playing = false
                            NoteSoundPlayer.fadeAndStopAudio()
                        }
                    }
                }
            }
        }
//        Image(systemName: "pause.fill")
//        Image(systemName: "play.fill"
        
        
    }
}
