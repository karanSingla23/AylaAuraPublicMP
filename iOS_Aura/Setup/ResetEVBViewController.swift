//
//  ResetEVBViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 5/3/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit

class ResetEVBViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func repeatSetupAction(_ sender: Any) {
        guard let viewControllers = navigationController?.viewControllers else {
            return
        }
        var firstPlugItInController: UIViewController?
        for controller in viewControllers {
            if controller is PlugItInViewController {
                firstPlugItInController = controller
                break
            }
        }
        guard let plugItInController = firstPlugItInController else {
            return
        }
        navigationController?.popToViewController(plugItInController, animated: true)
    }
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
