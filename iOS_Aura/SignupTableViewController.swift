//
//  SignupTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 3/24/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class SignupTableViewController: UITableViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneCountryCodeTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var devKitNumTextField: UITextField!
    @IBOutlet weak var signupButton: AuraButton!

    var tokenTextField: UITextField?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancelAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signUpAction(_ sender: AnyObject) {
        self.view.endEditing(true)
        var errorMessage: String?
        if emailTextField.text == nil || emailTextField.text!.characters.count < 1 {
            errorMessage = "Email field is required"
        } else if passwordTextField.text == nil || passwordTextField.text!.characters.count < 1 {
            errorMessage = "Password field is required"
        } else if confirmPasswordTextField.text == nil || confirmPasswordTextField.text!.characters.count < 1 {
            errorMessage = "Password confirmation field is required"
        } else if firstNameTextField.text == nil || firstNameTextField.text!.characters.count < 1 {
            errorMessage = "First name field is required"
        } else if lastNameTextField.text == nil || lastNameTextField.text!.characters.count < 1 {
            errorMessage = "Last Name field is required"
        }  else if passwordTextField.text != confirmPasswordTextField.text {
            errorMessage = "Password and confirmation don't match!"
        }  else {
            let phoneCountryCodeProvided = phoneCountryCodeTextField.text != nil && phoneCountryCodeTextField.text!.characters.count > 0
            let phoneProvided = phoneTextField.text != nil && phoneTextField.text!.characters.count > 0
            if phoneProvided != phoneCountryCodeProvided {
                errorMessage = "Either none or both Country Code and Phone must be provided"
            }
        }
        
        if let message = errorMessage {
            UIAlertController.alert("Error", message: message, buttonTitle: "OK",fromController: self)
            return;
        }
        
        let user = AylaUser(email: emailTextField.text!, password: passwordTextField.text!, firstName: firstNameTextField.text!, lastName: lastNameTextField.text!)
        user.phoneCountryCode = phoneCountryCodeTextField.text
        user.phone = phoneTextField.text
        user.company = companyTextField.text
        user.street = streetTextField.text
        user.city = cityTextField.text
        user.state = stateTextField.text
        user.zip = zipTextField.text
        user.country = countryTextField.text
        if devKitNumTextField.text != nil {
            let devKitNumber = Int(devKitNumTextField.text!)
            user.devKitNum = devKitNumber as NSNumber?
        }
        
        let emailTemplate = AylaEmailTemplate(id: "com.template.signUp", subject: "Aura Signup", bodyHTML: nil)
        
        signupButton.isEnabled = false
        signupButton.alpha = 0.6
        let loginManager = AylaNetworks.shared().loginManager
        loginManager.signUp(with: user, emailTemplate: emailTemplate, success: { () -> Void in
            let presentingController = self.presentingViewController
            self.dismiss(animated: true, completion: {
                UIAlertController.alert( "Account created", message: "Please check your email for a confirmation",buttonTitle: "OK",fromController: presentingController!)
            })
        }) { (error) -> Void in
            self.signupButton.isEnabled = true
            self.signupButton.alpha = 1.0
            UIAlertController.alert("Error", message: error.aylaServiceDescription, buttonTitle: "OK", fromController: self)
        }
    }
    
    @IBAction func enterTokenAction(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Enter your confirmation token", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Confirmation Token"
            textField.tintColor = UIColor(red: 93.0/255.0, green: 203/255.0, blue: 152/255.0, alpha: 1.0)
            self.tokenTextField = textField
        }
        let okAction = UIAlertAction (title: "Confirm", style: UIAlertActionStyle.default) { (action) -> Void in
            let token = self.tokenTextField!.text
            if token == nil || token!.characters.count < 1 {
                
                UIAlertController.alert("Error", message: "No token was provided", buttonTitle: "OK",fromController: self)
                return;
            }
            let loginManager = AylaNetworks.shared().loginManager
            loginManager.confirmAccount(withToken: token!, success: { () -> Void in
                let parentController = self.presentingViewController
                self.dismiss(animated: true, completion: { () -> Void in
                    let alert = UIAlertController(title: "Account confirmed", message: "Enter your credentials to log in", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler:nil)
                    alert.addAction(okAction)
                    if parentController != nil {
                        parentController!.present(alert, animated: true, completion: nil)
                    }
                })
                }, failure: { (error) -> Void in
                    UIAlertController.alert("Error", message: error.aylaServiceDescription, buttonTitle: "OK", fromController: self)
            })
        }
        
        let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
