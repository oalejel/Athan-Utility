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

@available(iOS 13.0.0, *)
extension View {
    func onValueChanged<Value: Equatable>(_ value: Value, completion: (Value) -> Void) -> some View {
        completion(value)
        return self
    }
}
