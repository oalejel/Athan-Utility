//
//  PrayerCalculation.swift
//  Athan Utility
//
//  The pure prayer-time calculation, kept out of AthanManager so targets that must not
//  carry its location manager / WatchConnectivity side effects (the watch complication
//  widget) compute times exactly the same way the app does.
//

import Foundation
import CoreLocation
import Adhan

/// Prayer times for the calendar day containing `referenceDate`, in `timeZone`.
/// Has no side effects.
func calculatePrayerTimes(referenceDate: Date,
                          coordinate: CLLocationCoordinate2D,
                          timeZone: TimeZone?,
                          prayerSettings: PrayerSettings,
                          adjustments: PrayerAdjustments?) -> PrayerTimes? {
    var cal = Calendar(identifier: Calendar.Identifier.gregorian)
    cal.timeZone = timeZone ?? cal.timeZone // if we want to pass a custom time zone not based on the device time zone
    let date = cal.dateComponents([.year, .month, .day], from: referenceDate)
    let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)

    let method = prayerSettings.method
    var params = method.base.params
    params.madhab = prayerSettings.madhab
    params.highLatitudeRule = prayerSettings.latitudeRule
    // custom minute offsets
    if let adjustments = adjustments {
        params.adjustments = adjustments
    }

    // handle ummAlQura +30m isha adjustment on ramadan
    // note: add +1day to reference date to account for taraweeh
    //      being on the night before the first day of ramadan
    let hijriCal = Calendar(identifier: .islamicUmmAlQura)
    // +1 calendar day (DST-safe) so taraweeh on the night before Ramadan's
    // first day gets the +30m isha adjustment.
    let refPlusDay = cal.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate.addingTimeInterval(24 * 60 * 60)
    let islamicComponents = hijriCal.dateComponents([.month], from: refPlusDay)
    if method == .standard(.ummAlQura) && islamicComponents.month == 9 {
        params.adjustments.isha += 30
    }

    method.applyRules(to: &params, coordinate: coordinate, date: date, calendar: cal)

    return PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params)
}
