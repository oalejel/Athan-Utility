//
//  AnimatedLabel.swift
//  Athan Utility
//
//  Created by Omar Alejel on 4/24/16.
//  Copyright © 2016 Omar Alejel. All rights reserved.
//

import UIKit

class AnimatedLabel: UILabel {
    var titles: [String] = []
    var titleIndex = 0
    
    init(frame: CGRect, titles: [String], delay: Double) {
        super.init(frame: frame)
        
        self.titles = titles
        text = titles[0]
        
        adjustsFontSizeToFitWidth = true
        numberOfLines = 1
        
        Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(nextTitle), userInfo: nil, repeats: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func nextTitle() {
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
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
}
