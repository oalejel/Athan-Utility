//
//  BubbleTextView.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/12/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

import UIKit

class BubbleTextView: UIView {
    var letterLabel: UILabel!
    
    init(letter: Character) {
        let f = CGRect(x: 0, y: 0, width: 20, height: 20)
        super.init(frame: f)
        letterLabel = UILabel(frame: f)
        letterLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        letterLabel.textAlignment = .center
        letterLabel.adjustsFontSizeToFitWidth = true
        letterLabel.text = "\(letter)" //NSLocalizedString("\(letter)_letter", comment: "")
        addSubview(letterLabel)
        letterLabel.textColor = UIColor.black
        layer.cornerRadius = f.width / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
