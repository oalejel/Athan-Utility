//
//  WidgetHelpers.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/23/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import SwiftUI
import WidgetKit

// Support iOS 17+ container backgrounds.
// Some widgets don't have background or need padding.
extension View {
    @ViewBuilder
    func applyContainerBackground(entry: AthanEntry, useGradientBackground: Bool, usePadding: Bool) -> some View {
        if #available(iOS 17, *) {
            self
                .padding(.all, usePadding ? nil : 0)
                .containerBackground(for: .widget) {
                    if useGradientBackground {
                        LinearGradient(gradient: entry.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .ignoresSafeArea()
                    }
                }
                .contentMargins(0)
                .ignoresSafeArea()
        } else {
            ZStack {
                if useGradientBackground {
                    LinearGradient(gradient: entry.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                self
                    .padding(.all, usePadding ? nil : 0)
            }
        }
    }
}

