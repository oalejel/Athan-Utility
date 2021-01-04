//
//  NoteSoundPlayer.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 5/12/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import UIKit
import AVFoundation

class NoteSoundPlayer: NSObject {
    
    private static var audioPlayer: AVAudioPlayer?
    private static var soundPreviewTimer: Timer?
    
    private static func playAudio(for index: Int, isPreview: Bool, fadeInterval: Int? = nil) -> Float {
        
        audioPlayer?.stop()
        
        do {
            if var fileName = NotificationSettings.Sounds(rawValue: index)?.filename() {
                if isPreview { fileName += "-preview" }
                if let asset = NSDataAsset(name: fileName) {
                    try audioPlayer = AVAudioPlayer(data: asset.data, fileTypeHint: "mp3")
                    // allow audio to play with ringer off
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                    audioPlayer?.play()
                    
                    soundPreviewTimer?.invalidate()
                    if let interval = fadeInterval {
                        soundPreviewTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false) { (timer) in
                            self.audioPlayer?.setVolume(0, fadeDuration: 1)
                        }
                    }
                    if let duration = audioPlayer?.duration {
                        return Float(duration)
                    }
                    return 0
                }
                return 0
            } else {
                AudioServicesPlaySystemSound(1315);
                return 0
            }
        } catch {
            return 0
            //            fatalError("unable to play audio file")
        }
    }
    
    static func playPreviewAudio(for index: Int) {
        let _ = playAudio(for: index, isPreview: true)
    }
    
    // returns duration of audio
    static func playFullAudio(for index: Int, fadeInterval: Int? = nil) -> Float {
        playAudio(for: index, isPreview: false, fadeInterval: fadeInterval)
    }
    
    static func fadeAndStopAudio() {
        if audioPlayer?.isPlaying != false {
            audioPlayer?.setVolume(0, fadeDuration: 0.5)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
                audioPlayer?.stop()
            }
            
        }
    }
    
    static func stopAudio() {
        audioPlayer?.stop()
    }
    
    static func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
}
