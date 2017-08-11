//
//  DeviceListViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

protocol DeviceListViewModelDelegate: class {
    func deviceListViewModel(_ viewModel:DeviceListViewModel, didSelectDevice device:AylaDevice)
    func deviceListViewModel(_ viewModel:DeviceListViewModel, didUnregisterDevice device:AylaDevice)
}

class DeviceListViewModel:NSObject, UITableViewDataSource, UITableViewDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    private let logTag = "DeviceListViewModel"
    /// Device manager where deivce list belongs
    let deviceManager: AylaDeviceManager
    
    /// Table view of devices
    var tableView: UITableView
    
    /// Devices which are being represented in table view.
    var devices : [ AylaDevice ]
    
    var sharesModel : DeviceSharesModel?

    weak var delegate: DeviceListViewModelDelegate?
    
    static let DeviceCellId: String = "DeviceCellId"
    static let LocalDeviceCellId: String = "LocalDeviceCellId";
    
    required init(deviceManager: AylaDeviceManager, tableView: UITableView) {
        
        self.deviceManager = deviceManager
        
        // Init device list as empty
        self.devices = []
        
        self.tableView = tableView

        super.init()
        self.sharesModel = DeviceSharesModel(deviceManager: deviceManager)
        
        // Add self as device manager listener
        deviceManager.add(self)
        
        // Add self as delegate and datasource of input table view.
        tableView.dataSource = self
        tableView.delegate = self
        
        // Update device list with device manager.
        self.updateDeviceListFromDeviceManager()
    }
    
    func updateDeviceListFromDeviceManager() {
        devices = self.deviceManager.devices.values.map({ (device) -> AylaDevice in
            return device as! AylaDevice
        })
        tableView.reloadData()
    }
    
    var shouldDisplayPlaceholder: Bool {
        return self.devices.count == 0
    }
    
    // MARK: Table View Data Source
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if shouldDisplayPlaceholder {
            return tableView.frame.height
        }
        return 76
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldDisplayPlaceholder {
            return 1
        }
        return self.devices.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldDisplayPlaceholder {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyDeviceListCell")!
            return cell
        }
        let device = self.devices[indexPath.row]
        let cellId = device is AylaLocalDevice ? DeviceListViewModel.LocalDeviceCellId : DeviceListViewModel.DeviceCellId
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? DeviceTVCell
        
        if (cell != nil) {
            cell!.configure(device)
        }
        else {
            assert(false, "\(cellId) - reusable cell can't be dequeued'")
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if shouldDisplayPlaceholder {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let unregisterAction = UITableViewRowAction(style: .default, title: "Unregister") { (action, indexPath) in
            let device = self.devices[indexPath.row]
            self.delegate?.deviceListViewModel(self, didUnregisterDevice: device)
        }
        unregisterAction.backgroundColor = UIColor.auraRedColor()
        return [unregisterAction]
    }
    
    // MARK: Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if shouldDisplayPlaceholder {
            return
        }
        let device = self.devices[indexPath.row]
        self.delegate?.deviceListViewModel(self, didSelectDevice: device)
    }
    
    // MARK - device manager listener
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : Error]) {
        AylaLogI(tag: logTag, flag: 0, message:"Init complete")
        self.updateDeviceListFromDeviceManager()
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

        self.updateDeviceListFromDeviceManager()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState) {
        AylaLogI(tag: logTag, flag: 0, message:"Change in deviceManager state: new state \(newState), was \(oldState)")
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        if change.isKind(of: AylaDeviceChange.self) {
            // Not a good udpate strategy
            self.updateDeviceListFromDeviceManager()
        }
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
        // Device errors are not handled here.
    }
}
