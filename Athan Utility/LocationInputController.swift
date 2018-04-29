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
        navigationController?.navigationBar.topItem!.title = "Location Search"
        
        activityIndicator.stopAnimating()
        
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator._hide()
        })
        
        tryButton.layer.cornerRadius = 10
        
        //for when a fetch is completed (regardless of success or not)
        Global.manager.fetchCompletionClosure = {
            if Global.manager.lastFetchSuccessful {
                self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
                    // do nothing for now
                })
                
                print("try succeeded")
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator._hide()
                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator._hide()
                    self.failedLabel._show()
                })
                
                print("try failed")
            }
        }
    }
    
    // attempt to fetch data for the given location string
    @IBAction func tryPressed(_ sender: AnyObject) {
        Global.manager.getData = true//should you set it like this!!!???
        let searchString = inputTextField.text!.replacingOccurrences(of: " ", with: "+")
        Global.manager.fetchJSONData(searchString: searchString, dateTuple: nil)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator._show()
        })
        activityIndicator.startAnimating()
    }
    
    @objc func cancelPressed() {
        // might need to reset some variables in manager like getData
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            // do nothing special for now
            
        })
    }
    
}
