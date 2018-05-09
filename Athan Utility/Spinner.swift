//
//  Spinner.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 5/7/18.
//  Copyright © 2018 Omar Alejel. All rights reserved.
//

import UIKit
import SwiftSpinner

//  Note: It is necessary to modify the SwiftSpinner class, as well as the vibrancyView
//  property to 'open' after updating on pods as of Swift 4

class Spinner: SwiftSpinner {
    fileprivate var cancelButton: UIButton!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        let f = frame
        cancelButton = SqueezeButton(frame: CGRect(x: 0, y: 0, width: f.size.width / 3, height: f.size.width / 7))
        cancelButton.layer.cornerRadius = 10
        cancelButton.backgroundColor = UIColor(white: 0.87, alpha: 0.5)
        cancelButton.setTitle("Cancel", for: UIControlState.normal)
        cancelButton.addTarget(Global.manager, action: #selector(Global.manager.cancelRequest), for: .touchUpInside)
        cancelButton.setTitleColor(UIColor.black, for: UIControlState())
        cancelButton.center = CGPoint(x: f.size.width / 2, y: f.size.height * 0.8)
        self.vibrancyView.contentView.addSubview(cancelButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
