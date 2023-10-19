//
//  CalendarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan
import SwiftUI

class DayModel {
    var times: PrayerTimes? // can also get date from this property
    var moonPhase: Double // percent for moon phase
    init(times: PrayerTimes?, moonPhase: Double) {
        self.times = times
        self.moonPhase = moonPhase
    }
}

@available(iOS 13.0.0, *)
public extension View {
    func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}

struct SimpleDate: Hashable, Identifiable {
    //    let day: Int
    let month: Int
    let year: Int
    let sampleDate: Date
    let id: Int
    
    var hashValue: Int { id }
    static func ==(lhs: SimpleDate, rhs: SimpleDate) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(month: Int, year: Int, sampleDate: Date) {
        self.month = month
        self.year = year
        self.sampleDate = sampleDate
        self.id = year * 100 + month
    }
}

// used for looking up by year and month
//struct HijriMonthYear: Hashable {
//    let month: Int
//    let year: Int
//}
//
//struct RegionalMonthYear: Hashable {
//    let month: Int
//    let year: Int
//}

class MonthModel: ObservableObject {
    @Published var months: [SimpleDate] = []
    var daysForMonth: [Int:[DayModel]] = [:]
    let suncalc = SwiftySuncalc()
    
    
    // date does not need to be at beginning of month
    // init will generate all appropriate prayer times for the month of this date
    init(startDate: Date = Date()) {
        generateStartMonths(startDate: startDate)
    }
    
    func generateStartMonths(startDate: Date = Date()) {
        let dayComp = Calendar.current.dateComponents([.day], from: startDate)
        let offsetDay = dayComp.day!
        let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: startDate)!
        
        // add 24 months for regional at init
        for i in 0..<12 {
            let iterDate = Calendar.current.date(byAdding: .month, value: i,
                                                 to: thisMonthsFirstDay, wrappingComponents: false)!
            let _ = self.calculateMonthTimes(for: iterDate)
        }
    }
    
    func generateDayModel(for dayDate: Date) -> DayModel {
        return DayModel(times: AthanManager.shared.calculateTimes(referenceDate: dayDate, customTimeZone: AthanManager.shared.locationSettings.timeZone, adjustments: AthanManager.shared.notificationSettings.adjustments()),
                        moonPhase: suncalc.getMoonIllumination(date: dayDate)["phase"]!)
    }
    
    // monthdate indicates which month we want data for
    func calculateMonthTimes(for monthDate: Date) -> [DayModel] {
        let selectedCalendar = Calendar.current
        
        // select month of interest and iterate through all days
        let components = selectedCalendar.dateComponents([.day, .month, .year], from: monthDate)
        let offsetDay = components.day!
        let requestedMonth = components.month!
        let requestedYear = components.year!
        
        let requestedSimpleDate = SimpleDate(month: requestedMonth, year: requestedYear, sampleDate: monthDate)
        if let existing = daysForMonth[requestedSimpleDate.id] {
            print("returned existing month: ", requestedMonth, requestedYear)
            return existing
        }
        
//        print("calculating month: ", requestedMonth, requestedYear)
        daysForMonth[requestedSimpleDate.id] = []
        months.append(requestedSimpleDate)
        
        let firstDayOfMonth = selectedCalendar.date(byAdding: .day , value: 1-offsetDay, to: monthDate)!
        
        // for each day of month, append a time
        let dayRange = selectedCalendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        for dayOffset in 0..<dayRange {
            // not sure if this rule of 24 hours per day can ever fail unless we
            //  go one billion years in the future and the lost seconds add up lol...
            let iterDayOfMonth = firstDayOfMonth.addingTimeInterval(TimeInterval(dayOffset*86400))
            daysForMonth[requestedSimpleDate.id]!.append(generateDayModel(for: iterDayOfMonth))
        }
        
        return daysForMonth[requestedSimpleDate.id]!
    }
}

@available(iOS 13.0.0, *)
struct CalendarView: View, Equatable {
    static func == (lhs: CalendarView, rhs: CalendarView) -> Bool {
        return lhs.model != nil && rhs.model != nil
    }
    
    @Binding var showCalendar: Bool
    @State var showShareSheet = false
    
    var model: MonthModel!
    
    @State var allPrayers = Array(Prayer.allCases)
    var timeFormatter: DateFormatter!
    
    //    @State var range: Range<Int> = 0..<12
    //    func loadMore() {
    //        print("Load more...")
    //        self.range = 0..<self.range.upperBound + 3
    //    }
    
    //                    Picker(selection: $showHijri.animation(.linear), label: Text("Picker"), content: {
    //                        ForEach([false, true], id: \.self) { hijri in
    //                            Text(hijri ? "Hijri" : "Regional")
    //                        }
    //                    })
    //                    .pickerStyle(SegmentedPickerStyle())
    init(showCalendar: Binding<Bool>) {
        self._showCalendar = showCalendar
        model = MonthModel()
        timeFormatter = {
            let df = DateFormatter()
            df.timeStyle = .short
            return df
        }()
    }
    
    var body: some View {
        GeometryReader { g in
            
            VStack(spacing: 0) {
                HStack { // main calendar header
                    Spacer()
                    VStack {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showCalendar = false
                            print("exit")
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(.tertiaryLabel))
                                .font(Font.system(size: 25).bold())
                        })
                        Spacer()
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding([.leading, .trailing, .top], 12)
                
                HStack {
                    Text(Strings.calendar)
                        .font(Font.largeTitle.bold()) // let font colors be naturally chosen based on dark / light mode here
                                                      //                        .onAppear {
                                                      //                            model.generateStartMonths()
                                                      //                        }
                    Spacer()
                    
                    // export button
                    Button(action: {
                        let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        lightImpactFeedbackGenerator.impactOccurred()
                        withAnimation {
                            let pdf = CalendarExport().makePDF()
                            showShareSheet = true
                        }
                    }) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(Strings.export)
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundColor(.red)
                        .padding(2)
                    }
                    .foregroundColor(Color(.red))
                    .padding(.trailing, 12)
                    .font(Font.body.weight(.bold))
                    .sheet(isPresented: $showShareSheet) {
                        
                    } content: {
                        let calendarFileURL: URL = {
                            let csvString = calendarCSVString()
                                    
                            let tempDirectoryURL = FileManager.default.temporaryDirectory
                            let fileURL = tempDirectoryURL.appendingPathComponent("athan-calendar").appendingPathExtension("csv")
                            
                            // Write the CSV string to the file URL
                            try! csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                            return fileURL
                        }()
                        
                        ShareSheet(activityItems: [calendarFileURL])
                    }
                }
                .padding(.leading, 12)
                
                
                let currCal = Calendar.current
                Divider()
                    .padding([.leading, .trailing])
                
                let dayComp = Calendar.current.dateComponents([.day, .month, .year], from: Date())
                let offsetDay = Int(dayComp.day!)
                let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: Date())!
                
                
                List(0..<13, id: \.self) { monthOffset in
                    //                    ForEach(range) { index in
                    let isCurrentMonth = (monthOffset == 0)
                    let _ = print("index: \(monthOffset)")
                    let d = currCal.date(byAdding: .month, value: monthOffset, to: thisMonthsFirstDay)!
                    let monthPrayerTimes = self.model.calculateMonthTimes(for: d)
                    
                    let monthDF: DateFormatter = {
                        let df = DateFormatter()
                        df.dateFormat = "MMMM"
                        df.locale = currCal.locale
                        return df
                    }()
                    
                    let yearDF: DateFormatter = {
                        let df = DateFormatter()
                        df.dateFormat = "YYYY"
                        df.locale = currCal.locale
                        return df
                    }()
                    
                    // name of months
                    VStack(alignment: .leading) {
                        
                        VStack(spacing: 2) {
                            // month header
                            HStack(alignment: .lastTextBaseline) {
                                Text(monthDF.string(from: d))
                                    .font(Font.system(size: 26).bold())
                                    .foregroundColor(.red)
                                    .padding(.top, 8)
                                Spacer()
                                //                                    .font(Font.system(size: 24).bold)
                                Text(yearDF.string(from: d))
                                    .font(Font.system(size: 16).bold())
                                    .foregroundColor(.gray)
                                //                                    .font(Font.system(size: 22).bold)
                            }
                            
                            
                            // table content header
                            HStack(alignment: .center, spacing: 0) {
                                Spacer()
                                ZStack {
                                    Text("Date")
                                        .font(Font.caption.bold())
                                        .lineLimit(1)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .foregroundColor(Color(.label))
                                        .padding([.top, .bottom], 2)
                                        .frame(width:100)
                                    
                                }
                                .frame(width: 1)
                                
                                
                                ForEach(allPrayers, id: \.self) { p in
                                    Spacer()
                                    Spacer()
                                    
                                    ZStack {
                                        PrayerSymbol(prayerType: p)
                                            .foregroundColor(Color(.label))
                                            .padding([.top, .bottom], 4)
                                            .frame(width:100)
                                        
                                    }
                                    .frame(width: 1)
                                }
                                Spacer()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        
                        // table
                        ZStack { // stack grid below times below
                            HStack { // grid column lines
                                ForEach(0..<6, id: \.self) { i in
                                    Spacer()
                                    Divider()
                                }
                                Spacer()
                            }
                            
                            VStack(alignment: .center, spacing: 0) { // grid row lines and content
                                
                                ForEach(0..<monthPrayerTimes.count, id: \.self) { dayIndex in
                                    let isToday = (offsetDay - 1 == dayIndex) && isCurrentMonth
                                    Divider()
                                    let lengthGoal = 11
                                    
                                    HStack(spacing: 0) {
                                        Spacer()
                                        
                                        ZStack(alignment: .center) {
                                            let dayText: String = {
                                                var str = "\(dayIndex + 1)"
                                                while str.count + 1 < lengthGoal {
                                                    str = " " + str + " "
                                                }
                                                return str
                                            }()
                                            
                                            Text(dayText)
                                                .bold()
                                                .frame(width: (g.size.width - 12) / 10)
                                                .fixedSize(horizontal: true, vertical: true)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.01)
                                                .padding([.top, .bottom], 1)
                                                .foregroundColor(isToday ? Color.red : Color(.label))
                                        }
                                        .frame(width: 3)
                                        
                                        // row contents
                                        ForEach(allPrayers, id: \.self) { p in
                                            
                                            let prayerTime = monthPrayerTimes[dayIndex].times?.time(for: p)
                                            let text: String = {
                                                var str = prayerTime == nil ? "--" : timeFormatter.string(from: prayerTime!)
                                                //                                                str = str.replacingOccurrences(of: " ", with: "")
                                                while str.count + 1 < lengthGoal {
                                                    str = " " + str + " "
                                                }
                                                return str
                                            }()
                                            
                                            Spacer()
                                            Spacer()
                                            ZStack(alignment: .center) {
                                                //                                                    Circle()
                                                //                                                        .frame(width: 10, height: 10)
                                                Text(text)
                                                    .bold()
                                                //                                                    .font(.system(size: 30, design: .monospaced))
                                                    .frame(width: (g.size.width - 12) / 8)
                                                    .fixedSize(horizontal: true, vertical: true)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.01)
                                                    .padding([.top, .bottom], 3)
                                                    .foregroundColor(isToday ? Color.red : Color(.label))
                                                
                                            }
                                            .frame(width: 3, height: 1)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding([.top, .bottom], 2)
                                    
                                }
                                Divider()
                            }
                            
                        }
                        ZStack {
                            Rectangle()
                                .foregroundColor(Color(.systemBackground))
                                .frame(width: g.size.width, height: 4)
                                .offset(y: 4)
                        }
                        .frame(width: g.size.width - 24, height: 0)
                    }
                    .modify { v in
                        if #available(iOS 15.0, *) {
                            v.listRowSeparator(.hidden)
                        } else {
                            v
                        }
                    }
                } // list end
                .listStyle(PlainListStyle())
            }
        }
    }
    
    func calendarCSVString() -> String {
        var csv = "Athan Calendar\n"
        
        let currCal = Calendar.current
        let dayComp = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let offsetDay = Int(dayComp.day!)
        let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: Date())!
        
        // for each month in the year...
        for monthOffset in 0..<13 {
            let isCurrentMonth = (monthOffset == 0)
            let _ = print("index: \(monthOffset)")
            let d = currCal.date(byAdding: .month, value: monthOffset, to: thisMonthsFirstDay)!
            let monthPrayerTimes = self.model.calculateMonthTimes(for: d)
            
            // create date formatters for getting the month and year
            let monthDF: DateFormatter = {
                let df = DateFormatter()
                df.dateFormat = "MMMM"
                df.locale = currCal.locale
                return df
            }()
            
            let yearDF: DateFormatter = {
                let df = DateFormatter()
                df.dateFormat = "YYYY"
                df.locale = currCal.locale
                return df
            }()
            
            
            // Month header row: E.g. "October, 2023"
            csv += "\(monthDF.string(from: d)) \(yearDF.string(from: d))\n"
            csv += "Day, Fajr, Sunrise, Thuhr, Asr, Maghrib, Isha\n"
            // ----
            
            for dayIndex in 0..<monthPrayerTimes.count {
                let isToday = (offsetDay - 1 == dayIndex) && isCurrentMonth
                let lengthGoal = 11
                // Day row: day of the month
                let dayText = "\(dayIndex + 1)"
                csv += dayText + ","
                
                for p in allPrayers {
                    let prayerTime = monthPrayerTimes[dayIndex].times?.time(for: p)
                    let surePrayerTime = prayerTime == nil ? "--" : timeFormatter.string(from: prayerTime!)
                    // Day row:
                    csv += surePrayerTime
                    if p != .isha {
                        csv += ","
                    }
                }
                csv += "\n"
            }
        }
            return csv
    }
}
        
        
        @available(iOS 13.0.0, *)
        struct CalViewPreview: PreviewProvider {
            static var previews: some View {
                CalendarView(showCalendar: .constant(true))
                    .background(Rectangle().foregroundColor(.white), alignment: .center)
            }
        }
        
