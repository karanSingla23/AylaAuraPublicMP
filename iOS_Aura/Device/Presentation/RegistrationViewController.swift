//
//  iOS_Aura
//
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


class RegistrationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CellButtonDelegate, CellSelectorDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    private let logTag = "RegistrationViewController"
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var logTextView: AuraConsoleTextView!
    
    /// Segue id to property view
    let segueIdToNodeRegistrationView :String = "toNodeRegistrationPage"
    
    enum Section :Int {
        case sameLan
        case buttonPush
        case gatewayNode
        case localDevice
        case manual
        case sectionCount
    }
    
    enum SelectorMode :Int {
        case display
        case dsn
        case apMode
        case manual
        case sectionCount
    }
    
    var selectorIndex : Int!
    
    /// Reference to our current AylaSessionManager instance.
    var sessionManager :AylaSessionManager?
    
    /// Reference to our current AylaDeviceManager instance.
    var deviceManager : AylaDeviceManager?
    
    /// Reference to our current list of devices.
    var devices: [AylaDevice] = []
    
    var candidateSameLan :AylaRegistrationCandidate?
    var candidateButtonPush :AylaRegistrationCandidate?
    var candidateManual :AylaRegistrationCandidate?
    var gateways : [AylaDeviceGateway?] = []
    
    var discoveredLocalDevices = [AylaRegistrationCandidate]()
    
    /// True while LocalDeviceManager is scanning for devices
    var BLEScanBool : Bool = false {
        didSet {
            if self.tableView != nil {
                self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.localDevice.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
            }
        }
    }

    let RegistrationCellId :String = "CandidateCellId"
    
    let RegistrationModeSelectorCellId :String = "ModeSelectorCellId"
    
    let RegistrationDSNCellId :String = "CandidateDSNCellId"
    let RegistrationDisplayCellId :String = "CandidateDisplayCellId"
    let RegistrationAPModeCellId :String = "CandidateAPModeCellId"
    let RegistrationManualCellId :String = "CandidateManualCellId"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
            self.sessionManager = sessionManager
            self.deviceManager = sessionManager.deviceManager
            // Add self as device manager listener
            self.deviceManager!.add(self)
        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"session manager can't be found")
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let refresh = UIBarButtonItem(barButtonSystemItem:.refresh, target: self, action: #selector(RegistrationViewController.refresh))
        self.navigationItem.rightBarButtonItem = refresh
        self.selectorIndex = 0
        
        // Add tap recognizer to dismiss keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.logTextView.backgroundColor = UIColor.white
    }
    
    func updateGatewaysList() {
        self.devices = self.deviceManager!.devices.values.map({ (device) -> AylaDevice in
            return device as! AylaDevice
        })
        gateways = []
        if self.devices.count > 0 {
            for device in self.devices {
                if device.isKind(of: AylaDeviceGateway.self) {
                    gateways.append((device as! AylaDeviceGateway))
                }
            }
        }
        self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.gatewayNode.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.updatePrompt(nil)
        super.viewWillDisappear(animated)
    }

    @IBAction func cancel() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func getCandidate(_ indexPath:IndexPath) -> AylaRegistrationCandidate? {
        var candidate :AylaRegistrationCandidate?
        switch Section(rawValue:indexPath.section)! {
        case .sameLan:
            candidate = candidateSameLan;
            break
        case .buttonPush:
            candidate = candidateButtonPush;
            break
        case .manual:
            candidate = candidateManual;
            break
        case .localDevice:
            candidate = discoveredLocalDevices[indexPath.row]
        default:
            break
        }
        return candidate
    }
    
    func register(_ candidate :AylaRegistrationCandidate) {
        if candidate.registrationType.rawValue == AylaRegistrationTypeLocal {
            guard let localDeviceManager = AylaNetworks.shared().getPluginWithId(AuraLocalDeviceManager.PLUGIN_ID_LOCAL_DEVICE) as? AuraLocalDeviceManager
                else {
                    self.updatePrompt("No Local Device Manager found")
                    return
            }
            guard let sessionManager = self.sessionManager
                else {
                    self.updatePrompt("No Session Manager found")
                    return
            }
            updatePrompt("Registering...")
            localDeviceManager.registerLocalDevice(candidate, sessionManager: sessionManager, success: { (localDevice) in
                AylaLogI(tag: self.logTag, flag: 0, message:"Registered device \(localDevice)")
                self.navigationController?.dismiss(animated: true, completion: nil)
                }, failure: { (error) in
                    self.updatePrompt("Failed to register Local Device")
                    self.addLog(error.aylaServiceDescription)
            })
            return
        }
        if let reg = sessionManager?.deviceManager.registration {
            updatePrompt("Registering...")
            reg.register(candidate, success: { (AylaDevice) in
                if candidate.registrationType == AylaRegistrationType.apMode {
                    PDKeychainBindings.shared().removeObject(forKey: AuraDeviceSetupTokenKeychainKey)
                    PDKeychainBindings.shared().removeObject(forKey: AuraDeviceSetupDSNKeychainKey)
                    AylaLogI(tag: self.logTag, flag: 0, message:"Removing AP Mode Device details from storage")
                }
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }, failure: { (error) in
                    self.updatePrompt("Failed")
                    self.addLog(error.aylaServiceDescription)
            })
        }
        else {
            updatePrompt("Invalid registration");
        }
    }
    
    func refresh() {
        self.updateGatewaysList()
        let aGroup = DispatchGroup()
        
        aGroup.enter()  // SameLAN
        aGroup.enter()  // PushButton
        aGroup.enter()  // LocalDevice

        if let reg = sessionManager?.deviceManager.registration {
        
            updatePrompt("Refreshing Candidate Devices...")
            self.addLog("Fetching Same-LAN Candidate.")
            reg.fetchCandidate(withDSN: nil, registrationType: .sameLan, success: { (candidate) in
                self.candidateSameLan = candidate
                self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.sameLan.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
                aGroup.leave()
                }, failure: { (error) in
                    self.candidateSameLan = nil;
                    self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.sameLan.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
                    //Skip 404 for now
                    if let httpResp = (error as NSError).userInfo[AylaHTTPErrorHTTPResponseKey] as? HTTPURLResponse {
                        if(httpResp.statusCode != 404) {
                            self.addLog("Same-LAN - " + error.aylaServiceDescription)
                        }
                        else {
                            self.addLog("No Same LAN candidate")
                        }
                    }
                    else {
                        self.addLog("Same-LAN - " + error.description)
                    }
                    aGroup.leave()
                    
            })
            self.addLog("Fetching Button Push Candidate.")
            reg.fetchCandidate(withDSN: nil, registrationType: .buttonPush, success: { (candidate) in
                self.candidateButtonPush = candidate
                self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.buttonPush.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
                aGroup.leave()
                }, failure: { (error) in
                    self.candidateButtonPush = nil;
                    self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.buttonPush.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
                    
                    //Skip 404 for now
                    if let httpResp = (error as NSError).userInfo[AylaHTTPErrorHTTPResponseKey] as? HTTPURLResponse {
                        if(httpResp.statusCode != 404) {
                            self.addLog("ButtonPush - " + error.description)
                        }
                        else  {
                            self.addLog("No Button Push candidate")
                        }
                    }
                    else {
                        self.addLog("ButtonPush - " + error.description)
                    }
                    aGroup.leave()
            })
            
            self.candidateManual = AylaRegistrationCandidate()
            self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.manual.rawValue, 1).toRange() ?? 0..<0), with: .automatic)

            aGroup.notify(queue: DispatchQueue.main, execute: {
                self.updatePrompt(nil)
            })
        }
        
        guard let localDeviceManager = AylaNetworks.shared().getPluginWithId(AuraLocalDeviceManager.PLUGIN_ID_LOCAL_DEVICE) as? AuraLocalDeviceManager
            else {
                return
        }
        
        self.addLog("Scanning for Local Devices.")
        self.BLEScanBool = true
        localDeviceManager.findLocalDevices(withHint: nil, timeout: 5000, success: { (foundDevices) in
            self.discoveredLocalDevices = foundDevices
            self.addLog("Local Devices: Found \(foundDevices.count).")
            aGroup.leave()
            self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(Section.localDevice.rawValue, 1).toRange() ?? 0..<0), with: .automatic)
            self.BLEScanBool = false
            }) { (error) in
                self.addLog("Error fetching local candidates: \(error)")
                self.BLEScanBool = false
                aGroup.leave()
        }
        aGroup.notify(queue: DispatchQueue.main, execute: {
            self.updatePrompt(nil)
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
        addLog(prompt ?? "Done.")
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
            (section == Section.localDevice.rawValue && BLEScanBool == true) {
            return height
        }
        return zeroHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Section.localDevice.rawValue && BLEScanBool == true {
            return tableView.statusHeaderFooterView("Scanning...", withActivityIndicator:true)
        }
        if tableView.numberOfRows(inSection: section) == 0 {
            return tableView.statusHeaderFooterView("None", withActivityIndicator:false)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.manual.rawValue{
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationModeSelectorCellId) as? RegistrationModeSelectorTVCell
                if (cell != nil) {
                    cell?.selectorDelegate = self
                    cell?.modeSelector.tintColor = UIColor.auraLeafGreenColor()
                } else {
                    assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
                }
                return cell!;
            case 1:
                
                switch self.selectorIndex!{
                case SelectorMode.display.rawValue:
                    let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationDisplayCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                case SelectorMode.dsn.rawValue:
                    let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationDSNCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                case SelectorMode.apMode.rawValue:
                    let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationAPModeCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    
                    if let dsn = PDKeychainBindings.shared().string(forKey: AuraDeviceSetupDSNKeychainKey) {
                        cell?.dsnField!.text = dsn
                    }
                    if let token = PDKeychainBindings.shared().string(forKey: AuraDeviceSetupTokenKeychainKey) {
                        cell?.regTokenField!.text = token
                    }
 
                    return cell!;
                case SelectorMode.manual.rawValue:
                    let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationManualCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                default:
                    let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationManualCellId) as? RegistrationManualTVCell
                    cell?.buttonDelegate = self
                    return cell!;
                }

            default:
                let cell = UITableViewCell()
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationCellId) as? RegistrationTVCell
        
            if (cell != nil) {
                switch Section(rawValue: indexPath.section)! {
                case .sameLan:
                    cell?.configure(candidateSameLan)
                    break
                case .buttonPush:
                    cell?.configure(candidateButtonPush)
                    break
                case .gatewayNode:
                    if let gateway = gateways[indexPath.row] {
                    cell?.nameLabel.text = gateway.productName
                    cell?.dsnLabel.text = gateway.dsn
                    }
                case .localDevice:
                    let registrationCandidate = discoveredLocalDevices[indexPath.row]
                    cell?.configure(registrationCandidate)
                default:
                    cell?.configure(nil)
                }
            } else {
                assert(false, "\(RegistrationCellId) - reusable cell can't be dequeued'")
            }
            return cell!;
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .sameLan:
            return candidateSameLan != nil ? 1 : 0;
        case .buttonPush:
            return candidateButtonPush != nil ? 1 : 0;
        case .gatewayNode:
            return gateways.count
        case .manual:
            return 2;
        case .localDevice:
            return discoveredLocalDevices.count
        default:
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Section.manual.rawValue {
            switch indexPath.row{
            case 0:
                return 65.0
            case 1:
                return 150.0
            default:
                return 0.0
            }
        } else {
            return 96.0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .sameLan:
            return "Same LAN Candidate"
        case .buttonPush:
            return "Button Push Candidate"
        case .gatewayNode:
            return "Add Node to Gateway"
        case .manual:
            return "Enter Candidate Details Manually"
        case .localDevice:
            return "Discovered Local Devices"
        default:
            return "";
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .manual:
            break
        case .gatewayNode:
            performSegue(withIdentifier: segueIdToNodeRegistrationView, sender: gateways[indexPath.row])
        case .sameLan:
            fallthrough
        case .buttonPush:
            if let configurationSent = WiFiSetupHelper.shared.configurationSent {
                if let currentSSID = AylaNetworkInformation.ssid(),
                    let candidateDSN = self.getCandidate(indexPath)?.dsn,
                    let configuredDeviceDSN = configurationSent.device?.dsn {
                    
                    if candidateDSN.compare(configuredDeviceDSN) == .orderedSame && currentSSID.compare(configurationSent.ssid) != .orderedSame  {
                        let notSameLANAlert = UIAlertController(title: "⚠ Connected to \(currentSSID)!", message: "Current network differs from the one used to configure this device, to register it you should connect to WiFi:\"\(configurationSent.ssid)\" and return here to retry", preferredStyle: .alert)
                        notSameLANAlert.addAction(UIAlertAction(title: "Continue", style: .default, handler:{(action) in
                            self.registerAlertForIndexPath(indexPath)
                        }))
                        notSameLANAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { (action) in
                            UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
                        }))
                        self.present(notSameLANAlert, animated: true, completion: nil)
                    } else {
                        registerAlertForIndexPath(indexPath)
                    }
                } else {
                    let notConnectedAlert = UIAlertController(title: "Not connected to WiFi", message: "Some registration methods will fail", preferredStyle: .alert)
                    notConnectedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    present(notConnectedAlert, animated: true, completion: nil)
                }
            } else {
                registerAlertForIndexPath(indexPath)
            }
        default:
            registerAlertForIndexPath(indexPath)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func registerAlertForIndexPath(_ indexPath: IndexPath){
        //var tokenTextField = UITextField()
        var latitudeTextField = UITextField()
        var longitudeTextField = UITextField()
        
        let message = selectorIndex == SelectorMode.display.rawValue ? "" : "You may manually set the coordinates for the device's location here if you wish."
        let alert = UIAlertController(title: "Register this device?", message: message, preferredStyle: .alert)
        let registerAction = UIAlertAction(title: "Register", style: .default) { (action) in
            
            if let candidate = self.getCandidate(indexPath) {
                let valid = self.verifyCoordinateStringsValid(latitudeTextField.text, lngString: longitudeTextField.text)
                if valid {
                    candidate.lat = latitudeTextField.text
                    candidate.lng = longitudeTextField.text
                    let message = String(format:"Adding Latitude: %@ and longitude: %@ to registration candidate", candidate.lat!, candidate.lng!)
                    AylaLogD(tag: self.logTag, flag: 0, message:message)
                    self.addLog(message)
                }
                self.register(candidate)
            }
            else {
                self.updatePrompt("Internal error")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        if selectorIndex != SelectorMode.display.rawValue {
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Latitude (optional)"
                textField.tintColor = UIColor.auraLeafGreenColor()
                textField.keyboardType = UIKeyboardType.decimalPad
                latitudeTextField = textField
            })
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Longitude (optional)"
                textField.tintColor = UIColor.auraLeafGreenColor()
                textField.keyboardType = UIKeyboardType.decimalPad
                longitudeTextField = textField
            })
        }
        alert.addAction(cancelAction)
        alert.addAction(registerAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - CellButtonDelegate
    func cellButtonPressed(_ cell: UITableViewCell){
        switch selectorIndex {
        case SelectorMode.display.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let regToken = regCell.regTokenField!.text
            if regToken == nil || regToken!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a registration token to register a Display Mode device.", buttonTitle: "OK",fromController: self)
                return
            }
            let newCandidate = AylaRegistrationCandidate()
            newCandidate.registrationType = AylaRegistrationType.display
            newCandidate.registrationToken = regToken
            candidateManual = newCandidate
        case SelectorMode.dsn.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let dsn = regCell.dsnField!.text
            if dsn == nil || dsn!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a DSN in order to register a DSN device.", buttonTitle: "OK",fromController: self)
                return
            }
            let deviceDict = ["device":["dsn":dsn!]]
            let newCandidate = AylaRegistrationCandidate(dictionary: deviceDict)
            AylaLogD(tag: logTag, flag: 0, message:"Candidate DSN: \(newCandidate.dsn ?? "nil")")
            newCandidate.registrationType = AylaRegistrationType.dsn
            candidateManual = newCandidate
        case SelectorMode.apMode.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let setupToken = regCell.regTokenField!.text
            if setupToken == nil || setupToken!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide the setup token generated during Wi-Fi Setup in order to register an AP Mode device.", buttonTitle: "OK",fromController: self)
                return
            }
            let dsn = regCell.dsnField!.text
            if dsn == nil || dsn!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a DSN in order to register a DSN device.", buttonTitle: "OK",fromController: self)
                return
            }
            let deviceDict = ["device":["dsn":dsn!]]
            let newCandidate = AylaRegistrationCandidate(dictionary: deviceDict)
            newCandidate.setupToken = setupToken
            AylaLogD(tag: logTag, flag: 0, message:"Candidate setupToken: \(newCandidate.setupToken ?? "nil")")
            newCandidate.registrationType = AylaRegistrationType.apMode
            candidateManual = newCandidate

        case SelectorMode.manual.rawValue:
            let regCell = cell as! RegistrationManualTVCell
            let dsn = regCell.dsnField!.text
            if dsn == nil || dsn!.characters.count < 1 {
                UIAlertController.alert("Error", message: "You must provide a DSN in order to find and register a candidate device this way.", buttonTitle: "OK",fromController: self)
                return
            }
            
            var regToken = regCell.regTokenField!.text
            
            if regToken != nil && regToken!.characters.count < 1 {
                regToken = nil
            }
            
            if let reg = sessionManager?.deviceManager.registration {
                let aGroup = DispatchGroup()
                aGroup.enter()
                reg.fetchCandidate(withDSN: dsn, registrationType: .sameLan, success: { (candidate) in
                    
                    candidate.registrationToken = regToken
                    self.candidateManual = candidate
                    
                    }, failure: { (error) in
                        self.candidateManual = nil;
                        UIAlertController.alert("Error", message: "Could not find a candidate device with that DSN.", buttonTitle: "OK",fromController: self)
                        //Skip 404 for now
                        if let httpResp = (error as NSError).userInfo[AylaHTTPErrorHTTPResponseKey] as? HTTPURLResponse {
                            if(httpResp.statusCode != 404) {
                                self.addLog("SameLan - " + error.description)
                            }
                            else {
                                self.addLog("No Same Lan candidate for this DSN")
                            }
                        }
                        else {
                            self.addLog("SameLan - " + error.description)
                        }
                        aGroup.leave()
                })
                aGroup.notify(queue: DispatchQueue.main, execute: {
                    self.updatePrompt(nil)
                })
            }
        default:
            return
        }
        self.registerAlertForIndexPath(self.tableView.indexPath(for: cell)!)
    }
    // MARK: - CellSelectorDelegate
    func cellSelectorPressed(_ cell: UITableViewCell, control:UISegmentedControl){
        self.selectorIndex = control.selectedSegmentIndex
        self.tableView.reloadRows(at: [IndexPath(row: 1, section: Section.manual.rawValue)], with: .none)
    }
    
    /**
     Call to dismiss keyboard.
     */
    func dismissKeyboard() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.updatePrompt(nil)
        if segue.identifier == segueIdToNodeRegistrationView {
            let vc = segue.destination as! NodeRegistrationViewController
            vc.targetGateway = (sender as! AylaDeviceGateway)
        }
    }
    
    // MARK - device manager listener
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : Error]) {
        AylaLogI(tag: logTag, flag: 0, message:"Init complete")
        self.updateGatewaysList()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitFailure error: Error) {
        AylaLogE(tag: logTag, flag: 0, message:"Failed to init: \(error)")
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didObserve change: AylaDeviceListChange) {
        AylaLogI(tag: logTag, flag: 0, message:"Observe device list change")
        if change.addedItems.count > 0 {
            for device:AylaDevice in change.addedItems {
                device.add(self)
            }
        }
        else {
            // We don't remove self as listener from device manager removed devices.
        }
        
        self.updateGatewaysList()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState) {
        AylaLogD(tag: logTag, flag: 0, message:"Change in deviceManager state: new state \(newState), was \(oldState)")
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        if change.isKind(of: AylaDeviceChange.self) {
            // Not a good long term update strategy
            self.updateGatewaysList()
        }
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
        // Device errors are not handled here.
    }
}
