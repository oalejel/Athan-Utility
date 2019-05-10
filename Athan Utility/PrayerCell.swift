//
//  PrayerCell.swift
//  Athan Utility
//
//  Created by Omar Alejel on 9/12/15.
//  Copyright (c) 2015 Omar Alejel. All rights reserved.
//

import UIKit

class PrayerCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    
    var alarmOn = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        timeLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "Helvetica-Light", size: 20)
        titleLabel.adjustsFontSizeToFitWidth = true
        timeLabel.font = UIFont(name: "Helvetica-Light", size: 20)
        timeLabel.adjustsFontSizeToFitWidth = true
        
        let image = UIImage(named: "bell")
        alarmButton.setImage(image, for: UIControl.State())
        alarmButton.imageView?.contentMode = .scaleAspectFit
        alarmButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        alarmButton.backgroundColor = UIColor.black
        alarmButton.tintColor = UIColor.darkGray
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func alarmButtonPressed(_ sender: AnyObject) {
        alarmOn = !alarmOn
        if alarmOn {
            alarmButton.tintColor = UIColor.darkGray
            let image = UIImage(named: "bell")
            alarmButton.setImage(image, for: UIControl.State())
        } else {
            alarmButton.tintColor = UIColor.lightGray
            let image = UIImage(named: "bell_off")
            alarmButton.setImage(image, for: UIControl.State())
        }
    }
}
