//
//  AboutViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/30/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(AboutViewController.donePressed))
        navigationController?.navigationBar.topItem!.title = "About"
        
        if !Global.darkTheme {
            navigationItem.rightBarButtonItem!.tintColor = UIColor.darkGray
        }
    }
    
    @objc func donePressed() {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            //something..
            
        })
    }
    
    @IBAction func contactPressed(_ sender: AnyObject) {
        if MFMailComposeViewController.canSendMail() {
            let mailController = MFMailComposeViewController()
            mailController.mailComposeDelegate = self
            mailController.setSubject("Feedback for Athan Utility")
            mailController.title = "Email Developer"
            mailController.setToRecipients(["omalsecondary@gmail.com"])
            
            present(mailController, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func martinPressed(_ sender: AnyObject) {
        let URL = "https://github.com/icanzilb/SwiftSpinner"
        UIApplication.shared.openURL(Foundation.URL(string: URL)!)
    }
    
    @IBAction func iconsPressed(_ sender: AnyObject) {
        UIApplication.shared.openURL(URL(string: "https://icons8.com")!)
    }
}
