//
//  DeviceViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceViewController: UIViewController, PropertyListViewModelDelegate, PropertyModelDelegate, DeviceSharesModelDelegate, TimeZonePickerViewControllerDelegate {
    private let logTag = "DeviceViewController"
    @IBOutlet weak var panelView: DevicePanelView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notificationsButton: AuraButton!
    @IBOutlet weak var schedulesButton: AuraButton!
    @IBOutlet weak var extraInfoButton: AuraButton!
    /// Segue id to property view
    let segueIdToPropertyView: String = "toPropertyView"
    
    /// Segue id to test view
    let segueIdToLanTestView: String = "toLanModeTest"
    
    /// Segue id to test view
    let segueIdToNetworkProfilerView: String = "toNetworkProfiler"
    
    /// Segue id to schedules view
    let segueIdToSchedules: String = "toSchedules"

    /// Segue id to notifications view
    let segueIdToNotifications: String = "toNotifications"

    /// Segue id to time zone picker
    let segueIdToTimeZonePicker = "toTimeZonePicker"
    
    /// Segue id to LAN OTA
    let segueIdToLANOTA = "toLANOTA"
    
    /// Segue id to device details
    let toDeviceDetails = "toDeviceDetails"
    
    /// Device which is represented on this device view.
    var device :AylaDevice?
    
    /// Device model used by view controller to present this device.
    var deviceViewModel :DeviceViewModel?
    
    var sharesModel: DeviceSharesModel?
    
    var nameTextField :UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let device = self.device {
            // Allocate a device view model to handle UX of panel view and table view.
            deviceViewModel = DeviceViewModel(device: device, panel: panelView, propertyListTableView: tableView, sharesModel:sharesModel)
            deviceViewModel?.propertyListViewModel?.delegate = self
            
            let options = UIBarButtonItem(image:UIImage(named:"ic_gear"), style: .plain, target: self, action: #selector(DeviceViewController.showOptions))
            sharesModel?.delegate = self
            
            let rename = UIBarButtonItem(image:UIImage(named:"ic_edit"), style: .plain, target: self, action: #selector(DeviceViewController.rename))
            let details = UIBarButtonItem(image:UIImage(named:"ic_info_outline"), style: .plain, target: self, action: #selector(DeviceViewController.showDeviceDetails))
            
            self.navigationItem.rightBarButtonItems = [options, details, rename]
        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"a device view with no device")
        }
        
        // Only present Notifications if we have at least one contact and the device has at least one property
        let contacts = ContactManager.sharedInstance.contacts ?? []
        let managedProperties = device?.managedPropertyNames() ?? []
        
        if contacts.isEmpty || managedProperties.isEmpty {
            notificationsButton.isEnabled = false
        }
        
        if let localDevice = device as? AylaLocalDevice {
            notificationsButton.isEnabled = true
            schedulesButton.isEnabled = true
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.deviceViewModel!.update()
    }
    
    @IBAction func fetchAllPropertiesAction(_ sender: AnyObject) {
        let _ = self.device?.fetchPropertiesCloud(nil, success: { (properties) in
            AylaLogI(tag: self.logTag, flag: 0, message:"Fetched properties")
            }, failure: { (error) in
                UIAlertController.alert("Error", message: "Failed to fetch all properties", buttonTitle: "OK", fromController: self)
        })
    }
    
    func showDeviceDetails() {
        performSegue(withIdentifier: toDeviceDetails, sender: nil)
    }
    
    func rename() {
        deviceViewModel?.renameDevice(self, successHandler: nil, failureHandler: nil)
    }
    
    func unregister() {
        deviceViewModel?.unregisterDeviceWithConfirmation(self, successHandler: { Void in
            let _ = self.navigationController?.popViewController(animated: true)
            }, failureHandler: { (error) in

        })
    }
    
    @IBAction func shareDevice() {
        deviceViewModel?.shareDevice(self, successHandler: { (share) in
            }, failureHandler: { (error) in
                
        })
    }
    
    func changeTimeZone() {
        let _ = self.device?.fetchTimeZone(success: { (timeZone) in
            self.performSegue(withIdentifier: self.segueIdToTimeZonePicker, sender: timeZone.tzID)
            }, failure: { (error) in
                let alert = UIAlertController(title: "Failed to fetch Time Zone", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler:nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
        })
    }
    
    @IBAction func notifications() {
        
        self.performSegue(withIdentifier: self.segueIdToNotifications, sender: nil)
    }
    
    @IBAction func schedules() {
        self.performSegue(withIdentifier: self.segueIdToSchedules, sender: nil)
    }
    
    func factoryReset() {
//        self.device?.factoryReset(success: {
//            UIAlertController.alert("Success!", message: "Factory reset was sent", buttonTitle: "OK", fromController: self)
//        }, failure: { (error) in
//            UIAlertController.alert("Failed to reset device", message: error.localizedDescription, buttonTitle: "OK", fromController: self)
//        })
    }
    
    // MARK: - Options
    
    func showOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let fetchAllProperties = UIAlertAction(title: "Fetch All Properties", style: .default) { (action) in
            self.fetchAllPropertiesAction(action)
        }
        let testRunner = UIAlertAction(title: "Run device tests...", style: .default) { (action) in
            self.performSegue(withIdentifier: self.segueIdToLanTestView, sender: nil)
        }
        
        let networkProfiler = UIAlertAction(title: "Network Profiler", style: .default) { (action) in
            self.performSegue(withIdentifier: self.segueIdToNetworkProfilerView, sender: nil)
        }
        
        let timeZone = UIAlertAction(title: "TimeZone", style: .default) { (action) in
            self.changeTimeZone()
        }
        
        let unregister = UIAlertAction(title: "Unregister Device", style: .destructive) { (action) in
            self.unregister()
        }
        
        let factoryReset = UIAlertAction(title: "Factory Reset", style: .destructive) { (action) in
            self.factoryReset()
        }
        let ota = UIAlertAction(title: "LAN OTA", style: .default) { (action) in
            // Swith to LAN OTA page
            self.performSegue(withIdentifier: self.segueIdToLANOTA, sender: self.device)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in }
        
        alert.addAction(fetchAllProperties)
        alert.addAction(testRunner)
        alert.addAction(networkProfiler)
        alert.addAction(timeZone)
        alert.addAction(unregister)
        alert.addAction(factoryReset)
        alert.addAction(ota)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - DeviceSharesModelDelegate
    
    func deviceSharesModel(_ model: DeviceSharesModel, ownedSharesListDidUpdate: ((_ shares: [AylaShare]) -> Void)?) {
        self.deviceViewModel?.update()
    }
    
    func deviceSharesModel(_ model: DeviceSharesModel, receivedSharesListDidUpdate: ((_ shares: [AylaShare]) -> Void)?) {
        self.deviceViewModel?.update()
    }
    
    // MARK: - PropertyListViewModelDelegate
    
    func propertyListViewModel(_ viewModel: PropertyListViewModel, didSelectProperty property: AylaProperty, assignedPropertyModel propertyModel: PropertyModel) {
        propertyModel.delegate = self
        propertyModel.presentActions(presentingViewController: self);
    }
    
    func propertyListViewModel(_ viewModel:PropertyListViewModel, displayPropertyDetails property:AylaProperty, assignedPropertyModel propertyModel:PropertyModel){
        propertyModel.delegate = self
        propertyModel.chosenAction(PropertyModelAction.details)
    }

    // MARK: - PropertyModelDelegate
    
    func propertyModel(_ model: PropertyModel, didSelectAction action: PropertyModelAction) {
        switch (action) {
        case .details:
            self.performSegue(withIdentifier: segueIdToPropertyView, sender: model)
            break
        }
    }
    
    // MARK: - TimeZonePickerViewControllerDelegate
    
    func timeZonePickerDidCancel(_ picker: TimeZonePickerViewController)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func timeZonePicker(_ picker: TimeZonePickerViewController, didSelectTimeZoneID timeZoneID:String) {
        let _ = self.device?.updateTimeZone(to: timeZoneID,
                                      success: { (timeZone) in
                                        self.deviceViewModel?.update()
            },
                                      failure: { (error) in
                                        let alert = UIAlertController(title: "Failed to save Time Zone", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                                        let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler:nil)
                                        alert.addAction(okAction)
                                        self.present(alert, animated: true, completion: nil)
        })
        
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdToPropertyView {
            let vc = segue.destination as! PropertyViewController
            vc.propertyModel = sender as? PropertyModel
        }
        else if segue.identifier == segueIdToLanTestView {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.viewControllers[0] as! TestPanelViewController
            vc.testModel = LanModeTestModel(testPanelVC: vc, deviceManager: device?.deviceManager, device: device)
        }
        else if segue.identifier ==  segueIdToNetworkProfilerView {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.viewControllers[0] as! TestPanelViewController
            vc.testModel = NetworkProfilerModel(testPanelVC: vc, device: device)
        }
        else if segue.identifier == segueIdToSchedules {
            let vc = segue.destination as! ScheduleTableViewController
            vc.device = device
        }
        else if segue.identifier == segueIdToNotifications {
            let vc = segue.destination as! NotificationsViewController
            vc.device = device
        }
        else if segue.identifier == segueIdToTimeZonePicker {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.viewControllers[0] as! TimeZonePickerViewController
            vc.timeZoneID = sender as? String
            vc.delegate = self
        }
        else if segue.identifier == segueIdToLANOTA {
            if let device = sender as? AylaDevice, let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName), let dsn = device.dsn, let lanIp = device.lanIp {
                let otaDevice = AylaLANOTADevice(sessionManager: sessionManager, dsn: dsn, lanIP: lanIp)
                let vc = segue.destination as! LANOTAViewController
                vc.device = otaDevice
            }
        } else if segue.identifier == toDeviceDetails {
            guard let destinationController = segue.destination as? DeviceDetailsTableViewController else {
                return
            }
            destinationController.device = device
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
