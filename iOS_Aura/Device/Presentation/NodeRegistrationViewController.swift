//
//  NodeRegistrationViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 6/7/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import PDKeychainBindingsController
import iOS_AylaSDK
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}



class NodeRegistrationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let logTag = "NodeRegistrationViewController"
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logTextView: AuraConsoleTextView!
    
    enum Section :Int {
        case targetGateway
        case nodes
        case sectionCount
    }
    
    var sessionManager :AylaSessionManager?
    
    var targetGateway : AylaDeviceGateway?
    var candidateNodeList : [AylaRegistrationCandidate] = []
    
    let RegistrationCellId :String = "CandidateCellId"
    
    var fetchNodesBool : Bool = false {
        didSet {
            if self.tableView != nil {
                self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.nodes.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
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
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        let refresh = UIBarButtonItem(barButtonSystemItem:.refresh, target: self, action: #selector(NodeRegistrationViewController.refresh))
        self.navigationItem.rightBarButtonItem = refresh
        
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.logTextView.backgroundColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.navigationBar.setNeedsUpdateConstraints()
        refresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.updatePrompt(nil)
        super.viewWillDisappear(animated)
    }
    
    func getCandidate(_ indexPath:IndexPath) -> AylaRegistrationCandidate? {
        var candidate :AylaRegistrationCandidate?
        switch indexPath.section {
        case Section.nodes.rawValue:
            candidate = candidateNodeList[indexPath.row];
            break
        default:
            break
        }
        return candidate
    }
    
    func register(_ candidate :AylaRegistrationCandidate) {
        if let reg = sessionManager?.deviceManager.registration {
            updatePrompt("Registering Node...")
            reg.register(candidate, success: { (AylaDevice) in
                // Un-comment to cause app to back out after single node registration.
                //self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                
                //  Comment this out if uncommenting above
                self.updatePrompt("Successfully Registered Device.")
                self.refresh()
                }, failure: { (error) in
                    self.updatePrompt("Registration Failed")
                    self.addLog(error.aylaServiceDescription)
            })
        }
        else {
            updatePrompt("Invalid registration");
        }
    }
    
    func refresh() {
        fetchNodesBool = true
        self.addLog("Fetching any node candidates")
        _ = targetGateway?.fetchCandidates(success: { (nodes) in
            self.addLog("Success. Fetched \(nodes.count) node candidates.")
            self.candidateNodeList = nodes
            self.fetchNodesBool = false
            }, failure: { (error) in
                self.candidateNodeList = []
                self.fetchNodesBool = false
                self.addLog("Service: " + error.aylaServiceDescription)
        })
    }
    
    func addLog(_ logText: String) {
        logTextView.text = logTextView.text + "\n" + logText
    }
    
    func updatePrompt(_ prompt: String?) {
        self.navigationController?.navigationBar.topItem?.prompt = prompt
        if prompt == nil {
            self.navigationController?.navigationBar.setNeedsUpdateConstraints()
        }
        addLog(prompt ?? "done")
    }
    
    
    func verifyCoordinateStringsValid(_ latString: String?, lngString: String?) -> Bool {
        if latString == nil || lngString == nil || latString?.characters.count < 1 || lngString?.characters.count < 1 {
            return false
        }
        if let latDouble = Double(latString!), let lngDouble = Double(lngString!) {
            if case (-180...180, -180...180) = (latDouble, lngDouble) {
                return true
            }
            else {
                return false
            }
        }
        return false
    }
    
    // MARK - Table view delegate / data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.sectionCount.rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let height : CGFloat = 40.0
        let zeroHeight : CGFloat = 0.0001
        if tableView.dataSource?.tableView(tableView, numberOfRowsInSection: section) == 0 ||
            (section == Section.nodes.rawValue && fetchNodesBool == true ) {
            return height
        }
        return zeroHeight
    }
    
    func statusHeaderFooterView(_ labelString:String, withActivityIndicator:Bool) -> UIView {
        let view = UIView(frame: CGRect.zero)
        let label = UILabel()
        label.text = labelString
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        if withActivityIndicator {
            let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            activityIndicator.isUserInteractionEnabled = false;
            activityIndicator.startAnimating()
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(activityIndicator)
            
            NSLayoutConstraint(
                item: label,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: activityIndicator,
                attribute: .leading,
                multiplier: 1.0,
                constant: 8.0
                ).isActive = true
            
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 22.0
                ).isActive = true
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 22.0
                ).isActive = true
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: view,
                attribute: .centerY,
                multiplier: 1.0,
                constant: 0.0
                ).isActive = true
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: view,
                attribute: .trailing,
                multiplier: 1.0,
                constant: -16.0
                ).isActive = true
        } else {
            NSLayoutConstraint(
                item: label,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: view,
                attribute: .trailing,
                multiplier: 1.0,
                constant: 8.0
                ).isActive = true
            
        }
        
        NSLayoutConstraint(
            item: label,
            attribute: .top,
            relatedBy: .equal,
            toItem: view,
            attribute: .top,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        
        NSLayoutConstraint(
            item: label,
            attribute: .leading,
            relatedBy: .equal,
            toItem: view,
            attribute: .leading,
            multiplier: 1.0,
            constant: 36.0
            ).isActive = true
        NSLayoutConstraint(
            item: label,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: view,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 8.0
            ).isActive = true
        
        return view
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Section.nodes.rawValue && fetchNodesBool == true {
            return self.statusHeaderFooterView("Scanning...", withActivityIndicator:true)
        }
        if tableView.numberOfRows(inSection: section) == 0 {
            return self.statusHeaderFooterView("None", withActivityIndicator:false)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationCellId) as? RegistrationTVCell
            if (cell != nil) {
                switch indexPath.section {
                case Section.nodes.rawValue:
                    cell?.configure(candidateNodeList[indexPath.row])
                    break
                case Section.targetGateway.rawValue:
                    cell?.nameLabel.text = self.targetGateway!.productName
                    cell?.dsnLabel.text = self.targetGateway!.dsn! + " (" + self.targetGateway!.oemModel! + ")"
                default:
                    cell?.configure(nil)
                }
            } else {
                assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
            }
            return cell!;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.targetGateway.rawValue:
            return 1
        case Section.nodes.rawValue:
            return candidateNodeList.count;
        default:
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.targetGateway.rawValue:
            return "Gateway Details"
        case Section.nodes.rawValue:
            return "Candidate Nodes"
        default:
            return "";
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.targetGateway.rawValue{
            if let propertyNames = self.targetGateway?.managedPropertyNames(){
                if propertyNames.contains("join_enable") {
                    self.joinWindowAlertForIndexPath(indexPath)
                } else {
                    UIAlertController.alert("No Join Window", message: "This gateway does not have the 'join_enable' property required for setting a join window.", buttonTitle: "Ok", fromController: self, okHandler: { (action) in
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    })
                }
            }
        } else {
            self.registerAlertForIndexPath(indexPath)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func joinWindowAlertForIndexPath(_ indexPath: IndexPath){
        let defaultDuration : UInt = 200
        var durationTextField = UITextField()

        let message = String(format:"Attempt to open a join window for this gateway?\n\n(Default window duration is %u seconds.)", defaultDuration)
        
        let alert = UIAlertController(title: "Open a join window?", message: message, preferredStyle: .alert)
        let joinWindowAction = UIAlertAction(title: "Open", style: .default) { (action) in
            var duration: UInt
            if durationTextField.text == nil || durationTextField.text == "" {
                duration = defaultDuration
            } else {
                duration = UInt(durationTextField.text!)!
            }
            _ = self.targetGateway?.openRegistrationJoinWindow(duration, success: { 
                self.addLog("Success.")
                }, failure: { (error) in
                    self.addLog("Failed to open Join Window")
                    self.addLog(error.description)
            })
            self.addLog("Opening Join Window...")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Custom Duration (optional)"
            textField.tintColor = UIColor.auraLeafGreenColor()
            textField.keyboardType = UIKeyboardType.numberPad
            durationTextField = textField
        })
        
        alert.addAction(cancelAction)
        alert.addAction(joinWindowAction)
        present(alert, animated: true, completion: nil)
    }
    
    func registerAlertForIndexPath(_ indexPath: IndexPath){

        let alert = UIAlertController(title: "Register this device?", message: nil, preferredStyle: .alert)
        let registerAction = UIAlertAction(title: "Register", style: .default) { (action) in
            
            if let candidate = self.getCandidate(indexPath) {
                candidate.registrationType = AylaRegistrationType.node
                self.register(candidate)
            }
            else {
                self.updatePrompt("Internal error")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.tableView.deselectRow(at: indexPath, animated: true)
        }

        alert.addAction(cancelAction)
        alert.addAction(registerAction)
        present(alert, animated: true, completion: nil)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
