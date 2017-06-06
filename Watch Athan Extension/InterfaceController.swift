//
//  InterfaceController.swift
//  Watch Athan Extension
//
//  Created by Omar Alejel on 12/23/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WatchDataDelegate {
    ///interface
    @IBOutlet var currentPrayerLabel: WKInterfaceLabel!
    @IBOutlet var timeLeftTimer: WKInterfaceTimer!
    @IBOutlet var nextPrayerLabel: WKInterfaceLabel!
    @IBOutlet var nextTimeLabel: WKInterfaceLabel!
    @IBOutlet var progressImage: WKInterfaceImage!
    @IBOutlet var prayerTable: WKInterfaceTable!
    
    var dateFormatter = DateFormatter()
    
    var interfaceLoaded = false
    var tasks: [() -> ()] = []

    var manager: WatchDataManager!
    
    var lastImageIndex = 0
    
    override init() {
        super.init()
        manager = WatchDataManager(delegate: self)
    }
    
    func dataReady(manager: WatchDataManager) {
        print("data here!")
        
        let task = {
            self.refreshCurrentInfo()
            
            ///set rows
            self.prayerTable.setNumberOfRows(6, withRowType: "prayerRow")
            for i in 0...5 {
                let row = self.prayerTable.rowController(at: i) as! PrayerRow
                row.nameLabel.setText(PrayerType(rawValue: i)!.stringValue())
                let p = PrayerType(rawValue: i)!
                self.dateFormatter.dateFormat = "h:mm a"
                row.timeLabel.setText(self.dateFormatter.string(from: manager.todayPrayerTimes[p]!))
                if p == manager.currentPrayer {
                    row.timeLabel.setTextColor(UIColor.green)
                    row.nameLabel.setTextColor(UIColor.green)
                } else {
                    row.timeLabel.setTextColor(UIColor.white)
                    row.nameLabel.setTextColor(UIColor.white)
                }
            }
        }
        
        if !interfaceLoaded {
            tasks.append(task)
        } else {
            task()
        }
    }
    
    func highlightCurrentPrayer() {
        if manager.dataReady {
            for i in 0...5 {
                let p = PrayerType(rawValue: i)!
                let row = self.prayerTable.rowController(at: i) as! PrayerRow
                if p == manager.currentPrayer {
                    row.timeLabel.setTextColor(UIColor.green)
                    row.nameLabel.setTextColor(UIColor.green)
                } else {
                    row.timeLabel.setTextColor(UIColor.white)
                    row.nameLabel.setTextColor(UIColor.white)
                }
            }
        }
    }
    
    func refreshCurrentInfo() {
        if manager.dataReady {
            let currentP = manager.currentPrayer
            self.currentPrayerLabel.setText(currentP.stringValue())
            self.nextPrayerLabel.setText(currentP.next().stringValue())
            
            ///set current prayer label
            self.dateFormatter.dateFormat = "h:mm a"
            self.nextTimeLabel.setText(self.dateFormatter.string(from: manager.nextPrayerTime()))
            
            manager.calculateProgress()
            
            ///set progress
            let length = Int(100 * manager.timeElapsed / manager.interval)
            print("progress out of 100: \(length)")
            self.progressImage.setImageNamed("badge-")
            let duration = (TimeInterval(length) / 100.0 * 1.5)
            self.progressImage.startAnimatingWithImages(in: NSRange(location: 0, length: length), duration: duration, repeatCount: 1)
            self.lastImageIndex = length
            
            ///start timer
            self.timeLeftTimer.setDate(manager.nextPrayerTime())
            
            self.timeLeftTimer.start()
        }
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        interfaceLoaded = true
        
        //run things that could not be run earlier...
        for closure in tasks {
            closure()
        }
        
        tasks.removeAll()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.prayerTable.setNumberOfRows(6, withRowType: "prayerRow")
        for i in 0...5 {
            let row = self.prayerTable.rowController(at: i) as! PrayerRow
            row.nameLabel.setText(PrayerType(rawValue: i)!.stringValue())
//            let p = PrayerType(rawValue: i)!
//            self.dateFormatter.dateFormat = "h:mm a"
//            row.timeLabel.setText(self.dateFormatter.string(from: manager.todayPrayerTimes[p]!))
//            if p == manager.currentPrayer {
            if i == 2 {
                row.timeLabel.setTextColor(UIColor.green)
                row.nameLabel.setTextColor(UIColor.green)
            }
//            } else {
//                row.timeLabel.setTextColor(UIColor.white)
//                row.nameLabel.setTextColor(UIColor.white)
//            }
        }

        
        if manager.dataReady {
            //!!!! might need to reset timer!!!!
            
            let oldP = manager.currentPrayer
            manager.calculateCurrentPrayer()
            
            if Date().timeIntervalSince(manager.tomorrowPrayerTimes[.fajr]!) > 0 {
                manager.alignPrayerTimes()
                manager.calculateProgress()
                dataReady(manager: manager)
            } else if manager.currentPrayer != oldP {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.refreshCurrentInfo()
                    self.updateProgress()
                    self.highlightCurrentPrayer()
                    self.refreshCurrentInfo()
                })
            }
            
            var length = Int(100 * manager.timeElapsed / manager.interval)
            if length == 0 {length = 1}
            print("progress out of 100: \(length)")
            progressImage.setImageNamed("badge-")
            let duration = (TimeInterval(length) / 100.0 * 1.5)
            progressImage.startAnimatingWithImages(in: NSRange(location: 0, length: length), duration: duration, repeatCount: 1)
            lastImageIndex = length
            
            if manager.elapsedTimer == nil {
                manager.elapsedTimer = Timer.scheduledTimer(timeInterval: 1, target: manager, selector: #selector(manager.updateElapsed), userInfo: nil, repeats: true)
            }
        }
    }

    func updateProgress() {
        if manager.dataReady {
            var length = Int(100 * manager.timeElapsed / manager.interval)
            if length == 0 {length = 1}
            if length != lastImageIndex {
                progressImage.setImageNamed("badge-")
                let duration = (TimeInterval(length) / 100.0 * 1.5)
                progressImage.startAnimatingWithImages(in: NSRange(location: 0, length: length), duration: duration, repeatCount: 1)
                lastImageIndex = length
            }
        }
    }
    
    func updatePrayer() {
        refreshCurrentInfo()
        highlightCurrentPrayer()
    }

}
