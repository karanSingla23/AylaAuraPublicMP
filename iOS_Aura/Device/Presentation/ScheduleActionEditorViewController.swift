//
//  ScheduleActionEditorViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleActionEditorViewController: UIViewController, UITextFieldDelegate,  UIPickerViewDataSource, UIPickerViewDelegate{
    private let logTag = "ScheduleActionEditorViewController"
    fileprivate var sessionManager : AylaSessionManager?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var parentScheduleNameLabel: UILabel!
    @IBOutlet fileprivate weak var activeSwitch: UISwitch!
    @IBOutlet fileprivate weak var propertyPicker: UIPickerView!
    @IBOutlet fileprivate weak var propertyTextField: UITextField!
    @IBOutlet fileprivate weak var valueTextField: UITextField!
    @IBOutlet fileprivate weak var saveActionButton: AuraButton!
    @IBOutlet fileprivate weak var valueLineItem: UIStackView!
    @IBOutlet fileprivate weak var firePointSelector: UISegmentedControl!
    
    fileprivate var properties : [AylaProperty?] = []
    fileprivate var propertyNames : [String?] = []

    fileprivate var selectedProperty : AylaProperty? = nil {
        didSet{
            if let property = self.selectedProperty {
                valueTextField.keyboardType = keyboardTypeForPropertyBaseType(property.baseType)
            }
            valueLineItem.isHidden = selectedProperty == nil ? true : false
        }
    }
    fileprivate var selectedValue : AnyObject?
    fileprivate var selectedFirePoint : AylaScheduleActionFirePoint?
    
    var action : AylaScheduleAction? = nil
    
    var schedule : AylaSchedule? = nil {
        didSet {
            // Once retrieved from the schedule, store all properties for which an action can be created
            var allProperties : [AylaProperty?] = []
            if schedule?.device?.properties != nil {
                allProperties = schedule!.device!.properties!.map { ($0.1 as! AylaProperty) }
            }
            if !allProperties.isEmpty {
                properties = allProperties.filter{ $0!.direction == AylaScheduleDirectionToDevice }.filter{ [AylaPropertyBaseTypeBoolean,
                    AylaPropertyBaseTypeString,
                    AylaPropertyBaseTypeInteger,
                    AylaPropertyBaseTypeDecimal].contains($0!.baseType) }.map{ $0 }
            }
            if !properties.isEmpty {
                propertyNames = properties.map{ $0!.name }
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"session manager can't be found")
        }
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem:.cancel, target: self, action:#selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        propertyTextField.delegate = self
        valueTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)
        
        propertyTextField.inputView = UIView()
        propertyPicker.dataSource = self
        propertyPicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateUI()
    }
    
    fileprivate func populateUI() {
        // Populate UI elements based on properties of a received schedule action, if one exists
        if action != nil {
            titleLabel.text = "Edit Schedule Action"
            saveActionButton.titleLabel?.text = "Update Action"
            let propertyName = self.action?.name
            if let propertyNameIndex = self.properties.index(where: { $0!.name == propertyName }) {
                propertyPicker.selectRow(propertyNameIndex, inComponent: 0, animated: true)
                if let property = properties[propertyNameIndex] {
                    propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
                    selectedProperty = property
                }
            }
            valueTextField.text = String(describing: action!.value as AnyObject)
            firePointSelector.selectedSegmentIndex = Int(action!.firePoint.rawValue - 1)
            parentScheduleNameLabel.text = schedule?.displayName
            activeSwitch.isOn = action!.isActive
        } else {
            parentScheduleNameLabel.text = schedule?.displayName
            titleLabel.text = "Create Schedule Action"
            saveActionButton.titleLabel?.text = "Create Action"
            selectedFirePoint = AylaScheduleActionFirePoint(rawValue: UInt(firePointSelector.selectedSegmentIndex + 1))
        }
        firePointSelector.tintColor = UIColor.auraLeafGreenColor()
    }
    
    fileprivate func internalError(){
        UIAlertController.alert("Internal Error", message: "A problem has occurred.", buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
            self.cancel()
        })
    }
    
    @objc fileprivate func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc fileprivate func cancel() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    fileprivate func toggleViewVisibilityAnimated(_ view: UIView){
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.33, animations: {
                view.isHidden = !(view.isHidden)
            }) 
        }
    }

    @IBAction fileprivate func propertyFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(propertyPicker)
        if selectedProperty == nil {
            if let property = properties[propertyPicker.selectedRow(inComponent: 0)] {
                selectedProperty = property
                propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
            } else {
                internalError()
            }
        }
    }

    @IBAction fileprivate func segmentedControlChanged(_ sender: UISegmentedControl){
        selectedFirePoint = AylaScheduleActionFirePoint(rawValue: UInt(sender.selectedSegmentIndex + 1))
    }
    
    // MARK: Schedule Handling Methods
    
    fileprivate func propertyAndBaseTypeStringForProperty(_ property: AylaProperty) -> String{
        return property.name + " (" + property.baseType + ")"
    }
    
    fileprivate func checkAllRequiredFields() -> Bool{
        // Verify that all required properties have a value set and show alerts for missing ones.
        var message : String? = nil
        if selectedProperty == nil {
            message = "You must select a property."
        } else if selectedValue == nil {
            message = "You must enter a valid value for the property."
        } else if selectedFirePoint == nil {
            message = "You must select a fire point for the action."
        }
        if message != nil {
            UIAlertController.alert("Error", message: message, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                
            })
        }
        else {
            return true
        }
        UIAlertController.alert("Error", message: "An unknown problem has occurred.", buttonTitle: "OK", fromController: self)
        return false
    }
    
    @IBAction fileprivate func saveActionButtonPressed(_ sender: AnyObject) {
        // If an action is present try to update it, otherwise, create a new one.
        saveActionButton.isEnabled = false
        if action != nil {
            // Presence of a key indicates it exists on the service and should be updated
            if action!.key != nil {
                updateScheduleAction(action!, successHandler: {
                    self.cancel()
                    }, failureHandler: { (error) in
                self.saveActionButton.isEnabled = true
                })
            } else{
                // Lack of key indicates action is new/local and needs to be created.
                createNewScheduleAction({
                    self.cancel()
                    }, failureHandler: { (error) in
                        self.saveActionButton.isEnabled = true
                })
            }
        } else {
            createNewScheduleAction({ 
                self.cancel()
                }, failureHandler: { (error) in
            self.saveActionButton.isEnabled = true
            })
        }
    }
    
    
    fileprivate func updateScheduleAction(_ action: AylaScheduleAction, successHandler: (() -> Void)?, failureHandler: ((_ error: Error) -> Void)?){
        if self.action == nil {
            internalError()
        } else {
            // Make a copy of existing action
            let actionToUpdate : AylaScheduleAction = self.action!.copy() as! AylaScheduleAction
            
            // Pull settings from UI and change existing schedule action accordingly
            if let property = selectedProperty {
                actionToUpdate.name = property.name
                actionToUpdate.baseType = property.baseType
            }
            if let newValue = self.selectedValue {
                actionToUpdate.value = newValue
            }
            
            if let newFirePoint = self.selectedFirePoint {
                actionToUpdate.firePoint = newFirePoint
            }
            actionToUpdate.isActive = activeSwitch.isOn

            if schedule != nil {
                schedule!.update([actionToUpdate], success: { (action) in
                    UIAlertController.alert("Success", message: "Action Successfully Updated", buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                        if let success = successHandler {
                            success()
                        }
                    })
                    }) { (error) in
                        UIAlertController.alert("Failed to Update Action", message: error.description, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                            if let failure = failureHandler {
                                failure(error)
                            }
                        })
                }
            } else {
                internalError()
            }
        }
    }
    
    fileprivate func createNewScheduleAction(_ successHandler: (() -> Void)?, failureHandler: ((_ error: Error) -> Void)?){
        if checkAllRequiredFields() == true {
            if let schedule = schedule, let value = selectedValue, let property = selectedProperty{
                let newAction = AylaScheduleAction(name: property.name,
                                                   value:value,
                                                   baseType: property.baseType,
                                                   active: activeSwitch.isOn,
                                                   firePoint: selectedFirePoint!,
                                                   schedule: schedule)
                schedule.createScheduleAction(newAction, success: { (action) in
                        UIAlertController.alert("Success", message: "Action Successfully Created", buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                            self.action = action
                            if let success = successHandler {
                                success()
                            }
                        })
                    }) { (error) in

                        UIAlertController.alert("Failed to Update Action", message: error.description, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                            if let failure = failureHandler {
                                failure(error)
                            }
                        })
                }
            } else {
                internalError()
            }
        }
    }
    
    
    // MARK: Text Field Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.propertyTextField {
            toggleViewVisibilityAnimated(propertyPicker)
            if selectedProperty == nil {
                if let property = properties[propertyPicker.selectedRow(inComponent: 0)] {
                    selectedProperty = property
                    propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
                } else {
                    internalError()
                }
            }
            return false
        } else {
            
            return true
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == self.propertyTextField {
            propertyPicker.reloadInputViews()
            //property = nil
            return true
        } else {
            return false
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == self.valueTextField {
            if validateStringInputForProperty(textField.text, property: selectedProperty) == true {
                selectedValue = valueForStringAndProperty(textField.text, property: selectedProperty)
                return true
            } else {
                UIAlertController.alert("Invalid Value", message: "Invalid Value for selected property.", buttonTitle: "OK", fromController: self)
                return false
            }
        } else {
            return true
        }
    }
    
    fileprivate func valueForStringAndProperty(_ str:String?, property: AylaProperty?) -> AnyObject? {
        // Given a string, and a target baseType, return a valid action.value if possible, otherwise nil.
        if str == nil || property == nil{
            return nil
        } else {
            switch property!.baseType{
            case AylaPropertyBaseTypeString:
                return str as AnyObject?;
            case AylaPropertyBaseTypeBoolean:
                if str == "1" {
                    return 1 as AnyObject?
                }
                if str == "0" {
                    return 0 as AnyObject?
                }
                return nil
            case AylaPropertyBaseTypeInteger:
                if let intValue = Int(str!) {
                    return intValue as AnyObject?
                }
                return nil
            case AylaPropertyBaseTypeDecimal:
                if let doubleValue = Double(str!) {
                    return doubleValue as AnyObject?
                }
                return nil
            default:
                return nil
            }
        }
    }
    
    fileprivate func validateStringInputForProperty(_ str:String?, property: AylaProperty?) -> Bool {
        // Given a string, and a target baseType, return a boolean for whether the string is a valid action.value.
        if let property = property {
            switch property.baseType{
            case AylaPropertyBaseTypeString:
                return true;
            case AylaPropertyBaseTypeBoolean:
                if str == "1" || str == "0" {
                    return true
                }
                return false
            case AylaPropertyBaseTypeInteger:
                if Int(str!) != nil {
                    return true
                }
                return false
            case AylaPropertyBaseTypeDecimal:
                if Double(str!) != nil {
                    return true
                }
                return false
            default:
                return false
            }
        } else {
            return false
        }
    }
    
    fileprivate func keyboardTypeForPropertyBaseType(_ baseType: String?) -> UIKeyboardType! {
        // Return a keyboard type appropriate for the given property baseType
        if baseType == nil {
            return UIKeyboardType.default
        }
        switch baseType!{
        case AylaPropertyBaseTypeString:
            return UIKeyboardType.default
        case AylaPropertyBaseTypeBoolean:
            return UIKeyboardType.numberPad
        case AylaPropertyBaseTypeInteger:
            return UIKeyboardType.numberPad
        case AylaPropertyBaseTypeDecimal:
            return UIKeyboardType.decimalPad
        default:
            return UIKeyboardType.default
        }
    }
    
    // MARK: - UIPickerView Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case propertyPicker:
            return properties.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case propertyPicker:
            if let property = properties[row] {
                propertyTextField.text = propertyAndBaseTypeStringForProperty(property)
                selectedProperty = properties[row]
            }
        default:
            break
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case propertyPicker:
            return propertyNames[row]
        default:
            return nil
        }
    }
    
}
