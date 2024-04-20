//
//  OptionalScrollView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/18/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import SwiftUI

// Wraps content in a scrollview if we are using a compact iphone height
//  or increased accessibility size
struct OptionalScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        if shouldUseScrollView() {
            ScrollView(.vertical) {
                content
            }
        } else {
            content
        }
    }
    
    private func shouldUseScrollView() -> Bool {
        let screenHeight = UIScreen.main.bounds.height
        let isAccessibilitySize = sizeCategory.isAccessibilityCategory

        let iPhone14ProHeight: CGFloat = 800

        // Check if screen size is smaller than iPhone 14 Pro's dimensions
        if screenHeight < iPhone14ProHeight {
            return true
        }

        // Check if accessibility sizes are larger than usual
        if isAccessibilitySize {
            return true
        }

        return false
    }
}
