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
    var body: some View {
        Text("\(AthanManager.shared.guaranteedNextPrayerTime(), style: .relative)\(Locale.preferredLanguages.first?.hasPrefix("en") == true ? " \(Strings.left)" : "")")
            .fontWeight(.bold)
            .autocapitalization(.none)
            .foregroundColor(Color(.lightText))
            .multilineTextAlignment(.trailing)
            .minimumScaleFactor(0.01)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(1)
            .id(id)
    }
}
