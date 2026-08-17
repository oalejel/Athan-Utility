//
//  UpdatingTextView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/16/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 14.0.0, *)
struct TimeLeftView: View {
    @Binding var id: Int

    /// Time from the pinned clock to the next prayer, in the same shape the live
    /// relative style produces ("1 hr, 16 min left").
    private static func pinnedRemaining() -> String {
        let now = snapshotFixedNow ?? Date()
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now,
                                                    to: AthanManager.shared.guaranteedNextPrayerTime())
        let h = max(0, comps.hour ?? 0), m = max(0, comps.minute ?? 0)
        let f = DateComponentsFormatter()
        f.allowedUnits = h > 0 ? [.hour, .minute] : [.minute]
        f.unitsStyle = .short
        let base = f.string(from: DateComponents(hour: h, minute: m)) ?? "\(m)m"
        let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true
        return isEnglish ? "\(base) \(Strings.left)" : base
    }
    var body: some View {
        // Text(_, style: .relative) is rendered by SwiftUI against the REAL system clock,
        // so it is the one countdown the injected screenshot clock cannot reach — it kept
        // showing hours-to-Isha from the capture machine's afternoon while every other
        // element showed the pinned Maghrib. During a capture, render a static string
        // computed from the same clock everything else uses.
        Group {
            if snapshotFixedNow == nil {
                Text("\(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative)\(Locale.preferredLanguages.first?.hasPrefix("en") == true ? " \(Strings.left)" : "")")
                    .fontWeight(.bold)
            } else {
                Text(Self.pinnedRemaining())
                    .fontWeight(.bold)
            }
        }
            .autocapitalization(.none)
            .foregroundColor(Color(.lightText))
            .multilineTextAlignment(.trailing)
            .minimumScaleFactor(0.01)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(1)
            .id(id)
    }
}
