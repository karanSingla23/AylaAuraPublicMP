//
//  AddDeviceTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/21/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit

class AddDeviceTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
