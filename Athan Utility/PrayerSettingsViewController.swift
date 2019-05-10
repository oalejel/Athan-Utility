//
//  PrayerSettingsViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/21/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import IntentsUI
import AVFoundation

// PrayerSettingsViewController displays the settings for an individual prayer time
class PrayerSettingsViewController: UITableViewController, INUIAddVoiceShortcutViewControllerDelegate {

    var currentRow = 0
    var manager: PrayerManager!
    var soundImage: UIImage!
    var noSoundImage: UIImage!
    
    // display names for notification sounds
    let noteSoundNames = ["iOS Default", "Echo", "Makkah", "Madina", "Al-Aqsa", "Egypt", "Abdulbaset", "Abdulghaffar"]
    // file names are in settings.swift
    
    var notificationSoundIndex = 0 // set this to user setting
    var soundPreviewPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "PrayerSettingCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "ToneSettingCell", bundle: nil), forCellReuseIdentifier: "tone_cell")
        tableView.register(UINib(nibName: "SiriCell", bundle: nil), forCellReuseIdentifier: "siri_cell")
//        tableView.contentInset = UIEdgeInsets(top: tableView.rowHeight, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .black
        tableView.backgroundView = nil
        tableView.allowsSelection = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PrayerSettingsViewController.donePressed))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "done"
        navigationController?.navigationBar.topItem!.title = NSLocalizedString("Settings", comment: "")//NSLocalizedString("Alarms", comment: "")
        navigationController?.navigationBar.topItem!.accessibilityLabel = "Settings"//"Alarms"
        
        navigationItem.rightBarButtonItem!.tintColor = UIColor.lightGray
        
        soundImage = UIImage(named: "sound")
        noSoundImage = UIImage(named: "no_sound")
    }
    
    // sections: Siri Extension, Athan Alarms, Notification Sound
    override func numberOfSections(in tableView: UITableView) -> Int {
        // don't include siri extention if user is behind ios 12
        if #available(iOS 12.0, *) { return 3 }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // notification sound
            return noteSoundNames.count
        case 1:
            // athan alarms
            return 6
        default:
            // siri
            return 1
        }
    }
    
    let headerLabels = ["Notification Sound", "Athan Alarms", "Siri Extension"]
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerLabels[section]
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.tintColor = .darkerGray
            headerView.textLabel?.textColor = .gray
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tone_cell") as! ToneSettingCell
            cell.textLabel?.text = noteSoundNames[indexPath.row]
            cell.selectionStyle = .gray
            // EDIT this so that we check the thing the user has in their settings
            cell.accessoryType = indexPath.row == 0 ? .checkmark : .none
            
            return cell
        } else if indexPath.section == 2 {
            if #available(iOS 12.0, *) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "siri_cell") as! SiriCell
                cell.selectionStyle = .none
                cell.button.addTarget(self, action: #selector(addToSiri), for: .touchUpInside)
                return cell
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PrayerSettingCell
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.backgroundView?.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
        cell.leftLabel?.textColor = UIColor.white
        cell.rightLabel.textColor = UIColor.white
        cell.rightLabel.alpha = 0.5
        cell.selectionStyle = .gray
        
        let setting = manager.prayerSettings[PrayerType(rawValue: indexPath.row)!]!
        
        var cellText = ""
        switch setting.alarmType {
        case .all:
            cellText = NSLocalizedString("Normal & 15m", comment: "")
        case .noEarly:
            cellText = NSLocalizedString("Normal Reminder", comment: "")
        case .none:
            cellText = NSLocalizedString("No Reminders", comment: "") 
        }
        cell.rightLabel?.text = cellText
        
        if setting.soundEnabled {
            cell.iconView.image = soundImage.imageFlippedForRightToLeftLayoutDirection()
        } else {
            cell.iconView.image = noSoundImage.imageFlippedForRightToLeftLayoutDirection()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // set new notification sound
            let c = tableView.cellForRow(at: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            
            // stop audio player if user tapped the same thing
            if indexPath.row == notificationSoundIndex && soundPreviewPlayer?.isPlaying ?? false {
                soundPreviewPlayer?.stop()
                soundPreviewPlayer = nil
            } else {
                handleSoundSelection(for: indexPath.row)
                Settings.notificationUpdatesPending = true
            }
            
            if indexPath.row == notificationSoundIndex {return}
            c?.accessoryType = .checkmark
            
            let originalIndexPath = IndexPath(row: notificationSoundIndex, section: 0)
            tableView.cellForRow(at: originalIndexPath)?.accessoryType = .none
            notificationSoundIndex = indexPath.row
        } else if indexPath.section == 1 {
            // show setting view controller for this specific prayer
            let c = tableView.cellForRow(at: indexPath) as! PrayerSettingCell
            currentRow = indexPath.row
            c.contentView.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
            let s = PrayerSettingController(style: .plain, prayer: PrayerType(rawValue: indexPath.row)!)
            //s.manager = manager
            tableView.deselectRow(at: indexPath, animated: true)
            navigationController?.pushViewController(s, animated: true)
        }
    }
    
    @objc func donePressed() {
        navigationController!.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            // save sound setting
            Settings.setSelectedSound(for: self.notificationSoundIndex)
            // if updates are pending, then recreate our notifications
            if Settings.notificationUpdatesPending {
                Settings.notificationUpdatesPending = false
                Global.manager.scheduleAppropriateNotifications()
            }
            self.navigationController!.removeFromParent()
            self.removeFromParent()
        })
    }
    
    // stop playing sound and play a new sound
    var soundPreviewTimer: Timer?
    func handleSoundSelection(for index: Int) {
        // stop potentially running previews
        soundPreviewPlayer?.stop()
        do {
            let fileName = Settings.noteSoundFileNames[index]
            if fileName == "DEFAULT" {
                AudioServicesPlaySystemSound(1315);
            } else {
                if let asset = NSDataAsset(name: fileName) {
                    try soundPreviewPlayer = AVAudioPlayer(data: asset.data, fileTypeHint: "mp3")
                    soundPreviewPlayer?.play()
                    soundPreviewTimer?.invalidate()
                    soundPreviewTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (timer) in
                        self.soundPreviewPlayer?.setVolume(0, fadeDuration: 1)
                    }
                }
            }
        } catch {
            fatalError("unable to play audio file")
        }
    }
    
    // MARK: Siri
    @objc
    @available(iOS 12.0, *)
    func addToSiri() {
        let intent = NextPrayerIntent()
        intent.suggestedInvocationPhrase = "Next prayer"
        if let shortcut = INShortcut(intent: intent) {
            let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self // Object conforming to `INUIAddVoiceShortcutViewControllerDelegate`.
            present(viewController, animated: true, completion: nil)
        }
    }
    
    // requires shortcut stubs
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        UserDefaults.standard.set(true, forKey: "hideSiriShortcuts")
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
        UserDefaults.standard.set(true, forKey: "hideSiriShortcuts")
    }
}


