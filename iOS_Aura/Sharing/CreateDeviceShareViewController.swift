//
//  CreateDeviceShareViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/6/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
import UIKit

class CreateDeviceShareViewController: UIViewController, UITextFieldDelegate{
    private let logTag = "CreateDeviceShareViewController"
    /// Device model used by view controller to present this device.
    var sessionManager : AylaSessionManager?
    var deviceViewModel : DeviceViewModel!
    
    var startDate : Date?
    var expiryDate : Date?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var roleNameTextField: UITextField!
    @IBOutlet weak var capabilitySelector: UISegmentedControl!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var expiryDateTextField: UITextField!
    @IBOutlet weak var expiryDatePicker: UIDatePicker!
    @IBOutlet weak var createShareButton: AuraButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"session manager can't be found")
        }

        let cancel = UIBarButtonItem(barButtonSystemItem:.cancel, target: self, action: #selector(RegistrationViewController.cancel))
        self.navigationItem.leftBarButtonItem = cancel
        self.emailTextField.delegate = self
        self.roleNameTextField.delegate = self
        self.startDateTextField.delegate = self
        self.expiryDateTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(CreateDeviceShareViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        capabilitySelector.tintColor = UIColor.auraLeafGreenColor()
        self.expiryDateTextField.inputView = UIView()
        self.startDateTextField.inputView = UIView()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        titleLabel.text = String(format:"Share %@", deviceViewModel.device.productName!)
        super.viewWillAppear(animated)
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func cancel() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func toggleViewVisibilityAnimated(_ view: UIView){
        DispatchQueue.main.async { 
            UIView.animate(withDuration: 0.33, animations: {
                view.isHidden = !(view.isHidden)
            }) 
        }
    }
    
    func setDateTextFieldValue(_ date: Date, field: UITextField) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        field.text = dateFormatter.string(from: date)
    }
    
    @IBAction func startDateFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(self.startDatePicker)
    }
    
    @IBAction func expiryDateFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(self.expiryDatePicker)
    }

    @IBAction func startPickerChanged(_ sender: UIDatePicker) {
        startDate = sender.date
        setDateTextFieldValue(startDate!, field:startDateTextField)
    }
    
    @IBAction func expiryPickerChanged(_ sender: UIDatePicker) {
        expiryDate = sender.date
        setDateTextFieldValue(expiryDate!, field:expiryDateTextField)
    }
    
    @IBAction func createButtonPressed(_ sender: AnyObject) {
        let email = emailTextField.text
        if email == nil || email!.characters.count < 1 {
            UIAlertController.alert("Error", message: "Please provide an email", buttonTitle: "OK",fromController: self)
            return;
        }
        self.createShareButton.isEnabled = false
        let roleName = roleNameTextField.text == "" ? nil : roleNameTextField.text
        var operation : AylaShareOperation
        if roleName != nil {
            operation = AylaShareOperation.none
        }
        else {
            let operationIndex = capabilitySelector.selectedSegmentIndex
            switch operationIndex {
            case 0:
                operation = AylaShareOperation.readAndWrite
            case 1:
                operation = AylaShareOperation.readOnly
            case 2:
                operation = AylaShareOperation.none
            default:
                operation = AylaShareOperation.readAndWrite
            }
        }
        let newShare = AylaShare(email: email!,
                                 resourceName:"device",
                                 resourceId: deviceViewModel.device.dsn!,
                                 roleName: roleName,
                                 operation:  operation,
                                 startAt: startDate,
                                 endAt: expiryDate)
        deviceViewModel.shareDevice(self, withShare: newShare, successHandler: { (share) in
            self.cancel()
            self.createShareButton.isEnabled = true
        }) { (error) in
            self.createShareButton.isEnabled = true
            UIAlertController.alert("Error", message:error.description , buttonTitle: "OK",fromController: self)
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.startDateTextField {
            toggleViewVisibilityAnimated(startDatePicker)
            return false
        } else if textField == self.expiryDateTextField {
            toggleViewVisibilityAnimated(expiryDatePicker)
            return false
        } else {
            return true
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == self.startDateTextField {
            startDatePicker.reloadInputViews()
            startDate = nil
            return true
        } else if textField == self.expiryDateTextField {
            expiryDatePicker.reloadInputViews()
            expiryDate = nil
            return true
        } else {
            return false
        }
    }

}
