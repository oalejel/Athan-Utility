//
//  UIView+Fading.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 10/31/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import UIKit

extension UIView {
    /// Custom UIView method to fade out a view in 0.77 seconds
    func _hide() {
        UIView.animate(withDuration: 0.77, animations: { () -> Void in self.alpha = 0.0 })
    }
    
    /// Custom UIView method to fade in a view in 0.77 seconds
    func _show() {
        UIView.animate(withDuration: 0.77, animations: { () -> Void in self.alpha = 1.0 })
    }
}
