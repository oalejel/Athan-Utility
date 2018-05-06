//
//  IntroViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 4/19/16.
//  Copyright © 2016 Omar Alejel. All rights reserved.
//

import UIKit
// IntroViewController is displayed on the first launch of Athan Utility
// Its purpose is to show the user what the app is capable of doing
class IntroViewController: UIViewController {
    
    // done button exits Introduction and displays primary app interface
    var buttonHeight: CGFloat = 55
    var doneButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let f = UIScreen.main.bounds
        let layer = CAGradientLayer()
        layer.colors = [UIColor(red: 75/255, green: 28/255, blue: 152/255, alpha: 1).cgColor, UIColor.black.cgColor]
        layer.frame = f
        view.layer.addSublayer(layer)
        
        let doneButton = SqueezeButton(frame: CGRect(x: 0, y: f.size.height - buttonHeight, width: f.size.width, height: buttonHeight))
        doneButton.setTitle("Continue", for: UIControlState())
        doneButton.setTitleColor(UIColor.lightGray, for: UIControlState())
        doneButton.setTitleColor(UIColor.lightGray.withAlphaComponent(0.7), for: .highlighted)
        doneButton.backgroundColor = Global.darkestGray
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        view.addSubview(doneButton)
        
        
        // add contraints to appropriately place dismiss button for phones including iPhone X
        let left = NSLayoutConstraint(item: doneButton, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 8)
        let right = NSLayoutConstraint(item: doneButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -8)
        let bottom = NSLayoutConstraint(item: doneButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1, constant: -8)
        let height = NSLayoutConstraint(item: doneButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonHeight)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([left, right, bottom, height])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //animate1()
        showFeatures()
        
        let f = UIScreen.main.bounds
        
        // animlabel animates through different translations of "peace be upon you"
        let animLabel = AnimatedLabel(frame: CGRect(x: 0, y: 0, width: f.size.width - 40, height: 200), titles: ["السلام عليكم", "Peace Be Upon You", "平和は貴方とともに", "שָׁלוֹם עֲלֵיכֶם", "Que La Paz Está Con Usted", "Paix à Vous", "Friede Sei Mit Dir"], delay: 2.5)
        animLabel.textColor = UIColor.white
        animLabel.font = UIFont(name: "HelveticaNeue", size: 60)
        animLabel.textAlignment = .center
        animLabel.center = CGPoint(x: f.size.width / 2, y: 100)
        animLabel.alpha = 0
        view.addSubview(animLabel)
        UIView.animate(withDuration: 0.2, animations: {
            animLabel.alpha = 1
        })
    }
    
    //animates images that communicate the feature of the app
    // motion goes from either side to the middle
    func showFeatures() {
        let f = UIScreen.main.bounds
        
        let i1 = UIImage(named: "info1")
        let iv1 = UIImageView(image: i1)
        iv1.sizeToFit()
        
        let yOffset: CGFloat = 24
        let finalXOffset: CGFloat = 12
        let width = (UIScreen.main.bounds.size.width - 30) / 2
        let scale = width / iv1.frame.size.width
        
        let xOffset = (iv1.frame.size.width * scale) + 10
        let combinedHeight = 3 * iv1.frame.size.height * scale
        iv1.frame = CGRect(x: -xOffset, y: (f.size.height / 2) - (0.5 * combinedHeight), width: iv1.frame.size.width * scale, height: iv1.frame.size.height * scale)
        
        let i2 = UIImage(named: "info2")
        let iv2 = UIImageView(image: i2)
        iv2.sizeToFit()
        
        iv2.frame = CGRect(x: -xOffset, y: yOffset + ((f.size.height / 2) - (0.25 * combinedHeight)), width: iv2.frame.size.width * scale, height: iv2.frame.size.height * scale)
        
        let i3 = UIImage(named: "info3")
        let iv3 = UIImageView(image: i3)
        iv3.sizeToFit()
        iv3.frame = CGRect(x: -xOffset, y: 2 * yOffset + (f.size.height / 2), width: iv3.frame.size.width * scale, height: iv3.frame.size.height * scale)
        
        let i4 = UIImage(named: "info4")
        let iv4 = UIImageView(image: i4)
        iv4.sizeToFit()
        
        iv4.frame = CGRect(x: f.size.width + xOffset, y: ((f.size.height / 2) - (0.5 * combinedHeight)), width: iv4.frame.size.width * scale, height: iv4.frame.size.height * scale)
        let i5 = UIImage(named: "info5")
        let iv5 = UIImageView(image: i5)
        iv5.sizeToFit()
        
        iv5.frame = CGRect(x: f.size.width + xOffset, y: yOffset + ((f.size.height / 2) - (0.25 * combinedHeight)), width: iv5.frame.size.width * scale, height: iv5.frame.size.height * scale)
        
        let i6 = UIImage(named: "info6")
        let iv6 = UIImageView(image: i6)
        
        iv6.sizeToFit()
        
        iv6.frame = CGRect(x: f.size.width + xOffset, y: 2 * yOffset + (f.size.height / 2), width: iv6.frame.size.width * scale, height: iv6.frame.size.height * scale)
        
        view.addSubview(iv1)
        view.addSubview(iv2)
        view.addSubview(iv3)
        view.addSubview(iv4)
        view.addSubview(iv5)
        view.addSubview(iv6)
        
        UIView.animateKeyframes(withDuration: 3, delay: 0.5, options: UIViewKeyframeAnimationOptions.calculationModeCubicPaced, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.33, animations: {
                iv1.frame = CGRect(x: finalXOffset, y: (f.size.height / 2) - (0.5 * combinedHeight), width: iv1.frame.size.width, height: iv1.frame.size.height)
                iv4.frame = CGRect(x: f.size.width - finalXOffset - iv1.frame.size.width, y: ((f.size.height / 2) - (0.5 * combinedHeight)), width: iv4.frame.size.width, height: iv4.frame.size.height)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.33, animations: {
                iv2.frame =  CGRect(x: finalXOffset, y: yOffset + ((f.size.height / 2) - (0.25 * combinedHeight)), width: iv2.frame.size.width, height: iv2.frame.size.height )
                iv5.frame = CGRect(x: f.size.width - finalXOffset - iv1.frame.size.width, y: yOffset + ((f.size.height / 2) - (0.25 * combinedHeight)), width: iv5.frame.size.width , height: iv5.frame.size.height )
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.33, animations: {
                iv3.frame = CGRect(x: finalXOffset, y: 2 * yOffset + (f.size.height / 2), width: iv3.frame.size.width, height: iv3.frame.size.height)
                iv6.frame = CGRect(x: f.size.width - finalXOffset - iv1.frame.size.width, y: 2 * yOffset + (f.size.height / 2), width: iv6.frame.size.width, height: iv6.frame.size.height )
            })
            
        }) { (done) in
            
        }
    }
    
    //called on tap of done button
    @objc func done() {
        print("DONE")
        presentingViewController?.dismiss(animated: true, completion: nil)
        
        Global.manager.delegate.loadingHandler()
        //request use of location services. Will ask for notifications permission later
        Global.manager.beginLocationRequest()
    }
}
