//
//  AuraTextField.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

class AuraLabel : UILabel {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class AuraSplashLabel : AuraLabel {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.font = UIFont(name: "Chalkduster", size: 68.0)
        self.textColor = UIColor.aylaFieryOrangeColor();
    }
    
}
