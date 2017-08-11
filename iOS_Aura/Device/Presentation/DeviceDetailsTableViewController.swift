//
//  DeviceDetailsTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 5/10/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceDetailsTableViewController: UITableViewController {
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var connectedAtLabel: UILabel!
    @IBOutlet weak var lanEnabledLabel: UILabel!
    @IBOutlet weak var lanIPLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var macLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var oemModelLabel: UILabel!
    @IBOutlet weak var productClassLabel: UILabel!
    @IBOutlet weak var templateIdLabel: UILabel!
    
    var device: AylaDevice!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        productNameLabel.text = device.productName
        dsnLabel.text = device.dsn
        connectionStatusLabel.text = String(format: "%@ (Via \(device.isLanModeActive() ? "LAN" : "Cloud"))", String.stringFromStringNumberOrNil(device.connectionStatus as AnyObject?))
        connectedAtLabel.text = device.connectedAt == nil ? "Unknown" : AylaSystemUtils.defaultDateFormatter().string(from: device.connectedAt!)
        lanEnabledLabel.text = device.lanEnabled == nil ? "Unknown" : device.lanEnabled!.boolValue ? "true" : "false"
        lanIPLabel.text = device.lanIp
        locationLabel.text = "\(device.lat ?? "0.0") / \(device.lng ?? "0.0")"
        macLabel.text = device.mac
        modelLabel.text = device.model
        oemModelLabel.text = device.oemModel
        productClassLabel.text = device.productClass
        templateIdLabel.text = device.templateId == nil ? "Unknown" : String(describing: device.templateId!)
    }
}
