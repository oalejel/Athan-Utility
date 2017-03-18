//
//  IntroViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 4/19/16.
//  Copyright © 2016 Omar Alejel. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    
    var scrollView: UIScrollView!
    
    var lastXOffset: CGFloat = 0
    
    var items = 3
    
    var scrollViewOffset: CGFloat = 14
    var buttonHeight: CGFloat = 55
    
    var doneButton: UIButton!
    
    var pageControl: UIPageControl!
    
    var slide1: UIView!
    var slide2: UIView!
    var slide3: UIView!
    
    var labels1: [UILabel] = []
    
    var drawNeeded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let f = UIScreen.main.bounds
        
        let layer = CAGradientLayer()
        layer.colors = [UIColor(red: 75/255, green: 28/255, blue: 152/255, alpha: 1).cgColor, UIColor.black.cgColor]
        layer.frame = f
        view.layer.addSublayer(layer)
        
        let doneButton = UIButton(frame: CGRect(x: 0, y: f.size.height - buttonHeight, width: f.size.width, height: buttonHeight))
        doneButton.setTitle("Continue", for: UIControlState())
        doneButton.setTitleColor(UIColor.lightGray, for: UIControlState())
        doneButton.setTitleColor(UIColor.lightGray.withAlphaComponent(0.7), for: .highlighted)
        doneButton.backgroundColor = Global.darkestGray
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        view.addSubview(doneButton)
        
        
        
        //
        //        for x in 0...(items-1) {
        //            let img = UIImage(named:"intro\(x)")
        //            let imgView = UIImageView(frame: CGRectMake(CGFloat(x) * f.size.width, 0, f.size.width, f.size.height - scrollViewOffset - buttonHeight))
        //            imgView.image = img
        //            imgView.contentMode = .ScaleAspectFit
        //            scrollView.addSubview(imgView)
        //        }
    }
    
    
    //    override func viewDidLayoutSubviews() {
    //        //addSlide1()
    //
    //        //scrollView.setNeedsDisplay()
    //    }
    
    override func viewDidAppear(_ animated: Bool) {
        //animate1()
        showFeatures()
        
        let f = UIScreen.main.bounds
        
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
    
    //    func addSlide1() {
    //        let f = UIScreen.mainScreen().bounds
    //
    //        slide1 = UIView(frame: CGRectMake(0, 0, f.size.width, f.size.height - scrollViewOffset - buttonHeight))
    //
    //        let imageView = UIImageView(image: UIImage(named: "intro1"))
    //        imageView.frame = slide1.frame
    //        imageView.contentMode = .ScaleAspectFit
    //        slide1.addSubview(imageView)
    //
    //        let arabic = UILabel(frame: CGRectMake(0,0, f.size.width - 140, 60))
    //
    //        arabic.text = "السلام عليكم"
    //        arabic.numberOfLines = 1
    //        arabic.font = UIFont(name: "HelveticaNeue", size: 60)
    //        arabic.adjustsFontSizeToFitWidth = true
    //        arabic.textAlignment = .Center
    //        arabic.center = CGPointMake(f.size.width / 2, 90)
    //        arabic.textColor = UIColor.whiteColor()
    //        arabic.alpha = 0
    //
    //        let english = UILabel(frame: CGRectMake(0,0, f.size.width - 60, 60))
    //        english.text = "Peace Be Upon You"
    //        english.numberOfLines = 1
    //        english.font = UIFont(name: "HelveticaNeue", size: 60)
    //        english.adjustsFontSizeToFitWidth = true
    //        english.textAlignment = .Center
    //        english.center = CGPointMake(f.size.width / 2, 145)
    //        english.textColor = UIColor.whiteColor()
    //        english.alpha = 0
    //
    //
    //        let japanese = UILabel(frame: CGRectMake(25, 155, f.size.width / 2.4, 60))
    //        japanese.text = "平和は貴方とともに"
    //        japanese.numberOfLines = 1
    //        japanese.font = UIFont(name: "HelveticaNeue", size: 60)
    //        japanese.adjustsFontSizeToFitWidth = true
    //        japanese.textAlignment = .Left
    //        japanese.textColor = UIColor.whiteColor()
    //        japanese.alpha = 0
    //
    //        let hebrew = UILabel(frame: CGRectMake(f.size.width - 25 - (f.size.width / 2.4), 155, f.size.width / 2.3, 60))
    //        hebrew.text = "שָׁלוֹם עֲלֵיכֶם"
    //        hebrew.numberOfLines = 1
    //        hebrew.font = UIFont(name: "HelveticaNeue", size: 60)
    //        hebrew.adjustsFontSizeToFitWidth = true
    //        hebrew.textAlignment = .Right
    //        hebrew.textColor = UIColor.whiteColor()
    //        hebrew.alpha = 0
    //
    //        let spanish = UILabel(frame: CGRectMake(0,0, f.size.width - 70, 60))
    //        spanish.text = "la paz está con usted"
    //        spanish.numberOfLines = 1
    //        spanish.font = UIFont(name: "HelveticaNeue", size: 60)
    //        spanish.adjustsFontSizeToFitWidth = true
    //        spanish.textAlignment = .Center
    //        spanish.center = CGPointMake(f.size.width / 2, 220)
    //        spanish.textColor = UIColor.whiteColor()
    //        spanish.alpha = 0
    //
    //
    //        let french = UILabel(frame: CGRectMake(0,0, f.size.width - 160, 60))
    //        french.text = "paix à vous"
    //        french.numberOfLines = 1
    //        french.font = UIFont(name: "HelveticaNeue", size: 60)
    //        french.adjustsFontSizeToFitWidth = true
    //        french.textAlignment = .Center
    //        french.center = CGPointMake(f.size.width / 2, 255)
    //        french.textColor = UIColor.whiteColor()
    //        french.alpha = 0
    //
    //
    //        let german = UILabel(frame: CGRectMake(0,0, f.size.width - 140, 60))
    //        german.text = "Friede sei mit dir"
    //        german.numberOfLines = 1
    //        german.font = UIFont(name: "HelveticaNeue", size: 60)
    //        german.adjustsFontSizeToFitWidth = true
    //        german.textAlignment = .Center
    //        german.center = CGPointMake(f.size.width / 2, 290)
    //        german.textColor = UIColor.whiteColor()
    //        german.alpha = 0
    //
    //        scrollView.addSubview(slide1)
    //        slide1.addSubview(spanish)
    //        slide1.addSubview(german)
    //        slide1.addSubview(french)
    //        slide1.addSubview(hebrew)
    //        slide1.addSubview(japanese)
    //        slide1.addSubview(english)
    //        slide1.addSubview(arabic)
    //
    //        labels1 = [spanish, german, french, hebrew, japanese, english, arabic]
    //    }
    
    //    func animate1() {
    //
    //        UIView.animateWithDuration(1, delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 4, options: UIViewAnimationOptions.TransitionNone, animations: {
    //            for label in self.labels1 {
    //                label.alpha = 1
    //
    //            }
    //            }) { (done) in
    //
    //        }
    //    }
    
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
        
        UIView.animateKeyframes(withDuration: 3, delay: 0.5, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: {
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
    
    func done() {
        print("DONE")
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    
}
