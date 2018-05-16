//
//  SqueezeButton.swift
//  Expense Tracker
//
//  Created by Omar Alejel on 6/30/15.
//  Copyright © 2015 omar alejel. All rights reserved.
//

import UIKit

/* Note: if gesture recognizers are used in your application, you may need to prevent delays on this view's touch recognition.
 
 One simple way to accomplish this is:
 let window = UIApplication.shared.windows[0]
 let g1 = window.gestureRecognizers?[0]
 g1?.delaysTouchesBegan = false
 let g2 = window.gestureRecognizers?[1]
 g2?.delaysTouchesBegan = false
 */

class SqueezeButton: UIButton {
    var completedSqueeze = true
    var pendingOut = false
    static let defaultCornerRadius: CGFloat = 10
    
    //setup corner radius and mask to bounds to prevent corners from being shown
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = SqueezeButton.defaultCornerRadius
        layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = SqueezeButton.defaultCornerRadius
        layer.masksToBounds = true
    }
    
    //react to touches with a press or rescale animation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        press()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        rescaleButton()
    }
    
    //if press has not completed, rescaling will not take place
    func press() {
        UIView.animateKeyframes(withDuration: 0.1, delay: 0.0, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: { () -> Void in
            self.completedSqueeze = false
            self.transform = self.transform.scaledBy(x: 0.9, y: 0.9)
        }) { (done) -> Void in
            self.completedSqueeze = true
            //if we find that our touch ended before shrinking is complete, we rescale
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


