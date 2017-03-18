//
//  PrayerManagerDelegate.swift
//  Sundial Athan
//
//  Created by Omar Alejel on 1/13/15.
//  Copyright (c) 2015 omar alejel. All rights reserved.
//

import Foundation

@objc protocol PrayerManagerDelegate {
    //    //main notification
    var manager: PrayerManager! {get set}
    func dataReady(manager: PrayerManager)
    func updatePrayer(manager: PrayerManager)
    func showLoader()
    func fifteenMinutesLeft()
    func newMeridiem()
    //    optional func updateProgress(percent: Float)
    //    //special notifications
    //    func newDay()
}
