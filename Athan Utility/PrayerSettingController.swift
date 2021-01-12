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
//    var initialSettings: DeprecatedPrayerSetting!
    
    init(style: UITableView.Style, prayer: PrayerType) {
        super.init(style: style)
        p = prayer
        //create a settings object to be compared later
//        let initialSettingsPointer = Global.manager.prayerSettings[p]
//        initialSettings = DeprecatedPrayerSetting()
//        initialSettings.alarmType = initialSettingsPointer!.alarmType
//        initialSettings.soundEnabled = initialSettingsPointer!.soundEnabled
        
//        let alarmType = Global.manager.prayerSettings[p]?.alarmType
//        let soundEnabled = Global.manager.prayerSettings[p]?.soundEnabled
//        switchesOn[2] = soundEnabled!//preliminary, can be broken if others are off
//        if alarmType == .all {
//            //do nothing
//        } else if alarmType == .noEarly {
//            //1 off, no disabling
//            switchesOn[1] = false
//        } else {
//            //all off, 2 disabled
//            switchesEnabled[1...2] = [false,false]
//            switchesOn[0...2] = [false,false,false]
//        }
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
        navigationItem.title = p.localizedString()
        
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
    //            return "Normal Reminder"
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
        enableSwitch.addTarget(self, action: #selector(PrayerSettingController.switched), for: UIControl.Event.touchUpInside)
        enableSwitch.isOn = switchesOn[indexPath.row]
        enableSwitch.isEnabled = switchesEnabled[indexPath.row]
        switches.append(enableSwitch)
        
        c.accessoryView = enableSwitch
        c.backgroundColor = .darkestGray
        c.textLabel?.textColor = UIColor.white
        
        
        switch indexPath.row {
        case 0:
            c.textLabel?.text = NSLocalizedString("Normal Reminder", comment: "")
        case 1:
            c.textLabel?.text = NSLocalizedString("15 minute reminder", comment: "")
        case 2:
            c.textLabel?.text = NSLocalizedString("Sounds", comment: "")
        default:
            break
        }
        
        return c
    }
    
    @objc func switched(_ sender: UISwitch) {
    }
    
    #warning("move settings saving to settings.swift")
    override func viewWillDisappear(_ animated: Bool) {
//        Global.manager.saveSettings()
//        if initialSettings.alarmType != Global.manager.prayerSettings[p]!.alarmType || initialSettings.soundEnabled != Global.manager.prayerSettings[p]!.soundEnabled {
////            Global.manager.scheduleAppropriateNotifications()
//            Settings.notificationUpdatesPending = true
//        }
    }
}
