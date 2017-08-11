//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import PDKeychainBindingsController
import iOS_AylaSDK

class SetupViewControllerOld: UIViewController, UITableViewDelegate, UITableViewDataSource, AylaDeviceWifiStateChangeListener {
    private let logTag = "SetupViewController"
    /// Setup cell id
    fileprivate static let CellId: String = "SetupCellId"
    
    /// Description view to display status
    @IBOutlet fileprivate weak var consoleView: AuraConsoleTextView!
    
    /// Table view of scan results
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    /// A reserved view for future use.
    @IBOutlet fileprivate weak var controlPanel: UIView!
    
    /// AylaSetup instance used by this setup view controller
    fileprivate var setup: AylaSetup
    
    /// Current presenting alert controller
    fileprivate var alert: UIAlertController? {
        willSet(newAlert) {
            if let oldAlert = alert {
                // If there is an alert presenting to user. dimiss it first.
                oldAlert.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    /// Wi-Fi 'state' as provided by the device being set up.
    fileprivate var moduleWiFiState: String! = "none" {
        willSet(newState){
            if newState != nil && newState != moduleWiFiState {
                let prompt = "Module Reported WiFi State: '\(newState!)'"
                addDescription(prompt)
            }
        }
    }
    
    /// Current running connect task
    fileprivate var currentTask: AylaConnectTask?
    
    /// Scan results which are presented in table view
    fileprivate var scanResults :AylaWifiScanResults?
    
    /// Last used token.
    fileprivate var token: String?
    
    /// Default timeout for device cloud connection polling
    fileprivate let defaultCloudConfirmationTimeout = 60.0
    
    
    required init?(coder aDecoder: NSCoder){
        // Init setup
        setup = AylaSetup(sdkRoot: AylaNetworks.shared())
        
        super.init(coder: aDecoder)
        
        //register as WiFi State listener
        setup.addWiFiStateListener(self)
        
        // Monitor connectivity
        monitorDeviceConnectivity()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // Init setup
        setup = AylaSetup(sdkRoot: AylaNetworks.shared())
    
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
        
        // Monitor connectivity
        monitorDeviceConnectivity()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign self as delegate and data source of tableview.
        tableView.delegate = self
        tableView.dataSource = self
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem:.refresh, target: self, action: #selector(refresh))
        navigationItem.rightBarButtonItem = refreshButton
        
        if sideMenuController == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        }
        attemptToConnect()
    }
    
    fileprivate func updatePrompt(_ prompt: String?) {
        navigationController?.navigationBar.topItem?.prompt = prompt
    }
    
    /**
     Monitor device connectivity by adding KVO to property `connected` of setup device.
     */
    fileprivate func monitorDeviceConnectivity() {
        // Add observer to setup device connection status.
        setup.addObserver(self, forKeyPath: "setupDevice.connected", options: .new, context: nil)
    }
    
    /**
     Use this method to connect to device again.
     */
    @objc fileprivate func refresh() {
        // Clean scan results
        scanResults = nil
        tableView.reloadData()
        
        attemptToConnect()
    }
    
    /**
     Writes the setupDevice's registrationType string to the consoleView
     */
    fileprivate func logRegistrationTypeForSetupDevice(_ setupDevice:AylaSetupDevice){
        let registrationType = AylaRegistration.registrationName(from: setupDevice.registrationType)
        addDescription("Device will use \(registrationType ?? "nil") Registration Type.")

    }
    
    /**
     Writes the setupDevice's details to the consoleView
     */
    fileprivate func logDetailsForSetupDevice(_ setupDevice:AylaSetupDevice){
        let indent = "    "
        self.addDescription("Device Details:")
        addDescription(indent + "DSN: \(setupDevice.dsn )")
        addDescription(indent + "FW version: \(setupDevice.version ?? "none")")
        addDescription(indent + "FW build: \(setupDevice.build ?? "none")")
        addDescription(indent + "LAN IP: \(setupDevice.lanIp )")
        addDescription(indent + "MAC: \(setupDevice.mac ?? "none")")
        addDescription(indent + "Model: \(setupDevice.model )")

        if let features = setupDevice.features {
            addDescription(indent + "Features:")
            for feature in features {
                addDescription(indent + indent + "\(feature)")
            }
        }
    }
    
    /**
     Must use this method to start setup for a device.
     */
    fileprivate func attemptToConnect() {

        updatePrompt("Connecting...")
        addDescription("Looking for a device to set up.")
        setup.connect(toNewDevice: { (setupDevice) -> Void in
            self.addDescription("Found Device")
            self.logDetailsForSetupDevice(setupDevice)
            
            // Start fetching AP list from module.
            self.fetchFreshAPListWithWiFiScan()
            
            }) { (error) -> Void in
                self.updatePrompt("")
                self.addDescription("Unable to find device: \(error.aylaServiceDescription ?? "unknown error")")
                let message = "Are you connected to the Wi-Fi access point of the device you wish to set up?\n\nIf not, please tap the button below to move to the Settings application.  Navigate to Wi-Fi settings section and select the AP/network name for your device.\n\nOnce the network is joined, you should be redirected here momentarily."
                let alert = UIAlertController(title: "No Device Found", message: message, preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Go To Settings App", style:.default, handler: { (action) in
                    if self.sideMenuController == nil {
                        self.dismiss(animated: false, completion: {})
                    }
                    
                    UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
                })
                let cancelAction = UIAlertAction(title: "Cancel", style:.cancel, handler: { (action) in
                    self.updatePrompt("No Device Found")
                })
                alert.addAction(settingsAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: {})
        }
    }

    /**
     * Use this method to have the module scan for Wi-Fi access points, then fetch the resulting AP list from setup.
     */
    fileprivate func fetchFreshAPListWithWiFiScan() {
        addDescription("Device is scanning for Wi-Fi Access Points...")
        currentTask = setup.startDeviceScan(forAccessPoints: {
            self.addDescription("Scan Complete. Fetching results.")
            self.fetchCurrentAPList()
            }) { (error) in
                let message = "Wi-Fi Scan Failed"
                self.updatePrompt(message)
                self.displayError(error as NSError, message: message)
        }
    }
    
    /**
     * Use this method to have the setup device scan for Wi-Fi access points.
     */
    fileprivate func fetchCurrentAPList(){
        currentTask = setup.fetchDeviceAccessPoints({ (scanResults) -> Void in
            self.addDescription("Received AP list.")
            self.updatePrompt(self.setup.setupDevice?.dsn ?? "")
            self.scanResults = scanResults
            self.tableView.reloadData()
            
            }, failure: { (error) -> Void in
                self.updatePrompt("Error")
                let message = "An error occurred while trying to fetch the Wi-Fi scan results."
                self.displayError(error as NSError, message: message)
        })

    }
    
    /**
     Use this method to connect device to the input SSID
     
     - parameter ssid:     The ssid which device would connect to.
     - parameter password: Password of the ssid.
     */
    fileprivate func connectToSSID(_ ssid: String, password: String?) {
    
        token = String.generateRandomAlphanumericToken(7)
        
        updatePrompt("Connecting device to '\(ssid)'...")
        addDescription("Connecting device to the network '\(ssid)'...")

        let tokenString = String(format:"Using Setup Token %@.", token!)
        addDescription(tokenString)
        setup.connectDeviceToService(withSSID: ssid, password: password, setupToken: token!, latitude: 0.0, longitude: 0.0, success: { (wifiStatus) -> Void in
            WiFiSetupHelper.shared.recordConfigurationSent(toDevice: self.setup.setupDevice, withSSID: ssid)
            // Succeeded, go confirming.
            self.addDescription("Device reports connection to SSID.")
            // Call to confirm connection.
            self.confirmConnectionToService()
            
            }) { (error) -> Void in
                var message = "Unknown error"
                
                if let errorCode = AylaWifiConnectionError(rawValue: UInt16(error.aylaResponseErrorCode)) {
                    
                    switch errorCode {
                    case .connectionTimedOut:
                        message += "Connection Timed Out"
                    case .invalidKey:
                        message += "Invalid Wi-Fi Key Entered"
                    case .notAuthenticated:
                        message += "Failed to Authenticate"
                    case .incorrectKey:
                        message += "Incorrect Wi-Fi Key Entered"
                    case .disconnected:
                        message += "Disconnected from Device"
                    default:
                        message += "AylaWifiConnectionError Code \(errorCode.rawValue)"
                    }
                }
                self.updatePrompt("Setup Failed")
                self.displayError(error as NSError, message: message)
        }
    }
    
    /**
     Use this method to confirm device connnection status with cloud service.
     */
    fileprivate func confirmConnectionToService() {
        func storeDeviceDetailsInKeychain(){
            // Store device info in keychain for use during a later registration attempt.
            PDKeychainBindings.shared().setString(self.token, forKey: AuraDeviceSetupTokenKeychainKey)
            PDKeychainBindings.shared().setString(self.setup.setupDevice?.dsn, forKey: AuraDeviceSetupDSNKeychainKey)
        }
        
        updatePrompt("Confirming device connection status ...")
        addDescription("Polling cloud service to confirm device connection.\n Timeout set to \(Int(defaultCloudConfirmationTimeout)) seconds. Please wait...")
        let deviceDSN = setup.setupDevice?.dsn
        
        setup.confirmDeviceConnected(withTimeout: defaultCloudConfirmationTimeout, dsn:(deviceDSN)!, setupToken:token!, success: { (setupDevice) -> Void in
                self.logRegistrationTypeForSetupDevice(setupDevice)
                self.updatePrompt("- Succeeded -")
                self.addDescription("- Wi-Fi Setup Complete -")

                let alertString = String(format:"Setup for device %@ completed successfully, using the setup token %@.\n\n You may wish to store this token if the device uses AP Mode registration.", (self.setup.setupDevice?.dsn)!, self.token!)

                let alert = UIAlertController(title: "Setup Successful", message: alertString, preferredStyle: .alert)
                let copyAction = UIAlertAction(title: "Copy Token to Clipboard", style: .default, handler: { (action) -> Void in
                    UIPasteboard.general.string = self.token!
                    storeDeviceDetailsInKeychain()
                })
                let cancelAction = UIAlertAction(title: "No, Thanks", style: .cancel, handler: { (action) -> Void in
                    storeDeviceDetailsInKeychain()
                })
                if let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
                    var deviceAlreadyRegistered = false
                    let devices = sessionManager.deviceManager.devices.values.map({ (device) -> AylaDevice in
                        return device as! AylaDevice
                    })
                    for device in devices {
                        if device.dsn == deviceDSN {
                            deviceAlreadyRegistered = true
                            self.addDescription("FYI, Device appears to be registered or shared to you already.");
                        }
                    }
                    
                    if deviceAlreadyRegistered == false {
                        let registerNowAction = UIAlertAction(title: "Register Device Now", style: .default, handler: { (action) -> Void in
                            storeDeviceDetailsInKeychain()
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let regVC = storyboard.instantiateViewController(withIdentifier: "registrationController")
                                self.navigationController?.pushViewController(regVC, animated: true)
                        })
                        alert.addAction(registerNowAction)
                    }
                }
                
                alert.addAction(copyAction)
                alert.addAction(cancelAction)

                self.present(alert, animated: true, completion: nil)

                // Clean scan results
                self.scanResults = nil
                self.tableView.reloadData()
            
            }) { (error) -> Void in
                let message = "Confirmation step has failed."
                self.displayError(error as NSError, message: message)
        }
    }
    
    /**
     Use this method to add a description to description text view.
     */
    fileprivate func addDescription(_ description: String) {
        consoleView.addLogLine(description)
        AylaLogD(tag: logTag, flag: 0, message:"Log: \(description)")
    }
    
    /**
     Display an error with UIAlertController
     
     - parameter error: The error which is going to be displayed.
     - parameter message: Message to be displayed along with error.
     */
    fileprivate func displayError(_ error:NSError, message: String?) {
        
        if let currentAlert = alert {
            currentAlert.dismiss(animated: false, completion: nil)
        }
        let serviceDescription = error.aylaServiceDescription
        var errorText = ""
        if let message = message {
            errorText = message + "\n\nAylaError: '" + serviceDescription! + "'"
        }
        
        let alertController = UIAlertController(title: "Error", message: errorText, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Got it", style: .cancel, handler: nil))
        alert = alertController
        self.present(alertController, animated: true, completion: nil)
        addDescription("Error: \(message ?? "")\n    '\(serviceDescription ?? "nil")'")
    }
    
    @IBAction fileprivate func cancel(_ sender: AnyObject) {
        dismiss(animated: true) { () -> Void in
            self.setup.exit()
        }
    }
    
    deinit {
        setup.removeObserver(self, forKeyPath: "setupDevice.connected")
        setup.removeWiFiStateListener(self)
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        if let result = scanResults?.results[indexPath.row] {
            
            // Compose an alert controller to let user input password.
            // TODO: If password is not required, the password text field should be removed from alert.
            let alertController = UIAlertController(title: "Password Required", message: "Please input password for the network \"\(result.ssid!)\".", preferredStyle: .alert)
            
            let connect = UIAlertAction(title: "Connect", style: .default) { (_) in
                let password = alertController.textFields![0] as UITextField
                self.connectToSSID(result.ssid, password: password.text)
            }
            connect.isEnabled = false
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                let password = alertController.textFields![0] as UITextField
                password.resignFirstResponder()
            }
            
            alertController.addTextField { (textField) in
                textField.placeholder = "SSID password"
                NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                    connect.isEnabled = textField.text != ""
                }
            }
            alertController.addAction(connect)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
            
            // Call to wake up main run loop
            CFRunLoopWakeUp(CFRunLoopGetCurrent());
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if let result = scanResults?.results[indexPath.row] {
            let connectAction = UITableViewRowAction(style: .normal, title:"\(result.signal)" ) { (rowAction:UITableViewRowAction, indexPath:IndexPath) -> Void in
                // Edit actions, empty for now.
            }
            connectAction.backgroundColor = UIColor.darkGray
            
            return [connectAction]
        }
        
        return nil
    }
    
    // MARK: - Table view datasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let results = scanResults?.results as [AylaWifiScanResult]!
            
        let result = results?[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SetupViewControllerOld.CellId)
            
        cell?.textLabel!.text = (result?.ssid)! + "\n    \((result?.security)!),  Signal: \((result?.signal)!) dBm"
        cell!.selectionStyle = UITableViewCellSelectionStyle.none
            
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanResults?.results.count ?? 0
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if object as? AylaSetupDevice === setup.setupDevice {
            if let device = object as? AylaSetupDevice {
                if !device.connected {
                    updatePrompt("Lost Connectivity To Device")
                }
            }
        }
    }
    
    func wifiStateDidChange(_ state: String) {
        moduleWiFiState = state
    }

}
