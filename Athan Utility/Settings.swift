//
//  Settings.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 5/9/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import Foundation
import os
import WidgetKit

class Settings {
    static var notificationUpdatesPending = false
    // filenames without suffix for full sound
    static let SOUND_INDEX_KEY = "SOUND_INDEX_KEY"
    static let CALCULATION_METHOD_KEY = "CALCULATION_METHOD_KEY"
    
    static let noteSoundFileNames = ["DEFAULT", "echo", "makkah", "madina", "alaqsa", "egypt", "abdulbaset", "abdulghaffar"]
    
    static let calculationMethodNames = [
        "Muslim World League",
        "Islamic Society of North America",
        "Egyptian General Authority of Survey",
        "Umm Al-Qura University, Makkah",
        "University of Islamic Sciences, Karachi",
        "Institute of Geophysics, University of Tehran",
        "Shia Ithna-Ashari, Leva Institute, Qum",
        "Gulf Region",
        "Kuwait",
        "Qatar",
        "Majlis Ugama Islam Singapura, Singapore",
        "Union Organization islamic de France",
        "Diyanet İşleri Başkanlığı, Turkey",
        "Spiritual Administration of Muslims of Russia"
    ]
    
    static func getSelectedSoundFilename() -> String {
        let selectedSoundIndex = UserDefaults.standard.integer(forKey: SOUND_INDEX_KEY)
        if selectedSoundIndex >= noteSoundFileNames.count {
            if #available(iOS 12.0, *) {
                os_log(.debug, "WARNING: invalid index for selected sound in getSelectedSoundFilename")
            }
        }
        return noteSoundFileNames[selectedSoundIndex % noteSoundFileNames.count]
    }
    
    static func getSelectedSoundIndex() -> Int {
        return UserDefaults.standard.integer(forKey: SOUND_INDEX_KEY)
    }
    
    static func setSelectedSound(for index: Int) {
        if index >= noteSoundFileNames.count {
            if #available(iOS 12.0, *) {
                os_log(.debug, "WARNING: invalid index for selected sound in setSelectedSound")
            }
        }
        UserDefaults.standard.set(index, forKey: SOUND_INDEX_KEY)
    }
    
    
    static func getCalculationMethodIndex() -> Int {
        // do a check to see if we don't have the setting
        // if this is the case, lets set a default of 1 (ISNA)
        if UserDefaults.standard.string(forKey: CALCULATION_METHOD_KEY) == nil {
            setCalculationMethodIndex(for: 1) // ISNA
        }
        return UserDefaults.standard.integer(forKey: CALCULATION_METHOD_KEY)
    }
    
    static func setCalculationMethodIndex(for index: Int) {
        if index >= calculationMethodNames.count {
            print("WARNING: invalid index for calc method")
            return
        }
        #warning("move this widget update somewhere else")
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "com.omaralejel.Athan-Utility.Athan-Widget")
        } else {
            // Fallback on earlier versions
        }
        UserDefaults.standard.set(index, forKey: CALCULATION_METHOD_KEY)
    }
}
