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
    @IBOutlet weak var themeButton: SqueezeButton!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var manager: PrayerManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        themeButton.isEnabled = true//false
        //themeButton.alpha = 0.5
        
        // Do any additional setup after loading the view.
        customLocationButton.layer.cornerRadius = 8
        editAlarmsButton.layer.cornerRadius = 8
        aboutButton.layer.cornerRadius = 8
        themeButton.layer.cornerRadius = 8
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let b = UIScreen.main.bounds.size.height
        if b < 960 {
            //            topConstraint.constant = 0
            //            bottomConstraint.constant = 0
        }
    }
    
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
        //        if #available(iOS 8.0,*) {
        //            let t = UITableViewController()
        //            t.tableView.tableHeaderView = UISearchBar()
        //            v = UISearchController(searchResultsController: nil)
        //        } else {
        //            v = UIViewController()
        //        }
        
        let navController = OptionsNavigatonController(rootViewController: v)
        
        parent!.present(navController, animated: true, completion: { () -> Void in
            
        })
    }
    
    @IBAction func aboutPressed(_ sender: SqueezeButton) {
        let v = AboutViewController()
        let navController = OptionsNavigatonController(rootViewController: v)
        parent!.present(navController, animated: true, completion: { () -> Void in
            
        })
    }
    
    ///IMPORTANT:
    @IBAction func themePressed(_ sender: AnyObject) {
        if Global.darkTheme {
            themeButton.setTitle("Dark Theme", for: UIControlState())
            
        } else {
            themeButton.setTitle("Color Theme", for: UIControlState())
        }
        Global.darkTheme = !Global.darkTheme
    }
    
    func updateTheme() {
        if Global.darkTheme {
            themeButton.backgroundColor = Global.darkerGray
            aboutButton.backgroundColor = Global.darkerGray
            editAlarmsButton.backgroundColor = Global.darkerGray
            customLocationButton.backgroundColor = Global.darkerGray
            
            themeButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
            aboutButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
            editAlarmsButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
            customLocationButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        } else {
            themeButton.backgroundColor = UIColor.white
            aboutButton.backgroundColor = UIColor.white
            editAlarmsButton.backgroundColor = UIColor.white
            customLocationButton.backgroundColor = UIColor.white
            
            themeButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
            aboutButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
            editAlarmsButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
            customLocationButton.setTitleColor(UIColor.darkGray, for: UIControlState.normal)
        }
    }
}
