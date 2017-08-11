//
//  RegistrationModeSelectorTVCell.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/19/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//
//

import UIKit
import iOS_AylaSDK

protocol CellSelectorDelegate {
    func cellSelectorPressed(_ cell: UITableViewCell, control:UISegmentedControl)
}

class RegistrationModeSelectorTVCell : UITableViewCell {
    
    var selectorDelegate: CellSelectorDelegate?
    
    @IBOutlet weak var modeSelector: UISegmentedControl!
    
    @IBAction func segmentedControlChanged(_ sender: AnyObject){
        selectorDelegate?.cellSelectorPressed(self, control: sender as! UISegmentedControl)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
}
