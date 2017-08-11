//
//  MenuViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 5/8/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import SideMenuController

class MenuViewController: SideMenuController {
    required init?(coder aDecoder: NSCoder) {
        SideMenuController.preferences.drawing.menuButtonImage = UIImage(named: "ic_menu")?.withRenderingMode(.alwaysTemplate)
        SideMenuController.preferences.drawing.sidePanelPosition = .overCenterPanelLeft
        SideMenuController.preferences.drawing.sidePanelWidth = 300
        SideMenuController.preferences.drawing.centerPanelShadow = true
        SideMenuController.preferences.animating.statusBarBehaviour = .horizontalPan
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performSegue(withIdentifier: "embedCenterController", sender: nil)
        performSegue(withIdentifier: "embedSideController", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
