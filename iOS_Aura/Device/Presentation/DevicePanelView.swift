//
//  DevicePanelView.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DevicePanelView: UIView {
    private let logTag = "DevicePanelView"
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var connectivityLabel: UILabel!

    @IBOutlet weak var extraInfoStackView: UIStackView!
    @IBOutlet weak var extraInfoButton: UIButton!
    
    @IBOutlet weak var oemModelLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    
    @IBOutlet weak var macAddressStackView: UIStackView!
    @IBOutlet weak var macAddressLabel: UILabel!
    
    @IBOutlet weak var lanIPStackView: UIStackView!
    @IBOutlet weak var lanIPAddressLabel: UILabel!
    
    @IBOutlet weak var btAddressStackView: UIStackView!
    @IBOutlet weak var btAddressLabel: UILabel!
    
    @IBOutlet weak var controlsStackView: UIStackView!
    
    @IBOutlet weak var timeZoneLabel: UILabel!
    
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var shareNamesLabel: UILabel!
    @IBOutlet weak var sharingNamesView: UIView!


    
    func configure(_ device:AylaDevice, sharesModel: DeviceSharesModel?) {
        nameLabel.text = device.productName
        dsnLabel.text = device.dsn
        
        let connStatus:String = String.stringFromStringNumberOrNil(device.connectionStatus as AnyObject?)
        
        var connectivityLabelString:String

        var activeLabelBool:Bool
        
        // Handle Local Devices here
        if let bleDevice = device as? AylaBLEDevice {
            self.controlsStackView.isHidden = true

            self.macAddressStackView.isHidden = true
            self.lanIPStackView.isHidden = true
            self.btAddressStackView.isHidden = false
            
            let btID = String.stringFromStringNumberOrNil(bleDevice.bluetoothIdentifier?.uuidString as AnyObject?)
            btAddressLabel.text = String.stringFromStringNumberOrNil(btID as AnyObject?)
            
            activeLabelBool = bleDevice.isConnectedLocal
            
            connectivityLabelString = "Bluetooth \(activeLabelBool ? "Connected" : "Disconnected")"
            
        } else {
            // Handle non-local devices
            self.controlsStackView.isHidden = false
            self.macAddressStackView.isHidden = false
            self.lanIPStackView.isHidden = false
            self.btAddressStackView.isHidden = true

            lanIPAddressLabel.text = String.stringFromStringNumberOrNil(device.lanIp as AnyObject?)
            macAddressLabel.text = String.stringFromStringNumberOrNil(device.mac as AnyObject?)
            connectivityLabelString = String(format: "%@ (Via \(device.isLanModeActive() ? "LAN" : "Cloud"))", String.stringFromStringNumberOrNil(connStatus as AnyObject?))
        }
        
        self.oemModelLabel.text = String.stringFromStringNumberOrNil(device.oemModel as AnyObject?)
        self.modelLabel.text = String.stringFromStringNumberOrNil(device.model as AnyObject?)
        device.fetchTimeZone(success: { (timeZone) in
            self.timeZoneLabel.text = String.stringFromStringNumberOrNil(timeZone.tzID as AnyObject?)
        }) { (error) in
            self.timeZoneLabel.text = "Unknown"
        }

        connectivityLabel.text = connectivityLabelString
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.extraInfoButton.setImage(UIImage(named:"disclosure-down-icon")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.extraInfoButton.setImage(UIImage(named:"disclosure-up-icon")?.withRenderingMode(.alwaysTemplate), for: .selected)
        self.extraInfoButton.imageView?.tintColor = UIColor.lightGray
        
        
    }
    
    @IBAction func expandInfoView(sender:UIButton){
        sender.isSelected = !sender.isSelected
        UIView.animate(withDuration: 0.3, animations: {
            self.extraInfoStackView.isHidden = !self.extraInfoStackView.isHidden
        })
    }
}
