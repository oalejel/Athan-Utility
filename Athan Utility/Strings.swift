//
//  Strings.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/29/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation

class Strings {
    static var appearance = NSLocalizedString("Appearance", comment: "")
    static var colors = NSLocalizedString("Colors", comment: "")
    static var customPrayerNames = NSLocalizedString("custom.names", comment: "")
    
    static var customNamesDescription = NSLocalizedString("custom.names.description", comment: "")
    
    static var changeLanguage = NSLocalizedString("Change Language", comment: "")
    
    static var calculationMethod = NSLocalizedString("Calculation Method", comment: "")
    static var calculationDescription = NSLocalizedString("Calculation methods primarily differ in Fajr and Isha sun angles.", comment: "")

    // Calculation-method suggestion popup
    static var adjustMethod = NSLocalizedString("Adjust Method", comment: "Button on the auto-method pill that opens the calculation method picker")
    static func calculationMethodAutoSet(_ methodName: String) -> String {
        String(format: NSLocalizedString("Calculation method set to %@", comment: "Pill shown when the app auto-selects a calculation method for the user's location. %@ is the localized method name."), methodName)
    }
    /// Title line of the bottom-floating popup shown after the method is auto-updated.
    static var updatedCalculationMethod = NSLocalizedString("Updated Calculation Method", comment: "Title of the popup shown when the app automatically updates the calculation method for the user's country.")
    /// Undo button on the method-update popup — reverts to the previous method.
    static var undo = NSLocalizedString("Undo", comment: "Button that reverts the automatic calculation-method change")
    static var ok = NSLocalizedString("OK", comment: "Confirm button on the calculation-method update popup")
    
    static var done = NSLocalizedString("Done", comment: "")
    static var athanSound = NSLocalizedString("athan.sound", comment: "")
    static var athanSoundDescription = NSLocalizedString("Full Athan can play when your iPhone is locked or Athan Utility is opened.", comment: "")
    
    static var madhab = NSLocalizedString("Madhab", comment: "")
    static var methodDescription = NSLocalizedString("The Hanafi madhab uses later Asr times, taking place when the length of a shadow increases in length by double the length of an object since solar noon.", comment: "")
    
    static var left = NSLocalizedString("left", comment: "")
    static var notifications = NSLocalizedString("Notifications", comment: "")
    
    // High latitude rule
    static var highLatitudeRuleTitle = NSLocalizedString("High Latitude Rule", comment: "")
    static var middleOfTheNight = NSLocalizedString("middleOfTheNight", comment: "")
    static var seventhOfTheNight = NSLocalizedString("seventhOfTheNight", comment: "")
    static var twilightAngle = NSLocalizedString("twilightAngle", comment: "")
    static var highLatitudeExplanation = NSLocalizedString("highLatitudeExplanation", comment: "")
    // Intro settings view
    static var calculationPreferences = NSLocalizedString("Calculation Preferences", comment: "")
    static var calculationPreferencesAdvice = NSLocalizedString("Consider setting...", comment: "")
    static var athanPreviewTitle = NSLocalizedString("Athan Preview", comment: "")
    static var editLocationButtonTitle = NSLocalizedString("Edit Location", comment: "")
    
    // prayer settings
    static var athanNotification = NSLocalizedString("Athan Notification", comment: "")
    static var enabled = NSLocalizedString("Enabled", comment: "")
    static var playSound = NSLocalizedString("Play Sound", comment: "")
    static var play30Seconds = NSLocalizedString("Play Longer Athan", comment: "")
    static var playLimitDescription = NSLocalizedString("Extends playback to the maximum iOS limit of ~30 seconds. Open Athan Utility to play the full Athan.", comment: "")
    static var playSoundDescription = NSLocalizedString("Disable \"Play Sound\" to force this prayer's notifications to play the default iOS chime.", comment: "")
    static var athanMinuteOffset = NSLocalizedString("athan.minute.offset", comment: "")
    
    static var reminderNotification = NSLocalizedString("Reminder Notification", comment: "")
    static var reminderMinuteOffset = NSLocalizedString("reminder.minute.offset", comment: "")
    static var minuteCharacter = NSLocalizedString("minute-character", comment: "")
    static var offsetDescription = NSLocalizedString("offset-description", comment: "")

    static var allPrayers = NSLocalizedString("All Prayers", comment: "")
    static var privacyNotes = NSLocalizedString("Privacy Notes", comment: "")
    static var sendFeedback = NSLocalizedString("Send Feedback", comment: "")
    
    
    static var colorsiOSRequirement = NSLocalizedString("colors.ios.requirement", comment: "")
    
    static var `static` = NSLocalizedString("static", comment: "")
    static var dynamic = NSLocalizedString("dynamic", comment: "")
    static var settings = NSLocalizedString("Settings", comment: "")
    static var rateAthanUtility = NSLocalizedString("Rate Athan Utility!", comment: "")
    
    static var restoreDefaults = NSLocalizedString("restore.defaults", comment: "")
    static var developedBy = NSLocalizedString("Developed by Omar Al-Ejel", comment: "")
    // notification messages
    static var standardNotificationMessage = NSLocalizedString("Time for %1$@ in %2$@ [%3$@]", comment: "")
    static var reminderNotificationMessage = NSLocalizedString("%1$@m until %2$@ in %3$@ [%4$@]", comment: "")
    static var reopenNotificationMessage = NSLocalizedString("Time for %1$@ [%2$@]. Please reopen Athan Utility to continue receiving notifications.", comment: "")
    
    static var setLocation = NSLocalizedString("Set Location", comment: "")
    static var setLocationManually = NSLocalizedString("Set Location Manually", comment: "")
    static var useCurrentLocation = NSLocalizedString("Use Current Location", comment: "")
    static var doesNotCollectData = NSLocalizedString("Athan Utility does not collect user data.", comment: "")
    static var locationDisabledAndDoesNotCollectData = NSLocalizedString("Location services are disabled, and can be adjusted in Settings. Athan Utility does not collect user data.", comment: "")
    
    static var locationName = NSLocalizedString("Location Name", comment: "")
    static var locationColon = NSLocalizedString("Location:", comment: "")
    static var showCalendar = NSLocalizedString("Show Calendar", comment: "")
    static var calendar = NSLocalizedString("Calendar", comment: "")
    static var export = NSLocalizedString("Export", comment: "")
    static var colorDescription = NSLocalizedString("Select a color picker to customize gradients.", comment: "")
    
    static var widgetOpenApp = NSLocalizedString("Open Athan Utility to set location.", comment: "")
    
    static var widgetUsefulDescription = NSLocalizedString("Use Athan Widgets to view upcoming salah times at a glance.", comment: "")
    
    // Accessibility strings for Qibla compass
    static var qiblaCompassLabel = NSLocalizedString("acc_qibla_compass_label", comment: "Accessibility label for the Qibla compass")
    static var qiblaCompassHint = NSLocalizedString("acc_qibla_compass_hint", comment: "Accessibility hint describing the haptic behavior")
    static var qiblaAlignedValue = NSLocalizedString("acc_qibla_aligned_value", comment: "Accessibility value when aligned with Qibla")
    static var qiblaTurnRight = NSLocalizedString("acc_qibla_turn_right", comment: "Accessibility direction to turn right")
    static var qiblaTurnLeft = NSLocalizedString("acc_qibla_turn_left", comment: "Accessibility direction to turn left")
    static var degreesAbbrev = NSLocalizedString("acc_degrees_abbrev", comment: "Spoken abbreviation for degrees")
}
