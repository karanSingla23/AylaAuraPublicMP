//
//  AuraButton.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit

public enum AuraButtonType : Int {
    case system // standard system button
    case standard // standard button
}

class AuraButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.backgroundColor = UIColor.aylaHippieGreenColor().cgColor
        self.layer.cornerRadius = 5.0
        
        self.setTitleColor(UIColor.aylaPearlBushColor(), for: UIControlState())
        self.setTitleColor(UIColor.aylaSisalColor(), for: .disabled)
    }
    
    override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1.0 : 0.6
        }
    }
}

class AuraProgressButton: AuraButton {
    var activityIndicator:UIActivityIndicatorView?
    var activityIndicatorColor:UIColor = UIColor.aylaSisalColor()
    
    override func setTitle(_ title: String?, for state: UIControlState) {
        if title != self.title(for: state) {
            self.stopActivityIndicator()
        }
        super.setTitle(title, for: state)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func startActivityIndicator(){
        let indicatorHeight = self.frame.height - 8
        if self.activityIndicator == nil {
            let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
            self.activityIndicator = activityIndicator;
        }
        self.activityIndicator?.isUserInteractionEnabled = false;
        self.activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator?.color = self.activityIndicatorColor
        self.superview?.addSubview(self.activityIndicator!)
        self.activityIndicator?.startAnimating()
        
        NSLayoutConstraint(
            item: self.activityIndicator!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: indicatorHeight
            ).isActive = true
        NSLayoutConstraint(
            item: self.activityIndicator!,
            attribute: .width,
            relatedBy: .equal,
            toItem: self.activityIndicator!,
            attribute: .height,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        NSLayoutConstraint(
            item: self.activityIndicator!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        NSLayoutConstraint(
            item: self.activityIndicator!,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        self.isEnabled = false
    }
    
    func stopActivityIndicator() {
        if let indicator = self.activityIndicator {
            indicator.removeFromSuperview()
        }
        self.isEnabled = true;
    }
    
}

class AuraTextButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitleColor(UIColor.aylaBahamaBlueColor(), for: UIControlState())
        titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
    }
}
