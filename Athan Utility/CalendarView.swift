//
//  CalendarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Adhan
import SwiftUI

@available(iOS 13.0.0, *)
struct CalendarView: View {
    
    @State var showHijri = false
    
    var body: some View {
        VStack {
            Text("Calendar")
            .font(.largeTitle) // let font colors be naturally chosen based on dark / light mode here
            
            Picker(selection: $showHijri.animation(.linear), label: Text("Picker"), content: {
                ForEach([true, false], id: \.self) { dynamic in
                    Text(dynamic ? "Regional" : "Hijri")
                }
            })
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .foregroundColor(.white)

            
            ScrollView {
                HStack { // force labels to truncate and ensure equal widths OR let them shrink
                    Text("day")
                    ForEach(Prayer.allCases, id: \.self) { p in
                        Divider()
                            .background(Color.black)
                        Text(p.localizedOrCustomString())
                    }
                }
                .background(Color(.lightGray))
            }
        }
        
    }
}
