//
//  DeviceSharesModel.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/6/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//


import iOS_AylaSDK


protocol DeviceSharesModelDelegate: class {
    func deviceSharesModel(_ model:DeviceSharesModel, receivedSharesListDidUpdate: ((_ shares :[AylaShare]) -> Void)?)
    func deviceSharesModel(_ model:DeviceSharesModel, ownedSharesListDidUpdate: ((_ shares :[AylaShare]) -> Void)?)
    
}

class DeviceSharesModel:NSObject, AylaDeviceManagerListener, AylaDeviceListener {
    private let logTag = "DeviceSharesModel"
    /// Device manager where device list belongs
    let deviceManager: AylaDeviceManager

    var ownedShares : [ AylaShare ]
    var receivedShares : [ AylaShare ]
    var devices : [ AylaDevice ]
    
    weak var delegate: DeviceSharesModelDelegate?
    
    required init(deviceManager: AylaDeviceManager) {
        
        self.deviceManager = deviceManager
        
        self.ownedShares = []
        self.receivedShares = []
        self.devices = []
        
        super.init()
        self.updateSharesList(nil, failureHandler: nil)
        
        // Add self as device manager listener
        deviceManager.add(self)
        NotificationCenter.default.addObserver(self, selector: #selector(DeviceSharesModel.refreshShares), name: NSNotification.Name(rawValue: AuraNotifications.SharesChanged), object: nil)
        self.refreshDeviceList()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func deviceForShare(_ share: AylaShare) -> AylaDevice? {
        for device in devices {
            if share.resourceId == device.dsn {
                return device
            }
        }
        return nil
    }
    
    func ownedSharesForDevice(_ device: AylaDevice) -> [AylaShare]? {
        var sharesArray = [AylaShare]()
        for share in self.ownedShares {
            if device.dsn == share.resourceId {
                sharesArray.append(share)
            }
        }
        return sharesArray
    }
    
    func receivedShareForDevice(_ device: AylaDevice) -> AylaShare? {
        for share in self.receivedShares {
            if device.dsn == share.resourceId {
                return share
            }
        }
        return nil
    }
    
    
    func refreshDeviceList(){
        devices = self.deviceManager.devices.values.map({ (device) -> AylaDevice in
            return device as! AylaDevice
        })
    }
    
    func refreshShares(){
        self.updateSharesList({ (shares) in }) { (error) in }
    }
    
    func updateSharesList(_ successHandler: ((_ shares :[AylaShare]) -> Void)?, failureHandler: ((_ error: Error) -> Void)?) {
        let _ = deviceManager.sessionManager?.fetchReceivedShares(withResourceName: AylaShareResourceNameDevice, resourceId: nil, expired: false, accepted: true, success: { (shares: [AylaShare]) in
                self.receivedShares = shares
                self.delegate?.deviceSharesModel(self, receivedSharesListDidUpdate: { (shares) in })
                if let successHandler = successHandler { successHandler(shares) }
            }, failure: { (error :Error) in
                AylaLogE(tag: self.logTag, flag: 0, message:"Failure to receive shares: \(error.localizedDescription)")
                if let failureHandler = failureHandler { failureHandler(error) }
            } 
        )
        let _ = deviceManager.sessionManager?.fetchOwnedShares(withResourceName: AylaShareResourceNameDevice, resourceId: nil, expired: false, accepted: true, success: { (shares: [AylaShare]) in
                self.ownedShares = shares
                self.delegate?.deviceSharesModel(self, ownedSharesListDidUpdate: { (shares) in })
                if let successHandler = successHandler { successHandler(shares) }
            }, failure: { (error :Error) in
                AylaLogE(tag: self.logTag, flag: 0, message:"Failure to receive shares: \(error.localizedDescription)")
                if let failureHandler = failureHandler { failureHandler(error) }
            }
        )
    }
    
    // MARK - device manager listener
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : Error]) {
        AylaLogI(tag: logTag, flag: 0, message:"Init complete")
        self.updateSharesList(nil, failureHandler: nil)
        self.refreshDeviceList()
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
        self.refreshDeviceList()
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState){
        
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        if change.isKind(of: AylaDeviceChange.self) || change.isKind(of: AylaDeviceListChange.self) {
            // Not a good udpate strategy
            self.updateSharesList(nil, failureHandler: nil)
            self.refreshDeviceList()
        }
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
        // Device errors are not handled here.
    }
}
