//
//  ViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

extension UIView {
    func _hide() {
        UIView.animate(withDuration: 0.77, animations: { () -> Void in self.alpha = 0.0 })
    }
    func _show() {
        UIView.animate(withDuration: 0.77, animations: { () -> Void in self.alpha = 1.0 })
    }
}

class ViewController: UIViewController, PrayerManagerDelegate {
    
    @IBOutlet weak var clock: ClockView!
    var table: TableController!
    var progressView: ElapsedView!
    
    @IBOutlet weak var locationLabel: UILabel!
    var manager: PrayerManager!
    var showSpinner = false
    var refreshClockNeeded = false
    
    @IBOutlet weak var refreshButton: SqueezeButton!
    @IBOutlet weak var settingsButton: SqueezeButton!
    @IBOutlet weak var qiblaButton: SqueezeButton!
    //not an actual xib containerview
    @IBOutlet weak var tableContainer: UIView!
    
    var settingsMode = false
    
    var gradientLayer: CAGradientLayer?
    var showIntroLate = false
    
    var lastUpdate: Date?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Table" {
            table = segue.destination as! TableController
            //!!! might want to not set default color as clear!!!
            table.view.backgroundColor = UIColor.clear
            table.view.layer.cornerRadius = 6
            table.tableView.backgroundColor = UIColor.clear
            table.tableView.backgroundView?.backgroundColor = UIColor.clear
        } else if segue.identifier == "Progress" {
            progressView = segue.destination.view as! ElapsedView
        }
    }
    
    var settingsController: SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.black
        
        //this will also set the manager variable equal to this (could cause a problem)!
        manager = PrayerManager(delegate: self)
        Global.manager = manager
        
        refreshButton.layer.cornerRadius = 8
        qiblaButton.layer.cornerRadius = 8
        settingsButton.layer.cornerRadius = 8
        
        refreshButton.setTitleColor(UIColor.lightGray, for: UIControlState())
        refreshButton.setTitle("Refresh", for: UIControlState())
        refreshButton.backgroundColor = Global.darkerGray
        qiblaButton.setTitleColor(UIColor.lightGray, for: UIControlState())
        qiblaButton.setTitle("Qibla", for: UIControlState())
        qiblaButton.backgroundColor = Global.darkerGray
        settingsButton.setTitleColor(UIColor.lightGray, for: UIControlState.normal)
        settingsButton.setTitle("Settings", for: UIControlState.normal)
        settingsButton.backgroundColor = Global.darkerGray
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredBackground), name: .UIApplicationDidEnterBackground, object: nil)
        
        if Global.openQibla {
            showQibla(self)
        }

        if !Global.darkTheme {
            updateTheme()
        }
        
        Global.mainController = self
    }

    @objc func enteredForeground() {
        if refreshClockNeeded {
            manager.calculateCurrentPrayer()
            updatePrayerInfo()
            
//            refreshClockNeeded = false
        }
    }

    @objc func enteredBackground() {
        refreshClockNeeded = true
        clock.pause()
        manager.saveSettings()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refreshClockNeeded = true
        clock.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if refreshClockNeeded {
            manager.calculateCurrentPrayer()
            updatePrayerInfo()
//            refreshClockNeeded = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //show introduction if never presented before!
        let pref = UserDefaults.standard.bool(forKey: "introduced")
        
        //CONNECT
        
        if showSpinner {
            SwiftSpinner.show("Loading Prayer\nData", animated: true)
            showSpinner = false
            if !pref { showIntroLate = true }
        } else if !pref {
            print("show intro screen!!!!")
            //show intro screen
            let intro = IntroViewController()
            intro.view.backgroundColor = UIColor.black
            present(intro, animated: true, completion: {
                
            })
            UserDefaults.standard.set(true, forKey: "introduced")
        }
        
        refreshClockNeeded = true
    }
    
   
    
    //Data Manager Delegate
    func dataReady(manager: PrayerManager) {
        lastUpdate = Date()
        
        DispatchQueue.main.async { () -> Void in
            SwiftSpinner.hide()
            if self.showIntroLate {
                print("show intro screen!!!!")
                //show intro screen
                let intro = IntroViewController()
                intro.view.backgroundColor = UIColor.black
                self.present(intro, animated: true, completion: {
                    
                })
                self.showIntroLate = false
                UserDefaults.standard.set(true, forKey: "introduced")
            }
            if let location = manager.locationString {
                self.locationLabel.text = location
            }
            //                if let state = manager.currentStateString {
            //                    if let city = manager.currentCityString {
            //                        if let country = manager.currentCountryString {
            //                                            self.locationLabel.text = "\(city), \(state), \(country)"
            //                        }
            //                    }
            //                }
            
            self.updatePrayerInfo()
        }
    }
    
    //specific to individual prayers
    func updatePrayer(manager: PrayerManager) {
        //a check if its NOT a good time to update
        if let x = lastUpdate {
            if Date().timeIntervalSince(x) < 360 {
                if locationLabel.text == manager.locationString {
                    return
                }
            }
        }
        
        updatePrayerInfo()
        if !Global.darkTheme {
            newGradientLayer(animated: true)
        }
        
        //now we save the update date
        lastUpdate = Date()
    }
    
    func updatePrayerInfo() {
        DispatchQueue.main.async { () -> Void in
            if self.manager.dataAvailable {
                self.table.reloadCellsWithTimes(self.manager.todayPrayerTimes)
                print(self.manager.todayPrayerTimes)
                self.table.highlightCellAtIndex(self.manager.currentPrayer.rawValue, color: Global.statusColor)
                self.clock.setPrayerBubbles(self.manager)
                self.clock.refresh()
                
                self.refreshProgressBar()
            }
        }
    }
    
    func newMeridiem() {
        clock.currentMeridiem = (clock.currentMeridiem! == .am) ? .pm : .am
        updatePrayerInfo()
    }
    
    func refreshProgressBar() {
        DispatchQueue.main.async { () -> Void in
            if self.manager.dataAvailable {
                if let startTime = self.manager.currentPrayerTime() {
                    if let endTime = self.manager.nextPrayerTime() {
                        let timeElapsed = Date().timeIntervalSince(startTime as Date)
                        let interval = endTime.timeIntervalSince(startTime as Date)
                        self.progressView.setup(CGFloat(interval), timeElapsed: CGFloat(timeElapsed))
                        self.progressView.progressLayer.backgroundColor = Global.statusColor.cgColor
                    }
                }
            }
        }
    }
    
    func showLoader() {
        showSpinner = true
    }
    
    @IBAction func showQibla(_ sender: AnyObject) {
        let qvc = QiblaViewController()
        qvc.qiblaOffset = self.manager.qibla
        qvc.headingManager = self.manager
        self.manager.headingDelegate = qvc
        present(qvc, animated: true) { () -> Void in
            //do something
        }
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        //get new data
        
        SwiftSpinner.show("Loading Prayer\nData", animated: true)
        manager.reload()
    }
    
    
    @IBAction func settingsButtonPressed(_ sender: AnyObject) {
        if !settingsMode {
            qiblaButton._hide()
            refreshButton._hide()
            table.tableView._hide()
            progressView._hide()
            settingsButton.setTitle("Done", for: UIControlState.normal)
            settingsButton.alpha = 1
            //add settings controller
            if settingsController == nil {
                let s = SettingsViewController()
                s.view.frame = table.tableView.frame
                s.view.alpha = 0
                settingsController = s
                s.manager = manager
            }
            addChildViewController(settingsController!)
            tableContainer.addSubview(settingsController!.view)
            settingsController!.view._show()
            
            //remember
            settingsMode = true
        } else {
            qiblaButton._show()
            refreshButton._show()
            table.tableView._show()
            progressView._show()
            settingsButton.setTitle("Settings", for: UIControlState.normal)
            if let s = settingsController {
                s.view._hide()
                s.removeFromParentViewController()//hmm sketchy...
            }
            
            //remember
            settingsMode = false
        }
    }
    
    func fifteenMinutesLeft() {
        let pIndex = manager.currentPrayer.rawValue
        if pIndex != 6 {
            table.highlightCellAtIndex(pIndex, color: Global.statusColor)
            progressView.progressLayer.backgroundColor = Global.statusColor.cgColor
            //clock
        }
    }
    
    func flash(_ midwayBlock: @escaping () -> Void) {
        let v = UIView(frame: view.frame)
        v.backgroundColor = UIColor.white
        v.alpha = 0
        view.addSubview(v)
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            v.alpha = 1
        }, completion: { (done) -> Void in
            midwayBlock()
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                v.alpha = 0
            }, completion: { (done) -> Void in
                v.removeFromSuperview()
            })
        })
    }
    
    //global is notified by the settings controller, global then tells the viewcontroller
    func updateTheme() {
        if Global.darkTheme {
            flash { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.clock.currentMeridiem = self.clock.currentMeridiem
                    
                    self.progressView.updateTheme()
                    self.table.updateTheme()
                    self.settingsController?.updateTheme()
                    
                    self.settingsButton.backgroundColor = Global.darkerGray
                    self.qiblaButton.backgroundColor = Global.darkerGray
                    self.refreshButton.backgroundColor = Global.darkerGray
                    self.settingsButton.setTitleColor(UIColor.gray, for: UIControlState())
                    self.refreshButton.setTitleColor(UIColor.gray, for: UIControlState())
                    self.qiblaButton.setTitleColor(UIColor.gray, for: UIControlState())
                    self.clock.currentMeridiem = self.clock.currentMeridiem//this will invoke a check on color
                    self.locationLabel.textColor = UIColor.gray
                    
                    self.view.backgroundColor = UIColor.black
                    if let gl = self.gradientLayer {
                        gl.removeFromSuperlayer()
                        self.gradientLayer = nil
                    }
                })
            }
            
        } else {
            flash({ () -> Void in
                //invoke a redraw, where it will check the setting
                self.clock.setNeedsDisplay()
                DispatchQueue.main.async(execute: { () -> Void in
                    self.progressView.updateTheme()
                    self.table.updateTheme()
                    self.settingsController?.updateTheme()
                    self.settingsButton.backgroundColor = UIColor.white
                    self.qiblaButton.backgroundColor = UIColor.white
                    self.refreshButton.backgroundColor = UIColor.white
                    self.settingsButton.setTitleColor(UIColor.darkGray, for: UIControlState())
                    self.refreshButton.setTitleColor(UIColor.darkGray, for: UIControlState())
                    self.qiblaButton.setTitleColor(UIColor.darkGray, for: UIControlState())
                    self.clock.currentMeridiem = self.clock.currentMeridiem
                    self.locationLabel.textColor = UIColor.white
                    self.newGradientLayer(animated: false)
                })
            })
        }
    }
    
    
    func newGradientLayer(animated: Bool) {
        //create layer
        let layer = CAGradientLayer()
        layer.frame = view.frame
        layer.colors = Global.colorsForPrayer(manager.currentPrayer)
        
        //make clear if going to animate
        if animated {layer.opacity = 0}
        
        if gradientLayer != nil {self.view.layer.insertSublayer(layer, above: gradientLayer)} else {
            self.view.layer.insertSublayer(layer, at: 0)
        }
        
        if animated {
            let basicAnimation = CABasicAnimation(keyPath: "opacity")
            basicAnimation.fromValue = 0
            basicAnimation.toValue = 1
            basicAnimation.duration = 1
            basicAnimation.isRemovedOnCompletion = false//why is these even an option?
            basicAnimation.fillMode = kCAFillModeForwards
            layer.add(basicAnimation, forKey: "opacity")
            
            gradientLayer?.removeFromSuperlayer()
        } else {
            gradientLayer?.removeFromSuperlayer()
        }
        //might need to make this exclusive to non-animations and have another copy after a completion is called
        self.gradientLayer = layer
    }
}
