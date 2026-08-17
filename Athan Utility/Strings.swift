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
    static var discoverFeatures = NSLocalizedString("discover_features", value: "Discover Features", comment: "Title for the feature-discovery list (light bulb / settings button)")
    static var recommendedForCountry = NSLocalizedString("recommended_for_country", value: "Recommended for %@", comment: "Intro: the calculation method recommended for the user's country. %@ = country name")
    static var useRecommendedMethod = NSLocalizedString("use_recommended_method", value: "Use recommended: %@", comment: "Intro: apply the recommended calculation method. %@ = method name")

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
    static var acknowledgements = NSLocalizedString("acknowledgements", value: "Acknowledgements", comment: "Button/title for the credits screen listing contributors and libraries")
    static var sendFeedback = NSLocalizedString("Send Feedback", comment: "")
    
    
    static var colorsiOSRequirement = NSLocalizedString("colors.ios.requirement", comment: "")
    
    static var `static` = NSLocalizedString("static", comment: "")
    static var dynamic = NSLocalizedString("dynamic", comment: "")
    static var settings = NSLocalizedString("Settings", comment: "")
    static var rateAthanUtility = NSLocalizedString("Rate Athan Utility!", comment: "")
    
    static var restoreDefaults = NSLocalizedString("restore.defaults", comment: "")
    static var developedBy = NSLocalizedString("Developed by Omar Al-Ejel", comment: "")
    // Mac toast confirmations, shown briefly in the corner of the detail pane when a
    // setting is flipped from the sidebar or the menu bar popover.
    /// Takes the already-localized prayer name rather than a `Prayer`: this file has no
    /// Adhan import, and the caller has the name in hand anyway.
    static func bellToastMessage(prayerName: String, enabled: Bool) -> String {
        let format = enabled
            ? NSLocalizedString("toast_notifications_enabled", value: "%@ notifications enabled",
                                comment: "Brief confirmation; %@ is a prayer name")
            : NSLocalizedString("toast_notifications_disabled", value: "%@ notifications disabled",
                                comment: "Brief confirmation; %@ is a prayer name")
        return String(format: format, prayerName)
    }

    static func silentModeToastMessage(silenced: Bool) -> String {
        silenced
            ? NSLocalizedString("toast_athan_silenced", value: "Athan sounds silenced",
                                comment: "Brief confirmation: notifications will use the system sound")
            : NSLocalizedString("toast_athan_restored", value: "Athan sounds on",
                                comment: "Brief confirmation: notifications will play the athan again")
    }

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
    static var searchCity = NSLocalizedString("Search City", comment: "Short location search field placeholder")
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

    // MARK: - Fajr Alarm (AlarmKit, iOS 26+)
    static var fajrAlarm = NSLocalizedString("Fajr Alarm", comment: "Feature title")
    static var fajrAlarmDescription = NSLocalizedString("fajr.alarm.description", comment: "Long description on the Fajr Alarm settings screen")
    static var fajrAlarmEntryDescription = NSLocalizedString("fajr.alarm.entry.description", comment: "Short description shown beneath the entry row")
    static var fajrAlarmOffsetDescription = NSLocalizedString("fajr.alarm.offset.description", comment: "Explanation of the offset stepper")
    static var fajrAlarmScheduleDescription = NSLocalizedString("fajr.alarm.schedule.description", comment: "Explanation of the schedule window stepper")
    static var fajrAlarmIOS26Required = NSLocalizedString("fajr.alarm.ios26.required", comment: "Shown when the user's iOS version is below 26")
    static var fajrAlarmAuthDenied = NSLocalizedString("fajr.alarm.authorization.denied", comment: "Shown when the user has denied AlarmKit authorization")
    static var fajrAlarmSummaryOff = NSLocalizedString("fajr.alarm.summary.off", comment: "Status shown on the entry row when the feature is disabled")
    static var fajrAlarmStateOn = NSLocalizedString("fajr.alarm.state.on", value: "Alarm On", comment: "Fajr alarm entry row title when the alarm is enabled")
    static var fajrAlarmStateOff = NSLocalizedString("fajr.alarm.state.off", value: "Alarm Off", comment: "Fajr alarm entry row title when the alarm is disabled")
    static var fajrAlarmPermissionNeeded = NSLocalizedString("fajr.alarm.permission.needed", comment: "Short status shown when AlarmKit permission is denied")
    static var fajrAlarmNoDaysSelected = NSLocalizedString("fajr.alarm.no.days", comment: "Warning shown when the alarm is enabled but no weekdays are selected")
    static var fajrAlarmAnchorPrayer = NSLocalizedString("Anchor Prayer", comment: "Label for selecting which prayer the alarm is anchored to")
    static var fajrAlarmOffset = NSLocalizedString("Offset", comment: "Label for the minute offset stepper")
    static var fajrAlarmDays = NSLocalizedString("Days", comment: "Label for the weekday selector")
    static var fajrAlarmSnooze = NSLocalizedString("Snooze", comment: "Label for the snooze toggle")
    static var fajrAlarmScheduleWindow = NSLocalizedString("Schedule Window", comment: "Label for the days-ahead stepper")
    static var fajrAlarmOpenSettings = NSLocalizedString("Open Settings", comment: "Button to open the system Settings app")
    // Format string for the alarm presentation title, e.g. "Fajr Alarm" / "منبّه الفجر".
    // %@ is the localized (or user-custom) prayer name.
    static var fajrAlarmTitleFormat = NSLocalizedString("fajr.alarm.title.format", comment: "%@ is replaced with the prayer name (Fajr or Sunrise)")
    // Format strings. Format specifiers must be preserved in translations.
    static var fajrAlarmOffsetZero = NSLocalizedString("fajr.alarm.offset.zero", comment: "At %@ time — exact offset of zero")
    static var fajrAlarmOffsetAfter = NSLocalizedString("fajr.alarm.offset.after", comment: "%1$d min after %2$@")
    static var fajrAlarmOffsetBefore = NSLocalizedString("fajr.alarm.offset.before", comment: "%1$d min before %2$@")
    static var fajrAlarmSnoozeMinutes = NSLocalizedString("fajr.alarm.snooze.minutes", comment: "%d minute snooze")
    static var fajrAlarmDaysAhead = NSLocalizedString("fajr.alarm.days.ahead", comment: "Next %d alarms — how many upcoming alarms stay scheduled")

    // MARK: - New-features announcement (one-time local notification for existing users)
    static var newFeaturesAnnouncementTitle = NSLocalizedString("new.features.announcement.title", value: "What's New", comment: "Title of the one-time local notification telling existing users about recent updates")
    static var newFeaturesAnnouncementBody = NSLocalizedString("new.features.announcement.body", value: "Check out Athan Utility's latest new features.", comment: "Body of the one-time local notification telling existing users about recent updates")
}
