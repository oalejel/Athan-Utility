//
//  ElapsedView.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/25/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

extension UIFont {
    var monospacedDigitFont: UIFont {
        let oldFontDescriptor = fontDescriptor
        let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
        return UIFont(descriptor: newFontDescriptor, size: 0)
    }
    
}

private extension UIFontDescriptor {
    var monospacedDigitFontDescriptor: UIFontDescriptor {
        let fontDescriptorFeatureSettings = [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType, UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
        let fontDescriptor = self.addingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
}

class ElapsedView: UIView {
    @IBOutlet weak var elapsedLabel: UILabel!
    @IBOutlet weak var timeLeftLabel: UILabel!
    var progressBGLayer: CAShapeLayer!
    var progressLayer: CAShapeLayer!
    var barLength: CGFloat!
    var didDraw = false
    var animationClosure: (() -> ())?
    
    //both in seconds
    var timeElapsed: CGFloat! = 0
    var interval: CGFloat! = 0
    
    var updateTimer: Timer! {
        didSet {
            //should protect from accidentally having an extra timer after drawrect...
            if let x = oldValue {
                x.invalidate()
            }
        }
        
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        //elapsedLabel.font = elapsedLabel.font.monospacedDigitFont
        //timeLeftLabel.font = timeLeftLabel.font.monospacedDigitFont
//        DispatchQueue.main.async {
            self.layer.cornerRadius = rect.size.height / 3
            self.layer.masksToBounds = true
            
            let RTLmode = x(self.elapsedLabel) > x(self.timeLeftLabel)
            let leftLabel: UILabel = RTLmode ? self.timeLeftLabel : self.elapsedLabel
            let rightLabel: UILabel = RTLmode ? self.elapsedLabel : self.timeLeftLabel
            
            let offset: CGFloat = 5
            let X = x(leftLabel) + width(leftLabel) + offset
            let H: CGFloat = 6
            let Y = (height(self) / 2) - H / 2
            let end = x(rightLabel)
            self.barLength = end - X - offset
            
            self.progressBGLayer = CAShapeLayer()
            self.progressBGLayer.frame = CGRect(x: X, y: Y, width: self.barLength, height: H)
            self.progressBGLayer.cornerRadius = H / 2
            
            self.layer.addSublayer(self.progressBGLayer)
            
            self.progressLayer = CAShapeLayer()
            self.progressLayer.frame = CGRect(x: X, y: Y, width: H, height: H)
            self.progressLayer.cornerRadius = H / 2
            self.progressLayer.backgroundColor = Global.manager.timeLeftColor().cgColor
            self.layer.addSublayer(self.progressLayer)
            
            self.backgroundColor = Global.darkerGray
            self.progressBGLayer.backgroundColor = Global.darkestGray.cgColor
            
            self.didDraw = true
            //if we had to wait for the view to be drawn...
            if let c = self.animationClosure {
                // setting self.animationClosure to nil right after calling it is dangerous
                c()
            }
            
            self.updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ElapsedView.timerTriggered), userInfo: nil, repeats: true)
//        }
    }

    func setup(_ interval: CGFloat, timeElapsed: CGFloat) {
        // create a closure to be called as soon as things are drawn
        self.interval = interval
        self.timeElapsed = timeElapsed
        
        self.animationClosure = {
            DispatchQueue.main.async { () -> Void in
                //hopefully we wont need to account for the ∆t between this and call time...
                let progress = CGFloat(timeElapsed / interval)
                let currentLength = progress * self.barLength
                let secondsLeft = interval - timeElapsed
            
                self.progressLayer.frame.size.width = currentLength
                self.progressLayer.backgroundColor = Global.manager.timeLeftColor().cgColor
                
                let anim = CABasicAnimation(keyPath: "tranform.width")
                anim.duration = Double(secondsLeft)
                anim.toValue = self.progressBGLayer.frame.size.width
                anim.fromValue = currentLength
                self.progressLayer.add(anim, forKey: "transform.width")
                self.progressLayer.removeAllAnimations()
                
                self.adjustTimeLabels()
            }
            // remove on completion
//            self.animationClosure = nil
        }
        
        // if we already drew to the screen, then okay to proceed and call block
        if self.didDraw {
            self.progressLayer.removeAllAnimations()
            self.animationClosure!()
        }
    }

    @objc func timerTriggered() {
        timeElapsed += 1
        
        if timeElapsed >= interval {
            
        }
        adjustTimeLabels()
    }
    
    func adjustTimeLabels() {
        let hoursPassed = Int(timeElapsed / 3600)
        let minutesPassed = Int(timeElapsed / 60) % 60
        let secondsPassed = Int(timeElapsed) % 60
        elapsedLabel.text = String(format: "%02d:%02d:%02d", arguments: [hoursPassed, minutesPassed, secondsPassed])
        
        let totalSecondsLeft = interval - timeElapsed
        
//        // safety check for negative time
//        if totalSecondsLeft < 0 {
//            Global.manager.delegate.emergencyRefresh()
//        }
        
        let hoursLeft = Int(totalSecondsLeft / 3600)
        let minutesLeft = Int(totalSecondsLeft / 60) % 60
        let secondsLeft = (Int(totalSecondsLeft) % 60) + 1
        timeLeftLabel.text = String(format: "%02d:%02d:%02d", arguments: [hoursLeft, minutesLeft, secondsLeft])
    }
}
