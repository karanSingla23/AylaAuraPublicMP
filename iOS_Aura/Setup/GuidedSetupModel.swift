//
//  GuidedSetupModel.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/18/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GuidedSetupModel: NSObject, AylaDeviceWifiStateChangeListener {
    var setup: AylaSetup
    var wiFiScanResults: AylaWifiScanResults?
    var ssidName: String?
    var ssidSecurity: String?
    var ssidPassword: String?
    var setupToken: String!
    var saveWiFiSetting: Bool = false
    var timeZone: String?
    var productName: String?
    var registeredDevice: AylaDevice? {
        get {
            guard let deviceManager = self.deviceManager,
                let dsn = self.setup.setupDevice?.dsn else {
                    return nil
            }
            return deviceManager.devices[dsn] as? AylaDevice
        }
    }
    
    struct Constants {
        static let confirmationTimeout: TimeInterval = 60
        static let defaultEVBName = "Ayla EVB"
    }
    
    enum GuidedSetupModelError: Error {
        case invalidParameters(String, String)
    }
    
    init(withSetup setup:AylaSetup) {
        self.setup = setup
    }
    
    var isConnectedToDeviceAP: Bool {
        get {
            let settings = AylaNetworks.shared().systemSettings
            return AylaNetworkInformation.connectedToAP(withRegEx: settings.deviceSSIDRegex)
        }
    }
    
    var isConnectedToSameLan: Bool {
        get {
            if let currentSSID = AylaNetworkInformation.ssid(),
                let deviceConnectedSSID = ssidName {
                return currentSSID.compare(deviceConnectedSSID) == .orderedSame
            }
            return false
        }
    }
    
    var deviceManager: AylaDeviceManager? {
        get {
            return AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)?.deviceManager
        }
    }
    
    public var selectedInsecureWiFi: Bool? {
        return ssidSecurity?.isEqual("None")
    }
    
    var isDeviceAlreadyRegistered: Bool? {
        get {
            return registeredDevice != nil
        }
    }
    
    func connect(toNewDevice successBlock: @escaping (AylaSetupDevice) -> (), failure failureBlock: @escaping (Error) -> ()) {
        self.setup.connect(toNewDevice: successBlock, failure: failureBlock)
    }
    
    func fetchDeviceAccessPoints(_ successBlock: @escaping () -> (), failure failureBlock: @escaping (Error) -> ()) {
        self.setup.fetchDeviceAccessPoints({ (results) in
            self.wiFiScanResults = results
            successBlock()
        }, failure: failureBlock)
    }
    
    func wifiStateDidChange(_ state: String) {
        
    }
    
    func connectDevice(successBlock: @escaping () -> (), failure failureBlock: @escaping (Error) -> ()) {
        self.setupToken = String.generateRandomAlphanumericToken(7)
        var ssidPassword: String? = nil
        if let selectedInsecureWiFi = self.selectedInsecureWiFi, !selectedInsecureWiFi {
            guard  let _ssidPassword = self.ssidPassword, _ssidPassword.characters.count >= 8 else {
                failureBlock(GuidedSetupModelError.invalidParameters("Password", "should be at least 8 characters long"))
                return
            }
            ssidPassword = _ssidPassword
        }
        guard let ssidName = ssidName else {
                failureBlock(GuidedSetupModelError.invalidParameters("Credentials", "should not be empty"))
                return
        }
        
        self.setup.connectDeviceToService(withSSID: ssidName, password: ssidPassword, setupToken: setupToken, latitude: 0.0, longitude: 0.0, success: { (wiFiStatus) in
            successBlock()
        }, failure: failureBlock)
    }
    
    func confirmConnection(successBlock: @escaping () -> (), failure failureBlock: @escaping (Error) -> ()) {
        self.setup.confirmDeviceConnected(withTimeout: Constants.confirmationTimeout, dsn: self.setup.setupDevice!.dsn, setupToken: self.setupToken, success: { (_) in
            successBlock()
        }, failure: failureBlock)
    }
    
    func getDeviceCandidates(successBlock: @escaping (AylaRegistrationCandidate?) -> (), failure failureBlock: @escaping (Error) -> ()){
        let regType = setup.setupDevice!.registrationType
        
        if let reg = self.deviceManager?.registration {
            switch regType {
            case .buttonPush, .sameLan:
                reg.fetchCandidate(withDSN: nil, registrationType: regType, success: { (candidate) in
                    successBlock(candidate)
                }, failure: { (error) in
                    failureBlock(error)
                })
            default:
                let candidate = AylaRegistrationCandidate()
                candidate.dsn = setup.setupDevice?.dsn
                candidate.registrationType = setup.setupDevice!.registrationType
                candidate.lanIp = setup.setupDevice?.lanIp
                candidate.setupToken = setupToken
                successBlock(candidate)
            }
        }
    }
    
    func registerDevice(candidate:AylaRegistrationCandidate!, successBlock: @escaping () -> (), failure failureBlock: @escaping (Error) -> ()) {
        self.deviceManager?.registration.register(candidate, success: { (device) in
            successBlock()
        }, failure: failureBlock)

    }
    
    func cancel() {
        self.setup.exit()
    }
    
    func renameProduct(successBlock: @escaping () -> (), failure failureBlock: @escaping (Error) -> ()) {
        var productName :String! = self.productName
        if productName == nil || productName!.characters.count == 0 {
            productName = Constants.defaultEVBName
        }
        guard let device = self.registeredDevice else {
                failureBlock(GuidedSetupModelError.invalidParameters("Registered device", "is nil"))
                return
        }
        
        device.updateProductName(to: productName, success: successBlock, failure: failureBlock)
    }
    
    func updateTimeZone(successBlock: @escaping () -> (), failure failureBlock: @escaping (Error) -> ()) {
        guard let device = self.registeredDevice,
            let timeZone = self.timeZone,
            timeZone.characters.count > 0 else {
                failureBlock(GuidedSetupModelError.invalidParameters("Time zone", "should not be empty"))
                return
        }
        device.updateTimeZone(to: timeZone, success: { (_) in
            successBlock()
        }, failure: failureBlock)
    }
    
    func fetchTimeZone(successBlock: @escaping (AylaTimeZone) -> (), failure failureBlock: @escaping (Error) -> ()) {
        guard let device = self.registeredDevice else {
                failureBlock(GuidedSetupModelError.invalidParameters("device", "is nil"))
                return
        }
        device.fetchTimeZone(success: successBlock, failure: failureBlock)
    }
}
