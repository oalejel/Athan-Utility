//
//  ViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import IntentsUI
import WhatsNew

extension UIView {
    /// Custom UIView method to fade out a view in 0.77 seconds
    func _hide() {
        UIView.animate(withDuration: 0.77, animations: { () -> Void in self.alpha = 0.0 })
    }
    
    /// Custom UIView method to fade in a view in 0.77 seconds
    func _show() {
        UIView.animate(withDuration: 0.77, animations: { () -> Void in self.alpha = 1.0 })
    }
}

class ViewController: UIViewController, PrayerManagerDelegate {
    
    @IBOutlet weak var clock: ClockView!
    var table: TableController!
    var progressView: ElapsedView!
    
//    @IBOutlet weak var locationLabel: UILabel!
    var manager: PrayerManager!
    var showSpinner = false
    var refreshClockNeeded = false
    
//    @IBOutlet weak var settingsButton: SqueezeButton!
    //not an actual xib containerview
    @IBOutlet weak var tableContainer: UIView!
    
    var settingsMode = false
    
    var gradientLayer: CAGradientLayer?
    var showIntroLate = false
    
    var lastUpdate: Date?
    
    //new buttons
    @IBOutlet weak var notificationsButton: SqueezeButton!
    @IBOutlet weak var infoButton: SqueezeButton!
    @IBOutlet weak var refreshButton: SqueezeButton!
    @IBOutlet weak var qiblaButton: SqueezeButton!
    @IBOutlet weak var locationButton: SqueezeButton!
    
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
    
//    var settingsController: SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.black
        
        //this will also set the manager variable equal to this (could cause a problem)!
        manager = PrayerManager(delegate: self)
        Global.manager = manager
        
//        refreshButton.layer.cornerRadius = 8
//        qiblaButton.layer.cornerRadius = 8
//        settingsButton.layer.cornerRadius = 8
        
        // prevent touch recognizers from delaying squeezebutton reactions
        let window = UIApplication.shared.windows[0]
        let g1 = window.gestureRecognizers?[0]
        g1?.delaysTouchesBegan = false
        let g2 = window.gestureRecognizers?[1]
        g2?.delaysTouchesBegan = false
        
//        refreshButton.setTitleColor(UIColor.lightGray, for: UIControlState())
//        refreshButton.setTitle("Refresh", for: UIControlState())
        refreshButton.backgroundColor = .darkerGray
        locationButton.backgroundColor = .darkerGray
        locationButton.setTitleColor(UIColor.lightGray, for: .normal)
//        qiblaButton.setTitleColor(UIColor.lightGray, for: UIControlState())
//        qiblaButton.setTitle("Qibla", for: UIControlState())
        qiblaButton.backgroundColor = .darkerGray
        infoButton.backgroundColor = .darkerGray
        notificationsButton.backgroundColor = .darkerGray
//        settingsButton.setTitleColor(UIColor.lightGray, for: UIControlState.normal)
//        settingsButton.setTitle("Settings", for: UIControlState.normal)
//        settingsButton.backgroundColor = Global.darkerGray
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredBackground), name: .UIApplicationDidEnterBackground, object: nil)
        
        // Deal with a force-press app shortcut
        if Global.openQibla {
            showQibla(self)
        }

        // Theme changing currently not supported
//        if !Global.darkTheme {
//            updateTheme()
//        }
        
        Global.mainController = self
    }

    @objc func enteredForeground() {
        // must reset timers, since they are not accurate in background
        manager.calculateCurrentPrayer()
        manager.setTimers()
        
        if refreshClockNeeded {
            softResetPrayerVisuals()
            clock.refreshTime()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // new button setup
        let radius = notificationsButton.frame.size.width / 2
        notificationsButton.layer.cornerRadius = radius
        infoButton.layer.cornerRadius = radius
        refreshButton.layer.cornerRadius = radius
        qiblaButton.layer.cornerRadius = radius
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if refreshClockNeeded {
            manager.calculateCurrentPrayer()
            softResetPrayerVisuals()
            // though this is called by hard reset, we always want to refresh this animation
            clock.refreshTime()
//            refreshClockNeeded = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //show what's new if never presented before!
        #warning("change mode from debug to majorVersion")
        if WhatsNew.shouldPresent(with: .majorVersion) {
            let whatsNewVC = WhatsNewViewController(items: [
                WhatsNewItem.text(title: "Months Long Storage", subtitle: "Offline use is possible with months of athan data storage."),
                WhatsNewItem.text(title: "15 minute reminders", subtitle: "Get reminded when athan will take place. Configurable in app preferences."),
                WhatsNewItem.text(title: "Today Extension", subtitle: "Check current and upcoming salah times with the Notification Center widget."),
                WhatsNewItem.text(title: "Athan clock face", subtitle: "A new way to visualize salah times throughout the day."),
            ])
            #warning("change mode from debug to majorVersion")
            whatsNewVC.presentationOption = .majorVersion
            whatsNewVC.titleStrings = ["السلام عليكم", "Peace Be Upon You", "平和は貴方とともに", "שָׁלוֹם עֲלֵיכֶם", "Que La Paz Está Con Usted", "Paix à Vous", "Friede Sei Mit Dir"]
            whatsNewVC.titleColor = .white
            whatsNewVC.buttonBackgroundColor = .white
            whatsNewVC.buttonTextColor = .darkGray
            whatsNewVC.itemSubtitleColor = .darkGray
            whatsNewVC.itemTitleColor = .gray
            whatsNewVC.view.backgroundColor = .black
            whatsNewVC.presentIfNeeded(on: self)
        } else {
            if showSpinner {
                let loadingString = NSLocalizedString("Loading Prayer Data", comment: "")
                SwiftSpinner.show(loadingString, animated: true)
                manager.beginLocationRequest()
                showSpinner = false
            }
        }
            
        
            /*
            if !pref { showIntroLate = true }
            manager.beginLocationRequest()
        } else if !pref {
            print("show intro screen")
            let intro = IntroViewController()
            intro.view.backgroundColor = UIColor.black
            present(intro, animated: true, completion: { })
            UserDefaults.standard.set(true, forKey: "introduced")
        }
             }
 */
        
        refreshClockNeeded = true
    }
    
    //Data Manager Delegate
    func dataReady(manager: PrayerManager) {
        lastUpdate = Date()
        
        DispatchQueue.main.async { () -> Void in
            self.hardResetPrayerVisuals()
            SwiftSpinner.hide()
            if let location = manager.locationString {
                self.locationButton.setTitle(location, for: .normal)
            }
        }
    }
    
    //specific to individual prayers
    func updatePrayer(manager: PrayerManager) {
        //a check if its NOT a good time to update
        if let x = lastUpdate {
            if Date().timeIntervalSince(x) < 360 {
                if locationButton.titleLabel?.text == manager.locationString {
                    return
                }
            }
        }
        
        softResetPrayerVisuals()
//        if !Global.darkTheme {
//            newGradientLayer(animated: true)
//        }
        
        // keep track of last time we updated our visuals
        lastUpdate = Date()
    }
    
    /// readjust only visual things that need changing within the same day. Does not include reloading table data.
    func softResetPrayerVisuals(_ fifteenMinutesLeft: Bool = false) {
        if manager.dataExists {
            refreshProgressBar()
            clock.refreshPrayerBubbles(manager.currentPrayer)
            
            let pIndex = manager.currentPrayer.rawValue
            if pIndex != 6 {
                table.highlightCellAtIndex(pIndex, color: Global.statusColor)
                if fifteenMinutesLeft {
                    progressView.progressLayer.backgroundColor = Global.statusColor.cgColor
                }
            }
        }
    }
    
    /// readjust all visual representations, **including** things reset in softResetPrayerVisuals
    func hardResetPrayerVisuals() {
        if manager.dataExists {
            // soft
            refreshProgressBar()
            clock.refreshPrayerBubbles(manager.currentPrayer)
            table.highlightCellAtIndex(self.manager.currentPrayer.rawValue, color: Global.statusColor)
            // hard
            table.reloadCellsWithTimes(self.manager.todayPrayerTimes)
            clock.setPrayerBubbles(manager)
            clock.refreshTime()
            
        }
    }
    
    func newMeridiem() {
        clock.currentMeridiem = (clock.currentMeridiem! == .am) ? .pm : .am
        hardResetPrayerVisuals()
    }
    
    func refreshProgressBar() {
        if self.manager.dataExists {
            if let startTime = self.manager.currentPrayerTime() {
                if let endTime = self.manager.nextPrayerTime() {
                    let timeElapsed = Date().timeIntervalSince(startTime as Date)
                    let interval = endTime.timeIntervalSince(startTime as Date)
                    self.progressView.setup(CGFloat(interval), timeElapsed: CGFloat(timeElapsed))
                }
            }
        }
    }
    
    func loadingHandler() {
        let loadingString = NSLocalizedString("Loading Prayer Data", comment: "")
        SwiftSpinner.show(loadingString, animated: true)
        manager.reload()
    }
    
    // tells vc to be ready to show spinner when prayer manager is initialized
    func setShouldShowLoader() {
        showSpinner = true
    }
    
    func fifteenMinutesLeft() {
        softResetPrayerVisuals()
        
        let pIndex = manager.currentPrayer.rawValue
        if pIndex != 6 {
            table.highlightCellAtIndex(pIndex, color: Global.statusColor)
            progressView.progressLayer.backgroundColor = manager.timeLeftColor().cgColor
        }
        clock.refreshPrayerBubbles(manager.currentPrayer, fifteenMinutesLeft: true)
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
    
    //MARK: - Button Presses
    
    // Refresh app data. Originates from button with rotating arrows
    @IBAction func refreshPressed(_ sender: AnyObject) {
        // tell manager that if we were locked on a location, we now want a new one
        manager.lockLocation = false
        // get new data
        loadingHandler()
    }
    
    // Show alarm controls. Originates from bell button
    @IBAction func alarmsButtonPressed(_ sender: AnyObject) {
        let prayerSettingsController = PrayerSettingsViewController()
        prayerSettingsController.manager = manager
        let navController = OptionsNavigatonController(rootViewController: prayerSettingsController)
        present(navController, animated: true, completion: nil)
    }
    
    // Show conrtol for setting custom location (originates from location button @ bottom)
    @IBAction func customLocationPressed(_ sender: SqueezeButton) {
        let v = LocationInputController()//: UIViewController!
        let navController = OptionsNavigatonController(rootViewController: v)
        present(navController, animated: true, completion: nil)
    }
    
    // Show app credits. Originates from 'i' info button
    @IBAction func aboutPressed(_ sender: SqueezeButton) {
        let v = AboutViewController()
        let navController = OptionsNavigatonController(rootViewController: v)
        present(navController, animated: true, completion: nil)
    }
    
    // Show compass direction to Kabah in Mecca. Originates from compass button.
    @IBAction func showQibla(_ sender: AnyObject) {
        let qvc = QiblaViewController()
        qvc.qiblaOffset = self.manager.qibla
        qvc.headingManager = self.manager
        self.manager.headingDelegate = qvc
        present(qvc, animated: true) { () -> Void in
            //do something
        }
    }
    
//    func emergencyRefresh() {
//        manager.alignPrayerTimes()
//        manager.calculateCurrentPrayer()
//        hardResetPrayerVisuals()
//    }
    
    /*
     
    //global is notified by the settings controller, global then tells the viewcontroller
    func updateTheme() {
        if Global.darkTheme {
            flash { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.clock.currentMeridiem = self.clock.currentMeridiem
                    
                    self.progressView.updateTheme()
                    self.table.updateTheme()
                    self.settingsController?.updateTheme()
                    
//                    self.settingsButton.backgroundColor = Global.darkerGray
                    self.qiblaButton.backgroundColor = Global.darkerGray
                    self.refreshButton.backgroundColor = Global.darkerGray
//                    self.settingsButton.setTitleColor(UIColor.gray, for: UIControlState())
                    self.refreshButton.setTitleColor(UIColor.gray, for: UIControlState())
                    self.qiblaButton.setTitleColor(UIColor.gray, for: UIControlState())
                    self.clock.currentMeridiem = self.clock.currentMeridiem//this will invoke a check on color
//                    self.locationLabel.textColor = UIColor.gray
                    
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
//                    self.settingsButton.backgroundColor = UIColor.white
                    self.qiblaButton.backgroundColor = UIColor.white
                    self.refreshButton.backgroundColor = UIColor.white
//                    self.settingsButton.setTitleColor(UIColor.darkGray, for: UIControlState())
                    self.refreshButton.setTitleColor(UIColor.darkGray, for: UIControlState())
                    self.qiblaButton.setTitleColor(UIColor.darkGray, for: UIControlState())
                    self.clock.currentMeridiem = self.clock.currentMeridiem
//                    self.locationLabel.textColor = UIColor.white
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
 */
}
