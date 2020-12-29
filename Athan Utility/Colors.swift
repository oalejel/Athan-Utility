//
//  Colors.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/25/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import UIKit
import SwiftUI
import Adhan

extension UIColor {
    static let athanTransparentWhite: UIColor = UIColor(white: 1, alpha: 0.2)
    
    var rgb: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue)
    }
    var rgbFloat: (red: Float, green: Float, blue: Float) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (Float(red), Float(green), Float(blue))
    }
}

@available (iOS 13, *)
extension AppearanceSettings {
    func colors(for context: Prayer?) -> (Color, Color) {
        let (t1, t2) = self.colorTuplesForContext(optionalPrayer: context)
        let c1 = Color(.sRGB, red: t1.0, green: t1.1, blue: t1.2, opacity: 1)
        let c2 = Color(.sRGB, red: t2.0, green: t2.1, blue: t2.2, opacity: 1)
        return (c1, c2)
    }
}
