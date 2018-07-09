//
//  ViewController.swift
//  SqueezeButtonPreview
//
//  Created by Omar Alejel on 12/25/15.
//  Copyright © 2015 Omar Alejel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var gradientButton: SqueezeButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let c1 = UIColor(red: 155/255, green: 184/255, blue: 1, alpha: 1)
        let c2 = UIColor(red: 168/255, green: 245/255, blue: 242/255, alpha: 1)
        gradientButton.addGradient(startColor: c1, endColor: c2, angle: CGFloat.pi * 0.5)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

