//
//  CalendarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan
import SwiftUI

struct DayModel {
    var times: PrayerTimes? // can also get date from this property
    var moonPhase: Double // percent for moon phase
}

struct SimpleDate: Hashable {
    let day: Int
    let month: Int
    let year: Int
}

// used for looking up by year and month
struct HijriMonthYear: Hashable {
    let month: Int
    let year: Int
}

struct RegionalMonthYear: Hashable {
    let month: Int
    let year: Int
}

@available(iOS 13.0.0, *)
class MonthModel: ObservableObject {
    @Published var dayModelDict: [SimpleDate:DayModel] = [:]
    let suncalc = SwiftySuncalc()
    var hijriMonthsStored = Set<HijriMonthYear>()
    var regionalMonthsStored = Set<RegionalMonthYear>()
    
    static var shared = MonthModel()
    
    // date does not need to be at beginning of month
    // init will generate all appropriate prayer times for the month of this date
    //    init() {
    //
    //    }
    
    func generateStartMonths() {
//        DispatchQueue.global(qos: .userInitiated).async { [self] in
        let dayComp = Calendar.current.dateComponents([.day], from: Date())
        let offsetDay = dayComp.day!
        let thisMonthsFirstDay = Calendar.current.date(byAdding: .day , value: 1-offsetDay, to: Date())!
        
        // add 24 months for regional at init
        for i in 0..<3 {
            let iterDate = Calendar.current.date(byAdding: .month, value: i,
                                                 to: thisMonthsFirstDay, wrappingComponents: true)!
            let _ = self.calculateMonthTimes(for: iterDate, calendarType: .Regional)
            let _ = calculateMonthTimes(for: iterDate, calendarType: .Hijri)
        }
//        }
    }
    
    func generateDayModel(for dayDate: Date, calendarType: CalendarType) -> DayModel {
        return DayModel(times: AthanManager.shared.calculateTimes(referenceDate: dayDate),
                        moonPhase: suncalc.getMoonIllumination(date: dayDate)["phase"]!)
    }
    
    // monthdate indicates which month we want data for
    func calculateMonthTimes(for monthDate: Date, calendarType: CalendarType) -> [DayModel] {
        
        var selectedCalendar = Calendar.current
        let hijriCalendar = Calendar(identifier: .islamic)
        if calendarType == .Hijri {
            selectedCalendar = hijriCalendar
        }
        // select month of interest and iterate through all days
        let components = selectedCalendar.dateComponents([.day, .month], from: monthDate)
        let offsetDay = components.day!
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
        print("MONTHS STORED: \(regionalMonthsStored.count)")
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
    
    @State var model = MonthModel.shared
    
    let x: Int = {
        UITableView.appearance().tableFooterView = UIView()
        // To remove all separators including the actual ones:
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = .clear
        UITableView.appearance().showsVerticalScrollIndicator = false
        return 0
    }()
    
    
    let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        return df
    }()
    
    
    var body: some View {
        GeometryReader { g in
            VStack {
                
                VStack(spacing: 8) {
                    HStack { // main calendar header
                        Text("Calendar")
                            .font(Font.largeTitle.bold()) // let font colors be naturally chosen based on dark / light mode here
                            .onAppear {
                                model.generateStartMonths()
                            }
                        Spacer()
                        VStack {
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                                print("exit")
                            }, label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .font(Font.system(size: 20).bold())
                            })
                            Spacer()
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    
                    
                    Picker(selection: $showHijri.animation(.linear), label: Text("Picker"), content: {
                        ForEach([false, true], id: \.self) { hijri in
                            Text(hijri ? "Hijri" : "Regional")
                        }
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    //                .onAppear {
                    //                    // for now, disable infinite scrolling
                    ////                            self.getNextPageIfNecessary(encounteredIndex: index)
                    //                }
                }
                .padding([.top, .leading, .trailing], 12)
                
                let currCal = showHijri ? Calendar(identifier: .islamic) : Calendar.current
                //                List(0..<(showHijri ? model.hijriMonthsStored.count : model.regionalMonthsStored.count), id: \.self) { index in
                
                
                List(0..<18, id: \.self) { index in
                    let d = currCal.date(byAdding: .month, value: index, to: Date())!
                    let calEnum = (showHijri ? MonthModel.CalendarType.Hijri : MonthModel.CalendarType.Regional)
                    let daysInMonth = self.model.calculateMonthTimes(for: d, calendarType: calEnum)
                    
                    let monthDF: DateFormatter = {
                        let df = DateFormatter()
                        df.dateFormat = "MMMM"
                        df.locale = currCal.locale
                        return df
                    }()
                    
                    let yearDF: DateFormatter = {
                        let df = DateFormatter()
                        df.dateFormat = "YYY"
                        df.locale = currCal.locale
                        return df
                    }()
                    
                    
                    
                    
                    
                    
                    
                    // name of months
                    VStack(alignment: .leading) {
                        
                        // month header
                        Text(monthDF.string(from: d))
                            .foregroundColor(.red)
                            .font(Font.body.bold())
                        
                        
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
                            //                            Divider()
                            //                                .background(Color.black)
                            //                                .padding([.top, .bottom], 2)
                            
                            ForEach(Prayer.allCases, id: \.self) { p in
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
                                
                                ForEach(0..<daysInMonth.count, id: \.self) { i in
                                    Divider()
                                    let lengthGoal = 11
                                    
                                    HStack(spacing: 0) {
                                        Spacer()
                                        
                                        ZStack(alignment: .center) {
                                            let dayText: String = {
                                                var str = "\(i + 1)"
                                                while str.count + 1 < lengthGoal {
                                                    str = " " + str + " "
                                                }

                                                return str
                                            }()
                                            
                                            Text(dayText)
                                                .bold()
//                                                .font(.system(size: 14, design: .monospaced))
                                                .frame(width: (g.size.width - 12) / 10)
                                                .fixedSize(horizontal: true, vertical: true)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.01)
                                                .padding([.top, .bottom], 1)
                                        }
                                        .frame(width: 3)
                                        
                                        // row contents
                                        ForEach(Prayer.allCases, id: \.self) { p in
                                            
                                            let prayerTime = daysInMonth[i].times?.time(for: p)
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
                                                
                                            }
                                            .frame(width: 3, height: 1)
                                            
                                            //                                                Text("test")
                                            //                                                    .font(Font.system(size: 12))
                                            //                                                    .frame(width: 3, height: 1)
                                            //                                                    .frame(width: 20)
                                        }
                                        Spacer()
                                    }
                                    .padding([.top, .bottom], 2)
                                    
                                }
                                Divider()
                            }
                            //                            }.fixedSize(horizontal: true, vertical: true)
                            
                            //
                            ////                                    GeometryReader { g2 in
                            //                                        HStack(spacing: 0) {
                            //                                            Spacer()
                            //
                            //
                            //                                            Text("\(i + 1)")
                            //                                                .frame(width: (g.size.width - 24) / 10)
                            //                                                //                                .frame(width: 10)
                            //                                                .fixedSize(horizontal: true, vertical: true)
                            //                                                .lineLimit(1)
                            //                                                .minimumScaleFactor(0.01)
                            //                                                .padding([.top, .bottom], 1)
                            //
                            //
                            //                                            ForEach(Prayer.allCases, id: \.self) { p in
                            //                                                let prayerTime = daysInMonth[i].times?.time(for: p)
                            //                                                let text: String = {
                            //                                                    return prayerTime == nil ? "--" : timeFormatter.string(from: prayerTime!)
                            //                                                }()
                            //
                            //                                                Spacer()
                            //                                                Text(text)
                            //                                                    .frame(width: (g.size.width - 24) / 10)
                            //                                                    .fixedSize(horizontal: true, vertical: true)
                            //                                                    .lineLimit(1)
                            //                                                    .minimumScaleFactor(0.01)
                            //                                                    .padding([.top, .bottom], 1)
                            //                                            }
                            //
                            //                                        }
                            ////                                        .frame(width: g.size.width - 24)
                            ////                                    }
                            //
                            
                        }
                    }
//                    .id(index)
                    
                    
                }
                .id(UUID())
                
            }
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
