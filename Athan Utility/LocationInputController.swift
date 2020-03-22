//
//  LocationInputController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/27/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import SqueezeButton

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
        
        inputTextField.text = Global.manager.locationString ?? ""
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator._hide()
        })
        
        tryButton.layer.cornerRadius = 10
    }
    
    // attempt to fetch data for the given location string
    @IBAction func tryPressed(_ sender: AnyObject) {
//        Global.manager.needsDataUpdate = true //WARNING: should you set it like this!!!???
        guard let rawLocationString = inputTextField.text else {
            // no input given
            return
        }
        
        // we want text before commas to be capitalized like normal pronouns
        // and text after commas to be all caps. Ex: Bloomfield Hills, MI, USA
        let rightHalfIndex = rawLocationString.firstIndex(of: ",") ?? rawLocationString.endIndex
        let leftHalf = rawLocationString[rawLocationString.startIndex..<rightHalfIndex].capitalized
        let rightHalf = rawLocationString[rightHalfIndex..<rawLocationString.endIndex].uppercased()
        
        let cleanedLocationString = String(leftHalf + rightHalf)
        Global.manager.fetchJSONData(forLocation: cleanedLocationString, dateTuple: nil, completion: { (successfulFetch) in
            
            if successfulFetch  {
                DispatchQueue.main.async {
                    print("try succeeded")

                    self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
                        // do nothing for now
                    })
                    // if we successfully used an input location, then we know that we are no longer GPS for the shown data
                    Global.manager.currentCityString = nil
                    Global.manager.currentStateString = nil
                    Global.manager.currentCountryString = nil
                    Global.manager.delegate.locationIsUpToDate = false
                    // hide the loading spinner that covers the screen
                    self.activityIndicator._hide()
                }
            } else {
                print("try failed")
                DispatchQueue.main.async {
                    // hide the loading spinner that covers the screen
                    self.activityIndicator._hide()
                    // show the user text that indicates input failure
                    self.failedLabel._show()
                }
            }
            
        })
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator._show()
        })
        activityIndicator.startAnimating()
    }
    
    @IBAction func lockPressed(_ sender: AnyObject) {
        Global.manager.lockLocation = true
    }
    
    @objc func cancelPressed() {
        // might need to reset some variables in manager like getData
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            // do nothing special for now
            
        })
    }
    
}
