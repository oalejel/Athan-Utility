//
//  ClockView.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/18/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

enum Meridiem {
    case am, pm
}

class ClockView: UIView {
    var width: CGFloat!
    var height: CGFloat!
    
    let separation: CGFloat = 2
    let bubbleRoom: CGFloat = 44
    let tickHeight: CGFloat = 10
    
    var secondsLayer: CAShapeLayer!
    var minutesLayer: CAShapeLayer!
    var hoursLayer: CAShapeLayer!
    var amLayer: CAShapeLayer!
    var pmLayer: CAShapeLayer!
    
    var amLabel: UILabel!
    var pmLabel: UILabel!
    
    var didDraw = false
    
    var prayerBubbleViews: [BubbleTextView] = []
    
    var animationsPaused = false
    
    var currentMeridiem: Meridiem! {
        didSet {
            switch currentMeridiem! {
            case .am:
//                if Global.darkTheme {
//                    //in this case, the non-darkgray is selected
                    amLayer.strokeColor = UIColor.darkGray.cgColor
                    pmLayer.strokeColor = Global.darkestGray.cgColor
                    amLabel.textColor = UIColor.lightGray
                    pmLabel.textColor = UIColor.lightGray
//                } else {
//                    //in this case, white is selected
//                    amLayer.strokeColor = UIColor(white: 1, alpha: 0.5).cgColor
//                    pmLayer.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
//                    amLabel.textColor = UIColor.darkGray
//                    pmLabel.textColor = UIColor.darkGray
//                }
                
                //!! i initially had this since they would not update colors...
                //                amLayer.removeFromSuperlayer()
                //                layer.insertSublayer(amLayer, below: pmLayer)
                //                pmLayer.removeFromSuperlayer()
                //                layer.insertSublayer(pmLayer, below: amLayer)
                break
            case .pm:
//                if Global.darkTheme {
                    pmLayer.strokeColor = UIColor.darkGray.cgColor
                    amLayer.strokeColor = Global.darkestGray.cgColor
                    amLabel.textColor = UIColor.lightGray
                    pmLabel.textColor = UIColor.lightGray
//                } else {
//                    pmLayer.strokeColor = UIColor(white: 1, alpha: 0.5).cgColor
//                    amLayer.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
//                    amLabel.textColor = UIColor.darkGray
//                    pmLabel.textColor = UIColor.darkGray
//                }
                
                //                amLayer.removeFromSuperlayer()
                //                layer.insertSublayer(amLayer, below: pmLayer)
                //                pmLayer.removeFromSuperlayer()
                //                layer.insertSublayer(pmLayer, below: amLayer)
                break
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        if !didDraw {
            width = frame.size.width
            height = frame.size.height
            addPMPath()
            addAMPath()
            addMinuteTicks()
            addHourTicks()
            addMovingHourHand()
            addMovingMinuteHand()
            addMovingSecondHand()
            
            backgroundColor = UIColor.clear
            
            didDraw = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func adjustToSize(_ s: CGSize) {
        frame = CGRect(x: 0, y: 0, width: s.width, height: s.height)
        
    }
    
    func addMinuteTicks() {
//        let lineWidth: CGFloat = 7.5
//        let center = CGPoint(x: width / 2, y: height / 2)
//        let radius = (width / 2) - (lineWidth / 2) - bubbleRoom
//        let circ: CGFloat = CGFloat(2 * Double.pi) * radius
//        let tickThickness: CGFloat = 0.3
//
//        let minutePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.path = minutePath.cgPath
//        shapeLayer.lineDashPhase = 1.5
//        shapeLayer.lineCap = kCALineCapRound
//
//        shapeLayer.lineDashPattern = [(tickThickness as NSNumber), (circ / 60) - tickThickness as NSNumber]
//        shapeLayer.strokeColor = UIColor.white.cgColor
//        shapeLayer.fillColor = UIColor.clear.cgColor
//        shapeLayer.lineWidth = lineWidth
//        layer.addSublayer(shapeLayer)
    }
    
    func addHourTicks() {
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = (width / 2) - (tickHeight / 2) - bubbleRoom - 4
        let circ: CGFloat = CGFloat(2 * Double.pi) * radius
        let tickThickness: CGFloat = 0
        
        let hourPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = hourPath.cgPath
        shapeLayer.lineDashPhase = 0
        shapeLayer.lineCap = kCALineCapRound
        
        shapeLayer.lineDashPattern = [tickThickness, (circ - 12 * (tickThickness)) / 12] as [NSNumber]
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = tickHeight
        layer.addSublayer(shapeLayer)
    }
    
    func addAMPath() {
        let lineWidth: CGFloat = (bubbleRoom / 2) - separation
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = (width / 2) - (lineWidth / 2) - (bubbleRoom / 2)
        
        let amPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        amLayer = CAShapeLayer()
        amLayer.path = amPath.cgPath
        
        amLayer.strokeColor = Global.darkestGray.cgColor
        amLayer.lineWidth = lineWidth
        amLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(amLayer)
        
        let labelFrame = CGRect(x: 0, y: 0, width: 40, height: lineWidth)
        amLabel = UILabel(frame: labelFrame)
        amLabel.text = "AM"
        amLabel.textColor = UIColor.lightGray
        amLabel.textAlignment = .center
        amLabel.center = CGPoint(x: bounds.size.width / 2, y: (1.5 * lineWidth) + separation)
        addSubview(amLabel)
    }
    
    func addPMPath() {
        let lineWidth: CGFloat = (bubbleRoom / 2) - separation
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = (width / 2) - (lineWidth / 2)
        
        let pmPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        pmLayer = CAShapeLayer()
        pmLayer.path = pmPath.cgPath
        
        pmLayer.strokeColor = Global.darkestGray.cgColor
        pmLayer.lineWidth = lineWidth
        pmLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(pmLayer)
        
        let labelFrame = CGRect(x: 0, y: 0, width: 40, height: lineWidth)
        pmLabel = UILabel(frame: labelFrame)
        pmLabel.text = "PM"
        pmLabel.textColor = UIColor.lightGray
        pmLabel.textAlignment = .center
        pmLabel.center = CGPoint(x: bounds.size.width / 2, y: lineWidth / 2)
        addSubview(pmLabel)
    }
    
    func addMovingSecondHand() {
        let armWidth: CGFloat = 1
        var armHeight = (width / 2) - (tickHeight / 2) - bubbleRoom
        
        let anchorOffset: CGFloat = 0//removing this for a cleaner look different form applewatch
        armHeight += anchorOffset
        
        let armRect = CGRect(x: 0, y: 0, width: armWidth, height: armHeight)
        let armLayer = CAShapeLayer()
        armLayer.frame = armRect
        armLayer.backgroundColor = UIColor.red.cgColor
        
        let nubWH: CGFloat = 9
        let nubLayer = CAShapeLayer()
        let nubRect = CGRect(x: (armWidth / 2) - (nubWH / 2), y: armHeight - anchorOffset - (nubWH / 2), width: nubWH, height: nubWH)
        nubLayer.frame = nubRect
        nubLayer.cornerRadius = nubWH / 2
        nubLayer.backgroundColor = UIColor.red.cgColor
        
        armLayer.addSublayer(nubLayer)
        secondsLayer = armLayer
        secondsLayer.anchorPoint = CGPoint(x: 0.5, y: ((armHeight - anchorOffset) / armHeight))
        secondsLayer.frame.origin = CGPoint(x: (width / 2) - (armWidth / 2), y: (height / 2) - (armHeight - anchorOffset))
        secondsLayer.allowsEdgeAntialiasing = true
        layer.addSublayer(secondsLayer)
        secondsLayer.contentsScale = UIScreen.main.scale
        //do animation work
        let anim = CABasicAnimation(keyPath: "transform.rotation")
        anim.duration = 60
        
        anim.repeatCount = Float.infinity
        
        let vc = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        vc.backgroundColor = UIColor.clear
        vc.center = CGPoint(x: width / 2, y: height / 2)
        vc.layer.cornerRadius = 1
        addSubview(vc)
        
        
        DispatchQueue.main.async { () -> Void in
            let df = Global.dateFormatter
            df.dateFormat = "s.S"
            let curDate = Date()
            let seconds = Float(df.string(from: curDate))
            let radians: CGFloat = CGFloat(seconds! / 30.0) * CGFloat(Double.pi)
            self.secondsLayer.transform = CATransform3DRotate(self.secondsLayer.transform, radians, 0, 0, 1)
            
            let oldRotation: NSNumber = self.secondsLayer.value(forKeyPath: "transform.rotation") as! NSNumber
            anim.fromValue = oldRotation
            anim.toValue = CGFloat(Double.pi * 2) + CGFloat(truncating: oldRotation)
            self.secondsLayer.add(anim, forKey: "transform.rotation")
            
        }
    }
    
    func addMovingMinuteHand() {
        let longWidth: CGFloat = 8
        let longHeight = (width / 2) - (tickHeight / 2) - bubbleRoom - 14
        let shortHeight: CGFloat = longHeight
        let shortWidth: CGFloat = longWidth / 2
        let shortLongOffset: CGFloat = 14
        
        let longRect = CGRect(x: 0, y: 0, width: longWidth, height: longHeight)
        let longLayer = CAShapeLayer()
        longLayer.frame = longRect
        longLayer.backgroundColor = UIColor.white.cgColor
        longLayer.cornerRadius = longWidth / 2
        
        let shortRect = CGRect(x: (longWidth - shortWidth) / 2, y: shortLongOffset, width: shortWidth, height: shortHeight)
        let shortLayer = CAShapeLayer()
        shortLayer.frame = shortRect
//        shortLayer.backgroundColor = UIColor.white.cgColor
        shortLayer.backgroundColor = UIColor.clear.cgColor
        shortLayer.cornerRadius = shortWidth / 2
        
        let fittingRect = shortRect.union(longRect)
        minutesLayer = CAShapeLayer()
        minutesLayer.frame = fittingRect
        minutesLayer.addSublayer(longLayer)
        minutesLayer.addSublayer(shortLayer)
        
        //antialiasing
        minutesLayer.allowsEdgeAntialiasing = true
        
        let totaHeight = fittingRect.size.height
        let totalWidth = longWidth
        
        minutesLayer.anchorPoint = CGPoint(x: 0.5, y: ((totaHeight - (shortWidth / 2)) / totaHeight))
        minutesLayer.frame.origin = CGPoint(x: (width / 2) - (totalWidth / 2), y: (height / 2) - (totaHeight - (shortWidth / 2)))
        
        
        // keep this shadow to differentiate between the minute arm and the hour dots it touches
        minutesLayer.shadowColor = UIColor.black.cgColor
        minutesLayer.shadowOpacity = 0.5
        
        layer.addSublayer(minutesLayer)
        
        //start it at 0 seconds
        //container.transform = CATransform3DRotate(container.transform, CGFloat(Double.pi * 0.25), 0, 0, 1)
        
        
        
        //do initial work
        
        let anim = CABasicAnimation(keyPath: "transform.rotation")
        anim.duration = 3600
        anim.repeatCount = Float.infinity
        
        let vc = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        vc.backgroundColor = UIColor.clear
        vc.center = CGPoint(x: width / 2, y: height / 2)
        vc.layer.cornerRadius = 1
        addSubview(vc)
        
        DispatchQueue.main.async { () -> Void in
            let curDate = Date()
            let seconds = Float(Calendar.current.component(.second, from: curDate))
            let minutes = Float(Calendar.current.component(.minute, from: curDate)) + (seconds / 60)
            let radians: CGFloat = CGFloat(minutes / 30.0) * CGFloat(Double.pi)
            self.minutesLayer.transform = CATransform3DRotate(self.minutesLayer.transform, radians, 0, 0, 1)
            
            let oldRotation = self.minutesLayer.value(forKeyPath: "transform.rotation") as! NSNumber
            anim.fromValue = oldRotation
            anim.toValue = (Double.pi * 2) + oldRotation.doubleValue
            self.minutesLayer.add(anim, forKey: "transform.rotation")
        }
    }
    
    func addMovingHourHand() {
        let longWidth: CGFloat = 8
        let longHeight = (width / 2) - (tickHeight / 2) - bubbleRoom - 45
        let shortHeight: CGFloat = longHeight
        let shortWidth: CGFloat = longWidth / 2
        let shortLongOffset: CGFloat = 14
        
        let longRect = CGRect(x: 0, y: 0, width: longWidth, height: longHeight)
        let longLayer = CAShapeLayer()
        longLayer.frame = longRect
        longLayer.backgroundColor = UIColor.white.cgColor
        longLayer.cornerRadius = longWidth / 2
        
        let shortRect = CGRect(x: (longWidth - shortWidth) / 2, y: shortLongOffset, width: shortWidth, height: shortHeight)
        let shortLayer = CAShapeLayer()
        shortLayer.frame = shortRect
//        shortLayer.backgroundColor = UIColor.white.cgColor
        shortLayer.backgroundColor = UIColor.clear.cgColor
        shortLayer.cornerRadius = shortWidth / 2
        
        let fittingRect = shortRect.union(longRect)
        hoursLayer = CAShapeLayer()
        hoursLayer.frame = fittingRect
        hoursLayer.addSublayer(longLayer)
        hoursLayer.addSublayer(shortLayer)
        //antialiasing
        hoursLayer.allowsEdgeAntialiasing = true
        
        let totaHeight = fittingRect.size.height
        let totalWidth = longWidth
        
        hoursLayer.anchorPoint = CGPoint(x: 0.5, y: ((totaHeight - (shortWidth / 2)) / totaHeight))
        hoursLayer.frame.origin = CGPoint(x: (width / 2) - (totalWidth / 2), y: (height / 2) - (totaHeight - (shortWidth / 2)))
        
//        hoursLayer.shadowColor = UIColor.black.cgColor
//        hoursLayer.shadowOpacity = 0.5
        
        layer.addSublayer(hoursLayer)
        
        //move somewhere else
//        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
//        circleView.backgroundColor = UIColor.white
//        circleView.layer.cornerRadius = 4
//        circleView.center = CGPoint(x: width / 2, y: height / 2)
//        addSubview(circleView)
        
        //do initial work
        
        let anim = CABasicAnimation(keyPath: "transform.rotation")
        anim.duration = 43200
        
        anim.repeatCount = Float.infinity
        
        let vc = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        vc.backgroundColor = UIColor.clear
        vc.center = CGPoint(x: width / 2, y: height / 2)
        vc.layer.cornerRadius = 1
        addSubview(vc)
        
        DispatchQueue.main.async { () -> Void in
            let curDate = Date()
            var hours = Float(Calendar.current.component(.hour, from: curDate))
            let minutes = Float(Calendar.current.component(.minute, from: curDate))
            hours += minutes / 60
            let radians: CGFloat = CGFloat(hours / 6) * CGFloat(Double.pi)
            self.hoursLayer.transform = CATransform3DRotate(self.hoursLayer.transform, radians, 0, 0, 1)
            
            let oldRotation: NSNumber = self.hoursLayer.value(forKeyPath: "transform.rotation") as! NSNumber
            anim.fromValue = oldRotation
            anim.toValue = CGFloat(Double.pi * 2) + CGFloat(truncating: oldRotation)
            self.hoursLayer.add(anim, forKey: "transform.rotation")
        }
    }
    
    //MARK: Bubbles
    
    func placeBubble(_ p: PrayerType, angle: CGFloat, mer: Meridiem, highlight: Bool) {
        let pName = p.stringValue()
        let letter = pName[pName.startIndex]
        
        var b: BubbleTextView!
        
        if prayerBubbleViews.count == 6 {
            //if we already made them then just
            b = prayerBubbleViews[p.rawValue]
        } else {
            //add it if there isnt already one...
            b = BubbleTextView(letter: letter)
            prayerBubbleViews.append(b)
            addSubview(b)
        }
        
        // special math for placement of bubble
        let lineWidth: CGFloat = (bubbleRoom / 2) - separation
        let standardRadius = (width / 2) - (lineWidth / 2)
        
        var radius = (width / 2) - (lineWidth / 2)
        if mer == .am {
            radius = (width / 2) - (lineWidth * 1.5) - separation
        }
        
        if highlight {
            b.backgroundColor = Global.statusColor
        } else {
            b.backgroundColor = UIColor.white
        }
        
        let xRect = (radius * cos(angle)) + standardRadius
        let yRect = (radius * sin(angle)) + standardRadius
        
        b.center = CGPoint(x: xRect + (b.frame.size.width / 2), y: yRect + (b.frame.size.height / 2))
    }
    
    func refreshPrayerBubbles(_ currentPrayer: PrayerType, fifteenMinutesLeft: Bool = false) {
        for (index, bubble) in prayerBubbleViews.enumerated() {
            if index == currentPrayer.rawValue {
                bubble.backgroundColor = fifteenMinutesLeft ? Global.statusColor : .green
            } else {
                bubble.backgroundColor = UIColor.white
            }
        }
    }
    
    func setPrayerBubbles(_ manager: PrayerManager) {
        DispatchQueue.main.async { () -> Void in
            let curDate = Date()
            let df = Global.dateFormatter
            self.currentMeridiem = Calendar.current.component(.hour, from: curDate) > 11 ? .am : .pm
            var p = PrayerType.fajr
            for _ in 0...5 {
                if let pDate = manager.todayPrayerTimes[p.rawValue] {
                    let hours = Float(Calendar.current.component(.hour, from: pDate))
                    let minutes = Float(Calendar.current.component(.minute, from: pDate))
                    var seconds = Float(Calendar.current.component(.second, from: pDate))
                    
                    // warning: ensure that hour -> meridiem calculations are consistent
                    var merid: Meridiem = .am
                    if (hours > 11) {
                        merid = .pm
                    }
                    
                    var outOfTwelve = hours + (minutes / 60)
                    outOfTwelve += seconds / 3600
                    let angle = (CGFloat(outOfTwelve / 6) * CGFloat(Double.pi)) - CGFloat(0.5 * Double.pi)
                    
                    let hightLight = p == manager.currentPrayer
                    self.placeBubble(p, angle: angle, mer: merid, highlight: hightLight)
                    p = p.next()
                } else {
                    print("error with today prayer times!")
                }
            }
        }
    }
    
    func setupNotifications() {
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("enterBackground"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("enterForeground"), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    //MARK: App state changes
    
    func pause() {
        animationsPaused = true
        hoursLayer.removeAllAnimations()
        secondsLayer.removeAllAnimations()
        minutesLayer.removeAllAnimations()
        hoursLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        minutesLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        secondsLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
    }
    
    func refreshTime() {
        if animationsPaused {
            animationsPaused = false
            
            let hourAnim = CABasicAnimation(keyPath: "transform.rotation")
            hourAnim.duration = 43200
            
            hourAnim.repeatCount = Float.infinity
            
            let df = Global.dateFormatter
            df.dateFormat = "h"
            let curDate = Date()
            guard var hours = Float(df.string(from: curDate)) else {
                
                return
            }
            df.dateFormat = "m"
            guard let minutes = Float(df.string(from: curDate)) else { return }
            df.dateFormat = "s.S"
            guard let seconds = Float(df.string(from: curDate)) else { return }

            DispatchQueue.main.async { () -> Void in
                hours += minutes / 60
                let radians: CGFloat = CGFloat(hours / 6) * CGFloat(Double.pi)
                self.hoursLayer.transform = CATransform3DRotate(self.hoursLayer.transform, radians, 0, 0, 1)
                
                let oldRotation: NSNumber = self.hoursLayer.value(forKeyPath: "transform.rotation") as! NSNumber
                hourAnim.fromValue = oldRotation
                hourAnim.toValue = CGFloat(Double.pi * 2) + CGFloat(truncating: oldRotation)
                self.hoursLayer.add(hourAnim, forKey: "transform.rotation")
            }
            
            let minuteAnim = CABasicAnimation(keyPath: "transform.rotation")
            minuteAnim.duration = 3600
            minuteAnim.repeatCount = Float.infinity
            
            DispatchQueue.main.async { () -> Void in
                let radians: CGFloat = CGFloat(minutes / 30.0) * CGFloat(Double.pi)
                self.minutesLayer.transform = CATransform3DRotate(self.minutesLayer.transform, radians, 0, 0, 1)
                
                let oldRotation: NSNumber = self.minutesLayer.value(forKeyPath: "transform.rotation") as! NSNumber
                minuteAnim.fromValue = oldRotation
                minuteAnim.toValue = CGFloat(Double.pi * 2) + CGFloat(truncating: oldRotation)
                self.minutesLayer.add(minuteAnim, forKey: "transform.rotation")
            }
            
            let secondsAnim = CABasicAnimation(keyPath: "transform.rotation")
            secondsAnim.duration = 60
            
            secondsAnim.repeatCount = Float.infinity
            
            DispatchQueue.main.async { () -> Void in
                let radians: CGFloat = CGFloat(seconds / 30.0) * CGFloat.pi
                self.secondsLayer.transform = CATransform3DRotate(self.secondsLayer.transform, radians, 0, 0, 1)
                
                let oldRotation: NSNumber = self.secondsLayer.value(forKeyPath: "transform.rotation") as! NSNumber
                secondsAnim.fromValue = oldRotation
                secondsAnim.toValue = CGFloat(Double.pi * 2) + CGFloat(truncating: oldRotation)
                self.secondsLayer.add(secondsAnim, forKey: "transform.rotation")
            }
        }
    }
    
}



