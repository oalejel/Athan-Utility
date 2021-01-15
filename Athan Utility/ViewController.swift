//
//  ViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 10/24/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import IntentsUI
import Intents

class ViewController: UIViewController, INUIAddVoiceShortcutViewControllerDelegate {
    
    // MARK: - Class Properties
    
    @IBOutlet weak var clock: ClockView!
    var table: TableController!
    var progressView: ElapsedView!
    
    //    @IBOutlet weak var locationLabel: UILabel!
    var manager = AthanManager.shared
    var showSpinner = false
    
    //    @IBOutlet weak var settingsButton: SqueezeButton!
    //not an actual xib containerview
    @IBOutlet weak var siriButtonView: UIView!
    @IBOutlet weak var tableContainer: UIView!
    
    var settingsMode = false
    
    @IBOutlet weak var siriAnchorView: UIView!
    var gradientLayer: CAGradientLayer?
    var showIntroLate = false
    
    //    // recall last time
    //    var lastUpdate: Date?
    
    @IBOutlet weak var notificationsButton: SqueezeButton!
    @IBOutlet weak var infoButton: SqueezeButton!
    @IBOutlet weak var refreshButton: SqueezeButton!
    @IBOutlet weak var qiblaButton: SqueezeButton!
    @IBOutlet weak var locationButton: SqueezeButton!
    
    // protocol variable
    var locationIsSynced = false {
        didSet {
            // show/hide the current location image in case we lost location
            let imageName: UIImage? = manager.locationPermissionsGranted ? UIImage(named: "arrow") : nil
            DispatchQueue.main.async {
                self.locationButton.setImage(imageName, for: .normal)
            }
        }
    }
    
    //    var settingsController: SettingsViewController?
    
    // MARK: - UI State
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.movedToForeground()
        // by default, hide siri recommendation view
        siriButtonView.isHidden = true
        
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
        
        // register for foreground updates in case user moves to new location and opens app in that place
//        NotificationCenter.default.addObserver(manager!, selector: #selector(PrayerManager.enteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // add siri button, which will request siri permissions this function
        // checks for compatibility and whether the user has interacted with the button
        
        self.siriButtonView.isHidden = true
//        INVoiceShortcutCenter.shared.getAllVoiceShortcuts(completion: { (shortcuts, err) in
//            if shortcuts == nil || shortcuts?.count == 0 {
//                DispatchQueue.main.async {
//                    self.prepareSiriButtonView()
//                }
//            } else {
                
//            }
//        })
        
        // prevent touch recognizers from delaying squeezebutton reactions
        //        let window = UIApplication.shared.windows[0]
        //        let g1 = window.gestureRecognizers?[0]
        ////        g1?.delaysTouchesBegan = false
        //        let g2 = window.gestureRecognizers?[1]
        ////        g2?.delaysTouchesBegan = false
        
        refreshButton.backgroundColor = .darkerGray
        qiblaButton.backgroundColor = .darkerGray
        infoButton.backgroundColor = .darkerGray
        notificationsButton.backgroundColor = .darkerGray
        locationButton.backgroundColor = .darkerGray
        locationButton.setTitleColor(UIColor.lightGray, for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Deal with a force-press app shortcut on app launch
//        if Global.openQibla {
//            self.showQibla(self)
//        }
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
        locationButton.layer.cornerRadius = 6
    }
    
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
        
        progressView.setNeedsDisplay()
        softResetPrayerVisuals()
        dataReady()
//        manager.calculateCurrentPrayer()
        // though this is called by hard reset, we always want to refresh this animation
        clock.refreshTime()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //show what's new if never presented before!
        //        #warning("change mode from debug to majorVersion")
        self.manager.attemptSingleLocationUpdate()
    }
    
    
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
    
    
    // MARK: - Application State Handlers
    
    @objc func enteredForeground() {
        print("entered foreground")
        // must reset timers, since they are not accurate in background
        softResetPrayerVisuals()
        clock.refreshTime()
    }
    
    @objc func enteredBackground() {
        clock.pause()
        // if we started playing audio, don't let it resume on enter foreground
        NoteSoundPlayer.stopAudio()
    }
    
    
    // MARK: - Siri Intents
    
    func prepareSiriButtonView() {
        if #available(iOS 12.0, *) {
//            if UserDefaults.standard.bool(forKey: Global.HIDE_SIRI_SHORTCUTS_KEY) == true {
//                return // no reason to show button
//            }
            
            siriButtonView.isHidden = false
            siriButtonView.layer.cornerRadius = 10
            siriButtonView.backgroundColor = .darkerGray
            
            let button = INUIAddVoiceShortcutButton(style: .blackOutline)
            button.translatesAutoresizingMaskIntoConstraints = false
            siriButtonView.addSubview(button)
            button.trailingAnchor.constraint(equalTo: siriAnchorView.trailingAnchor).isActive = true
            button.centerYAnchor.constraint(equalTo: siriAnchorView.centerYAnchor).isActive = true
            
            button.addTarget(self, action: #selector(beginSiriShortcutsSetup), for: .touchUpInside)
            
            let suggestionLabel = UILabel()
            suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
            suggestionLabel.text = "Ask Siri for the \nnext prayer time."
            suggestionLabel.textColor = .white
            suggestionLabel.font = UIFont.systemFont(ofSize: suggestionLabel.font.pointSize - 4, weight: .bold)
            suggestionLabel.numberOfLines = 2
            
            siriButtonView.addSubview(suggestionLabel)
            
            suggestionLabel.heightAnchor.constraint(equalTo: siriButtonView.heightAnchor, constant: -16).isActive = true
            suggestionLabel.widthAnchor.constraint(equalTo: siriButtonView.widthAnchor, multiplier: 0.5, constant: 0).isActive = true
            suggestionLabel.leadingAnchor.constraint(equalTo: siriButtonView.leadingAnchor, constant: 12).isActive = true
            suggestionLabel.centerYAnchor.constraint(equalTo: siriButtonView.centerYAnchor).isActive = true
        }
    }
    
    
    @objc
    func beginSiriShortcutsSetup() {
        INPreferences.requestSiriAuthorization { (status: INSiriAuthorizationStatus) in
            if status == .authorized {
                if #available(iOS 12.0, *) {
                    let intent = NextPrayerIntent()
                    intent.suggestedInvocationPhrase = "Next prayer"
                    if let shortcut = INShortcut(intent: intent) {
                        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                        viewController.modalPresentationStyle = .formSheet
                        viewController.delegate = self // Object conforming to `INUIAddVoiceShortcutViewControllerDelegate`.
                        self.present(viewController, animated: true, completion: nil)
                    }
                }
            } else if status == .denied {
                // do not show siri button in future if user rejects allowing siri permissions
//                UserDefaults.standard.set(true, forKey: Global.HIDE_SIRI_SHORTCUTS_KEY)
            }
        }
    }
    
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
        DispatchQueue.main.async {
            self.siriButtonView.isHidden = true
//            self.table.tableView.estimatedRowHeight = 300
//            self.table.tableView.needsUpdateConstraints()
//            self.table.tableView.setNeedsLayout()
//            self.table.tableView.setNeedsDisplay()
//            self.table.tableView.beginUpdates()
//            self.table.tableView.endUpdates()
//            self.table.tableView.reloadData()
        }
        // from now on, users must enable shortcuts in settings view controller
        UserDefaults.standard.set(true, forKey: Global.HIDE_SIRI_SHORTCUTS_KEY)
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        // if canceled, keep shortcut suggestion visible, but set default settings to off
        controller.dismiss(animated: true, completion: nil)
        // from now on, users must enable shortcuts in settings view controller
        UserDefaults.standard.set(true, forKey: Global.HIDE_SIRI_SHORTCUTS_KEY)
    }
    
    // MARK: - PrayerManagerDelegate
    
    // When called, assume that location and times have changed
    func dataReady() {
        //        lastUpdate = Date()
        
        DispatchQueue.main.async { () -> Void in
            self.hardResetPrayerVisuals()
//            SwiftSpinner.hide()
            self.locationButton.setTitle(AthanManager.shared.locationSettings.locationName, for: .normal)
            
            // now that we actually have a qibla heading, we can have a dynamic quick action
            let icon = UIApplicationShortcutIcon(type: .location)
            let dynamicItem = UIApplicationShortcutItem(type: "qibla", localizedTitle: "Qibla", localizedSubtitle: nil, icon: icon, userInfo: nil)
            UIApplication.shared.shortcutItems = [dynamicItem]
        }
    }
    
    //specific to individual prayers
    func newPrayer() {
        softResetPrayerVisuals()
        
//        if manager.dataExists {
        let timeElapsed = Date().timeIntervalSince(self.manager.guaranteedCurrentPrayerTime())
        if timeElapsed < 3 { // only play athan if its been < 2 seconds since athan
            NoteSoundPlayer.playFullAudio(for: Settings.getSelectedSoundIndex())
        }
//        }
        
        // keep track of last time we updated our visuals
        //        lastUpdate = Date()
    }
    
    
    /// readjust only visual things that need changing within the same day. Does not include reloading table data.
    func softResetPrayerVisuals(fifteenMinutesLeft: Bool = false) {
//        if manager.dataExists {
            refreshProgressBar()
            
            let pIndex = manager.currentPrayer?.rawValue() ?? 5
            var cellIndex = pIndex
            if cellIndex > 5 { cellIndex = 5 }
            table.highlightCellAtIndex(cellIndex, color: Global.statusColor)
        clock.refreshPrayerBubbles(manager.currentPrayer ?? .isha, fifteenMinutesLeft: fifteenMinutesLeft)
            //            progressView?.progressLayer.backgroundColor = Global.statusColor.cgColor
//        }
    }
    
    
    /// readjust all visual representations, **including** things reset in softResetPrayerVisuals
    func hardResetPrayerVisuals() {
//        if manager.dataExists {
            // soft
            refreshProgressBar()
        clock.refreshPrayerBubbles(manager.currentPrayer ?? .isha)
        table.highlightCellAtIndex((self.manager.currentPrayer ?? .isha).rawValue(), color: Global.statusColor)
            //            progressView?.progressLayer.backgroundColor = Global.statusColor.cgColor
            
            // hard
            table.reloadCellsWithTimes(self.manager.todayTimes)
            clock.setPrayerBubbles()
            clock.refreshTime()
//        }
    }
    
    
    func newMeridiem() {
        clock.currentMeridiem = (clock.currentMeridiem! == .am) ? .pm : .am
        hardResetPrayerVisuals()
    }
    
    
    func refreshProgressBar() {
//        if self.manager.dataExists {
            let startTime = AthanManager.shared.guaranteedCurrentPrayerTime()
            let endTime = AthanManager.shared.guaranteedNextPrayerTime()
            let timeElapsed = Date().timeIntervalSince(startTime as Date)
            let interval = endTime.timeIntervalSince(startTime as Date)
            self.progressView.setup(CGFloat(interval), timeElapsed: CGFloat(timeElapsed))
//        }
    }
    
    
    
    func hideLoadingView() {
//        SwiftSpinner.hide()
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
    
    
    //MARK: - Button Press IBActions
    
    // Refresh app data. Originates from button with rotating arrows
    @IBAction func refreshPressed(_ sender: AnyObject) {
        // tell manager that if we were locked on a location, we now want a new one
        let loadingString = NSLocalizedString("Loading Prayer Data", comment: "")
//        SwiftSpinner.show(loadingString, animated: true)
        manager.attemptSingleLocationUpdate { locSettings in
            self.locationButton.setTitle(locSettings?.locationName ?? "Location Disabled", for: .normal)
        }
    }
    
    // Show alarm controls. Originates from bell button
    @IBAction func alarmsButtonPressed(_ sender: AnyObject) {
        let prayerSettingsController = SettingsViewController()
        let navController = OptionsNavigatonController(rootViewController: prayerSettingsController)
        present(navController, animated: true, completion: nil)
    }
    
    
    // Show conrtol for setting custom location (originates from location button @ bottom)
    @IBAction func customLocationPressed(_ sender: SqueezeButton) {
        AthanManager.shared.requestLocationPermission()
        AthanManager.shared.attemptSingleLocationUpdate()
        AthanManager.shared.attemptSingleLocationUpdate { (loc) in
            self.dataReady()
        }
//        let v = LocationInputController()//: UIViewController!
//        let navController = OptionsNavigatonController(rootViewController: v)
//        present(navController, animated: true, completion: nil)
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
//            Global.openQibla = false
            let qvc = QiblaViewController()
            qvc.qiblaOffset = self.manager.heading
//            qvc.headingManager = self.manager
//            self.manager.headingDelegate = qvc
            self.present(qvc, animated: true) { () -> Void in
                // do something
            }
        }
    }
    
}
