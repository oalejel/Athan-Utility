//
//  Settings.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 5/9/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import Foundation
import os

class Settings {
    static var notificationUpdatesPending = false
    // filenames without suffix for full sound
    static let SOUND_INDEX_KEY = "SOUND_INDEX_KEY"
    static let noteSoundFileNames = ["DEFAULT", "echo", "makkah", "madina", "alaqsa", "egypt", "abdulbaset", "abdulghaffar"]
    
    static func getSelectedSoundFilename() -> String {
        let selectedSoundIndex = UserDefaults.standard.integer(forKey: SOUND_INDEX_KEY)
        if selectedSoundIndex >= noteSoundFileNames.count {
            if #available(iOS 12.0, *) {
                os_log(.debug, "WARNING: invalid index for selected sound in getSelectedSoundFilename")
            }
        }
        return noteSoundFileNames[selectedSoundIndex % noteSoundFileNames.count]
    }
    
    static func setSelectedSound(for index: Int) {
        if index >= noteSoundFileNames.count {
            if #available(iOS 12.0, *) {
                os_log(.debug, "WARNING: invalid index for selected sound in setSelectedSound")
            }
        }
        UserDefaults.standard.set(index, forKey: SOUND_INDEX_KEY)
    }
}
