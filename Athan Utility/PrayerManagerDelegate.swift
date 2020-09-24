//
//  PrayerManagerDelegate.swift
//  Sundial Athan
//
//  Created by Omar Alejel on 1/13/15.
//  Copyright (c) 2015 omar alejel. All rights reserved.
//

import Foundation

/*
 This protocol defines a delegate for prayer time updates
 A PrayerManagerDelegate protocol should be used for all sorts of Extensions including
 Watchkit and Today extensions
*/
@objc protocol PrayerManagerDelegate {
    var manager: PrayerManager! {get set}
    var locationIsSynced: Bool { get set }
    
    func dataReady(manager: PrayerManager)
    @objc optional func newPrayer(manager: PrayerManager)
    @objc optional func setShouldShowLoader()
    @objc optional func fifteenMinutesLeft()
    @objc optional func newMeridiem()
    @objc optional func loadingHandler()
    @objc optional func hideLoadingView()
}
