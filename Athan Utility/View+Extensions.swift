//
//  View+Extensions.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/1/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
extension View {
    public func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
             .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }
}

//@available(iOS 13.0.0, *)
//extension View {
//    // view.inverseMask(_:)
//    public func inverseMask<M: View>(_ mask: M) -> some View {
//        // exchange foreground and background
//        let inversed = mask
//            .foregroundColor(.black)  // hide foreground
//            .background(Color.white)  // let the background stand out
//            .compositingGroup()       // ⭐️ composite all layers
//            .luminanceToAlpha()       // ⭐️ turn luminance into alpha (opacity)
//        return self.mask(inversed)
//    }
//}
