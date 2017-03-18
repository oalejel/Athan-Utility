//
//  GlanceController.swift
//  Watch Athan Extension
//
//  Created by Omar Alejel on 12/23/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController, WatchDataDelegate {
    @IBOutlet var prayerImage: WKInterfaceImage!
    @IBOutlet var progressImage: WKInterfaceImage!
    @IBOutlet var currentPrayerLabel: WKInterfaceLabel!
    @IBOutlet var nextPrayerLabel: WKInterfaceLabel!
    @IBOutlet var prayerTimer: WKInterfaceTimer!
    
    var manager: WatchDataManager!
    
    var lastLocation = 0
    
    var interfaceLoaded = false
    var updatePending = false
    var lastUpdate: NSDate!
    var updateTask: (() -> ())!
    
    var dateFormatter = NSDateFormatter()
    
    override init() {
        super.init()
        manager = WatchDataManager(delegate: self)
    }
    
    func dataReady(manager manager: WatchDataManager) {
        print("data here!")
        
        updateTask = {
            //NEED TO DO A REFRESH SINCE THIS IS EXECUTED LATER!!...
            manager.calculateCurrentPrayer()
            manager.calculateProgress()
            
            let currentP = manager.currentPrayer
            self.currentPrayerLabel.setText(currentP.stringValue())
            
            self.dateFormatter.dateFormat = "h:mm a"
            self.nextPrayerLabel.setText("\(currentP.next().stringValue()) at \(self.dateFormatter.stringFromDate(manager.nextPrayerTime()))")
            
            ///start timer
            self.prayerTimer.setDate(manager.nextPrayerTime())
            self.prayerTimer.start()
            
            ///set progress
            let length = Int(100 * manager.timeElapsed / manager.interval)
            print("progress out of 100: \(length)")
            self.progressImage.setImageNamed("badge-")
            let duration = (NSTimeInterval(length) / 100.0 * 1.5)
            self.progressImage.startAnimatingWithImagesInRange(NSRange(location: 0, length: length), duration: duration, repeatCount: 1)
            self.lastLocation = length
            
            //prayer image
            self.prayerImage.setImage(self.imageForPrayer(currentP))
            
            self.lastUpdate = NSDate()
        }
        
        if !interfaceLoaded {
            updatePending = true
        } else {
            updateTask()
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
        interfaceLoaded = true
        
        //run things that could not be run earlier...
        if updatePending {
            updateTask()//this will reset lastUpdate
            updatePending = false
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        //update if a new prayer time passed...
        if NSDate().timeIntervalSinceDate(manager.nextPrayerTime()) > 0.0 {
            updateTask()
        } else if interfaceLoaded {
            let length = Int(100 * manager.timeElapsed / manager.interval) - lastLocation
            if length > 0 {
                print("progress out of 100: \(length)")
                let duration = (NSTimeInterval(length) / 100.0 * 1.5)
                progressImage.startAnimatingWithImagesInRange(NSRange(location: lastLocation, length: length), duration: duration, repeatCount: 1)
                lastLocation += length
            }
        }
    }

    func imageForPrayer(p: PrayerType) -> UIImage {
        var imageName = ""
        switch p {
        case .Fajr:
            imageName = "sunhorizon"
        case .Shurooq:
            imageName = "sunhorizon"
        case .Thuhr:
            imageName = "sun"
        case .Asr:
            imageName = "sunfilled"
        case .Maghrib:
            imageName = "sunhorizon"
        case .Isha:
            imageName = "moon"
        }
        
        return UIImage(named: imageName)!
    }

}
