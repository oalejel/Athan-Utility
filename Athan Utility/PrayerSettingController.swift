//
//  PrayerSettingController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/22/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

// PrayerSettingController is responsible for user settings related to notifications frequency,
// sounds, and other future settings
class PrayerSettingController: UITableViewController {
    
    var p: PrayerType!
    
    var switches: [UISwitch] = []
    var switchesOn: [Bool] = [true,true,true]
    var switchesEnabled: [Bool] = [true,true,true]
    
    var initialSettings: PrayerSetting!
    
    init(style: UITableViewStyle, prayer: PrayerType) {
        super.init(style: style)
        p = prayer
        //create a settings object to be compared later
        let initialSettingsPointer = Global.manager.prayerSettings[p]
        initialSettings = PrayerSetting()
        initialSettings.alarmType = initialSettingsPointer!.alarmType
        initialSettings.soundEnabled = initialSettingsPointer!.soundEnabled
        
        let alarmType = Global.manager.prayerSettings[p]?.alarmType
        let soundEnabled = Global.manager.prayerSettings[p]?.soundEnabled
        switchesOn[2] = soundEnabled!//preliminary, can be broken if others are off
        if alarmType == .all {
            //do nothing
        } else if alarmType == .noEarly {
            //1 off, no disabling
            switchesOn[1] = false
        } else {
            //all off, 2 disabled
            switchesEnabled[1...2] = [false,false]
            switchesOn[0...2] = [false,false,false]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorColor = UIColor.black
        tableView.allowsSelection = false
        navigationItem.title = p.stringValue()
        
        tableView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
    }
    
    //    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    //        return 3
    //    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    //if we decide to organize our table using headers and cells separated... use this
    //    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        switch section {
    //        case 0:
    //            return "Standard Alarm"
    //        case 1:
    //            return "15 minute reminder"
    //        default:
    //            return nil
    //        }
    //    }
    
    // setup for settings cells in tableview
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let enableSwitch = UISwitch()
        enableSwitch.addTarget(self, action: #selector(PrayerSettingController.switched), for: UIControlEvents.touchUpInside)
        enableSwitch.isOn = switchesOn[indexPath.row]
        enableSwitch.isEnabled = switchesEnabled[indexPath.row]
        switches.append(enableSwitch)
        
        c.accessoryView = enableSwitch
        c.backgroundColor = .darkestGray
        c.textLabel?.textColor = UIColor.white
        
        
        switch indexPath.row {
        case 0:
            c.textLabel?.text = "Standard Alarm"
        case 1:
            c.textLabel?.text = "15 minute reminder"
        case 2:
            c.textLabel?.text = "Sounds"
        default:
            break
        }
        
        return c
    }
    
    @objc func switched(_ sender: UISwitch) {
        if sender != switches[2] {//test if not the sound switch
            if sender == switches[0] {
                if sender.isOn {
                    switches[1].isEnabled = true
                    switches[2].isEnabled = true
                } else {
                    //disable the 15 minutes alarm..
                    switches[1].isEnabled = false
                    switches[1].isOn = false
                    switches[2].isEnabled = false
                    switches[2].isOn = false
                }
            }
            
            let a = switches[0].isOn ? 1 : 0
            let b = switches[1].isOn ? 1 : 0
            switch (a + b) {
            case 2:
                Global.manager.prayerSettings[p]?.alarmType = .all
            case 1:
                Global.manager.prayerSettings[p]?.alarmType = AlarmSetting.noEarly
            case 0:
                Global.manager.prayerSettings[p]?.alarmType = AlarmSetting.none
                Global.manager.prayerSettings[p]?.soundEnabled = false
            default:
                break
            }
        } else {
            Global.manager.prayerSettings[p]?.soundEnabled = sender.isOn
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if initialSettings.alarmType != Global.manager.prayerSettings[p]!.alarmType || initialSettings.soundEnabled != Global.manager.prayerSettings[p]!.soundEnabled {
            Global.manager.scheduleAppropriateNotifications()
        }
    }
}
