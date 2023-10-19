//
//  CalendarExport.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 3/21/23.
//  Copyright © 2023 Omar Alejel. All rights reserved.
//
 
import Foundation
import TPPDF

class CalendarExport {
    func makePDF() -> PDFDocument {
        let pdf = PDFDocument(format: .a4)
        pdf.add(textObject: PDFSimpleText.init(text: "Athan Times"))
        
        // for each month
        // add table with rows = # of days
        // columns: date, fajr, sunrise, thuhr, asr, maghrib, isha
        pdf.add(table: PDFTable(rows: 0, columns: 0))
        return pdf
    }
}
