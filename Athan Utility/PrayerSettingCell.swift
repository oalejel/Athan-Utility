//
//  PrayerSettingCell.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/21/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

class PrayerSettingCell: UITableViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
