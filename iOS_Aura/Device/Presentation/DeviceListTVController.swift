//
//  DeviceListTVController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import ActionSheetPicker_3_0
import MBProgressHUD

class DeviceListTVController: UITableViewController, DeviceListViewModelDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    private let logTag = "DeviceListTVController"
    
    /// Id of a segue which is linked to GrillRight device page.
    let segueIdToGrillRight = "GrillRightDeviceSegue"
    
    /// Id of a segue which is linked to device page.
    let segueIdToDevice :String = "toDevicePage"
    
    /// Segue id to property view
    let segueIdToRegisterView :String = "toRegisterPage"
    
    /// Segue id to Shares List view
    let segueIdToSharesView :String = "toSharesPage"
    
    /// The session manager which retains device manager of device list showing on this table view.
    var sessionManager :AylaSessionManager?
    
    /// View model used by view controller to present device list.
    var viewModel : DeviceListViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        sessionManager?.deviceManager.add(self)
        
        if let sessionManager = sessionManager {
            viewModel = DeviceListViewModel(deviceManager: sessionManager.deviceManager, tableView: tableView)
            viewModel?.delegate = self
            if sessionManager.isCachedSession {
                UIAlertController.alert("Offline Mode", message: "Logged in LAN Mode, some features might not be available", buttonTitle: "OK", fromController: self)
            }
        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"device list with a nil session manager")
            // TODO: present a warning and give fresh option
        }
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(initDeviceManager), for: UIControlEvents.valueChanged)
    }

    func initDeviceManager() {
        self.sessionManager?.resume()
    }
    @IBAction func rightBarButtonTapped(_ sender: AnyObject) {
        let setupStoryboard: UIStoryboard = UIStoryboard(name: "GuidedSetup", bundle: nil)
        let setupVC = setupStoryboard.instantiateInitialViewController()
        self.navigationController?.present(setupVC!, animated: true, completion:nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Device list view delegate

    func deviceListViewModel(_ viewModel: DeviceListViewModel, didSelectDevice device: AylaDevice) {
        if device.isKind(of: AylaBLEDevice.self) {
            let localDevice = device as! AylaBLEDevice
            let detailsSegue = localDevice.model == GrillRightDevice.GRILL_RIGHT_MODEL ? self.segueIdToGrillRight : self.segueIdToDevice
            if localDevice.requiresLocalConfiguration {
                let alert = UIAlertController(title: "Configure Local Connection", message: "This device requires additional setup to allow your mobile device to reach it. Would you like to configure this device now?", preferredStyle: .alert)
                let configureDeviceAction = UIAlertAction(title: "Yes", style: .default, handler: { (alert) in
                    
                    let progressView = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
                    progressView.mode = .indeterminate
                    progressView.label.text = "Finding compatible devices"
                    
                    let dismissProgress : (String, String?) -> () = { message, details in
                        progressView.label.text = message
                        progressView.detailsLabel.text = details
                        let deadlineTime = DispatchTime.now() + 3
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            progressView.hide(animated: true)
                        }
                    }
                    
                    if let localDeviceManager = AylaNetworks.shared().getPluginWithId(PLUGIN_ID_LOCAL_DEVICE) as? AylaLocalDeviceManager {
                        localDeviceManager.findLocalDevices(withHint: nil, timeout: 5000, success: { (candidates) in
                            
                            let connectToCandidate: (AylaBLECandidate) -> Void = { candidate in
                                if progressView.isHidden {
                                    progressView.show(animated: false)
                                }
                                
                                progressView.label.text = "Connecting to device..."
                                localDevice.map(toIdentifier: candidate.peripheral.identifier)
                                localDevice.connectLocal(success: {
                                    self.performSegue(withIdentifier: detailsSegue, sender: device)
                                    
                                    dismissProgress("Done", "Your device is now ready to use")
                                    }, failure: { (error) in
                                        dismissProgress("Could not connect to device", "Error: \(error.description)")
                                })
                            }
                            
                            if candidates.count == 0 {
                                dismissProgress("Unable to find this device","Please make sure the device is turned on and you are nearby.")
                            } else if candidates.count == 1 {
                                let candidate = candidates.first! as! AylaBLECandidate
                                progressView.label.text = "Found a device, connecting."
                                connectToCandidate(candidate)
                                
                            } else {
                                progressView.hide(animated: false)
                                let strings = candidates.map({ (candidate) -> String in
                                    let candidate = candidate as! AylaBLECandidate
                                    
                                    return "\(candidate.oemModel ?? "Candidate"): \(candidate.peripheral.identifier.uuidString)"
                                })
                                ActionSheetStringPicker.show(withTitle: "Select the device", rows: strings, initialSelection: 0, doneBlock: { (picker, index, uuidString) in
                                    let candidate = candidates[index]
                                    connectToCandidate(candidate as! AylaBLECandidate)
                                    }, cancel: { _ in }, origin: self.view)
                            }
                            }, failure: { (error) in
                                UIAlertController.alert(nil, message: "Unable to find devices: \(error.localizedDescription).", buttonTitle: "OK", fromController: self)
                        })
                    }
                })
                alert.addAction(configureDeviceAction)
                alert.addAction(UIAlertAction(title: "No, thanks", style: .cancel, handler: { _ in
                    self.performSegue(withIdentifier: detailsSegue, sender: device)
                }))
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            self.performSegue(withIdentifier: detailsSegue, sender: device)
            return
        }
        
        self.performSegue(withIdentifier: segueIdToDevice, sender: device)
    }
    
    func deviceListViewModel(_ viewModel: DeviceListViewModel, didUnregisterDevice device: AylaDevice){
        let deviceViewModel = DeviceViewModel(device: device, panel: nil, propertyListTableView: nil, sharesModel: self.viewModel!.sharesModel)
        deviceViewModel.unregisterDeviceWithConfirmation(self, successHandler: {
            self.tableView.reloadData()
            }, failureHandler: { (error) in
                self.tableView.reloadData()
        })
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdToDevice { // To device page
            if let device = sender as? AylaDevice {
                let vc = segue.destination as! DeviceViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToGrillRight {
            if let device = sender as? GrillRightDevice {
                let vc = segue.destination as! GrillRightViewController
                vc.device = device
                vc.sharesModel = self.viewModel?.sharesModel
            }
        } else if segue.identifier == segueIdToRegisterView { // To registration page
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endRefreshing()
    }
    
    func endRefreshing() {
        guard let isRefreshing = self.refreshControl?.isRefreshing, isRefreshing else {
            return
        }
        self.refreshControl?.endRefreshing()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitFailure error: Error) {
        endRefreshing()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : Error]) {
        endRefreshing()
        self.tableView.reloadData()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState) {
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didObserve change: AylaDeviceListChange) {
        self.tableView.reloadData()
        for deviceObject in deviceManager.devices.values {
            guard let device = deviceObject as? AylaDevice else {
                return
            }
            device.add(self)
        }
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
    }
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
    }
    func device(_ device: AylaDevice, didUpdateLanState isActive: Bool) {
        tableView.reloadData()
    }
}
