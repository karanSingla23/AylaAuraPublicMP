//
//  GreenButton.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/20/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit

class GreenButton: AuraButton {
    override var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height = intrinsicContentSize.height + 15.0
        return intrinsicContentSize
        
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}
