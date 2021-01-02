//
//  TableController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/9/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

import UIKit
import Adhan

class TableController: UITableViewController {
    var cellHeight: CGFloat = 44//sill change according to height
    var times: PrayerTimes?
    //var highLightIndexes: [Int:UIColor] = [:]
    var highlightIndex: Int = -1
    var highlightColor = UIColor.white
    
    let bounds = UIScreen.main.bounds
    
    var lastHeight: CGFloat = 0
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // trick to get table cells to resize when the height changes after siri button is removed
        if lastHeight != 0 && lastHeight != height(tableView) {
            tableView.reloadData()
        }
        lastHeight = height(tableView)
    }
    
    override func loadView() {
        tableView = UITableView(frame: CGRect.zero)
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false
//        tableView.separatorColor = UIColor.darkGray
        tableView.separatorStyle = .none
//        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.register(UINib(nibName: "PrayerCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    //dont need
    func adjustToSize() {
        cellHeight = height(tableView) / 6 //6 cells
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return height(tableView) / 6
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return height(tableView) / 6
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! PrayerCell
        if let times = times {
            let p = Prayer(index: indexPath.row)
            let df = Global.dateFormatter
            cell.titleLabel.text = p.localizedString()
            
            if bounds.size.height < 568 {
                print(bounds.size.height)
                cell.titleLabel.font = cell.titleLabel.font.withSize(12)
                cell.timeLabel.font = cell.timeLabel.font.withSize(12)
            }

            let prayerDate = times.time(for: p)
                df.timeStyle = .short
                df.dateStyle = .none
                
                let timeString = df.string(from: prayerDate).uppercased()
                //#warning("add this back")
//                if let meridEnd = timeString.lastIndex(where: { (char) -> Bool in
//                    return CharacterSet.alphanumerics.contains(char.unicodeScalars.first!)
//                }) {
//                    if let meridStart = timeString.firstIndex(where: { (char) -> Bool in
//                        return CharacterSet.alphanumerics.contains(char.unicodeScalars.first!)
//                    }) {
//                        if meridEnd == timeString.endIndex {
//                            // we know meridiem is at right end of string, so put space before meridStart
//                            timeString.insert(" ", at: meridStart)
//                        } else {
//                            // else, we know meridiem is likely on left side of string
//                            timeString.insert(" ", at: timeString.index(meridEnd, offsetBy: 1))
//                        }
//                    }
//                }
                
                cell.timeLabel.text = timeString
            
//            df.dateFormat = "hh:mm a"
//            c.timeLabel.text = df.string(from: date!)
//            if (c.timeLabel.text?.count)! < 7 {
//                print("ALERT: shortened time detected for cells")
//                //do it again if we have an error
//                df.dateFormat = "hh:mm a"
//                c.timeLabel.text = df.string(from: date!)
//            }
            
            if highlightIndex == indexPath.row {
                cell.titleLabel.textColor = highlightColor
                cell.timeLabel.textColor = highlightColor
            } else {
                cell.timeLabel.textColor = UIColor.white
                cell.titleLabel.textColor = UIColor.white
            }
        } else {
            if indexPath.row < 6 {
                let p = Prayer(index: indexPath.row)
                cell.titleLabel.text = p.localizedString()
                cell.timeLabel.text = "0:00"
            }
        }
        
        return cell
    }
    
    func reloadCellsWithTimes(_ t: PrayerTimes) {
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
    
    
    
//    func updateTheme() {
//        if Global.darkTheme {
//            view.backgroundColor = UIColor.clear
//            tableView.separatorColor = UIColor.darkGray
//        } else {
//            view.backgroundColor = UIColor(white: 1, alpha: 0.1)
//            tableView.separatorColor = UIColor.clear
//        }
//    }
}
