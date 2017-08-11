//
//  PropertyNotificationDetailsContactTableViewCell.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK
import UIKit

class PropertyNotificationDetailsContactTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var emailButton: UIButton!
    @IBOutlet fileprivate weak var pushButton: UIButton!
    @IBOutlet fileprivate weak var smsButton: UIButton!
    
    weak var delegate:PropertyNotificationDetailsContactTableViewCellDelegate?
    
    var contact: AylaContact? = nil {
        didSet {
            self.configureForContact(contact)
        }
    }
    
    static let nib = UINib(nibName: "PropertyNotificationDetailsContactTableViewCell", bundle: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Actions

    @IBAction fileprivate func email(_ button: UIButton) {
        button.isSelected = !button.isSelected;
        delegate?.didToggleEmail(self)
    }

    @IBAction fileprivate func push(_ button: UIButton) {
        button.isSelected = !button.isSelected;
        delegate?.didTogglePush(self)
    }

    @IBAction fileprivate func sms(_ button: UIButton) {
        button.isSelected = !button.isSelected;
        delegate?.didToggleSMS(self)
    }

    // MARK: - Utilities
    
    func configureForContact(_ contact: AylaContact?) {
        nameLabel.text = contact?.displayName
        
        var enabledApps:[AylaServiceAppType] = []
        
        if contact != nil {
            enabledApps = delegate?.enabledAppsForContact(contact!) ?? []
        }
        
        emailButton.isHidden = (contact?.email ?? "").isEmpty
        smsButton.isHidden = (contact?.phoneNumber ?? "").isEmpty
        
        // TODO: Unhide for owner
        pushButton.isHidden = true
        
        emailButton.isSelected = enabledApps.contains(AylaServiceAppType.email)
        pushButton.isSelected = enabledApps.contains(AylaServiceAppType.push)
        smsButton.isSelected = enabledApps.contains(AylaServiceAppType.SMS)
    }
}

// MARK: -

protocol PropertyNotificationDetailsContactTableViewCellDelegate: class {
    
    // Client should return an array of the enabled apps for the specified contact.
    // The array can contain zero or more of the following constants: AylaServiceAppTypeEmail, AylaServiceAppTypePush, AylaServiceAppTypeSMS
    func enabledAppsForContact(_ contact: AylaContact) -> [AylaServiceAppType]
    
    // Client should enable or disable the email app for the associated contact
    func didToggleEmail(_ cell: PropertyNotificationDetailsContactTableViewCell)

    // Client should enable or disable the push notification app for the associated contact
    func didTogglePush(_ cell: PropertyNotificationDetailsContactTableViewCell)
    
    // Client should enable or disable the SMS app for the associated contact
    func didToggleSMS(_ cell: PropertyNotificationDetailsContactTableViewCell)
}
