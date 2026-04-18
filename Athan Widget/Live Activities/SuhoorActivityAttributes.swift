//
//  SuhoorActivityAttributes.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 2/17/26.
//  Copyright © 2026 Omar Alejel. All rights reserved.
//

import Foundation
import ActivityKit
//import Foundation
//import SwiftUI
//import WidgetKit

@available(iOS 16.1, *)
struct SuhoorActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var suhoorTime: Date
        var fajrTime: Date
        var locationName: String
    }
    
    var activityName: String
}
