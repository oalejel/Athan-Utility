//
//  TableController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/9/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

import UIKit

class TableController: UITableViewController {
    var cellHeight: CGFloat = 44//sill change according to height
    var times: [PrayerType : Date] = [:]
    //var highLightIndexes: [Int:UIColor] = [:]
    var highlightIndex: Int = -1
    var highlightColor = UIColor.white
    
    let bounds = UIScreen.main.bounds
    
    override func loadView() {
        tableView = UITableView(frame: CGRect.zero)
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false
        tableView.separatorColor = UIColor.darkGray
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.register(UINib(nibName: "PrayerCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    //dont need
    func adjustToSize() {
        cellHeight = height(tableView) / 6 //6 cells
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return height(tableView) / 6
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: "cell") as! PrayerCell
        if times.count == 6 {
            let p = PrayerType(rawValue: indexPath.row)!
            let df = Global.dateFormatter
            c.titleLabel.text = p.stringValue()
            
            if bounds.size.height < 568 {
                print(bounds.size.height)
                c.titleLabel.font = c.titleLabel.font.withSize(12)
                c.timeLabel.font = c.timeLabel.font.withSize(12)
            }
            
            
            
            /////
            
            
            
//            if NSCalendar.current.timeZone.nextDaylightSavingTimeTransition != nil {
//                //if this is true, the country observes daylgiht savings!!!
//                print("country observes daylight savings")
//                if !NSCalendar.current.timeZone.isDaylightSavingTime(for: date!) {
//                    print("this date requires a DST offset fix for website \(String(describing: date))")
//                    dateStringg += "-1"
//                }
//            }
            let date = times[p]
            df.dateFormat = "hh:mm a"
            c.timeLabel.text = df.string(from: date!)
            if (c.timeLabel.text?.count)! < 7 {
                print("ALERT: shortened time detected for cells")
                //do it again if we have an error
                df.dateFormat = "hh:mm a"
                c.timeLabel.text = df.string(from: date!)
            }
            
            ////
            
            if highlightIndex == indexPath.row {
                c.titleLabel.textColor = highlightColor
                c.timeLabel.textColor = highlightColor
            } else {
                c.timeLabel.textColor = UIColor.white
                c.titleLabel.textColor = UIColor.white
            }
        } else {
            if indexPath.row < 6 {
                let p = PrayerType(rawValue: indexPath.row)!
                c.titleLabel.text = p.stringValue()
                c.timeLabel.text = "0:00"
            }
        }
        
        return c
    }
    
    func reloadCellsWithTimes(_ t: [PrayerType : Date]) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.times = t
            self.tableView.reloadData()
        })
    }
    
    func highlightCellAtIndex(_ i: Int, color: UIColor) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.highlightIndex = i
            self.highlightColor = color
            self.tableView.reloadData()
        })
    }
    
    func updateTheme() {
        if Global.darkTheme {
            view.backgroundColor = UIColor.clear
            tableView.separatorColor = UIColor.darkGray
        } else {
            view.backgroundColor = UIColor(white: 1, alpha: 0.1)
            tableView.separatorColor = UIColor.clear
        }
    }
}
