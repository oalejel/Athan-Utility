//
//  PrayerSettingsViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/21/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

// PrayerSettingsViewController displays the settings for an individual prayer time
class PrayerSettingsViewController: UITableViewController {
    
    var currentRow = 0
    var manager: PrayerManager!
    var soundImage: UIImage!
    var noSoundImage: UIImage!
    
    var changesMade = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView?.backgroundColor = UIColor.clear
        tableView.register(UINib(nibName: "PrayerSettingCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.contentInset = UIEdgeInsets(top: tableView.rowHeight, left: 0, bottom: 0, right: 0)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PrayerSettingsViewController.donePressed))
        navigationController?.navigationBar.topItem!.title = "Alarms"
        
        navigationItem.rightBarButtonItem!.tintColor = UIColor.lightGray
        
        soundImage = UIImage(named: "sound")
        noSoundImage = UIImage(named: "no_sound")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.size.height / 10//is this good???
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PrayerSettingCell
        cell.backgroundView?.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
        cell.leftLabel?.textColor = UIColor.white
        cell.rightLabel.textColor = UIColor.white
        cell.rightLabel.alpha = 0.5
        cell.selectionStyle = .none
        
        let setting = manager.prayerSettings[PrayerType(rawValue: indexPath.row)!]!
        
        var cellText = ""
        switch setting.alarmType {
        case .all:
            cellText = "Normal & 15m"
        case .noEarly:
            cellText = "Normal Reminder"
        case .none:
            cellText = "No Reminders"
        }
        cell.rightLabel?.text = cellText
        
        if setting.soundEnabled {
            cell.iconView.image = soundImage
        } else {
            cell.iconView.image = noSoundImage
        }
        
        cell.iconView.contentMode = .center
        
        switch indexPath.row {
        case 0:
            cell.leftLabel?.text = PrayerType.fajr.localizedString()
        case 1:
            cell.leftLabel?.text = PrayerType.shurooq.localizedString()
        case 2:
            cell.leftLabel?.text = PrayerType.thuhr.localizedString()
        case 3:
            cell.leftLabel?.text = PrayerType.asr.localizedString()
        case 4:
            cell.leftLabel?.text = PrayerType.maghrib.localizedString()
        case 5:
            cell.leftLabel?.text = PrayerType.isha.localizedString()
        default:
            break
        }
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let c = tableView.cellForRow(at: IndexPath(row: currentRow, section: 0))
        c?.contentView.backgroundColor = UIColor.clear
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = tableView.cellForRow(at: indexPath) as! PrayerSettingCell
        currentRow = indexPath.row
        c.contentView.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
        let s = PrayerSettingController(style: .plain, prayer: PrayerType(rawValue: indexPath.row)!)
        //s.manager = manager
        navigationController?.pushViewController(s, animated: true)
    }
    
    @objc func donePressed() {
        navigationController!.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            //!! will it still exist in memory?? when this happens
            if self.changesMade {
                //reset notifications with manager if we had changes
                
            }
            
            //maybe save??
            self.navigationController!.removeFromParentViewController()
            self.removeFromParentViewController()
        })
    }
    
}
