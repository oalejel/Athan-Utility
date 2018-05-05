//
//  SettingsViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/7/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var customLocationButton: SqueezeButton!
    @IBOutlet weak var editAlarmsButton: SqueezeButton!
    @IBOutlet weak var aboutButton: SqueezeButton!
//    @IBOutlet weak var themeButton: SqueezeButton!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var manager: PrayerManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //custom theme is disabled for the time being
//        themeButton.isEnabled = false
//        themeButton.alpha = 0.5
        
        //adjust button corner radii
        customLocationButton.layer.cornerRadius = 8
        editAlarmsButton.layer.cornerRadius = 8
        aboutButton.layer.cornerRadius = 8
        
        customLocationButton.backgroundColor = Global.darkerGray
        editAlarmsButton.backgroundColor = Global.darkerGray
        aboutButton.backgroundColor = Global.darkerGray
        
//        themeButton.layer.cornerRadius = 8
    }
    
    // may need this when testing for future iPhone sizes
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        let b = UIScreen.main.bounds.size.height
//        if b < 960 {
//            //            topConstraint.constant = 0
//            //            bottomConstraint.constant = 0
//        }
//    }
    
    @IBAction func alarmsButtonPressed(_ sender: AnyObject) {
        let prayerSettingsController = PrayerSettingsViewController()
        //let navController = UINavigationController(rootViewController: prayerSettingsController)
        prayerSettingsController.manager = manager
        let navController = OptionsNavigatonController(rootViewController: prayerSettingsController)
        
        parent!.present(navController, animated: true, completion: { () -> Void in
            
        })
    }
    
    @IBAction func customLocationPressed(_ sender: SqueezeButton) {
        let v = LocationInputController()//: UIViewController!
        
        let navController = OptionsNavigatonController(rootViewController: v)
        parent!.present(navController, animated: true, completion: { () -> Void in
            // do nothing extra for now
        })
    }
    
    @IBAction func aboutPressed(_ sender: SqueezeButton) {
        let v = AboutViewController()
        let navController = OptionsNavigatonController(rootViewController: v)
        parent!.present(navController, animated: true, completion: { () -> Void in
            
        })
    }
    
    // this function will never be called for now
    
    func updateTheme() {
        if Global.darkTheme {
//            themeButton.backgroundColor = Global.darkerGray
            aboutButton.backgroundColor = Global.darkerGray
            editAlarmsButton.backgroundColor = Global.darkerGray
            customLocationButton.backgroundColor = Global.darkerGray
            
//            themeButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
            aboutButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
            editAlarmsButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
            customLocationButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        } else {
//            themeButton.backgroundColor = UIColor.white
            aboutButton.backgroundColor = UIColor.white
            editAlarmsButton.backgroundColor = UIColor.white
            customLocationButton.backgroundColor = UIColor.white
            
//            themeButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
            aboutButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
            editAlarmsButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
            customLocationButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
        }
    }

}
