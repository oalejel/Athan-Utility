//
//  CalendarExportView.swift
//  Athan Utility
//
//  Lets the user add Salah times to their calendar over a chosen range, with per-prayer
//  toggles and an optional alert. Events go into a dedicated calendar so they can be removed
//  in one tap.
//

import SwiftUI
import EventKit
import Adhan

@available(iOS 14.0, *)
struct CalendarExportView: View {
    @Environment(\.presentationMode) private var presentationMode

    enum RangeChoice: Int, CaseIterable, Identifiable {
        case month, threeMonths, sixMonths, year
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .month:       return NSLocalizedString("cal_range_month", value: "1 month", comment: "")
            case .threeMonths: return NSLocalizedString("cal_range_3month", value: "3 months", comment: "")
            case .sixMonths:   return NSLocalizedString("cal_range_6month", value: "6 months", comment: "")
            case .year:        return NSLocalizedString("cal_range_year", value: "1 year", comment: "")
            }
        }
        var months: Int {
            switch self {
            case .month: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .year: return 12
            }
        }
    }

    // The obligatory prayers are on by default; sunrise is optional.
    @State private var selectedPrayers: Set<Prayer> = [.fajr, .dhuhr, .asr, .maghrib, .isha]
    @State private var range: RangeChoice = .month
    @State private var addAlert = false
    @State private var alertMinutesBefore = 0

    @State private var status: Status = .idle
    @State private var progress: Double = 0
    @State private var resultCount = 0
    @State private var errorMessage: String?

    enum Status { case idle, working, done, failed }

    private let allPrayers: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

    private var endDate: Date {
        Calendar.current.date(byAdding: .month, value: range.months, to: Date()) ?? Date()
    }
    private var estimatedEvents: Int {
        let days = max(1, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 30)
        return days * selectedPrayers.count
    }
    private var hasExisting: Bool { CalendarExportManager.shared.dedicatedCalendar != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("cal_prayers_header", value: "Prayers", comment: ""))) {
                    ForEach(allPrayers, id: \.self) { p in
                        Button(action: { toggle(p) }) {
                            HStack {
                                Image(systemName: p.sfSymbolName())
                                    .frame(width: 24)
                                    .foregroundColor(.accentColor)
                                Text(p.localizedOrCustomString())
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: selectedPrayers.contains(p) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPrayers.contains(p) ? .accentColor : .secondary)
                            }
                        }
                    }
                }

                Section(header: Text(NSLocalizedString("cal_range_header", value: "How far ahead", comment: ""))) {
                    Picker("", selection: $range) {
                        ForEach(RangeChoice.allCases) { r in Text(r.title).tag(r) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }

                Section(header: Text(NSLocalizedString("cal_alert_header", value: "Alert", comment: ""))) {
                    Toggle(NSLocalizedString("cal_add_alert", value: "Add a calendar alert", comment: ""), isOn: $addAlert)
                    if addAlert {
                        Stepper(value: $alertMinutesBefore, in: 0...60, step: 5) {
                            Text(alertMinutesBefore == 0
                                 ? NSLocalizedString("cal_alert_attime", value: "At prayer time", comment: "")
                                 : String(format: NSLocalizedString("cal_alert_before", value: "%d min before", comment: ""), alertMinutesBefore))
                        }
                    }
                }

                Section(footer: VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: NSLocalizedString("cal_estimate_footer",
                        value: "About %d events will be added to a dedicated \u{201C}Athan Utility\u{201D} calendar. Events are stamped with your current location.", comment: ""), estimatedEvents))
                    Label(NSLocalizedString("cal_tip", value: "Tip: when you change location or extend the range, use Remove to clear the old events first — adding again always clears and rebuilds them.", comment: ""), systemImage: "lightbulb.fill")
                        .font(.footnote)
                }) {
                    Button(action: startExport) {
                        HStack {
                            if status == .working {
                                ProgressView().padding(.trailing, 4)
                                Text(String(format: NSLocalizedString("cal_adding", value: "Adding… %d%%", comment: ""), Int(progress * 100)))
                            } else {
                                Image(systemName: "calendar.badge.plus")
                                Text(NSLocalizedString("cal_add_button", value: "Add to Calendar", comment: ""))
                            }
                            Spacer()
                        }
                    }
                    .disabled(status == .working || selectedPrayers.isEmpty)

                    if hasExisting {
                        Button(action: removeAll) {
                            HStack {
                                Image(systemName: "trash")
                                Text(NSLocalizedString("cal_remove_button", value: "Remove Athan events", comment: ""))
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                        .disabled(status == .working)
                    }
                }

                if status == .done {
                    Section {
                        Label(String(format: NSLocalizedString("cal_done", value: "Added %d prayer times.", comment: ""), resultCount),
                              systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                if status == .failed, let msg = errorMessage {
                    Section {
                        Label(msg, systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    }
                }
            }
            .navigationBarTitle(NSLocalizedString("cal_export_title", value: "Calendar Integration", comment: ""), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("done", value: "Done", comment: "")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Actions

    private func toggle(_ p: Prayer) {
        if selectedPrayers.contains(p) { selectedPrayers.remove(p) } else { selectedPrayers.insert(p) }
    }

    private func startExport() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let mgr = CalendarExportManager.shared
        let run = {
            status = .working
            progress = 0
            let opts = CalendarExportManager.Options(
                prayers: allPrayers.filter { selectedPrayers.contains($0) }, // keep chronological order
                startDate: Date(),
                endDate: endDate,
                alarmMinutesBefore: addAlert ? alertMinutesBefore : nil)
            mgr.export(options: opts, progress: { progress = $0 }) { result in
                switch result {
                case .success(let n):
                    resultCount = n
                    status = .done
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case .failure(let err):
                    errorMessage = err.localizedDescription
                    status = .failed
                }
            }
        }
        if mgr.isAuthorized {
            run()
        } else {
            mgr.requestAccess { granted in
                if granted { run() }
                else {
                    errorMessage = CalendarExportManager.ExportError.accessDenied.localizedDescription
                    status = .failed
                }
            }
        }
    }

    private func removeAll() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        status = .working
        CalendarExportManager.shared.removeAllEvents { result in
            switch result {
            case .success:
                status = .idle
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure(let err):
                errorMessage = err.localizedDescription
                status = .failed
            }
        }
    }
}
