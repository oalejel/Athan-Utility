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
        let fontDescriptorFeatureSettings = [[UIFontFeatureTypeIdentifierKey: kNumberSpacingType, UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings]
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
    
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        //elapsedLabel.font = elapsedLabel.font.monospacedDigitFont
        //timeLeftLabel.font = timeLeftLabel.font.monospacedDigitFont
        DispatchQueue.main.async {
            self.layer.cornerRadius = rect.size.height / 3
            self.layer.masksToBounds = true
            
            let offset: CGFloat = 5
            let X = x(self.elapsedLabel) + width(self.elapsedLabel) + offset
            let H: CGFloat = 6
            let Y = (height(self) / 2) - H / 2
            let end = x(self.timeLeftLabel)
            self.barLength = end - X - offset
            
            self.progressBGLayer = CAShapeLayer()
            self.progressBGLayer.frame = CGRect(x: X, y: Y, width: self.barLength, height: H)
            self.progressBGLayer.cornerRadius = H / 2
            self.progressBGLayer.backgroundColor = UIColor(white: 0.1, alpha: 1.0).cgColor
            self.layer.addSublayer(self.progressBGLayer)
            
            self.progressLayer = CAShapeLayer()
            self.progressLayer.frame = CGRect(x: X, y: Y, width: H, height: H)
            self.progressLayer.cornerRadius = H / 2
            self.progressLayer.backgroundColor = UIColor.green.cgColor
            self.layer.addSublayer(self.progressLayer)
            
            self.didDraw = true
            //if we had to wait for the view to be drawn...
            if let c = self.animationClosure {
                c()
                self.animationClosure = nil
            }
            
            self.updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ElapsedView.updateLabels), userInfo: nil, repeats: true)
            
        }
        
    }

    func setup(_ interval: CGFloat, timeElapsed: CGFloat) {
        
        DispatchQueue.main.async { () -> Void in
            self.interval = interval
            self.timeElapsed = timeElapsed
            self.animationClosure = {
                //hopefully we wont need to account for the ∆t between this and call time...
                let progress = CGFloat(timeElapsed / interval)
                let currentLength = progress * self.barLength
                let secondsLeft = interval - timeElapsed
                
                self.progressLayer.frame.size.width = currentLength
                
                let anim = CABasicAnimation(keyPath: "tranform.width")
                anim.duration = Double(secondsLeft)
                anim.toValue = currentLength
                anim.fromValue = currentLength
                self.progressLayer.add(anim, forKey: "transform.width")
                self.progressLayer.removeAllAnimations()
                
                self.setLabels()
            }
            if self.didDraw {
                self.animationClosure!()
                self.animationClosure = nil
            }
        }
    }
    
    func updateTheme() {
        if Global.darkTheme {
            
        } else {
            backgroundColor = UIColor.white
            elapsedLabel.textColor = UIColor.darkGray
            timeLeftLabel.textColor = UIColor.darkGray
        }
    }
    
    func updateLabels() {
        timeElapsed = timeElapsed + 1
        setLabels()
    }
    
    func setLabels() {
        let hoursPassed = Int(timeElapsed / 3600)
        let minutesPassed = Int(timeElapsed / 60) % 60
        let secondsPassed = Int(timeElapsed) % 60
        elapsedLabel.text = String(format: "%02d:%02d:%02d", arguments: [hoursPassed, minutesPassed, secondsPassed])
        
        let totalSecondsLeft = interval - timeElapsed
        let hoursLeft = Int(totalSecondsLeft / 3600)
        let minutesLeft = Int(totalSecondsLeft / 60) % 60
        let secondsLeft = (Int(totalSecondsLeft) % 60) + 1
        timeLeftLabel.text = String(format: "%02d:%02d:%02d", arguments: [hoursLeft, minutesLeft, secondsLeft])
    }
}
