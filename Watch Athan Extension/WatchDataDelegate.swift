//
//  WatchDataDelegate.swift
//  Athan Utility
//
//  Created by Omar Alejel on 12/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import Foundation
import WatchKit

@objc protocol WatchDataDelegate {
    var manager: WatchDataManager! {get set}
    func dataReady(manager manager: WatchDataManager)
    optional func updateProgress()
    optional func updatePrayer()
}
