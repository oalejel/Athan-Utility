//
//  CalendarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan
import SwiftUI


// tell month model which days we want to calculate for
// if we have those days, return them

// store model object for every day / row in each month table
// tell a standard month model to generate the times and which calendar type we are interested in


// month model is told which month we want to show
// month model uses a helper function to generate each day needed depending on the
//      type of calendar we are using, and adds them to a table

fileprivate struct DayModel {
    var times: PrayerTimes? // can also get date from this property
    var moonPhase: Double // percent for moon phase
}

fileprivate struct SimpleDate: Hashable {
    let day: Int
    let month: Int
    let year: Int
}

// used for looking up by year and month
fileprivate struct HijriMonthYear: Hashable {
    let month: Int
    let year: Int
}

fileprivate struct RegionalMonthYear: Hashable {
    let month: Int
    let year: Int
}

@available(iOS 13.0.0, *)
fileprivate class MonthModel: ObservableObject {
    @Published var dayModelDict: [SimpleDate:DayModel] = [:]
    let suncalc = SwiftySuncalc()
    var hijriMonthsStored = Set<HijriMonthYear>()
    var regionalMonthsStored = Set<RegionalMonthYear>()
    
    // date does not need to be at beginning of month
    // init will generate all appropriate prayer times for the month of this date
    init() {
        let dayComp = Calendar.current.dateComponents([.day], from: Date())
        let offsetDay = dayComp.day!
        let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: Date())!
        
        // add 24 months for regional at init
        for i in 0..<24 {
            let iterDate = Calendar.current.date(byAdding: .month, value: i,
                                  to: thisMonthsFirstDay, wrappingComponents: true)!
            let _ = dates(for: iterDate, calendarType: .Regional)
        }
        
    }
    
    func generateDayModel(for dayDate: Date, calendarType: CalendarType) -> DayModel {
        return DayModel(times: AthanManager.shared.calculateTimes(referenceDate: dayDate),
                        moonPhase: suncalc.getMoonIllumination(date: dayDate)["phase"]!)
    }
    
    // monthdate indicates which month we want data for
    func dates(for monthDate: Date, calendarType: CalendarType) -> [DayModel] {
        
        var selectedCalendar = Calendar.current
        let hijriCalendar = Calendar(identifier: .islamic)
        if calendarType == .Hijri {
            selectedCalendar = hijriCalendar
        }
        // select month of interest and iterate through all days
        let components = selectedCalendar.dateComponents([.day, .month], from: monthDate)
        let offsetDay = components.day!
        print("adding month: ", components.month!)
        #warning("confirm this is always first day of month")
        let firstDayOfMonth = selectedCalendar.date(byAdding: .day , value: 1-offsetDay, to: monthDate)!
        
        var output: [DayModel] = []
        // for each day of month, append a time
        let dayRange = selectedCalendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        for dayOffset in 0..<dayRange {
            #warning("not sure if this rule of 24 hours per day can ever fail unless we")
            //  go one billion years in the future and the lost seconds add up lol...
            let iterDayOfMonth = firstDayOfMonth.addingTimeInterval(TimeInterval(dayOffset*86400))
            
            // WARNING: MUST use regional calendar for date components in simple date,
            // or else our calendar dates will not be matched up
            let iterComponents = Calendar.current.dateComponents([.day, .month, .year], from: iterDayOfMonth)
            let simpleDate = SimpleDate(day: iterComponents.day!,
                                        month: iterComponents.month!,
                                        year: iterComponents.year!)
            
            // ALWAYS use current cal as regional for remembering the regional months we have
            regionalMonthsStored.insert(RegionalMonthYear(month: iterComponents.month!, year: iterComponents.year!))
            // then add hijri stored based on hijri calendar
//            let hijriComps = Calendar.current.dateComponents([.day, .month, .year], from: iterDayOfMonth)
//            hijriMonthsStored.insert(HijriMonthYear(month: hijriComps.month!, year: hijriComps.year!))
            
            // save if we dont have an entry for this day
            if dayModelDict[simpleDate] == nil {
                let newModel = generateDayModel(for: iterDayOfMonth, calendarType: calendarType)
                dayModelDict[simpleDate] = newModel
            }
            output.append(dayModelDict[simpleDate]!)
        }
        return output
    }
    
    enum CalendarType {
        case Regional, Hijri
    }
}

@available(iOS 13.0.0, *)
struct CalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var showHijri = false
    @ObservedObject fileprivate var model = MonthModel()
    
//    @State var rows: [String] = Array(repeating: "Item", count: 10)

    let x: Int = {
        UITableView.appearance().showsVerticalScrollIndicator = false
        return 0
    }()
    
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

    
    var body: some View {
        GeometryReader { g in
            VStack {
                HStack {
                    Text("Calendar")
                        .font(Font.largeTitle.bold()) // let font colors be naturally chosen based on dark / light mode here
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                        print("exit")
                    }, label: {
                        Text("x buttton")
                            .foregroundColor(.gray)
                    })
                }
                
                Picker(selection: $showHijri.animation(.linear), label: Text("Picker"), content: {
                    ForEach([false, true], id: \.self) { dynamic in
                        Text(dynamic ? "Regional" : "Hijri")
                    }
                })
                .pickerStyle(SegmentedPickerStyle())
                
                let currCal = showHijri ? Calendar(identifier: .islamic) : Calendar.current
                List(0..<(showHijri ? model.hijriMonthsStored.count : model.regionalMonthsStored.count), id: \.self) { index in
                    let d = currCal.date(byAdding: .month, value: index, to: Date())!
                    let cal = (showHijri ? MonthModel.CalendarType.Hijri : MonthModel.CalendarType.Regional)
                    let daysInMonth = self.model.dates(for: d, calendarType: cal)
                    Text("\(daysInMonth.count)")
                        .onAppear {
                            // for now, disable infinite scrolling
//                            self.getNextPageIfNecessary(encounteredIndex: index)
                        }
                }
//                VStack {
//
//                    ScrollView {
//                        HStack { // force labels to truncate and ensure equal widths OR let them shrink
//                            Text("day")
//                            ForEach(Prayer.allCases, id: \.self) { p in
//                                Divider()
//                                    .background(Color.black)
//                                Text(p.localizedOrCustomString())
//                            }
//                        }
//                        .background(Color(.lightGray))
//                        Spacer()
//                    }
//                    .edgesIgnoringSafeArea(.all)
//                }
            }
            .padding()
            //            .padding()
        }
    }
}


@available(iOS 13.0.0, *)
struct CalViewPreview: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .background(Rectangle().foregroundColor(.white), alignment: .center)
    }
}
