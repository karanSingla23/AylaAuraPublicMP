//
//  PlugItInViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/21/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit

class PlugItInViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
