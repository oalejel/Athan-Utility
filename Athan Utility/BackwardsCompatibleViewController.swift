//
//  BackwardsCompatibleViewController.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/1/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import UIKit

class BackwardsCompatibleViewController: UIViewController {
    
    var gradientLayer: CAGradientLayer?
    var addedGrad = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !addedGrad {
//            let gradLayer = CAGradientLayer()
//            gradLayer.colors = [UIColor.black.cgColor, UIColor(red: 0, green: 0, blue: 0.3, alpha: 1).cgColor]
//            gradLayer.frame = view.frame
//            gradLayer.startPoint = CGPoint(x: 0.2, y: 0.2)
//            gradLayer.endPoint = CGPoint(x: 1, y: 1)
//            view.layer.insertSublayer(gradLayer, at: 0)
            addedGrad = true
        }
    }

}
