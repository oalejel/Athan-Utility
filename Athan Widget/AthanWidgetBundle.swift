//
//  SecondaryAthanWidgetBundle.swift
//  SecondaryAthanWidget
//
//  Created by Omar Al-Ejel on 4/23/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
@available(iOS 17.0.0, *)
struct AthanWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        Athan_Widget()
        SecondaryAthanWidget()
        TertiaryAthanWidget()
        // Live activities
        SuhoorLiveActivity()

        // AlarmKit-backed Fajr alarm Live Activity. Required by AlarmKit
        // whenever an alarm uses `secondaryButtonBehavior: .countdown`.
        // The `#if canImport(AlarmKit)` guard lets the widget target still
        // compile against older SDKs that don't ship AlarmKit headers; the
        // runtime `#available` guards usage on the device.
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            FajrAlarmLiveActivity()
        }
        #endif
    }
}
