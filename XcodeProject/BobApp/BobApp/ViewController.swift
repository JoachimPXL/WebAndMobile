//
//  ViewController.swift
//  BobApp
//
//  Created by Joachim Zeelmaekers on 05/10/2017.
//  Copyright © 2017 Joachim Zeelmaekers. All rights reserved.
//

import UIKit
import Pulsator

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let pulsator = Pulsator()
        view.layer.addSublayer(pulsator)
        pulsator.start()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

