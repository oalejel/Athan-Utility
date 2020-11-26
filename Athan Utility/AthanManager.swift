//
//  AthanManager.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/14/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation
import Adhan
import CoreLocation

/*
 Athan manager now uses the batoul apps api to calculate prayer times
 Process flow of this manager can roughly be condensed to this list:
 - Current location calculation
    - Use corelocation to find a location name and coordinates
    - Or use manual location input to find coordinates using reversegeocode location
    - Store coordinates on disk, with a flag of whether we want that location to be manual or not
 - Provide accessors to today and tomorrow's prayer times, only recalculating when last calculation day ≠ current day
 - Modify settings for prayer calculation, write changes to user defaults
- No storage of qibla --> user location angle is enough
 */

class AthanManager {
    
    // MARK: - Updated calculations
    var _lastRefreshedDayOfMonth: Int = 0
    private var _todayTimes: PrayerTimes? = nil
    private var _tomorrowTimes: PrayerTimes? = nil
    
    var todayTimes: PrayerTimes? {
        get { // if new day calculating prayers, reset today and tomorrow times
            considerRefreshTimes()
            return _todayTimes
        }
    }
    
    var tomorrowTimes: PrayerTimes? {
        get { // if new day calculating prayers, reset today and tomorrow times
            considerRefreshTimes()
            return _tomorrowTimes
        }
    }
    
    // MARK: - Settings to load from storage
    var prayerSettings = PrayerSettings.shared
    var notificationSettings = NotificationSettings.shared
    var locationSettings = LocationSettings.shared
    
    // MARK: - Reasons to redo notifications and interface
    func setLocation(name: String, coordinate: CLLocationCoordinate2D) {
        
    }
    
    // MARK: - Prayer Times
    
    func considerRefreshTimes() {
        let dayOfMonth = Calendar.current.component(.day, from: Date())
        if dayOfMonth != _lastRefreshedDayOfMonth {
            _todayTimes = calculateTimes(referenceDate: Date())
            _tomorrowTimes = calculateTimes(referenceDate: Date().addingTimeInterval(86400)) // add 24 hours for next day
            _lastRefreshedDayOfMonth = dayOfMonth // no need to store last set day to file, since recalculating is not hard
        }
    }
    
    private func calculateTimes(referenceDate: Date) -> PrayerTimes? {
        guard let locationCoordinate = LocationSettings.shared.locationCoordinate else {
            print("no coordinate available yet")
            return nil
        }
        
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
        let coordinates = Coordinates(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
        
        var params = PrayerSettings.shared.calculationMethod.params
        params.madhab = PrayerSettings.shared.madhab
        
        if let prayers = PrayerTimes(coordinates: coordinates,
                                     date: date,
                                     calculationParameters: params) {
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
    
    // MARK: - CoreLocation Coordinate + location name
    
    
}
