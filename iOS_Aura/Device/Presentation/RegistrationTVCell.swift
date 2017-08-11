//
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class RegistrationTVCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dsnLabel: UILabel!

    func configure(_ candidate: AylaRegistrationCandidate?) {
        nameLabel.text = candidate?.productName ?? ""
        let oem = " (" + (candidate?.oemModel ?? "") + ")"
        dsnLabel.text = (candidate?.dsn ?? "") + oem
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
