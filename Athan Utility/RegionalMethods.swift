//
//  RegionalMethods.swift
//  Athan Utility
//
//  Calculation methods the Adhan package doesn't ship. Adhan's CalculationMethod is a
//  closed enum, so the app's picker works in terms of PrayerMethod: every Adhan method,
//  plus regional authorities layered on top of one of them. PrayerSettings stores the
//  regional choice separately from `calculationMethod` (which keeps the base method),
//  so older archives and older watch builds still decode and fall back to the base.
//
//  Only depends on Foundation + Adhan so every target that calculates times can use it.
//

import Foundation
import CoreLocation
import Adhan

enum PrayerMethod: Hashable, Codable {
    case standard(CalculationMethod)
    /// Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan:
    /// Fajr 18°, Isha 18°, Maghrib 5 minutes after sunset.
    case jordan
    /// Inter-Masajed Shura of Edmonton (Al Rashid Mosque's published calendar). Fajr 18° and
    /// Isha 17°, with seasonal rules for the summer months when twilight never ends.
    case edmonton

    /// Every method offered in the pickers, in display order.
    static var allMethods: [PrayerMethod] {
        CalculationMethod.allCases.filter { $0 != .other }.map(PrayerMethod.standard) + [.jordan, .edmonton]
    }

    /// The Adhan method stored in `PrayerSettings.calculationMethod`. For regional methods,
    /// the closest standard one, which is what an older build reading the archive will use.
    var base: CalculationMethod {
        switch self {
        case .standard(let method): return method
        case .jordan, .edmonton: return .muslimWorldLeague
        }
    }

    /// Persisted in `PrayerSettings.regionalMethod`; nil for standard methods.
    var regionalID: String? {
        switch self {
        case .standard: return nil
        case .jordan: return "jordan"
        case .edmonton: return "edmonton"
        }
    }

    init(base: CalculationMethod, regionalID: String?) {
        switch regionalID {
        case "jordan": self = .jordan
        case "edmonton": self = .edmonton
        default: self = .standard(base)
        }
    }

    /// Applies this method's rules to `params`, which already carry the base method's
    /// angles plus the user's madhab, latitude rule and minute adjustments.
    func applyRules(to params: inout CalculationParameters, coordinate: CLLocationCoordinate2D,
                    date: DateComponents, calendar: Calendar) {
        switch self {
        case .standard:
            break
        case .jordan:
            params.ishaAngle = 18
            params.adjustments.maghrib += 5
        case .edmonton:
            EdmontonIMS.applyRules(to: &params, coordinate: coordinate, date: date, calendar: calendar)
        }
    }
}

/// "Prayer Times Calculation for Edmonton and Surrounding Area" (Inter-Masajed Shura).
/// Times stay on 18° / 17° except:
///
/// Fajr
/// - May 21 – Jul 20: the Fajr period is the same fraction of the night as at latitude 45°
///   on the same day (18°).
/// - Apr 21 – May 20: that fraction is held at its April 20 value.
/// - Jul 21 – Aug 20: held at its August 21 value.
///
/// Isha
/// - Apr 21 – Aug 20: 1 hour 15 minutes after sunset.
/// - Mar 21 – Apr 20: the gap after sunset moves linearly from its 17° value on March 20
///   to 1h15 on April 21.
/// - Aug 21 – Sep 20: moves linearly from 1h15 on August 21 to its 17° value on September 21.
///
/// Adhan's PrayerTimes can't be edited after the fact, so the rules are expressed as
/// parameters for the day: a minute adjustment on Fajr and an `ishaInterval` for Isha.
enum EdmontonIMS {
    static let summerIshaMinutes = 75

    static func applyRules(to params: inout CalculationParameters, coordinate: CLLocationCoordinate2D,
                           date: DateComponents, calendar: Calendar) {
        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let year = date.year, let month = date.month, let day = date.day else { return }
        let monthDay = month * 100 + day
        // Reference calculations use the plain angles, without the user's minute adjustments
        // (those are still applied on top of the final result).
        var plain = params
        plain.adjustments = PrayerAdjustments()
        plain.ishaInterval = 0

        func components(_ m: Int, _ d: Int) -> DateComponents {
            DateComponents(year: year, month: m, day: d)
        }
        func daysBetween(_ a: DateComponents, _ b: DateComponents) -> Double? {
            guard let from = calendar.date(from: a), let to = calendar.date(from: b),
                  let days = calendar.dateComponents([.day], from: from, to: to).day else { return nil }
            return Double(days)
        }
        /// Minutes from sunset to Isha at 17° on the given day.
        func ishaGap(_ day: DateComponents) -> Double? {
            guard let times = PrayerTimes(coordinates: coordinates, date: day, calculationParameters: plain) else { return nil }
            return times.isha.timeIntervalSince(times.maghrib) / 60
        }
        /// (sunrise − Fajr) / (previous sunset → sunrise) at 18°.
        func fajrFraction(at coords: Coordinates, on day: DateComponents) -> Double? {
            guard let dayDate = calendar.date(from: day),
                  let previousDate = calendar.date(byAdding: .day, value: -1, to: dayDate),
                  let today = PrayerTimes(coordinates: coords, date: day, calculationParameters: plain),
                  let previous = PrayerTimes(coordinates: coords,
                                             date: calendar.dateComponents([.year, .month, .day], from: previousDate),
                                             calculationParameters: plain) else { return nil }
            let night = today.sunrise.timeIntervalSince(previous.maghrib)
            guard night > 0 else { return nil }
            return today.sunrise.timeIntervalSince(today.fajr) / night
        }

        // Isha
        switch monthDay {
        case 421...820:
            params.ishaInterval = summerIshaMinutes
        case 321...420:
            if let start = ishaGap(components(3, 20)),
               let elapsed = daysBetween(components(3, 20), date),
               let span = daysBetween(components(3, 20), components(4, 21)), span > 0 {
                let gap = start + (Double(summerIshaMinutes) - start) * elapsed / span
                params.ishaInterval = Int(gap.rounded())
            }
        case 821...920:
            if let end = ishaGap(components(9, 21)),
               let elapsed = daysBetween(components(8, 21), date),
               let span = daysBetween(components(8, 21), components(9, 21)), span > 0 {
                let gap = Double(summerIshaMinutes) + (end - Double(summerIshaMinutes)) * elapsed / span
                params.ishaInterval = Int(gap.rounded())
            }
        default:
            break
        }

        // Fajr
        let fraction: Double?
        switch monthDay {
        case 521...720:
            fraction = fajrFraction(at: Coordinates(latitude: 45, longitude: coordinate.longitude), on: date)
        case 421...520:
            fraction = fajrFraction(at: coordinates, on: components(4, 20))
        case 721...820:
            fraction = fajrFraction(at: coordinates, on: components(8, 21))
        default:
            fraction = nil
        }
        if let fraction = fraction,
           let dayDate = calendar.date(from: date),
           let previousDate = calendar.date(byAdding: .day, value: -1, to: dayDate),
           let today = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: plain),
           let previous = PrayerTimes(coordinates: coordinates,
                                      date: calendar.dateComponents([.year, .month, .day], from: previousDate),
                                      calculationParameters: plain) {
            let night = today.sunrise.timeIntervalSince(previous.maghrib)
            let target = today.sunrise.addingTimeInterval(-fraction * night)
            let shift = target.timeIntervalSince(today.fajr) / 60
            params.adjustments.fajr += Int(shift.rounded())
        }
    }
}
