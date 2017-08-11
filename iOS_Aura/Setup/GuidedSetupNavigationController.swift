//
//  GuidedSetupNavigationViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/20/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit

class GuidedSetupNavigationController: UINavigationController {
    let modalProgress = ModalProgressViewController(nibName: "ModalProgressViewController", bundle: Bundle.main)

    func displayProgressView(animated: Bool = true, completion: @escaping ()->() = {}) {
        if modalProgress.presentingViewController == nil {
            self.present(modalProgress, animated: animated, completion: completion)
            modalProgress.activityIndicator?.startAnimating()
        }
    }
    func hideProgressView(animated: Bool = true, completion: @escaping ()->() = {}) {
        self.modalProgress.dismiss(animated: animated, completion: completion)
    }
}
