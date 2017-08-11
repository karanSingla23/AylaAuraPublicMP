//
//  RegistrationManualTVCell.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

protocol CellButtonDelegate {
    func cellButtonPressed(_ cell: UITableViewCell)
}

class RegistrationManualTVCell : UITableViewCell {
    
    var buttonDelegate: CellButtonDelegate?
    
    @IBOutlet weak var dsnField: UITextField?
    @IBOutlet weak var regTokenField: UITextField?
    @IBOutlet weak var registerButton: UIButton!
    
    func configure(_ candidate: AylaRegistrationCandidate?) {

    }
    
    
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        if let delegate = buttonDelegate {
            delegate.cellButtonPressed(self)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
}
