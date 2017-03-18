//
//  SqueezeButton.swift
//  Expense Tracker
//
//  Created by Omar Alejel on 6/30/15.
//  Copyright © 2015 omar alejel. All rights reserved.
//

import UIKit


class SqueezeButton: UIButton {
    var completedSqueeze = true
    var pendingOut = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        press()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        rescaleButton()
    }
    
    func press() {
        UIView.animateKeyframes(withDuration: 0.1, delay: 0.0, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: { () -> Void in
            self.completedSqueeze = false
            self.transform = self.transform.scaledBy(x: 0.9, y: 0.9)
            }) { (done) -> Void in
                self.completedSqueeze = true
                if self.pendingOut {
                    self.rescaleButton()
                    self.pendingOut = false
                }
        }
    }
    
    func rescaleButton() {
        if completedSqueeze {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: { () -> Void in
                self.transform = self.transform.scaledBy(x: 1/0.9, y: 1/0.9)
                }) { (done) -> Void in
                    
            }
        } else {
            pendingOut = true
        }
    }
}
