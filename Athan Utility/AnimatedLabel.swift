//
//  AnimatedLabel.swift
//  Athan Utility
//
//  Created by Omar Alejel on 4/24/16.
//  Copyright © 2016 Omar Alejel. All rights reserved.
//

import UIKit

// Animated Label takes an array of strings and animates through every string with a given delay
// Example: "Hello" -> "Hola" -> "Bonjour" -> repeat
class AnimatedLabel: UILabel {
    var titles: [String] = []
    var titleIndex = 0
    
    init(frame: CGRect, titles: [String], delay: Double) {
        super.init(frame: frame)
        
        self.titles = titles
        text = titles[0]
        
        adjustsFontSizeToFitWidth = true
        numberOfLines = 1
        //set a timer to animate in the next translation
        Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(nextTitle), userInfo: nil, repeats: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func nextTitle() {
        titleIndex += 1
        if titleIndex >= titles.count {
            titleIndex = 0
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { (done) in
            self.text = self.titles[self.titleIndex]
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 1
            }, completion: { (done) in
                
            })
        })
    }
}
