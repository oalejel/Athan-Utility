//
//  SiriCell.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 5/9/19.
//  Copyright © 2019 Omar Alejel. All rights reserved.
//

import UIKit
import IntentsUI

@available(iOS 12.0, *)
class SiriCell: UITableViewCell, INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        
    }
    
    @IBOutlet weak var descriptionLabel: UILabel!
    var button: INUIAddVoiceShortcutButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        button = INUIAddVoiceShortcutButton(style: .blackOutline)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
}
