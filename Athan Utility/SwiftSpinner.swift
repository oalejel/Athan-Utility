//
// Copyright (c) 2015 Marin Todorov, Underplot ltd.
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

@available(iOS 8.0, *)
open class SwiftSpinner: UIView {
    
    // MARK: - Singleton
    
    //
    // Access the singleton instance
    //
    open class var sharedInstance: SwiftSpinner {
        struct Singleton {
            static let instance = SwiftSpinner(frame: CGRect.zero)
        }
        return Singleton.instance
    }
    
    // MARK: - Init
    
    //
    // Custom init to build the spinner UI
    //
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let f = UIScreen.main.bounds
        
        blurEffect = UIBlurEffect(style: blurEffectStyle)
        blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        
        vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        addSubview(vibrancyView)
        
        let titleScale: CGFloat = 0.85
        titleLabel.frame.size = CGSize(width: frameSize.width * titleScale, height: frameSize.height * titleScale)
        titleLabel.font = defaultTitleFont
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.adjustsFontSizeToFitWidth = true
        
        vibrancyView.contentView.addSubview(titleLabel)
        blurView.contentView.addSubview(vibrancyView)
        
        //
        
        cancelButton = SqueezeButton(frame: CGRect(x: 0, y: 0, width: f.size.width / 3, height: f.size.width / 7))
        cancelButton.layer.cornerRadius = 10
        cancelButton.backgroundColor = UIColor(white: 0.87, alpha: 0.5)
        cancelButton.setTitle("Cancel", for: UIControlState.normal)
        cancelButton.addTarget(Global.manager, action: #selector(Global.manager.cancelRequest), for: .touchUpInside)
        cancelButton.setTitleColor(UIColor.black, for: UIControlState())
        cancelButton.center = CGPoint(x: f.size.width / 2, y: f.size.height * 0.8)
        vibrancyView.contentView.addSubview(cancelButton)
        
        //
        
        outerCircleView.frame.size = frameSize
        
        outerCircle.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frameSize.width, height: frameSize.height)).cgPath
        outerCircle.lineWidth = 8.0
        outerCircle.strokeStart = 0.0
        outerCircle.strokeEnd = 0.45
        outerCircle.lineCap = kCALineCapRound
        outerCircle.fillColor = UIColor.clear.cgColor
        outerCircle.strokeColor = UIColor.white.cgColor
        outerCircleView.layer.addSublayer(outerCircle)
        
        outerCircle.strokeStart = 0.0
        outerCircle.strokeEnd = 1.0
        
        vibrancyView.contentView.addSubview(outerCircleView)
        
        innerCircleView.frame.size = frameSize
        
        let innerCirclePadding: CGFloat = 12
        innerCircle.path = UIBezierPath(ovalIn: CGRect(x: innerCirclePadding, y: innerCirclePadding, width: frameSize.width - 2*innerCirclePadding, height: frameSize.height - 2*innerCirclePadding)).cgPath
        innerCircle.lineWidth = 4.0
        innerCircle.strokeStart = 0.5
        innerCircle.strokeEnd = 0.9
        innerCircle.lineCap = kCALineCapRound
        innerCircle.fillColor = UIColor.clear.cgColor
        innerCircle.strokeColor = UIColor.gray.cgColor
        innerCircleView.layer.addSublayer(innerCircle)
        
        innerCircle.strokeStart = 0.0
        innerCircle.strokeEnd = 1.0
        
        vibrancyView.contentView.addSubview(innerCircleView)
    }
    
    // MARK: - Public interface
    
    //
    // Show the spinner activity on screen, if visible only update the title
    //
    open class func show(_ title: String, animated: Bool = true) {
        
        let window = UIApplication.shared.windows.first! as UIWindow
        let spinner = SwiftSpinner.sharedInstance
        
        spinner.updateFrame()
        
        if spinner.superview == nil {
            //show the spinner
            spinner.alpha = 0.0
            window.addSubview(spinner)
            
            UIView.animate(withDuration: 0.33, delay: 0.0, options: .curveEaseOut, animations: {
                spinner.alpha = 1.0
                }, completion: nil)
        }
        
        spinner.title = title
        spinner.animating = animated
    }
    
    //
    // Show the spinner activity on screen with custom font, if visible only update the title
    // Note that the custom font will be discarded when hiding the spinner
    // To permanently change the title font, set the defaultTitleFont property
    //
    open class func show(_ title: String, withFont font: UIFont, animated: Bool = true) {
        let spinner = SwiftSpinner.sharedInstance
        spinner.titleLabel.font = font
        
        show(title, animated: true)
    }
    
    //
    // Hide the spinner
    //
    open class func hide(_ completion: (() -> Void)? = nil) {
        let spinner = SwiftSpinner.sharedInstance
        
        if spinner.superview == nil {
            return
        }
        
        UIView.animate(withDuration: 0.33, delay: 0.0, options: .curveEaseOut, animations: {
            spinner.alpha = 0.0
            }, completion: {_ in
                spinner.alpha = 1.0
                spinner.removeFromSuperview()
                spinner.titleLabel.font = spinner.defaultTitleFont
                spinner.titleLabel.text = nil
                
                completion?()
        })
        
        spinner.animating = false
    }
    
    //
    // Set the default title font
    //
    open class func setDefaultTitleFont(_ font: UIFont?) {
        let spinner = SwiftSpinner.sharedInstance
        spinner.defaultTitleFont = font
        spinner.titleLabel.font = font
    }
    
    //
    // The spinner title
    //
    open var title: String = "" {
        didSet {
            
            let spinner = SwiftSpinner.sharedInstance
            
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                spinner.titleLabel.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                spinner.titleLabel.alpha = 0.2
                }, completion: {_ in
                    spinner.titleLabel.text = self.title
                    UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.35, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                        spinner.titleLabel.transform = CGAffineTransform.identity
                        spinner.titleLabel.alpha = 1.0
                        }, completion: nil)
            })
        }
    }
    
    //
    // observe the view frame and update the subviews layout
    //
    open override var frame: CGRect {
        didSet {
            if frame == CGRect.zero {
                return
            }
            blurView.frame = bounds
            vibrancyView.frame = blurView.bounds
            titleLabel.center = vibrancyView.center
            outerCircleView.center = vibrancyView.center
            innerCircleView.center = vibrancyView.center
        }
    }
    
    //
    // Start the spinning animation
    //
    
    open var animating: Bool = false {
        
        willSet (shouldAnimate) {
            if shouldAnimate && !animating {
                spinInner()
                spinOuter()
            }
        }
        
        didSet {
            // update UI
            if animating {
                self.outerCircle.strokeStart = 0.0
                self.outerCircle.strokeEnd = 0.45
                self.innerCircle.strokeStart = 0.5
                self.innerCircle.strokeEnd = 0.9
            } else {
                self.outerCircle.strokeStart = 0.0
                self.outerCircle.strokeEnd = 1.0
                self.innerCircle.strokeStart = 0.0
                self.innerCircle.strokeEnd = 1.0
            }
        }
    }
    
    // MARK: - Private interface
    
    //
    // layout elements
    //
    
    fileprivate var blurEffectStyle: UIBlurEffectStyle = .dark
    fileprivate var blurEffect: UIBlurEffect!
    fileprivate var blurView: UIVisualEffectView!
    fileprivate var vibrancyView: UIVisualEffectView!
    fileprivate var cancelButton: UIButton!
    
    lazy var titleLabel = UILabel()
    var defaultTitleFont = UIFont(name: "HelveticaNeue", size: 22.0)
    let frameSize = CGSize(width: 200.0, height: 200.0)
    
    fileprivate lazy var outerCircleView = UIView()
    fileprivate lazy var innerCircleView = UIView()
    
    fileprivate let outerCircle = CAShapeLayer()
    fileprivate let innerCircle = CAShapeLayer()
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("Not coder compliant")
    }
    
    fileprivate var currentOuterRotation: CGFloat = 0.0
    fileprivate var currentInnerRotation: CGFloat = 0.1
    
    fileprivate func spinOuter() {
        
        if superview == nil {
            return
        }
        
        let duration = Double(Float(arc4random()) /  Float(UInt32.max)) * 2.0 + 1.5
        let randomRotation = Double(Float(arc4random()) /  Float(UInt32.max)) * (Double.pi / 4) + (Double.pi)
        
        //outer circle
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.currentOuterRotation -= CGFloat(randomRotation)
            self.outerCircleView.transform = CGAffineTransform(rotationAngle: self.currentOuterRotation)
            }, completion: {_ in
                let waitDuration = Double(Float(arc4random()) /  Float(UInt32.max)) * 1.0 + 1.0
                self.delay(seconds: waitDuration, completion: {
                    if self.animating {
                        self.spinOuter()
                    }
                })
        })
    }
    
    fileprivate func spinInner() {
        if superview == nil {
            return
        }
        
        //inner circle
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.currentInnerRotation += CGFloat(Double.pi / 4)
            self.innerCircleView.transform = CGAffineTransform(rotationAngle: self.currentInnerRotation)
            }, completion: {_ in
                self.delay(seconds: 0.5, completion: {
                    if self.animating {
                        self.spinInner()
                    }
                })
        })
    }
    
    fileprivate func updateFrame() {
        let window = UIApplication.shared.windows.first! as UIWindow
        SwiftSpinner.sharedInstance.frame = window.frame
    }
    
    // MARK: - Util methods
    
    func delay(seconds: Double, completion:@escaping ()->()) {
        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * seconds )) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            completion()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        updateFrame()
    }
    
}

