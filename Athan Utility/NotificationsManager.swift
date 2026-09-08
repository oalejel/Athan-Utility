//
//  NotificationsManager.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/15/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import NotificationCenter
import UserNotifications
import Adhan
import CoreLocation.CLLocation
import WatchConnectivity

// could make this an extension of athan manager tbh. uses too many heavy lifting helpers from athan manager?..
// but... not necessarily the case that all devices using athan amanger will be notification capabale

// Managest loading and storing of settings for notitification selection and sounds to be used for notifications
class NotificationsManager {
    
//    static func calculateTimes(referenceDate: Date, coordinate: CLLocationCoordinate2D, calculationMethod: CalculationMethod, madhab: Madhab) -> PrayerTimes? {
//
//        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
//        let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
//        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
//
//        var params = calculationMethod.params
//        params.madhab = madhab
//
//        if let prayers = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params) {
////            let formatter = DateFormatter()
////            formatter.timeStyle = .medium
////            formatter.timeZone = TimeZone.current
//
////            print("fajr \(formatter.string(from: prayers.fajr))")
////            print("sunrise \(formatter.string(from: prayers.sunrise))")
////            print("dhuhr \(formatter.string(from: prayers.dhuhr))")
////            print("asr \(formatter.string(from: prayers.asr))")
////            print("maghrib \(formatter.string(from: prayers.maghrib))")
////            print("isha \(formatter.string(from: prayers.isha))")
//            return prayers
//        }
//        return nil
//    }
    
    // generate as many notificiations as possible for the prayer
    static func createNotifications(coordinate: CLLocationCoordinate2D,
                                    calculationMethod: CalculationMethod,
                                    madhab: Madhab,
                                    noteSettings: NotificationSettings,
                                    shortLocationName: String) {

        // No notification permission prompt / scheduling during snapshot runs.
        // (Inline check — this file is shared with the widget/Siri targets that
        // don't compile SnapshotSupport.)
        if CommandLine.arguments.contains("-UITEST_DEMO") || CommandLine.arguments.contains("-UITEST_INTRO") { return }

        let center = UNUserNotificationCenter.current()
        // Deliberately NOT requestAuthorization() here. Scheduling reruns on every
        // location/settings change, so prompting inline meant the system alert fired
        // the instant the user finished picking their city — before they had seen a
        // single prayer time. NotificationPermission owns the prompt now (5s after the
        // main UI first appears); this path only schedules when permission already exists.
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: break
            default:
                print("notification permission not granted yet — skipping scheduling")
                return
            }
            center.getPendingNotificationRequests { (notes) in
                print("pending notes: ")
                print(notes.count)

                // Only clear our own prayer-time notifications here, not every pending
                // request — a blanket removeAllPendingNotificationRequests() would also
                // wipe out unrelated scheduled notifications (e.g. the "explore settings"
                // nudge) every time prayer times regenerate, which happens often.
                let prayerNoteIDs = notes
                    .map { $0.identifier }
                    .filter { $0.hasPrefix("standard_note_") || $0.hasPrefix("pre_note_") }
                center.removePendingNotificationRequests(withIdentifiers: prayerNoteIDs)

                // only remove delivered if we open the main app
                if let bundleID = Bundle.main.bundleIdentifier, bundleID == "com.omaralejel.Athan-Utility" {
                    center.removeAllDeliveredNotifications()
                }
                
//                let noteSoundFilename = Settings.
                let noteSoundFilename = noteSettings.selectedSound.filename()
                let df = DateFormatter()
//                df.dateFormat = "h:mm"
                df.timeStyle = .short
                #warning("change this to use a number formatter or something")
                
                // loop over 5 days worth of times
                var noteCount = 0
                let lastOffset = 4
                for dayOffset in 0..<(lastOffset + 1) {
                    let calcDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
                    let isFinalDayOfNotifications = lastOffset == dayOffset
//                    print("making notifications for \(calcDate)")
//                    guard let times = calculateTimes(referenceDate: calcDate, coordinate: coordinate, calculationMethod: calculationMethod, madhab: madhab) else {
//                        print("encountered nil calculating times for notifications")
//                        return
//                    }
                    
                    // prayerDate below is computed IN this timezone (calculateTimes takes
                    // it as customTimeZone). The trigger's calendar components must be
                    // extracted using the SAME zone — using the device's ambient
                    // Calendar.current instead (as this used to) silently fires prayer
                    // notifications at the wrong wall-clock time whenever the location's
                    // timezone differs from the device's current one: e.g. a manually-set
                    // location in a different zone than the phone is physically in, or the
                    // device's system timezone changing (travel) between when this was
                    // scheduled and when it fires. A reminder computed as "30 min before a
                    // 5:11 AM Fajr in America/New_York" got its hour/minute reinterpreted
                    // against whatever zone Calendar.current happened to be — landing on a
                    // completely different prayer's time of day if the offset was large.
                    var locationCalendar = Calendar.current
                    locationCalendar.timeZone = AthanManager.shared.locationSettings.timeZone
                    guard let times = AthanManager.shared.calculateTimes(referenceDate: calcDate, customCoordinate: coordinate, customTimeZone: AthanManager.shared.locationSettings.timeZone, adjustments: noteSettings.adjustments()) else {
                        print("encountered nil calculating times for notifications")
                        return
                    }
                    
                    // times the day after the current iteration of times
                    // used to calculate qiyam time
                    let sequentialDate = Calendar.current.date(byAdding: .day, value: dayOffset + 1, to: Date())!
                    guard let sequentialDayTimes = AthanManager.shared.calculateTimes(referenceDate: sequentialDate, customCoordinate: coordinate, customTimeZone: AthanManager.shared.locationSettings.timeZone, adjustments: noteSettings.adjustments()) else {
                        print("encountered nil calculating sequential day times for notifications")
                        return
                    }
                    
                    for p in Prayer.allCases {
                        let setting = noteSettings.settings[p]!
                        let prayerDate = times.time(for: p)

                        // Today's already-passed prayers must not be scheduled. A
                        // UNCalendarNotificationTrigger whose date is in the past fires
                        // IMMEDIATELY, so rescheduling — which happens on every settings
                        // change, including toggling a single bell — delivered an athan
                        // for a prayer that was hours ago. Skips the pre-prayer reminder
                        // below too, since that fires even earlier.
                        guard prayerDate > Date() else { continue }

                        let dateString = df.string(from: prayerDate)
                        
                        // The object that stores text and sound for a note
                        let noteContent = UNMutableNotificationContent()
                        noteContent.categoryIdentifier = "athan"
                        
                        // schedule a normal if settings allow
                        if setting.athanAlertEnabled { // note: will always have athan alert enabled if reminder enabled
                            if setting.athanSoundEnabled, let noteSoundFilename = noteSoundFilename {
                                var soundFileWithSuffix = noteSoundFilename
                                if setting.playExtendedSound == true {
                                    soundFileWithSuffix += "-30.caf"
                                } else {
                                    soundFileWithSuffix += "-preview.caf"
                                }
                                // TODO: support separate fajr athan
                                let soundName = UNNotificationSoundName(rawValue: soundFileWithSuffix)
                                noteContent.sound = UNNotificationSound(named: soundName)
                            } else { // always play default sound. user can use ios deliver quietly if they want to
                                noteContent.sound = .default
                            }
                            
                            var alertString = ""
                            // finalFlag indicates that we have reached the limit for stored
                            // local notifications, and should let the user know
                            if isFinalDayOfNotifications && p == .isha {
                                let alertAndReopenMessage = Strings.reopenNotificationMessage
                                alertString = String(format: alertAndReopenMessage, p.localizedOrCustomString(), dateString)
                            } else {
                                // Reverting decision to tell users to pray isha before a certain time
                                // This is not a majority position and users should know it themselves.
                                
                                // Alternative string stores a shorter version of the location
                                // in order to show "San Francisco" instead of "San Francisco, CA, USA"
                                let noteMessage = Strings.standardNotificationMessage
                                alertString = String(format: noteMessage,
                                                     p.localizedOrCustomString(), shortLocationName, dateString)
                            }
                            print(alertString)
                            
                            // set the notification body
                            noteContent.body = alertString
                            
                            // create a trigger with the correct date
                            let dateComp = locationCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: prayerDate)
                            let noteTrigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: false)
                            // create request, and make sure it is added on the main thread (there was an issue before with the old UINotificationCenter. test for whether this is needed)
                            let noteID = "standard_note_\(dateComp.day!)_\(dateComp.hour!)_\(dateComp.minute!)"
                            let noteRequest = UNNotificationRequest(identifier: noteID, content: noteContent, trigger: noteTrigger)
                            center.add(noteRequest) {_ in /*print(p.localizedOrCustomString(), "d: ", dateComp.day!, " \(dateComp.hour!):\(dateComp.minute!)")*/ }
                            noteCount += 1
                        }
                        
                        // if user would ALSO like to get notified 15 minutes prior
                        if setting.reminderAlertEnabled {
                            // adding a reminder for 15 minutes before the actual prayer time
                            
                            // if the offset is too large, then default to 15 minutes
                            var minuteOffset = setting.reminderOffset
                            if p.previous() != .isha { // almost always safe to assume time between isha and fajr is large enough
                                let previousDate = times.time(for: p.previous())
                                let interval = Int(prayerDate.timeIntervalSince(previousDate) / 60)
                                if interval < minuteOffset {
                                    if interval > 15 {
                                        minuteOffset = 15
                                    } else {
                                        minuteOffset = interval / 2
                                    }
                                }
                            }
                           
                            let preNoteContent = UNMutableNotificationContent()
                            preNoteContent.categoryIdentifier = "reminder"
                            let preDate = Calendar.current.date(byAdding: .minute, value: -1 * minuteOffset, to: prayerDate)!
                            preNoteContent.userInfo = ["intendedFireDate": preDate]
                            let preNoteComponents = locationCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: preDate)
                            
                            let preNoteTrigger = UNCalendarNotificationTrigger(dateMatching: preNoteComponents, repeats: false)
                            
                            //use a standard note tone when giving a 15m reminder
//                            if setting.athanSoundEnabled {
                            preNoteContent.sound = .default
//                            }
                            
                            let localizedMinutes = NumberFormatter.localizedString(from: NSNumber(value: setting.reminderOffset), number: .none)
                            let reminderMessage = Strings.reminderNotificationMessage
                            var alertString = String(format: reminderMessage,
                                                 localizedMinutes,
                                                 p.localizedString(),
                                                 shortLocationName,
                                                 dateString)
                            
                            preNoteContent.body = alertString
                            
                            // hold onto the intended date for notification so that local notes can be handled in an accurate alert view
                            preNoteContent.userInfo["intendedDate"] = prayerDate
                            
                            //create a unique time based id
                            let preNoteID = "pre_note_\(preNoteComponents.day!)_\(preNoteComponents.hour!)_\(preNoteComponents.minute!)"
                            
                            let preNoteRequest = UNNotificationRequest(identifier: preNoteID, content: preNoteContent, trigger: preNoteTrigger)
                            center.add(preNoteRequest) {_ in /*print("R: ", p.localizedString(), "d: ", preNoteComponents.day!, " \(preNoteComponents.hour!):\(preNoteComponents.minute!)")*/ }
                            noteCount += 1
                        }
                    }
                }
                print(noteCount, " NOTIFICATIONS SUBMITTED TO NC")
            }
        }
    }

    /// Prints the live reminderOffset/enabled flags for every prayer plus every pending
    /// local notification's identifier, next fire date, and body — the ground truth for
    /// diagnosing a notification that fired with the wrong content or at the wrong time,
    /// since neither is otherwise visible outside Settings > Notifications' summary UI.
    /// Called from Debug Tools on demand, and once automatically at launch in DEBUG builds.
    static func dumpPendingNotifications() {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium

        let loc = AthanManager.shared.locationSettings
        print("=== LocationSettings ===")
        print("name=\(loc.locationName) coord=\(loc.locationCoordinate) tz=\(loc.timeZone.identifier) useCurrentLocation=\(loc.useCurrentLocation) deviceTZ=\(TimeZone.current.identifier)")

        // Deliberately String(describing:) rather than .localizedString() — that extension
        // lives in CalculationMethod+Extensions.swift, which is main-app-target-only, while
        // this file also compiles into the Siri and widget extension targets.
        let prayer = AthanManager.shared.prayerSettings
        print("=== PrayerSettings ===")
        print("method=\(String(describing: prayer.calculationMethod)) madhab=\(String(describing: prayer.madhab)) latitudeRule=\(String(describing: prayer.latitudeRule))")

        print("=== FajrAlarmSettings ===")
        print("enabled=\(FajrAlarmSettings.shared.enabled)")

        print("=== WCSession (Watch) ===")
        let session = WCSession.isSupported() ? WCSession.default : nil
        print("supported=\(WCSession.isSupported()) isPaired=\(session?.isPaired ?? false) isWatchAppInstalled=\(session?.isWatchAppInstalled ?? false) isReachable=\(session?.isReachable ?? false) activationState=\(String(describing: session?.activationState.rawValue))")

        print("=== NotificationSettings.shared.settings (offset in minutes) ===")
        for p in Prayer.allCases {
            guard let s = NotificationSettings.shared.settings[p] else { continue }
            print("\(p.stringValue()): athanAlertEnabled=\(s.athanAlertEnabled) reminderAlertEnabled=\(s.reminderAlertEnabled) reminderOffset=\(s.reminderOffset) athanOffset=\(s.athanOffset ?? 0)")
        }

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let sorted = requests.sorted { lhs, rhs in
                let l = (lhs.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
                let r = (rhs.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
                return l < r
            }
            print("=== \(sorted.count) pending notification requests ===")
            for r in sorted {
                let fireDate = (r.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                let fireDateStr = fireDate.map { df.string(from: $0) } ?? "unknown"
                print("[\(r.identifier)] fires \(fireDateStr) — \(r.content.body)")
            }
        }
    }
}

