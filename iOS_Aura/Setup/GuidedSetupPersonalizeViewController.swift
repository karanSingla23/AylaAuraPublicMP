//
//  GuidedSetupPersonalizeViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/20/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GuidedSetupPersonalizeViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var deviceImageContainerView: UIView!
    @IBOutlet weak var deviceImageView: UIImageView!
    
    @IBOutlet weak var deviceNameTextField: UITextField!
    
    var model: GuidedSetupModel!
    var setupNavigationController : GuidedSetupNavigationController? {
        get {
            return self.navigationController as? GuidedSetupNavigationController
        }
    }
    var deviceJustRegistered :Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        deviceNameTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        model.fetchTimeZone(successBlock: { (timeZone) in
            guard let timeZoneId = timeZone.tzID,
                let row = NSTimeZone.knownTimeZoneNames.index(of: timeZoneId) else {
                return
            }
            pickerView.selectRow(row, inComponent: 0, animated: false)
            self.updateTextField(withTimeZoneAtRow: row)
        }, failure: { (_) in
            pickerView.selectRow(0, inComponent: 0, animated: false)
        })
        timeZone.inputView = pickerView
        navigationItem.hidesBackButton = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(GuidedSetupPersonalizeViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(GuidedSetupPersonalizeViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GuidedSetupPersonalizeViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        deviceImageContainerView.layer.cornerRadius = deviceImageContainerView.frame.height / 2
        deviceImageContainerView.layer.borderColor = UIColor.brown.cgColor
        deviceImageContainerView.layer.borderWidth = 2.0
        
        var message: String = "Congratulations. Your EVB has been successfully connected to the Wi-Fi Network \"\(model.ssidName ?? "unknown")\"."
        
        if deviceJustRegistered && self.model.isDeviceAlreadyRegistered! { // Device just registered.  No name yet, do not prefill.

            message = message + "\n\nIt has been registered to your account. You may wish to give it a meaningful name."

        } else if self.model.isDeviceAlreadyRegistered! { // Device previously registered to you.  Name already exists.
            if let deviceName = model.registeredDevice?.productName {
                deviceNameTextField.text = deviceName
            }
            message = message + "\n\nIt is already registered to you, but if you wish, you may give it a new name."
        }
        completionMessage.text = message
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func deviceNameChanged(_ sender: UITextField) {
        self.model.productName = sender.text
    }
    
    @IBOutlet weak var completionMessage: UILabel!
    @IBOutlet weak var timeZone: UITextField!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return NSTimeZone.knownTimeZoneNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NSTimeZone.knownTimeZoneNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateTextField(withTimeZoneAtRow: row)
    }
    
    func updateTextField(withTimeZoneAtRow row:Int) {
        let timeZone = String(NSTimeZone.knownTimeZoneNames[row])
        self.model.timeZone = timeZone
        self.timeZone.text = timeZone
    }
    
    func showError(error: [String:Error]) {
        var title = "Error"
        var message = "Unknown error: \(String(describing: error.first?.value))"
        if let modelError = error.first, let error = modelError.value as? GuidedSetupModel.GuidedSetupModelError {
            title = modelError.key
            switch error {
            case .invalidParameters:
                message = "Invalid parameters"
            }
        }
        
        UIAlertController.alert(title, message: message, buttonTitle: "OK", fromController: self)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        view.endEditing(true)
        let dispatchGroup = DispatchGroup()
        var errorDictionary = [String:Error]()
        dispatchGroup.enter()
        self.model.renameProduct(successBlock: {
            dispatchGroup.leave()
        }) { (error) in
            errorDictionary["Name"] = error
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.model.updateTimeZone(successBlock: {
            
            dispatchGroup.leave()
        }) { (error) in
            errorDictionary["Time Zone"] = error
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            if errorDictionary.count > 0 {
                self.showError(error: errorDictionary)
                return
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func keyboardWillShow(notification: Notification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            //self.view.frame.origin.y -= keyboardSize.height
            var userInfo = notification.userInfo!
            var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            keyboardFrame = self.view.convert(keyboardFrame, from: nil)
            
            var contentInset:UIEdgeInsets = self.tableView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            self.tableView.contentInset = contentInset
            
            let indexpath = IndexPath(row: 1, section: 0)
            self.tableView.scrollToRow(at:indexpath, at: .top, animated: true)
        }
    }
    
    func keyboardWillHide(notification: Notification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            var contentInset:UIEdgeInsets = UIEdgeInsets.zero
            contentInset.bottom = contentInset.bottom - 45
            self.tableView.contentInset = contentInset
        }
    }
    
    // MARK - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if text.characters.count > 0 {
                self.model.productName = textField.text
            }
        }
        return true
    }
    
}
