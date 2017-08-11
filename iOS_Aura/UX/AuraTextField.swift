//
//  AuraTextField.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

class AuraTextField : UITextField {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.tintColor = UIColor.auraTintColor()
    }
    
}
