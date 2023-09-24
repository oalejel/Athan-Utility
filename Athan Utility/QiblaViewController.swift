//
//  QiblaViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/30/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import CoreLocation

// QiblaViewController displays a compass arrow in Qibla mode
class QiblaViewController: UIViewController {
    var needleLayer: CAShapeLayer!
    var qiblaOffset: Double!
    let bounds = UIScreen.main.bounds
    
    @IBOutlet weak var dismissButton: UIButton!
//    var headingManager: PrayerManager!
    
    @IBOutlet weak var angleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let northNeedle = CAShapeLayer()
        
        // define geometry of the arrow
        let w: CGFloat = 30
        let h = (height(bounds) - (height(bounds) / 3)) - (width(bounds) / 2)
        let x = (width(bounds) / 2) - (w / 2)
        let y = height(bounds) / 4
        let tailY = h - 15
        
        let frame = CGRect(x: x, y: y, width: w, height: h)
        
        let northPath = UIBezierPath()
        northPath.move(to: CGPoint(x: w / 2, y: 0))
        northPath.addLine(to: CGPoint(x: 0, y: h))
        northPath.addLine(to: CGPoint(x: w / 2, y: tailY))
        northPath.addLine(to: CGPoint(x: w, y: h))
        northPath.addLine(to: CGPoint(x: w / 2, y: 0))
        // set the layer's path using the UIBezierPath
        northNeedle.path = northPath.cgPath
        
//        if Global.darkTheme {
        northNeedle.fillColor = UIColor(red: 0.92, green: 0.72, blue: 0.1666, alpha: 1.0).cgColor
        dismissButton.backgroundColor = .darkerGray
        dismissButton.titleLabel?.textColor = .white
        dismissButton.accessibilityLabel = Strings.done
        view.backgroundColor = .black
//        } else {
//            northNeedle.fillColor = UIColor.red.cgColor
//            dismissButton.backgroundColor = .white
//            dismissButton.titleLabel?.textColor = Global.darkestGray
//            view.backgroundColor = .white//add a vibrancy layer in light theme
//        }
        
        view.layer.addSublayer(northNeedle)
        
        needleLayer = CAShapeLayer()
        needleLayer.frame = frame
        needleLayer.addSublayer(northNeedle)
        view.layer.addSublayer(needleLayer)
        
        needleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        let localizedQiblaString = numberFormatter.string(from: qiblaOffset! as NSNumber)
        let localizedAngleString = NSLocalizedString("Offset: %@˚", comment: "")
        angleLabel.text = String(format: localizedAngleString, localizedQiblaString ?? "none")
    }
    
    //get heading for qibla
    func newHeading(_ h: CLHeading) {
        // set angle based on heading
        let angle = h.trueHeading
        let radians = (-1 * Double.pi * (angle / 180)) + (Double.pi * Double(self.qiblaOffset / 180))
        self.needleLayer?.transform = CATransform3DMakeRotation(CGFloat(radians), 0, 0, 1)
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        Global.openQibla = false
//        headingManager.headingDelegate = nil
        presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            // do nothing for now
        })
    }
}
