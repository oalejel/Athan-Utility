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
    var lastUpdate: Date!
    var updateTask: (() -> ())!
    
    var dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        manager = WatchDataManager(delegate: self)
    }
    
    func dataReady(manager: WatchDataManager) {
        print("data here!")
        
        updateTask = {
            //NEED TO DO A REFRESH SINCE THIS IS EXECUTED LATER!!...
            manager.calculateCurrentPrayer()
            manager.calculateProgress()
            
            let currentP = manager.currentPrayer
            self.currentPrayerLabel.setText(currentP.stringValue())
            
            self.dateFormatter.dateFormat = "h:mm a"
            self.nextPrayerLabel.setText("\(currentP.next().stringValue()) at \(self.dateFormatter.string(from: manager.nextPrayerTime()))")
            
            ///start timer
            self.prayerTimer.setDate(manager.nextPrayerTime())
            self.prayerTimer.start()
            
            ///set progress
            let length = Int(100 * manager.timeElapsed / manager.interval)
            print("progress out of 100: \(length)")
            self.progressImage.setImageNamed("badge-")
            let duration = (TimeInterval(length) / 100.0 * 1.5)
            self.progressImage.startAnimatingWithImages(in: NSRange(location: 0, length: length), duration: duration, repeatCount: 1)
            self.lastLocation = length
            
            //prayer image
            self.prayerImage.setImage(self.imageForPrayer(currentP))
            
            self.lastUpdate = Date()
        }
        
        if !interfaceLoaded {
            updatePending = true
        } else {
            updateTask()
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
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
        if Date().timeIntervalSince(manager.nextPrayerTime()) > 0.0 {
            updateTask()
        } else if interfaceLoaded {
            let length = Int(100 * manager.timeElapsed / manager.interval) - lastLocation
            if length > 0 {
                print("progress out of 100: \(length)")
                let duration = (TimeInterval(length) / 100.0 * 1.5)
                progressImage.startAnimatingWithImages(in: NSRange(location: lastLocation, length: length), duration: duration, repeatCount: 1)
                lastLocation += length
            }
        }
    }

    func imageForPrayer(_ p: PrayerType) -> UIImage {
        var imageName = ""
        switch p {
        case .fajr:
            imageName = "sunhorizon"
        case .shurooq:
            imageName = "sunhorizon"
        case .thuhr:
            imageName = "sun"
        case .asr:
            imageName = "sunfilled"
        case .maghrib:
            imageName = "sunhorizon"
        case .isha:
            imageName = "moon"
        }
        
        return UIImage(named: imageName)!
    }

}
