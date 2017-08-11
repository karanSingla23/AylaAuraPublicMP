//
//  GuidedSetupEnterPasswordTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/19/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GuidedSetupEnterPasswordTableViewController: UITableViewController, AylaConnectivityListener, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    struct Constants {
        struct Segue {
            static let goToPersonalization = "GoToPersonalizationSegue"
            static let goToResetEVB = "GoToResetEVBSegue"
        }
        struct Strings {
            static let confirmingConnectionStatus = "Confirming the EVB's connection status"
            static let addingDeviceToAccount = "Adding the EVB to your account"
            static let searchingLocalNetwork = "Searching for the EVB on your local network"
            static func connectingEVB(toSSID ssid:String?) -> String {
                return "Connecting EVB to the network: \n\(ssid ?? "Error")"
            }
            
            struct Error {
                static let unknown = "Unknown error"
                static let resourceProblem = "There has been a resource problem, out of memory or buffers, perhaps temporary"
                static let connectionTimedOut = "Connection Timed Out"
                static let invalidWiFi = "Invalid Wi-Fi Key Entered"
                static let ssidNotFound = "SSID not found"
                static let failedToAuthenticate = "Failed to Authenticate"
                static let incorrectWiFi = "Incorrect Wi-Fi Key Entered"
                static let dhcpIp = "Failed to get IP Address from DHCP"
                static let dhcpGW = "Failed to get default gateway from DHCP"
                static let dhcpDNS = "Failed to get DNS server from DHCP"
                static let signalLost = "Signal lost from AP (Beacon miss)"
                static let deviceServiceLookup = "Service host lookup failed"
                static let deviceServiceRedirect = "Service GET was redirected"
                static let deviceServiceTimedOut = "Service connection timed out"
                static let noProfileSlots = "No empty Wi-Fi profile slots"
                static let secNotSupported = "The security method used by the AP is not supported"
                static let netTypeNotSupported = "The network type (e.g. ad-hoc) is not supported."
                static let serverIncompatible = "The server responded in an incompatible way.  The AP may be a Wi-Fi hotspot"
                static let serviceAuthFailure = "Service authentication failed"
                static let disconnectedFromDevice = "Disconnected from Device"
                static func message(withCode code:AylaWifiConnectionError) -> String {
                    return ""
                }
            }
        }
    }
    
    var shouldHideSSIDOptions :Bool = false
    var nonSecureWiFi :Bool = false
    var deviceJustRegistered :Bool = false
    var model: GuidedSetupModel! {
        didSet  {
            shouldHideSSIDOptions = self.model.ssidName != nil
            nonSecureWiFi = self.model.ssidSecurity == "None"
        }
    }
    var setupNavigationController : GuidedSetupNavigationController? {
        get {
            return self.navigationController as? GuidedSetupNavigationController
        }
    }
    
    let securityTypes = ["WPA2 Personal AES",
                         "WPA2 Personal Mixed",
                         "WEP",
                         "None"]
    
    
    @IBOutlet weak var ssid: UITextField!
    @IBOutlet weak var security: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var rememberSettings: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        AylaNetworks.shared().connectivity.add(self)
        self.ssid.delegate = self
        self.password.delegate = self
        
        if shouldHideSSIDOptions {
            headerLabel.text = String(format:"Enter the password for \"%@\":", self.model.ssidName ?? "unknown")
        } else if nonSecureWiFi {
            headerLabel.text = String(format:"Press \"Join\" to connect to \"%@\":", self.model.ssidName ?? "unknown")
        } else {
            headerLabel.text = "Enter the network information."
        }
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        security.inputView = pickerView
        pickerView.selectRow(0, inComponent: 0, animated: false)
        
    }
    
    func connectivity(_ connectivity: AylaConnectivity, didObserveNetworkChange reachabilityStatus: AylaNetworkReachabilityStatus) {
        if !model.isConnectedToDeviceAP && (reachabilityStatus == .reachableViaWiFi || reachabilityStatus == .reachableViaWWAN) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                self.confirmDeviceConnected()
            })
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        // Go back here, not true 'cancel'
        self.navigationController?.popViewController(animated: true)
    }
    
    func registerDevice() {
        self.setupNavigationController?.displayProgressView()
        
        self.model.getDeviceCandidates(successBlock: { (candidate) in
                    self.setupNavigationController?.modalProgress.textLabel.text = Constants.Strings.addingDeviceToAccount
            let setupDevice = self.model.setup.setupDevice
            let regType = setupDevice?.registrationType
            if (regType == .sameLan || regType == .buttonPush) && candidate?.dsn != setupDevice?.dsn {
                let message = "An error has occurred. (DSN of found candidate is mismatched).  This can happen when many new Ayla devices are on the same network. Please try again."
                UIAlertController.alert("Error Adding Device",
                                        message: message,
                                        buttonTitle: "OK",
                                        fromController: self,
                                        okHandler: { (action) in
                                            self.dismiss(animated: false, completion: {
                                                self.goToResetEVB()
                                                return
                                            })
                                            // Todo: add message about power cycling EVB as potential workaround.
                })
            }
            self.model.registerDevice(candidate:candidate, successBlock: {
                self.setupNavigationController?.modalProgress.textLabel.text = "Success!"
                self.deviceJustRegistered = true
                self.setupNavigationController?.hideProgressView(animated: true, completion: {
                    self.goToEVBPersonalization()
                })
                
            }, failure: { (error) in
                self.dismiss(animated: true, completion: {
                    UIAlertController.alert("Error Adding Device", message: error.aylaServiceDescription, buttonTitle: "OK", fromController: self)
                })
                self.goToResetEVB()
            })

        }) { (error) in
            let errorMessage = "Failed to register your device.\n\nError: \(error.aylaServiceDescription)"
            UIAlertController.alert("Error Adding Device",
                                    message: errorMessage,
                                    okayButtonTitle: "Retry",
                                    cancelButtonTitle: "Cancel",
                                    fromController: self,
                                    okHandler: { (action) in
                                        self.registerDevice()
            },
                                    cancelHandler: { (action) in
                                        self.dismiss(animated: false, completion: {
                                            self.goToResetEVB()
                                            return
                                        })
            })        }

           }
    
    func confirmDeviceConnected() {
        self.setupNavigationController?.displayProgressView()
        self.setupNavigationController?.modalProgress.textLabel.text = Constants.Strings.confirmingConnectionStatus
        self.model.confirmConnection(successBlock: {
            var requiresSameLAN = true
            var supportedRegType = false
            
            guard let regType = self.model.setup.setupDevice?.registrationType else {
                self.setupNavigationController?.hideProgressView(animated:false, completion: {
                    self.dismiss(animated: true, completion: {
                        //TODO: display success message?
                    })
                })
                return
            }
            
            switch regType {
            case .apMode, .dsn:
                requiresSameLAN = false
                supportedRegType = true
            case .buttonPush, .sameLan:
                requiresSameLAN = true
                supportedRegType = true
            default:
                break
            }
            
            if !supportedRegType {
                self.setupNavigationController?.hideProgressView(animated:false, completion: {
               
                    UIAlertController.alert("Error",
                                            message: "Your EVB is set to use a registration type not currently supported within this flow.\n\nPlease check the device settings on the cloud and try again, or used the advanced setup.",
                                            buttonTitle: "OK",
                                            fromController: self,
                                            okHandler: { (action) in
                                                self.dismiss(animated: true, completion: nil)
                    })
                })
            }
            
            guard let isAlreadyRegistered = self.model.isDeviceAlreadyRegistered else {
                self.setupNavigationController?.hideProgressView(animated:false, completion: {
                    // no session is found (wifi setup without login?)
                    self.dismiss(animated: true, completion: {
                        //TODO: display success message?
                    })
                })
                return
            }
            
            if isAlreadyRegistered {
                self.setupNavigationController?.hideProgressView(animated: true, completion: {
                    self.goToEVBPersonalization()
                })
                return
            }
            
            // AP Mode and DSN type can proceed without being on the Same LAN
            if self.model.isConnectedToSameLan || !requiresSameLAN {
                if !requiresSameLAN && !self.model.isConnectedToSameLan {
                    //Display alert indicating device is connected to a different network
                    let message = "You are not on the same Wi-Fi network (\(self.model.ssidName ?? "unknown")) as your device, but the device can be registered anyway."
                    
                    self.setupNavigationController?.hideProgressView(animated: true, completion: {
                        UIAlertController.alert("Caution",
                                                message: message,
                                                okayButtonTitle: "Register",
                                                cancelButtonTitle: "Start Over",
                                                fromController: self,
                                                okHandler: { (action) in
                                                    self.dismiss(animated: false, completion: {
                                                        self.registerDevice()
                                                        return
                                                    })
                        },
                                                cancelHandler: { (action) in
                                                    self.dismiss(animated: false, completion: {
                                                        self.goToResetEVB()
                                                        return
                                                    })
                        })
                    })
                } else {
                    if requiresSameLAN {
                        self.setupNavigationController?.modalProgress.textLabel.text = Constants.Strings.searchingLocalNetwork
                    }
                    self.registerDevice()
                    return
                }

            } else {
                
                //Display error indicating device is connected to a different network
                let differentLANAlert = UIAlertController(title: "Cannot Add Device", message: "The device's registration type requires that you be connected to the same Wi-Fi network as the device (\(self.model.ssidName ?? "unknown")).\n\nYour current network is \"\(AylaNetworkInformation.ssid() ?? "unknown")\" You may wish to change your device settings, then return to Aura.", preferredStyle: .alert)
                differentLANAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                self.goToResetEVB()
                }))
                differentLANAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { (alert) in
                    self.dismiss(animated: false, completion: {
                        goToWiFiSettings()
                    })
                }))
                self.setupNavigationController?.hideProgressView(animated: true, completion: {
                    self.present(differentLANAlert, animated: true, completion: nil)
                })
            }

        }, failure: { (error) in
            
            self.setupNavigationController?.hideProgressView(animated:false, completion: {
                
                if !self.model.isConnectedToDeviceAP {
                    
                    let failedConfirmationAlert = UIAlertController(title: "Error confirming connection", message: "Please make sure you're connected to the internet and return here to try again", preferredStyle: .alert)
                    failedConfirmationAlert.addAction(UIAlertAction(title: "Exit Setup", style: .default, handler: { (alert) in
                        self.dismiss(animated: true, completion: nil)
                    }))
                    
                    if let selectedInsecureWiFi = self.model.selectedInsecureWiFi, selectedInsecureWiFi {
                        failedConfirmationAlert.addAction(UIAlertAction(title: "Go to settings", style: .default, handler: { (alert) in
                            goToWiFiSettings()
                        }))
                    } else {
                        failedConfirmationAlert.addAction(UIAlertAction(title: "Start over", style: .default, handler: { (alert) in
                            self.goToResetEVB()
                        }))
                    }
                    
                    self.present(failedConfirmationAlert, animated: true, completion: nil)
                } else {
                    UIAlertController.alert("Error confirming connection", message: String(describing: error), buttonTitle: "OK", fromController: self)
                }
            })
        })
    }
    
    func goToEVBPersonalization() {
        performSegue(withIdentifier: Constants.Segue.goToPersonalization, sender: nil)
    }
    
    func goToResetEVB(){
        self.performSegue(withIdentifier: Constants.Segue.goToResetEVB, sender: nil)
    }
    
    @IBAction func joinNetwork(_ sender: Any) {
        join()
    }
    
    func join() {
        self.setupNavigationController?.displayProgressView()
        self.setupNavigationController?.modalProgress.textLabel.text = Constants.Strings.connectingEVB(toSSID: self.model.ssidName)
        self.model.connectDevice(successBlock: {
            self.confirmDeviceConnected()
        }) { (error) in
            var errorTitle = "Error connecting device"
            var message = Constants.Strings.Error.unknown
            var goToResetEVB = false
            if let guidedSetupError = error as? GuidedSetupModel.GuidedSetupModelError {
                switch guidedSetupError {
                case .invalidParameters(let parameter, let description):
                    message = "\(parameter) \(description)"
                }
            } else if let errorCode = AylaWifiConnectionError(rawValue: UInt16(error.aylaResponseErrorCode)), errorCode != AylaWifiConnectionError.noError {
                
                switch errorCode {
                case .resourceProblem:
                    message = Constants.Strings.Error.resourceProblem
                case .connectionTimedOut:
                    message = Constants.Strings.Error.connectionTimedOut
                case .invalidKey:
                    message = Constants.Strings.Error.invalidWiFi
                case .ssidNotFound:
                    message = Constants.Strings.Error.ssidNotFound
                case .notAuthenticated:
                    message = Constants.Strings.Error.failedToAuthenticate
                case .incorrectKey:
                    message = Constants.Strings.Error.incorrectWiFi
                case .DHCP_IP:
                    message = Constants.Strings.Error.dhcpIp
                case .DHCP_GW:
                    message = Constants.Strings.Error.dhcpGW
                case .DHCP_DNS:
                    message = Constants.Strings.Error.dhcpDNS
                case .disconnected:
                    message = Constants.Strings.Error.disconnectedFromDevice
                    goToResetEVB = true
                case .signalLost:
                    message = Constants.Strings.Error.signalLost
                case .deviceServiceLookup:
                    message = Constants.Strings.Error.deviceServiceLookup
                case .deviceServiceRedirect:
                    message = Constants.Strings.Error.deviceServiceRedirect
                case .deviceServiceTimedOut:
                    message = Constants.Strings.Error.deviceServiceTimedOut
                case .noProfileSlots:
                    message = Constants.Strings.Error.noProfileSlots
                case .secNotSupported:
                    message = Constants.Strings.Error.secNotSupported
                case .netTypeNotSupported:
                    message = Constants.Strings.Error.netTypeNotSupported
                case .serverIncompatible:
                    message = Constants.Strings.Error.serverIncompatible
                case .serviceAuthFailure:
                    message = Constants.Strings.Error.serviceAuthFailure
                    
                default:
                    errorTitle = "AylaWifiConnectionError Code \(errorCode.rawValue)"
                    message = Constants.Strings.Error.message(withCode: errorCode)
                }
            } else {
                switch error.errorCode {
                case AylaRequestErrorCode.timedOut.rawValue:
                    if !self.model.isConnectedToDeviceAP {
                        message = Constants.Strings.Error.disconnectedFromDevice
                        goToResetEVB = true
                    } else {
                        message = Constants.Strings.Error.connectionTimedOut
                    }
                default:
                    goToResetEVB = true
                }
            }
            self.setupNavigationController?.hideProgressView(animated: true, completion: {
                if goToResetEVB {
                    self.goToResetEVB()
                }
                UIAlertController.alert(errorTitle, message: message, buttonTitle: "OK", fromController: self)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let nameCell: Bool = indexPath.section == 0
        let securityCell: Bool = indexPath.section == 1 && indexPath.row == 0
        let passwordCell: Bool = indexPath.section == 1 && indexPath.row == 1
        let saveWifiSection: Bool = indexPath.section == 2
        
        if  (nameCell || securityCell) && shouldHideSSIDOptions {
            // Hide ssid name and security type selection (only password visible)
            return 0.0
        }
        if passwordCell && nonSecureWiFi {
            // Hide password when using an unsecured network
            return 0.0
        }
        // Selecting an unsecured network from previous screen results in only the 'save wi-fi' options, when available.
        if saveWifiSection { // Save Wi-Fi UI is disabled for now.
            return 0.0
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect.zero)
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        if nonSecureWiFi && section == 1 {
            return 0
        }
        return 26.0
        //return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    @IBAction func passwordDidChange(_ sender: Any) {
        self.model.ssidPassword = password.text
    }

    @IBAction func rememberWiFiSettingsDidChange(_ sender: Any) {
        self.model.saveWiFiSetting = rememberSettings.isOn
    }
    
    @IBAction func nameDidChange(_ sender: Any) {
        self.model.ssidName = ssid.text
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return securityTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return securityTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateTextField(withSecurityTypeAtRow: row)
    }
    
    @IBAction func showPasswordButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        password.isSecureTextEntry = !password.isSecureTextEntry
    }
    
    func updateTextField(withSecurityTypeAtRow row:Int) {
        let securityType = String(securityTypes[row])
        self.model.ssidSecurity = securityType
        self.security.text = securityType
    }
    
    // MARK - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.ssid {
            self.password.becomeFirstResponder()
            return true
        } else if textField == self.password && self.password.text != "" {
            self.join()
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? GuidedSetupPersonalizeViewController,
            let segueIdentifier = segue.identifier,
            segueIdentifier.compare(Constants.Segue.goToPersonalization) ==  .orderedSame else {
            return
        }
        destination.model = model
        destination.deviceJustRegistered = deviceJustRegistered
    }
    
}
