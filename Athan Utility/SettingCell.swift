//
//  SettingCell.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/1/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

struct GradientButtonStyle: ButtonStyle {
    @available(iOS 13.0.0, *)
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(
                Rectangle()
                    .foregroundColor(.init(.sRGB, white: 1, opacity: 0.1))
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.linear(duration: 0.2))
    }
}
