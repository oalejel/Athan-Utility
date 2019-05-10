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
import SqueezeButton
import Intents


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

class ViewController: UIViewController, PrayerManagerDelegate, INUIAddVoiceShortcutViewControllerDelegate {
    
    @IBOutlet weak var clock: ClockView!
    var table: TableController!
    var progressView: ElapsedView!
    
    //    @IBOutlet weak var locationLabel: UILabel!
    var manager: PrayerManager!
    var showSpinner = false
    
//    @IBOutlet weak var settingsButton: SqueezeButton!
    //not an actual xib containerview
    @IBOutlet weak var siriButtonView: UIView!
    @IBOutlet weak var tableContainer: UIView!
    
    var settingsMode = false
    
    @IBOutlet weak var siriAnchorView: UIView!
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
            table = segue.destination as? TableController
            //!!! might want to not set default color as clear!!!
            table.view.backgroundColor = UIColor.clear
            table.view.layer.cornerRadius = 6
            table.tableView.backgroundColor = UIColor.clear
            table.tableView.backgroundView?.backgroundColor = UIColor.clear
        } else if segue.identifier == "Progress" {
            progressView = segue.destination.view as? ElapsedView
        }
    }
    
    // protocol variable
    var locationIsUpToDate = false {
        didSet {
            // show/hide the current location image in case we lost location
            let imageName: UIImage? = locationIsUpToDate ? UIImage(named: "arrow") : nil
            DispatchQueue.main.async {
                self.locationButton.setImage(imageName, for: .normal)
            }
        }
    }
    
//    var settingsController: SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // by default, hide siri recommendation view
        siriButtonView.isHidden = true
        
        // for now, ask for siri permission immediately.
        // goal is to have settings available for requesting manually,
        // and a banner to show the feature in the second and third times the app is opened.
        INPreferences.requestSiriAuthorization { (status: INSiriAuthorizationStatus) in

            // if on iOS 12, show button for creating shortcut
            if #available(iOS 12.0, *) {
                // check that user still wants to see shortcut
                if UserDefaults.standard.bool(forKey: "hideSiriShortcuts") == false {
                    if status == INSiriAuthorizationStatus.authorized {
                        self.prepareSiriButtonView()
                    }
                }
            }
        }
        
        // setup accessibility on buttons and elements of screen
//        #warning("should eventually make this based on a localized string")
        notificationsButton.accessibilityLabel = "notification settings"
        infoButton.accessibilityLabel = "info"
        refreshButton.accessibilityLabel = "refresh"
        qiblaButton.accessibilityLabel = "qibla"
        locationButton.accessibilityLabel = "location"
        
        // make current location indication image look normal
        locationButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 12)
        locationButton.imageView?.contentMode = .scaleAspectFit
        locationButton.setImage(nil, for: .normal)
        
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.black
        
        //this will also set the manager variable equal to this (could cause a problem)!
        manager = PrayerManager(delegate: self)
        Global.manager = manager
        
        // register for foreground updates in case user moves to new location and opens app in that place
        NotificationCenter.default.addObserver(manager!, selector: #selector(PrayerManager.enteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // prevent touch recognizers from delaying squeezebutton reactions
        let window = UIApplication.shared.windows[0]
        let g1 = window.gestureRecognizers?[0]
        g1?.delaysTouchesBegan = false
        let g2 = window.gestureRecognizers?[1]
        g2?.delaysTouchesBegan = false
        
        refreshButton.backgroundColor = .darkerGray
        qiblaButton.backgroundColor = .darkerGray
        infoButton.backgroundColor = .darkerGray
        notificationsButton.backgroundColor = .darkerGray
        locationButton.backgroundColor = .darkerGray
        locationButton.setTitleColor(UIColor.lightGray, for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Deal with a force-press app shortcut on app launch
        if Global.openQibla {
            self.showQibla(self)
        }
    }
    
    // MARK: Siri Intents
    
    func hideLoadingView() {
        SwiftSpinner.hide()
    }
    
    func prepareSiriButtonView() {
        if #available(iOS 12.0, *) {
            siriButtonView.isHidden = false
            siriButtonView.layer.cornerRadius = 10
            siriButtonView.backgroundColor = .darkerGray
            
            let button = INUIAddVoiceShortcutButton(style: .blackOutline)
            button.translatesAutoresizingMaskIntoConstraints = false
            siriButtonView.addSubview(button)
            button.trailingAnchor.constraint(equalTo: siriAnchorView.trailingAnchor).isActive = true
            button.centerYAnchor.constraint(equalTo: siriAnchorView.centerYAnchor).isActive = true
            
            button.addTarget(self, action: #selector(addToSiri), for: .touchUpInside)
            
            let suggestionLabel = UILabel()
            suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
            suggestionLabel.text = "Ask Siri for the \nnext prayer time."
            suggestionLabel.textColor = .white
            suggestionLabel.font = UIFont(name: "\(suggestionLabel.font.fontName)-Bold", size: suggestionLabel.font.pointSize - 4)
            suggestionLabel.numberOfLines = 2
            
            siriButtonView.addSubview(suggestionLabel)
            
            suggestionLabel.heightAnchor.constraint(equalTo: siriButtonView.heightAnchor, constant: -16).isActive = true
            suggestionLabel.widthAnchor.constraint(equalTo: siriButtonView.widthAnchor, multiplier: 0.5, constant: 0).isActive = true
            suggestionLabel.leadingAnchor.constraint(equalTo: siriButtonView.leadingAnchor, constant: 12).isActive = true
            suggestionLabel.centerYAnchor.constraint(equalTo: siriButtonView.centerYAnchor).isActive = true
        }
    }
    
    @objc
    func addToSiri() {
        if #available(iOS 12.0, *) {
            let intent = NextPrayerIntent()
            intent.suggestedInvocationPhrase = "Next prayer"
            if let shortcut = INShortcut(intent: intent) {
                let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                viewController.modalPresentationStyle = .formSheet
                viewController.delegate = self // Object conforming to `INUIAddVoiceShortcutViewControllerDelegate`.
                present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        siriButtonView.isHidden = true
        controller.dismiss(animated: true, completion: nil)
        // from now on, users must enable shortcuts in settings view controller
        UserDefaults.standard.set(true, forKey: "hideSiriShortcuts")
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        // if canceled, keep shortcut suggestion visible, but set default settings to off
        controller.dismiss(animated: true, completion: nil)
        // from now on, users must enable shortcuts in settings view controller
        UserDefaults.standard.set(true, forKey: "hideSiriShortcuts")
    }
    
    @objc func enteredForeground() {
        print("entered foreground")
        // must reset timers, since they are not accurate in background
        manager.calculateCurrentPrayer()
        manager.setTimers()
        
        softResetPrayerVisuals()
        clock.refreshTime()
    }

    @objc func enteredBackground() {
        clock.pause()
        manager.saveSettings()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        
        progressView.setNeedsDisplay()
        softResetPrayerVisuals()
        manager.calculateCurrentPrayer()
        // though this is called by hard reset, we always want to refresh this animation
        clock.refreshTime()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //show what's new if never presented before!
//        #warning("change mode from debug to majorVersion")
        if WhatsNew.shouldPresent(with: .majorVersion) {
            let title1 = NSLocalizedString("Offline Storage", comment: "")
            let title2 = NSLocalizedString("15 minute reminders", comment: "")
            let title3 = NSLocalizedString("Today Extension", comment: "")
            let title4 = NSLocalizedString("Athan clock face", comment: "")
            let title5 = NSLocalizedString("Qibla", comment: "")
            
            let subtitle1 = NSLocalizedString("Athan Utility stores months of athan data for offline use.", comment: "")
            let subtitle2 = NSLocalizedString("Get reminded before the next athan takes place. Configurable in app preferences.", comment: "")
            let subtitle3 = NSLocalizedString("Check current and upcoming salah times with the Notification Center widget.", comment: "")
            let subtitle4 = NSLocalizedString("A new way to visualize salah times throughout the day.", comment: "")
            // no subtitle for qibla
            
            let whatsNewVC = WhatsNewViewController(items: [
                WhatsNewItem.text(title: title1,
                                  subtitle: subtitle1),
                                   //image: UIImage(named: "no_wifi_icon") ?? UIImage()),
                WhatsNewItem.text(title: title2,
                                  subtitle: subtitle2),
                                  //image: UIImage(named: "timer_icon") ?? UIImage()),
                WhatsNewItem.text(title: title3,
                                  subtitle: subtitle3),
                                  //image: UIImage(named: "widget_icon") ?? UIImage()),
                WhatsNewItem.text(title: title4,
                                  subtitle: subtitle4),
                WhatsNewItem.text(title: title5,
                                  subtitle: "")
            ])
//            #warning("change mode from debug to majorVersion")
            whatsNewVC.presentationOption = .majorVersion
            whatsNewVC.titleStrings = ["السلام عليكم", "Peace Be Upon You", "Paix à Vous", "Selamünaleyküm", "平和は貴方とともに", "שָׁלוֹם עֲלֵיכֶם", "Que La Paz Está Con Usted", "Friede Sei Mit Dir"]
            whatsNewVC.titleColor = .white
            whatsNewVC.buttonBackgroundColor = .darkerGray
            whatsNewVC.buttonTextColor = .lightGray
            whatsNewVC.itemSubtitleColor = .darkGray
            whatsNewVC.itemTitleColor = .gray
            whatsNewVC.view.backgroundColor = .black
            whatsNewVC.presentIfNeeded(on: self)
        } else {
            // if we were in a mode to show the spinner, then show it and being location request
            if showSpinner {
                let loadingString = NSLocalizedString("Loading Prayer Data", comment: "")
                SwiftSpinner.show(loadingString, animated: true)
                showSpinner = false
            }
            // always do a location request on first appearance of view
            manager.beginLocationRequest()
        }
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
            
            // now that we actually have a qibla heading, we can have a dynamic quick action
            let icon = UIApplicationShortcutIcon(type: .location)
            let dynamicItem = UIApplicationShortcutItem(type: "qibla", localizedTitle: "Qibla", localizedSubtitle: nil, icon: icon, userInfo: nil)
            UIApplication.shared.shortcutItems = [dynamicItem]
        }
    }
    
    //specific to individual prayers
    func newPrayer(manager: PrayerManager) {
        softResetPrayerVisuals()
        
        // keep track of last time we updated our visuals
        lastUpdate = Date()
    }
    
    /// readjust only visual things that need changing within the same day. Does not include reloading table data.
    func softResetPrayerVisuals(fifteenMinutesLeft: Bool = false) {
        if manager.dataExists {
            refreshProgressBar()
            
            let pIndex = manager.currentPrayer.rawValue
            var cellIndex = pIndex
            if cellIndex > 5 { cellIndex = 5 }
            table.highlightCellAtIndex(cellIndex, color: Global.statusColor)
            clock.refreshPrayerBubbles(manager.currentPrayer, fifteenMinutesLeft: fifteenMinutesLeft)
//            progressView?.progressLayer.backgroundColor = Global.statusColor.cgColor
        }
    }
    
    /// readjust all visual representations, **including** things reset in softResetPrayerVisuals
    func hardResetPrayerVisuals() {
        if manager.dataExists {
            // soft
            refreshProgressBar()
            clock.refreshPrayerBubbles(manager.currentPrayer)
            table.highlightCellAtIndex(self.manager.currentPrayer.rawValue, color: Global.statusColor)
//            progressView?.progressLayer.backgroundColor = Global.statusColor.cgColor
            
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
        manager.userRequestsReload()
    }
    
    // tells vc to be ready to show spinner when prayer manager is initialized
    func setShouldShowLoader() {
        showSpinner = true
    }
    
    func fifteenMinutesLeft() {
        softResetPrayerVisuals(fifteenMinutesLeft: true)
        
//        let pIndex = manager.currentPrayer.rawValue
//        var cellIndex = pIndex
//        if cellIndex > 5 { cellIndex = 5 }
//        table.highlightCellAtIndex(cellIndex, color: Global.statusColor)
////        progressView.progressLayer.backgroundColor = manager.timeLeftColor().cgColor
//        clock.refreshPrayerBubbles(manager.currentPrayer, fifteenMinutesLeft: true)
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
        DispatchQueue.main.async {
            Global.openQibla = false
            let qvc = QiblaViewController()
            qvc.qiblaOffset = self.manager.qibla
            qvc.headingManager = self.manager
            self.manager.headingDelegate = qvc
            self.present(qvc, animated: true) { () -> Void in
                // do something
            }
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
