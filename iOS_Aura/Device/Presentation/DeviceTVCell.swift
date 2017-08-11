//
//  DeviceTVC.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceTVCell : UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!
    @IBOutlet weak var connectivityLabel: UILabel!
    @IBOutlet weak var oemModelLabel: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    
    var dsn: String
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    required init?(coder aDecoder: NSCoder) {
        dsn = ""
        super.init(coder: aDecoder)
    }
    
    func configure(_ device: AylaDevice) {
        assert(device.dsn != nil, "DSN can not be found")
        dsn = device.dsn!
        nameLabel.text = device.productName
        dsnLabel.text = device.dsn
        oemModelLabel.text = device.oemModel

        let connStatus = device.connectionStatus
        
        if let bleLocalDevice = device as? AylaBLEDevice {
            let imageName = bleLocalDevice.requiresLocalConfiguration ? "stat_sys_warning" : "stat_sys_data_bluetooth"
            let imageColor = bleLocalDevice.requiresLocalConfiguration ? 0xAAAA00 :
                bleLocalDevice.isConnectedLocal ? 0x0044CC : 0x757575
            
            let image = UIImage(named:imageName)?.withRenderingMode(.alwaysTemplate)
            self.statusIcon.tintColor = UIColor(hexRGB: imageColor)
            self.statusIcon.image = image
            
        } else {
            self.statusIcon.image = UIImage(named: device.isLanModeActive() ? "ic_network_wifi" :
                connStatus == "Online" ? "ic_cloud_circle" : "ic_cloud_off")
            self.statusIcon.tintColor = connStatus == "Online" ? UIColor.auraTintColor() : UIColor.auraRedColor()
        }
    }
  
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
