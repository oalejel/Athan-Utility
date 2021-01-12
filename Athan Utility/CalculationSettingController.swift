//
//  PrayerSettingController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/22/15.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import UIKit

class CalculationSettingController: UITableViewController {
    var selectedMethod = Settings.getCalculationMethodIndex()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        tableView.separatorColor = UIColor.black
        navigationItem.title = "Calculation Method"
        tableView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.calculationMethodNames.count
    }
    
    // setup for settings cells in tableview
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = UITableViewCell()
        
        c.accessoryType = (indexPath.row == selectedMethod) ? .checkmark : .none
        c.accessoryView?.tintColor = .white
        c.backgroundColor = .darkestGray
        c.textLabel?.textColor = UIColor.white
        c.textLabel?.text = Settings.calculationMethodNames[indexPath.row]
            
        return c
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == selectedMethod {
            return
        }
    
        
        if let currentMethodCell = tableView.cellForRow(at: IndexPath(row: selectedMethod, section: 0)) {
            currentMethodCell.accessoryType = .none
            if let newMethodCell = tableView.cellForRow(at: indexPath) {
                newMethodCell.accessoryType = .checkmark
            }
        }
        selectedMethod = indexPath.row
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        Global.manager.saveSettings()
//        if selectedMethod != Settings.getCalculationMethodIndex() {
//            Settings.setCalculationMethodIndex(for: selectedMethod)
//            // tell prayer manager to update
//            Global.manager.userRequestsReload()
//        }
    }
}
