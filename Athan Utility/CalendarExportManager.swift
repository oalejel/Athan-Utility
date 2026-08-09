//
//  CalendarExportManager.swift
//  Athan Utility
//
//  Writes prayer-time events into a dedicated "Athan Utility" calendar over a chosen date
//  range, so users can see Salah times alongside the rest of their day. Events go in their
//  own calendar so the whole set can be removed in one step without touching other events.
//

import Foundation
import EventKit
import UIKit
import Adhan

final class CalendarExportManager {
    static let shared = CalendarExportManager()
    let store = EKEventStore()

    /// Title of the dedicated calendar we create/own.
    static let calendarTitle = "Athan Utility — Salah"

    enum ExportError: LocalizedError {
        case accessDenied
        case noCalendarSource
        var errorDescription: String? {
            switch self {
            case .accessDenied:     return NSLocalizedString("cal_access_denied", value: "Calendar access is off. Enable it in Settings to add prayer times.", comment: "")
            case .noCalendarSource: return NSLocalizedString("cal_no_source", value: "No calendar account is available to add events to.", comment: "")
            }
        }
    }

    struct Options {
        var prayers: [Prayer]
        var startDate: Date
        var endDate: Date
        var alarmMinutesBefore: Int?   // nil = no alert
        var durationMinutes: Int = 25
    }

    // MARK: - Authorization

    var isAuthorized: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) { return status == .fullAccess }
        return status == .authorized
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        let done: (Bool, Error?) -> Void = { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
        if #available(iOS 17.0, *) {
            store.requestFullAccessToEvents(completion: done)
        } else {
            store.requestAccess(to: .event, completion: done)
        }
    }

    // MARK: - Dedicated calendar

    var dedicatedCalendar: EKCalendar? {
        store.calendars(for: .event).first { $0.title == Self.calendarTitle }
    }

    private func getOrCreateCalendar() throws -> EKCalendar {
        if let existing = dedicatedCalendar { return existing }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = Self.calendarTitle
        cal.cgColor = UIColor(red: 0.25, green: 0.55, blue: 0.9, alpha: 1).cgColor
        // Prefer the account the user's default calendar lives in, then iCloud, then local.
        cal.source = store.defaultCalendarForNewEvents?.source
            ?? store.sources.first { $0.sourceType == .calDAV }
            ?? store.sources.first { $0.sourceType == .local }
        guard cal.source != nil else { throw ExportError.noCalendarSource }
        try store.saveCalendar(cal, commit: true)
        return cal
    }

    // MARK: - Export

    /// Adds events across the range. Clears any existing Athan events in the same range first
    /// so re-running doesn't create duplicates. Progress is reported 0...1 on the main queue.
    func export(options: Options,
                progress: @escaping (Double) -> Void,
                completion: @escaping (Result<Int, Error>) -> Void) {
        guard isAuthorized else { completion(.failure(ExportError.accessDenied)); return }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let calendar = try self.getOrCreateCalendar()

                var greg = Calendar(identifier: .gregorian)
                greg.timeZone = AthanManager.shared.locationSettings.timeZone
                let startDay = greg.startOfDay(for: options.startDate)
                let lastDay = greg.startOfDay(for: options.endDate)
                let dayCount = max(0, greg.dateComponents([.day], from: startDay, to: lastDay).day ?? 0)

                // Always clear ALL existing Athan events before a new load — a location or
                // timing change makes the old ones wrong, so we never want stale events left.
                let clearStart = greg.date(byAdding: .year, value: -2, to: startDay) ?? startDay
                let clearEnd = greg.date(byAdding: .year, value: 5, to: lastDay) ?? lastDay
                let pred = self.store.predicateForEvents(withStart: clearStart, end: clearEnd, calendars: [calendar])
                for e in self.store.events(matching: pred) {
                    try? self.store.remove(e, span: .thisEvent, commit: false)
                }

                let mgr = AthanManager.shared
                let adjustments = mgr.notificationSettings.adjustments()
                let notes = NSLocalizedString("cal_event_notes", value: "Prayer time from Athan Utility.", comment: "")
                let locationName = mgr.locationSettings.locationName
                var created = 0

                for dayOffset in 0...dayCount {
                    guard let day = greg.date(byAdding: .day, value: dayOffset, to: startDay),
                          let times = mgr.calculateTimes(referenceDate: day, adjustments: adjustments) else { continue }
                    for prayer in options.prayers {
                        let start = times.time(for: prayer)
                        let ev = EKEvent(eventStore: self.store)
                        ev.calendar = calendar
                        ev.title = prayer.localizedOrCustomString()
                        ev.startDate = start
                        ev.endDate = start.addingTimeInterval(TimeInterval(options.durationMinutes * 60))
                        ev.notes = notes
                        if !locationName.isEmpty { ev.location = locationName }
                        if let m = options.alarmMinutesBefore {
                            ev.addAlarm(EKAlarm(relativeOffset: TimeInterval(-m * 60)))
                        }
                        try self.store.save(ev, span: .thisEvent, commit: false)
                        created += 1
                    }
                    let frac = Double(dayOffset) / Double(max(1, dayCount))
                    DispatchQueue.main.async { progress(frac) }
                }

                try self.store.commit()
                DispatchQueue.main.async { completion(.success(created)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    /// Deletes the dedicated calendar and everything in it.
    func removeAllEvents(completion: @escaping (Result<Void, Error>) -> Void) {
        guard isAuthorized else { completion(.failure(ExportError.accessDenied)); return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let cal = self.dedicatedCalendar {
                    try self.store.removeCalendar(cal, commit: true)
                }
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
