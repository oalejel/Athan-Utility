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
        // Live Activities intentionally disabled app-wide (product decision):
        //  - SuhoorLiveActivity(): lingers after app closes (pending fix)
        //  - FajrAlarmLiveActivity(): AlarmKit only needs it when the alarm uses
        //    `secondaryButtonBehavior: .countdown`. The Fajr alarm is configured
        //    alert-only (no countdown), so no Live Activity is required.
        // SuhoorLiveActivity()
        // FajrAlarmLiveActivity()
    }
}
