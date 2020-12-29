//
//  NotificationsManager.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/15/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import NotificationCenter
import Adhan
import CoreLocation.CLLocation

// Managest loading and storing of settings for notitification selection and sounds to be used for notifications
class NotificationsManager {
    
    static func calculateTimes(referenceDate: Date, coordinate: CLLocationCoordinate2D, calculationMethod: CalculationMethod, madhab: Madhab) -> PrayerTimes? {
        
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        var params = calculationMethod.params
        params.madhab = madhab
        
        if let prayers = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params) {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.timeZone = TimeZone.current
            
//            print("fajr \(formatter.string(from: prayers.fajr))")
//            print("sunrise \(formatter.string(from: prayers.sunrise))")
//            print("dhuhr \(formatter.string(from: prayers.dhuhr))")
//            print("asr \(formatter.string(from: prayers.asr))")
//            print("maghrib \(formatter.string(from: prayers.maghrib))")
//            print("isha \(formatter.string(from: prayers.isha))")
            return prayers
        }
        return nil
    }
    
    // generate as many notificiations as possible for the prayer
    static func createNotifications(coordinate: CLLocationCoordinate2D,
                                    calculationMethod: CalculationMethod,
                                    madhab: Madhab,
                                    noteSettings: NotificationSettings,
                                    shortLocationName: String) {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, err) in
            if !granted {
                print("user denied notifications")
                return
            }
            center.getPendingNotificationRequests { (notes) in
                print("pending notes: ")
                print(notes.count)
                
                center.removeAllPendingNotificationRequests()
                
//                let noteSoundFilename = Settings.
                let noteSoundFilename = noteSettings.selectedSound.filename()
                let df = DateFormatter()
                df.dateFormat = "h:mm"
                
                // loop over 5 days worth of times
                var noteCount = 0
                let lastOffset = 4
                for dayOffset in 0..<(lastOffset + 1) {
                    let calcDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
                    let isFinalDayOfNotifications = lastOffset == dayOffset
//                    print("making notifications for \(calcDate)")
                    guard let times = calculateTimes(referenceDate: calcDate, coordinate: coordinate, calculationMethod: calculationMethod, madhab: madhab) else {
                        print("encountered nil calculating times for notifications")
                        return
                    }
                    
                    for p in Prayer.allCases {
                        let setting = noteSettings.settings[p]!
                        let prayerDate = times.time(for: p)
                        let dateString = df.string(from: prayerDate)
                        
                        // The object that stores text and sound for a note
                        let noteContent = UNMutableNotificationContent()
                        
                        //schedule a normal if settings allow
                        if setting.athanAlertEnabled { // note: will always have athan alert enabled if reminder enabled
                            if setting.athanSoundEnabled, let noteSoundFilename = noteSoundFilename {
                                let soundName = UNNotificationSoundName(rawValue: "\(noteSoundFilename)-preview.caf")
                                noteContent.sound = UNNotificationSound(named: soundName)
                            } else { // always play default sound. user can use ios deliver quietly if they want to
                                noteContent.sound = .default
                            }
                            
                            var alertString = ""
                            // finalFlag indicates that we have reached the limit for stored
                            // local notifications, and should let the user know
                            if isFinalDayOfNotifications && p == .isha {
                                let localizedAlertString = NSLocalizedString("Time for %1$@ [%2$@]. Please reopen Athan Utility to continue recieving notifications.", comment: "")
                                alertString = String(format: localizedAlertString, p.localizedString(), dateString)
                            } else {
                                // Alternative string stores a shorter version of the location
                                // in order to show "San Francisco" instead of "San Francisco, CA, USA"
                                let localizedStandardNote = NSLocalizedString("Time for %1$@ in %2$@ [%3$@]", comment: "")
                                alertString = String(format: localizedStandardNote,
                                                     p.localizedString(), shortLocationName, dateString)
                            }
                            
                            // set the notification body
                            noteContent.body = alertString
                            
                            // create a trigger with the correct date
                            let dateComp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: prayerDate)
                            let noteTrigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: false)
                            // create request, and make sure it is added on the main thread (there was an issue before with the old UINotificationCenter. test for whether this is needed)
                            let noteID = "standard_note_\(dateComp.day!)_\(dateComp.hour!)_\(dateComp.minute!)"
                            let noteRequest = UNNotificationRequest(identifier: noteID, content: noteContent, trigger: noteTrigger)
                            center.add(noteRequest) {_ in /*print(p.localizedString(), "d: ", dateComp.day!, " \(dateComp.hour!):\(dateComp.minute!)")*/ }
                            noteCount += 1
                        }
                        
                        // if user would ALSO like to get notified 15 minutes prior
                        if setting.reminderAlertEnabled {
                            // adding a reminder for 15 minutes before the actual prayer time
                            let preNoteContent = UNMutableNotificationContent()
                            let preDate = Calendar.current.date(byAdding: .minute, value: -1 * setting.reminderOffset, to: prayerDate)!
                            preNoteContent.userInfo = ["intendedFireDate": preDate]
                            let preNoteComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: preDate)
                            
                            let preNoteTrigger = UNCalendarNotificationTrigger(dateMatching: preNoteComponents, repeats: false)
                            
                            //use a standard note tone when giving a 15m reminder
                            if setting.athanSoundEnabled {
                                preNoteContent.sound = .default
                            }
                            
                            let localizedMinutes = NumberFormatter.localizedString(from: NSNumber(value: setting.reminderOffset), number: .none)
                            let localized15mAlert = NSLocalizedString("%1$@m left til %2$@ in %3$@! [%4$@]", comment: "")
                            var alertString = String(format: localized15mAlert,
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
}

