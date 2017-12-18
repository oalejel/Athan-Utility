//
//  OptionsNavigatonController.swift
//  Athan Utility
//
//  Created by Omar Alejel on 11/25/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

class OptionsNavigatonController: UINavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        var fx: UIBlurEffect!
        
        if Global.darkTheme {
            fx = UIBlurEffect(style: UIBlurEffectStyle.dark)
        } else {
            fx = UIBlurEffect(style: UIBlurEffectStyle.light)
        }
        
        
        let fxView = UIVisualEffectView(effect: fx)
        fxView.frame = UIScreen.main.bounds
        view.insertSubview(fxView, at: 0)
        view.backgroundColor = UIColor.clear
        //show what is behind!
        modalPresentationStyle = UIModalPresentationStyle.overCurrentContext

        
        //nav
        if Global.darkTheme {
            navigationBar.barTintColor = UIColor(white: 0.1, alpha: 1.0)
            navigationBar.tintColor = UIColor.white
            navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        } else {
            navigationBar.barTintColor = UIColor(white: 1, alpha: 1.0)
        }
        
        
        
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
