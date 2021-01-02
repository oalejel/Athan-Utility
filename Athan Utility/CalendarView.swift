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

@available(iOS 13.0.0, *)
class MonthModel: ObservableObject {
    @Published var months: [SimpleDate] = []
    var daysForMonth: [Int:[DayModel]] = [:]
    let suncalc = SwiftySuncalc()
//    var hijriMonthsStored = Set<HijriMonthYear>()
//    var regionalMonthsStored = Set<RegionalMonthYear>()
    
    
//    static var shared = MonthModel()
    
    // date does not need to be at beginning of month
    // init will generate all appropriate prayer times for the month of this date
    init() {
        generateStartMonths()
    }
    
    func generateStartMonths() {
        //        DispatchQueue.global(qos: .userInitiated).async { [self] in
        let dayComp = Calendar.current.dateComponents([.day], from: Date())
        let offsetDay = dayComp.day!
        let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: Date())!
        
        // add 24 months for regional at init
        for i in 0..<12 {
            let iterDate = Calendar.current.date(byAdding: .month, value: i,
                                                 to: thisMonthsFirstDay, wrappingComponents: false)!
            let _ = self.calculateMonthTimes(for: iterDate)
        }
        //        }
    }
    
    func generateDayModel(for dayDate: Date) -> DayModel {
        return DayModel(times: AthanManager.shared.calculateTimes(referenceDate: dayDate, customTimeZone: AthanManager.shared.locationSettings.timeZone),
                        moonPhase: suncalc.getMoonIllumination(date: dayDate)["phase"]!)
    }
    
    // monthdate indicates which month we want data for
    func calculateMonthTimes(for monthDate: Date) -> [DayModel] {
        var selectedCalendar = Calendar.current

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
        
        print("calculating month: ", requestedMonth, requestedYear)
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
//        return lhs.showCalendar == rhs.showCalendar
        return lhs.model != nil && rhs.model != nil
    }
    
    @Binding var showCalendar: Bool
//    @Environment(\.presentationMode) var presentationMode
    
    @State var model: MonthModel!
        
    @State var allPrayers = Array(Prayer.allCases)
    @State var timeFormatter: DateFormatter!
    
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
                .onAppear {
                    UITableView.appearance().tableFooterView = UIView()
                    // To remove all separators including the actual ones:
                    UITableView.appearance().separatorStyle = .none
                    UITableView.appearance().separatorColor = .clear
                    UITableView.appearance().showsVerticalScrollIndicator = false

                    model = MonthModel()
                    timeFormatter = {
                        let df = DateFormatter()
                        df.timeStyle = .short
                        return df
                    }()
                }
                
                HStack {
                    Text(Strings.calendar)
                        .font(Font.largeTitle.bold()) // let font colors be naturally chosen based on dark / light mode here
//                        .onAppear {
//                            model.generateStartMonths()
//                        }
                    Spacer()
                }
                .padding(.leading, 12)
                
                
                let currCal = Calendar.current
                //                List(0..<(showHijri ? model.hijriMonthsStored.count : model.regionalMonthsStored.count), id: \.self) { index in
                
                
                //                List(0..<18, id: \.self) { index in
                
                Divider()
                    .padding([.leading, .trailing])
//                List {
//                List(model.months, id: \.self) { date in
                
                let dayComp = Calendar.current.dateComponents([.day, .month, .year], from: Date())
                let offsetDay = Int(dayComp.day!)
                let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: Date())!
                
                
                List(0..<13, id: \.self) { monthOffset in
//                    ForEach(range) { index in
                        let isCurrentMonth = (monthOffset == 0)
                        let x = print("index: \(monthOffset)")
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
                            .frame(width: g.size.width, height: 0)
                        }
                        
                        //                    .id(index)
//                    }
                    
                    
//                    Text("")
//                        .onAppear {
//                            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 10)) {
//                                self.loadMore()
//                            }
//                        }
                    
                    
                } // list end
//                .id(UUID())
            }
            
        }
    }
}


@available(iOS 13.0.0, *)
struct CalViewPreview: PreviewProvider {
    static var previews: some View {
        CalendarView(showCalendar: .constant(true))
            .background(Rectangle().foregroundColor(.white), alignment: .center)
    }
}



/*
 
 private func getNextPageIfNecessary(encounteredIndex: Int) {
 //        guard encounteredIndex == rows.count - 5 else { return }
 //        rows.append(contentsOf: Array(repeating: "Item", count: 20))
 
 
 let monthCount = showHijri ? model.hijriMonthsStored.count : model.regionalMonthsStored.count
 
 guard encounteredIndex == monthCount - 5 else { return }
 // last completed month depends on current date
 let monthsToCalculate = monthsNeeded(hijri: showHijri)
 print("GET MONTHS ", encounteredIndex..<(encounteredIndex + monthsToCalculate.count))
 for d in monthsToCalculate {
 let _ = model.dates(for: d, calendarType: showHijri ? .Hijri : .Regional)
 }
 }
 
 
 
 func monthsNeeded(hijri: Bool) -> [Date] {
 // load 3 months worth
 let monthsToLoad = 3
 var cal = Calendar.current
 if hijri {
 cal = Calendar(identifier: .islamic)
 }
 
 let firstUnstoredMonthOffset = hijri ? model.hijriMonthsStored.count : model.regionalMonthsStored.count // if count=1, we start by adding one
 
 let dayComp = cal.dateComponents([.day], from: Date())
 let offsetDay = dayComp.day!
 let thisMonthsFirstDay = cal.date(byAdding: .day , value: 1-offsetDay, to: Date())!
 var out: [Date] = []
 print("-- calc: need months ", firstUnstoredMonthOffset..<(monthsToLoad + firstUnstoredMonthOffset))
 for i in firstUnstoredMonthOffset..<(monthsToLoad + firstUnstoredMonthOffset) {
 let dateInOtherMonth = cal.date(byAdding: .month, value: monthsToLoad, to: thisMonthsFirstDay)!
 out.append(dateInOtherMonth)
 }
 return out
 }
 
 
 
 
 
 
 
 
 */
