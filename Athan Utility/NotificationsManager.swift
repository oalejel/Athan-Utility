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

            print("fajr \(formatter.string(from: prayers.fajr))")
            print("sunrise \(formatter.string(from: prayers.sunrise))")
            print("dhuhr \(formatter.string(from: prayers.dhuhr))")
            print("asr \(formatter.string(from: prayers.asr))")
            print("maghrib \(formatter.string(from: prayers.maghrib))")
            print("isha \(formatter.string(from: prayers.isha))")
            return prayers
        }
        return nil
    }
    
    static func createNotifications(coordinate: CLLocationCoordinate2D,
                                                   calculationMethod: CalculationMethod,
                                                   madhab: Madhab,
                                                   prayerSettings: [Prayer:PrayerSetting],
                                                   shortLocationName: String) {
        let center = UNUserNotificationCenter.current()
        let noteSoundFilename = Settings.getSelectedSoundFilename()
        let df = DateFormatter()
        df.dateFormat = "h:mm"
        
        // loop over 5 days worth of times
        let lastOffset = 4
        for dayOffset in 0..<(lastOffset + 1) {
            let calcDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let isFinalDayOfNotifications = lastOffset == dayOffset
            print("making notifications for \(calcDate)")
            guard let times = calculateTimes(referenceDate: calcDate, coordinate: coordinate, calculationMethod: calculationMethod, madhab: madhab) else {
                print("encountered nil calculating times for notifications")
                return
            }
            
            for p in Prayer.allCases {
                let setting = prayerSettings[p]!
                let prayerDate = times.time(for: p)
                let dateString = df.string(from: prayerDate)
                
                // The object that stores text and sound for a note
                let noteContent = UNMutableNotificationContent()
                
                //schedule a normal if settings allow
                if setting.alarmType == .all || setting.alarmType == .noEarly {
                    if setting.soundEnabled {
                        if noteSoundFilename == "DEFAULT" {
                            noteContent.sound = .default
                        } else {
                            let soundName = UNNotificationSoundName(rawValue: "\(noteSoundFilename)-preview.caf")
                            noteContent.sound = UNNotificationSound(named: soundName)
                        }
                    }
                    
                    var alertString = ""
                    // finalFlag indicates that we have reached the limit for stored
                    // local notifications, and should let the user know
                    if isFinalDayOfNotifications {
                        if p == .isha {
                            let localizedAlertString = NSLocalizedString("Time for %1$@ [%2$@]. Please reopen Athan Utility to continue recieving notifications.", comment: "")
                            alertString = String(format: localizedAlertString, p.localizedString(), dateString)
                        }
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
                    center.add(noteRequest) { print($0 ?? "", separator: "", terminator: "") }
                }
                
                // if user would ALSO like to get notified 15 minutes prior
                if setting.alarmType == .all {
                    // adding a reminder for 15 minutes before the actual prayer time
                    let preNoteContent = UNMutableNotificationContent()
                    let preDate = Calendar.current.date(byAdding: .minute, value: -15, to: prayerDate)! //prayerDate.addingTimeInterval(-900) // 15 mins before
                    preNoteContent.userInfo = ["intendedFireDate": preDate]
                    let preNoteComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone, .calendar], from: preDate)
                    
                    let preNoteTrigger = UNCalendarNotificationTrigger(dateMatching: preNoteComponents, repeats: false)
                    
                    //use a standard note tone when giving a 15m reminder
                    if setting.soundEnabled {
                        preNoteContent.sound = .default
                    }
                    
                    var alertString = ""
                    let localized15mAlert = NSLocalizedString("15m left til %1$@ in %2$@! [%3$@]", comment: "")
                    alertString = String(format: localized15mAlert,
                                                 p.localizedString(),
                                                 shortLocationName,
                                                 dateString)
                    
                    preNoteContent.body = alertString
                    
                    // hold onto the intended date for notification so that local notes can be handled in an accurate alert view
                    preNoteContent.userInfo["intendedDate"] = prayerDate
                   
                    //create a unique time based id
                    let preNoteID = "pre_note_\(preNoteComponents.day!)_\(preNoteComponents.hour!)_\(preNoteComponents.minute!)"
                    
                    let preNoteRequest = UNNotificationRequest(identifier: preNoteID, content: preNoteContent, trigger: preNoteTrigger)
                    center.add(preNoteRequest, withCompletionHandler: nil)
                }
            }
        }
    }
}
