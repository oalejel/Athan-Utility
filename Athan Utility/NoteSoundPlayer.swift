//
//  NoteSoundPlayer.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 5/12/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import UIKit
import AVFoundation
import Combine

/// Notified when a NoteSoundPlayer-managed AVAudioPlayer finishes playing ON ITS OWN
/// (natural completion — NOT a manual stopAudio() call, which AVAudioPlayer doesn't
/// report through this delegate at all). Lets UI (e.g. a Preview/Stop button) know to
/// flip back to its idle state without polling isPlaying().
private final class SoundPlayerDelegateProxy: NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        AthanPlaybackState.shared.isPlayingFullAthan = false
        NoteSoundPlayer.onFinishedPlaying?()
    }
}

/// Whether a full athan is playing right now. Shared and observable because the mute
/// control has to survive the main view being swapped for Settings — it used to keep this
/// in local @State, so switching screens gave the view a new identity, reset the flag, and
/// faded the only stop button out while the athan kept playing.
final class AthanPlaybackState: ObservableObject {
    static let shared = AthanPlaybackState()
    @Published var isPlayingFullAthan = false
    private init() {}
}

class NoteSoundPlayer: NSObject {

    private static var audioPlayer: AVAudioPlayer?
    private static var soundPreviewTimer: Timer?
    private static let delegateProxy = SoundPlayerDelegateProxy()

    /// Fires when playback finishes naturally (not via stopAudio()). Set this before
    /// calling playPreviewAudio/playFullAudio if you need to know when it's done.
    static var onFinishedPlaying: (() -> Void)?

    private static func playAudio(for index: Int, isPreview: Bool, fadeInterval: Int? = nil) -> Float {
        audioPlayer?.stop()

        do {
            if var fileName = NotificationSettings.Sounds(rawValue: index)?.filename() {
                if isPreview { fileName += "-30" }

                if let audioFile = Bundle.main.url(forResource: fileName, withExtension:"caf"), let asset = try? Data(contentsOf: audioFile) {
                    try audioPlayer = AVAudioPlayer(data: asset, fileTypeHint: "caf")
                    audioPlayer?.delegate = delegateProxy
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
        let duration = playAudio(for: index, isPreview: false, fadeInterval: fadeInterval)
        DispatchQueue.main.async { AthanPlaybackState.shared.isPlayingFullAthan = duration >= 3 }
        return duration
    }
    
    static func fadeAndStopAudio() {
        DispatchQueue.main.async { AthanPlaybackState.shared.isPlayingFullAthan = false }
        if audioPlayer?.isPlaying != false {
            audioPlayer?.setVolume(0, fadeDuration: 0.5)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
                audioPlayer?.stop()
            }
            
        }
    }
    
    static func stopAudio() {
        DispatchQueue.main.async { AthanPlaybackState.shared.isPlayingFullAthan = false }
        audioPlayer?.stop()
    }
    
    static func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
}
