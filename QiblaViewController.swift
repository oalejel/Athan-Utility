//
//  QiblaViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/30/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import CoreLocation

class QiblaViewController: UIViewController, HeadingDelegate {
    var needleLayer: CAShapeLayer!
    var qiblaOffset: Double!
    let bounds = UIScreen.main.bounds
    
    @IBOutlet weak var dismissButton: UIButton!
    var headingManager: PrayerManager!
    
    @IBOutlet weak var angleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
        let northNeedle = CAShapeLayer()
        
        let w: CGFloat = 30
        let h = (height(bounds) - (height(bounds) / 3)) - (width(bounds) / 2)
        let x = (width(bounds) / 2) - (w / 2)
        let y = height(bounds) / 4
        let tailY = h - 15
        
        //        let tipX = width(bounds) / 2
        //        let tipY = height(bounds) / 4
        //        let bottomY = height(bounds) - (height(bounds) / 3)
        //        let bottomY2 = bottomY - 15
        //        let bottomX1 = tipX - 15
        //        let bottomX2 = tipX + 15
        
        let frame = CGRect(x: x, y: y, width: w, height: h)
        
        let northPath = UIBezierPath()
        northPath.move(to: CGPoint(x: w / 2, y: 0))
        northPath.addLine(to: CGPoint(x: 0, y: h))
        northPath.addLine(to: CGPoint(x: w / 2, y: tailY))
        northPath.addLine(to: CGPoint(x: w, y: h))
        northPath.addLine(to: CGPoint(x: w / 2, y: 0))
        
        
        northNeedle.path = northPath.cgPath
        
        if Global.darkTheme {
            northNeedle.fillColor = UIColor(red: 0.92, green: 0.72, blue: 0.1666, alpha: 1.0).cgColor
            dismissButton.backgroundColor = Global.darkerGray
            dismissButton.titleLabel?.textColor = .white
            view.backgroundColor = .black
        } else {
            northNeedle.fillColor = UIColor.red.cgColor
            dismissButton.backgroundColor = .white
            dismissButton.titleLabel?.textColor = Global.darkestGray
            view.backgroundColor = .white//add a vibrancy layer in light theme
        }
        
        view.layer.addSublayer(northNeedle)
        
        needleLayer = CAShapeLayer()
        needleLayer.frame = frame
        needleLayer.addSublayer(northNeedle)
        view.layer.addSublayer(needleLayer)
        
        needleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        angleLabel.text = "Offset: \(qiblaOffset ?? 0)˚"
    }
    
    //get heading for qibla
    func newHeading(_ h: CLHeading) {
        //        UIView.animateWithDuration(0.2) { () -> Void in
        let angle = h.trueHeading
        let radians = (-1 * Double.pi * (angle / 180)) + (Double.pi * Double(self.qiblaOffset / 180))
        self.needleLayer?.transform = CATransform3DMakeRotation(CGFloat(radians), 0, 0, 1)
        //        }
        
        //        let angle = h.trueHeading
        //        let radians = ( Double.pi * (angle / 180)) - (Double.pi * Double(self.qiblaOffset / 180))
        //        let anim = CABasicAnimation(keyPath: "transform.rotation")
        //        anim.duration = 0.3
        //        let oldRotation: NSNumber = self.needleLayer.valueForKeyPath("transform.rotation") as! NSNumber
        //        anim.fromValue = oldRotation
        //        anim.toValue = NSNumber(double: Double.pi)//oldRotation.doubleValue + 0.1)//NSNumber(double: oldRotation)
        //        self.needleLayer.addAnimation(anim, forKey: "transform.rotation")
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        headingManager.headingDelegate = nil
        presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            //
        })
    }
}
