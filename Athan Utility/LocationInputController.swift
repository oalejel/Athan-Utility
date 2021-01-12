//
//  LocationInputController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/27/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

//LocationInputController allows the user to input a location they do not live in
class LocationInputController: UIViewController {
    
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var tryButton: SqueezeButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var failedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(LocationInputController.cancelPressed))
        navigationItem.rightBarButtonItem!.tintColor = UIColor.lightGray
        navigationController?.navigationBar.topItem!.title = NSLocalizedString("Location Search", comment: "")
//        navigationController?.navigationBar.topItem!.accessibilityLabel = "Location Search"
        
        // localize the try button
        let localizedTry = NSLocalizedString("Try Location", comment: "")
        tryButton.setTitle(localizedTry, for: .normal)
//        tryButton.accessibilityLabel = "Try Location"
        
        // localize the text field
        inputTextField.placeholder = NSLocalizedString("Locality, State, Country", comment: "")
//        inputTextField.accessibilityLabel = "Locality, State, Country"
        
        self.failedLabel.alpha = 0
        
        // localized failure label
        failedLabel.text = NSLocalizedString("Try again", comment: "")
//        failedLabel.accessibilityLabel = "Try again"
        
        activityIndicator.stopAnimating()
        
        inputTextField.text = AthanManager.shared.locationSettings.locationName
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator._hide()
        })
        
        tryButton.layer.cornerRadius = 10
    }
    
    // attempt to fetch data for the given location string
    @IBAction func tryPressed(_ sender: AnyObject) {
    }
        
    @objc func cancelPressed() {
        // might need to reset some variables in manager like getData
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            // do nothing special for now
            
        })
    }
    
}
