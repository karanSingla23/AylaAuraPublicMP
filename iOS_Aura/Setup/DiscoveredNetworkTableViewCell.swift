//
//  DiscoveredNetworkTableViewCell.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/19/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DiscoveredNetworkTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var securityIcon: UIImageView!
    @IBOutlet weak var signalStrength: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func imageForSignal(bars: Int32) -> UIImage? {
        var image: UIImage?
        switch bars {
        case 3: image = UIImage(named: "icon-wifi-fair")
        case 4: image = UIImage(named: "icon-wifi-good")
        case 5: image = UIImage(named: "icon-wifi-strong")
        default: image = UIImage(named: "icon-wifi-weak")
        }
        return image
    }

    func configure(withWiFiResult result:AylaWifiScanResult) {
        self.securityIcon.isHidden = result.security == "None"
        let signalImage = imageForSignal(bars: result.bars)
        if signalImage != nil {
            self.signalStrength.image = signalImage
        }
        self.titleLabel.text = result.ssid
    }
}
