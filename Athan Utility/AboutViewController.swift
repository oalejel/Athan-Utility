//
//  AboutViewController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/30/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit
import MessageUI

// AboutViewController is responsible for showing contact info and gratitude to Icons8 and SwiftSpinner
class AboutViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the bar button item in the top right to dismiss
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(AboutViewController.donePressed))
        navigationController?.navigationBar.topItem!.title = NSLocalizedString("About", comment: "")
        
//        if !Global.darkTheme {
        navigationItem.rightBarButtonItem!.tintColor = UIColor.lightGray
//        }
    }
    
    @objc func donePressed() {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            // do nothing for now
            
        })
    }
    
    // when the contact button is pressed, compose an email to me
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
    
    // Delegate function for when mail composition is done
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // When button for swiftSpinner is pressed, show martin's github
    @IBAction func martinPressed(_ sender: AnyObject) {
        let URLString = "https://github.com/icanzilb/SwiftSpinner"
        UIApplication.shared.open(URL(string: URLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    // when icons8 link is pressed, show website
    //NOTE: change this to display the website without leaving the application (using SafariViewController)
    @IBAction func iconsPressed(_ sender: AnyObject) {
        UIApplication.shared.open(URL(string: "https://icons8.com")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
