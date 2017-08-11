//
//  DeviceShareViewModel.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/5/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK


class ShareViewModel: NSObject, UITextFieldDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    private let logTag = "ShareViewModel"
    /// Share presented by this model
    var share: AylaShare
    
    /// Reference to device used in this share.
    weak var device: AylaDevice?
    
    /// Reference to current session manager.
    weak var sessionManager: AylaSessionManager?
    
    static let DeviceShareCellId: String = "DeviceShareCellId"
    
    required init(share:AylaShare) {
        self.share = share
        if let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
            self.sessionManager = sessionManager
            
            var devices : [AylaDevice]
            devices = sessionManager.deviceManager.devices.values.map({ (device) -> AylaDevice in
                return device as! AylaDevice
            })
            
            for device in devices {
                if device.dsn == share.resourceId {
                    self.device = device
                }
            }
            
            super.init()
        }
        else {
            AylaLogD(tag: logTag, flag: 0, message:"No Session manager present")
            super.init()
        }
    }
    
    
    
    func deleteShare(_ presentingViewController:UIViewController, successHandler: (() -> Void)?, failureHandler: ((_ error: Error) -> Void)?) {
        if let sessionManager = sessionManager {
            let confirmation = UIAlertController(title: "Delete this Share?", message: "Are you sure you want to unshare this device?", preferredStyle: .alert)
            let delete = UIAlertAction(title: "Delete Share", style: .destructive, handler:{(action) -> Void in
                sessionManager.delete(self.share, success: {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: AuraNotifications.SharesChanged), object:self)
                    if let successHandler = successHandler {
                        successHandler()
                    }
                    }, failure: { (error) in
                        let alert = UIAlertController(title: "Error. Failed to Delete Share.", message: error.description, preferredStyle: .alert)
                        let gotIt = UIAlertAction(title: "Got it", style: .cancel, handler: nil)
                        alert.addAction(gotIt)
                        presentingViewController.present(alert, animated: true, completion: nil)
                        if let failureHandler = failureHandler {
                            failureHandler(error)
                        }
                })
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            confirmation.addAction(delete)
            confirmation.addAction(cancel)
            presentingViewController.present(confirmation, animated: true, completion: nil)
            
        }
        else {
            AylaLogD(tag: logTag, flag: 0, message:"No Session Manager found!")
        }
        
    }
    
    func deleteShareWithoutConfirmation(_ presentingViewController:UIViewController, successHandler: (() -> Void)?, failureHandler: ((_ error: Error) -> Void)?) {
        if let sessionManager = sessionManager {
            sessionManager.delete(self.share, success: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: AuraNotifications.SharesChanged), object:self)
                if let successHandler = successHandler {
                    successHandler()
                }
                }, failure: { (error) in
                    let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .cancel, handler: nil)
                    alert.addAction(gotIt)
                    presentingViewController.present(alert, animated: true, completion: nil)
                    if let failureHandler = failureHandler {
                        failureHandler(error)
                    }
            })
        } else {
            AylaLogD(tag: logTag, flag: 0, message:"No Session Manager found!")
        }
    }
    
    func valueFromString(_ str:String?) -> AnyObject? {
        
        if str == nil {
            return nil;
        }
        else if self.share.userEmail == "string" {
            return str as AnyObject?;
        }
        else {
            if let doubleValue = Double(str!) {
                return NSNumber(value: doubleValue as Double)
            }
        }
        
        return nil
    }
    
    
    // MARK - device manager listener
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : Error]) {
        if deviceFailures.count > 0 {
            AylaLogE(tag: logTag, flag: 0, message: "device failures: \(deviceFailures)")
        }
        AylaLogI(tag: logTag, flag: 0, message:"Init complete")
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitFailure error: Error) {
        AylaLogE(tag: logTag, flag: 0, message:"Failed to init: \(error)")
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didObserve change: AylaDeviceListChange) {
        AylaLogD(tag: logTag, flag: 0, message:"Observe device list change")
        if change.addedItems.count > 0 {
            for device:AylaDevice in change.addedItems {
                device.add(self)
            }
        }
        else {
            // We don't remove self as listener from device manager removed devices.
        }
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState){
        
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        if change.isKind(of: AylaDeviceChange.self) {
            // Not a good udpate strategy
        }
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
        // Device errors are not handled here.
    }
}
