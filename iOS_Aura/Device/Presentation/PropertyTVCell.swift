//
//  PropertyTVCell.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class PropertyTVCell: UITableViewCell {
    private let logTag = "PropertyTVCell"
    @IBOutlet weak var valueView: UIView!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var propertySwitch: UISwitch!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    var nameTapRecognizer: UITapGestureRecognizer!
    var valueTapRecognizer: UITapGestureRecognizer!
    weak var parentPropertyListViewModel: PropertyListViewModel!
    
    var property: AylaProperty?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //Set up tap recognizers for each side of the cell
        nameTapRecognizer = UITapGestureRecognizer(target:self, action:#selector(PropertyTVCell.nameTapped(_:)))
        nameTapRecognizer.numberOfTapsRequired = 1
        nameView.isUserInteractionEnabled = true
        nameView.addGestureRecognizer(nameTapRecognizer)
        
        valueTapRecognizer = UITapGestureRecognizer(target:self, action: #selector(PropertyTVCell.valueTapped(_:)))
        valueTapRecognizer.numberOfTapsRequired = 1
        valueView.isUserInteractionEnabled = true
        valueView.addGestureRecognizer(valueTapRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func nameTapped (_ sender: UITapGestureRecognizer){
        self.parentPropertyListViewModel.showDetailsForProperty(sender, property:self.property!)
    }
    func valueTapped (_ sender: UITapGestureRecognizer){
        self.parentPropertyListViewModel.showValueAlertForProperty(sender, property:self.property!)
    }
    
    func configure(_ property: AylaProperty) {
        self.property = property
        if let baseType = self.property?.baseType{
            //  Make switch visible only if property is a boolean
            //  Disable switch if property is from_device
            if baseType == "boolean"{
                if let direction = self.property?.direction {
                    propertySwitch?.isEnabled = direction == "input" ? true : false
                    if let value = self.property?.value {
                        propertySwitch?.isOn = value as! Bool
                    }
                    else {
                        propertySwitch?.isOn = false
                    }
                }
                propertySwitch?.isHidden = false
            }
            else {
                propertySwitch?.isHidden = true
            }
        }
        nameLabel.text = self.property?.name
        infoLabel?.text = String.localizedStringWithFormat("%@ - %@", (self.property?.direction)!, (self.property?.baseType)!)
        
        let value = String.stringFromStringNumberOrNil(self.property?.value as AnyObject?)
        valueLabel.text = value
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        sender.isEnabled = false
        valueTapRecognizer.isEnabled = false
        AylaLogD(tag: logTag, flag: 0, message:sender.isOn ? "Switch turned on" : "Switch turned Off")
        
        // Code to reenable cell after datapoint call completes.
        func reenableCell() {
            sender.isEnabled = true
            valueTapRecognizer.isEnabled = true
        }
        
        // Check for previous value of property. If there is no previous value, create datapoint with value (1).
        var boolValue = NSNumber(value: 0 as Int32)
        if let curVal = self.property?.value {
            boolValue = curVal as! NSNumber
        }
            
        // Set up datapoint for new value
        let newVal = boolValue == 1 ? NSNumber(value: 0 as Int32) : NSNumber(value: 1 as Int32)
        let dpParams = AylaDatapointParams()
        dpParams.value = newVal
        
        // Create Datapoint
        self.property!.createDatapoint(dpParams, success: { (datapoint) -> Void in
            AylaLogI(tag: self.logTag, flag: 0, message:"Created datapoint.")
            reenableCell()
            }, failure: { (error) -> Void in
                reenableCell()
                AylaLogE(tag: self.logTag, flag: 0, message:"Create Datapoint Failed. \(error)")
                error.displayAsAlertController()
        })
    }
}
