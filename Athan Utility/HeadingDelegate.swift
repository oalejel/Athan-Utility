//
//  HeadingDelegate.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/30/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import Foundation
import CoreLocation

// A HeadingDelegate is notified when the compass direction is changed in "Qibla Mode"
@objc protocol HeadingDelegate {
    func newHeading(_ h: CLHeading)
}
