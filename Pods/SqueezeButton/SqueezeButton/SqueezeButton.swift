
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

@IBDesignable class SqueezeButton: UIButton {
    var completedSqueeze = true
    var pendingOut = false
    @IBInspectable var defaultCornerRadius: CGFloat = 10 {
        didSet {
            layer.cornerRadius = defaultCornerRadius
        }
    } // can be set in interface builder
    
    // for gradient purposes
    var firstLayoutComplete = false
    var pendingGradient = false
    var drawGradientClosure: (() -> ())?
    
    
    //setup corner radius and mask to bounds to prevent corners from being shown
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = defaultCornerRadius
        layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = defaultCornerRadius
        layer.masksToBounds = true
    }
    
    convenience init(frame: CGRect, cornerRadius: CGFloat) {
        self.init(frame: frame)
        layer.cornerRadius = cornerRadius
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !firstLayoutComplete {
            firstLayoutComplete = true
            if pendingGradient, let gc = drawGradientClosure {
                gc()
                pendingGradient = false
            }
        }
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
    
    /// adds a gradient layer to the button
    /// - note: It is okay to call this method before or after the button is drawn to the screen
    func addGradient(startColor: UIColor, endColor: UIColor, angle: CGFloat) {
        // if things have already been shown and frame size is set, we immediately add the gradient
        if firstLayoutComplete {
            drawGradient(startColor: startColor, endColor: endColor, angle: angle)
        } else {
            // else, we prepare for a future drawing of the gradient
            pendingGradient = true
            drawGradientClosure = { [weak self, a = startColor, b = endColor, c = angle] in
                self?.drawGradient(startColor: a, endColor: b, angle: c)
            }
        }
    }
    
    private func drawGradient(startColor: UIColor, endColor: UIColor, angle: CGFloat) {
        let gradient = CAGradientLayer()
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.5 + -0.5 * sin(angle), y: 0.5 + -0.5 * cos(angle))
        gradient.endPoint = CGPoint(x: 0.5 + 0.5 * sin(angle), y: 0.5 + 0.5 * cos(angle))
        gradient.frame = frame
        gradient.frame.origin = .zero
        layer.insertSublayer(gradient, at: 0)
    }
}


