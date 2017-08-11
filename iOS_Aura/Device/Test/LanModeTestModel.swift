//
//  LanModeTestModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK


extension AylaDevice {

    func lanTest_isSupportedDevice() -> Bool {
        if oemModel == "ledevb" {
            return true
        }
        return false
    }

    func lanTest_getPropertyNamesForFetchRequest() -> [String]? {
        if self.isKind(of: AylaDeviceNode.self) && model == "GenericNode" {
            return [ "01:0006_S:0000" ]
        }
    
        // Get managed properties from device detail provider
        let array = AylaNetworks.shared().systemSettings.deviceDetailProvider.monitoredPropertyNames(for: self) as? [String]
        return array
    }
    
    func lanTest_getProperty(_ name: String) -> AylaProperty? {
        if let properties = self.properties as? [String: AylaProperty]{
            return properties[name]
        }
        return nil
    }
    
    func lanTest_getBooleanProperty() -> AylaProperty? {
        if oemModel == "ledevb" {
            // Use green led
            return lanTest_getProperty("Green_LED")
        }
        else if self.isKind(of: AylaDeviceGateway.self) && oemModel == "generic" {
            // No boolean property could be used for datapoint creation test on a generic gateway
            return nil
        }
        else if self.isKind(of: AylaDeviceNode.self) && model == "GenericNode" {
            return lanTest_getProperty("01:0006_S:00")
        }
        
        // For unsupported device, get a boolean property which has input direction
        var property: AylaProperty?
        if let properties = self.properties {
            let filtered = properties.filter({ (key, property) -> Bool in
                if (property as AnyObject).baseType == AylaPropertyBaseTypeBoolean && (property as AnyObject).direction == "input" {
                    return true
                }
                return false
            })
            
            if filtered.count > 0 {
                property = filtered[0].1 as? AylaProperty
            }
        }
        return property
    }

    func lanTest_getStringProperty() -> AylaProperty? {
        if oemModel == "ledevb" {
            // Use green led
            return lanTest_getProperty("cmd")
        }
        else if self.isKind(of: AylaDeviceGateway.self) && oemModel == "generic" {
            return lanTest_getProperty("cmd")
        }
        else if self.isKind(of: AylaDeviceNode.self) && model == "GenericNode" {
            // No strinng property could be used for datapoint creation test on a generic node
            return nil
        }
        
        // Get a string property which has input direction
        var property: AylaProperty?
        if let properties = self.properties {
            let filtered = properties.filter({ (key, property) -> Bool in
                if (property as AnyObject).baseType == AylaPropertyBaseTypeString && (property as AnyObject).direction == "input" {
                    return true
                }
                return false
            })
            
            if filtered.count > 0 {
                property = filtered[0].1 as? AylaProperty
            }
        }
        return property
    }
    
    func lanTest_getAckEnableBooleanProperty() -> AylaProperty? {
        if self.isKind(of: AylaDeviceNode.self) && oemModel == "generic" {
            return lanTest_getProperty("01:0006_S:01")
        }
        return nil
    }
    
    func lanTest_getConfirmingPropertyAndDatapointParamsFor(_ property: AylaProperty, dpParams:AylaDatapointParams) -> (AylaProperty?, AylaDatapointParams?) {
        if property.name == "cmd" {
            return (lanTest_getProperty("log"), dpParams)
        }
        else if property.name == "01:0006_S:00" {
            let params = AylaDatapointParams()
            params.value = Int(0)
            return (lanTest_getProperty("01:0006_S:0000"), params)
        }
        else if property.name == "01:0006_S:01" {
            let params = AylaDatapointParams()
            params.value = Int(1)
            return (lanTest_getProperty("01:0006_S:0000"), params)
        }
        return (property, dpParams)
    }
    
}

class LanModeTestModel: TestModel {
    
    var deviceManager: AylaDeviceManager?
    var device :AylaDevice?
    
    init(testPanelVC: TestPanelViewController, deviceManager:AylaDeviceManager?, device: AylaDevice?) {
        super.init(testPanelVC: testPanelVC)
        
        self.deviceManager = deviceManager
        self.device = device
    }
    
    override func testPanelIsReady() {
        testPanelVC?.title = "LAN Test"
        testPanelVC?.tf1.isHidden = false
        testPanelVC?.tf1Label.isHidden = false
        testPanelVC?.tf1Label.text = "Iters"
        testPanelVC?.tf1.keyboardType = .numberPad
    }
    
    override func start() -> Bool {
        if (super.start()) {
            setupTestSequencer()
            
            var iters = 1
            if let text = self.testPanelVC?.tf1.text {
                if let input = Int(text) {
                    iters = input > 0 ? input : 1
                }
            }

            self.testPanelVC?.iterCountLabel.text = "1/\(iters)"
            testSequencer?.start(UInt(iters))
            return true
        }
        
        return false
    }
    
    override func stop() -> Bool {
        return super.stop()
    }
    
    override func setupTestSequencer() {
        let sequencer = TestSequencer()
            .addTest(NSStringFromSelector(#selector(testFetchPropertiesLAN)), testBlock: { [weak self] (testCase) in self?.testFetchPropertiesLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testFetchProperties)), testBlock: { [weak self] (testCase) in self?.testFetchProperties(testCase) })
            .addTest(NSStringFromSelector(#selector(testCreateBooleanDatapointLAN)), testBlock: { [weak self] (testCase) in self?.testCreateBooleanDatapointLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testCreateStringDatapointLAN)), testBlock: { [weak self] (testCase) in self?.testCreateStringDatapointLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testDatapointAckWithBooleanPropertyLAN)), testBlock: { [weak self] (testCase) in self?.testDatapointAckWithBooleanPropertyLAN(testCase) })
            .addTest(NSStringFromSelector(#selector(testFetchPropertiesLAN)), testBlock: { [weak self] (testCase) in self?.testFetchPropertiesLAN(testCase) })
        
        testSequencer = sequencer
    }

    // NOTE: Lan Mode Test Model only supports devices with oemModel `ledevb`
    // For this test suite to succeed, mobile device must be on the same LAN as the module (so as to enable LAN Mode)
    // You may still run the test for other modules, but there is no guarantee the full test suite will pass.
    
    // MARK Test in sequence

    func testFetchProperties(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        _ = device?.fetchProperties(device?.lanTest_getPropertyNamesForFetchRequest(), success: { (properties) in
            self.passTestCase(tc)
            }, failure: { (error) in
            self.failTestCase(tc, error: error)
        })
    }
    
    func testFetchPropertiesLAN(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        _ = device?.fetchPropertiesLAN(device?.lanTest_getPropertyNamesForFetchRequest() ?? [], success: { (properties) in
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func testCreateBooleanDatapointLAN(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let device = self.device
        let property: AylaProperty? = device?.lanTest_getBooleanProperty()
        
        if property == nil {
            addLog(.warning, log: "Unable to find boolean property")
            passTestCase(tc)
            return
        }
        
        // Create a datapoint
        let dp = AylaDatapointParams()
        if let curVal = (property!.value as AnyObject).int32Value {
            dp.value = NSNumber(value: 1 - curVal as Int32)
        }
        else {
            dp.value = NSNumber(value: 1 as Int32)
        }

        addLog(.info, log: "Using property \(property?.name ?? "nil"), dp.value \(dp.value as AnyObject)")
        
        let confirm = device?.lanTest_getConfirmingPropertyAndDatapointParamsFor(property!, dpParams: dp)
        createAndConfirmDatapoint(tc, property: property!, datapoint: dp, confirmProperty: confirm!.0) { (createdValue) -> Bool in
            if let expectedParams = confirm?.1 {
                return createdValue.boolValue == (expectedParams.value as AnyObject).boolValue
            }
            return false
        }
    }
    
    func testCreateStringDatapointLAN(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let device = self.device
        let property = device?.lanTest_getStringProperty()
        
        if property == nil {
            addLog(.warning, log: "Unable to find string property")
            passTestCase(tc)
            return
        }
        
        // Create a datapoint
        let dp = AylaDatapointParams()
        dp.value = "TEST_STRING \(Int(arc4random_uniform(9999)))"
        addLog(.info, log: "Using property \(property?.name ?? "nil"), dp.value \(dp.value as AnyObject)")
        
        let confirm = device?.lanTest_getConfirmingPropertyAndDatapointParamsFor(property!, dpParams: dp)
        createAndConfirmDatapoint(tc, property: property!, datapoint: dp, confirmProperty: confirm!.0) { (createdValue) -> Bool in
            if let expectedParams = confirm?.1 {
                return createdValue as! String == expectedParams.value as! String
            }
            return false
        }
    }

    func testDatapointAckWithBooleanPropertyLAN(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let device = self.device
        let property = device?.lanTest_getAckEnableBooleanProperty()
        
        if property == nil {
            addLog(.warning, log: "Unable to find ACK enable boolean property, skip.")
            passTestCase(tc)
            return
        }
        
        // Create a datapoint
        let dp = AylaDatapointParams()
        if let curVal = (property!.value as AnyObject).int32Value {
            dp.value = NSNumber(value: 1 - curVal as Int32)
        }
        else {
            dp.value = NSNumber(value: 1 as Int32)
        }
        
        addLog(.info, log: "Using property \(property?.name ?? "nil"), dp.value \(String(describing: (dp.value as AnyObject?) ?? nil))")
        
        _ = property?.createDatapointLAN(dp, success: { (datapoint) in
            if datapoint.ackStatus == 0 {
                self.addLog(.error, log: "Ack status = 0")
                self.failTestCase(tc, error: nil)
            }
            else if (datapoint.value as AnyObject).boolValue != (dp.value as AnyObject).boolValue {
                self.addLog(.error, log: "DP value mismatched.")
                self.failTestCase(tc, error: nil)
            }
            else {
                self.passTestCase(tc)
            }
            }, failure: { (error) in
            self.failTestCase(tc, error: error)
        })

    }

    func createAndConfirmDatapoint(_ tc:TestCase, property: AylaProperty, datapoint: AylaDatapointParams , confirmProperty: AylaProperty?, checkBlock: @escaping (AnyObject) -> Bool)  {

        let device = self.device
        // Create a datapoint
        
        property.createDatapointLAN(datapoint, success: { (datapoint) in
            // Fetch from device to guarantee the created datapoint
            if confirmProperty != nil {
                // Delay 1s before fetching property to confirm
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
                    self.addLog(.info, log: "Fetching property \"\(confirmProperty!.name)\" to confirm datapoint.")
                    _ = device?.fetchPropertiesLAN([ confirmProperty!.name ], success: { (properties) in
                            if let createdValue = properties.first?.value {
                                if checkBlock(createdValue as AnyObject) {
                                    self.passTestCase(tc)
                                }
                                else {
                                    self.addLog(.error, log: "DP value mismatched.")
                                    self.failTestCase(tc, error: nil)
                                }
                            }
                            else {
                                self.addLog(.error, log: "DP is missing.")
                                self.failTestCase(tc, error: nil)
                            }
                        }, failure: { (error) in
                        self.failTestCase(tc, error: error)
                    })
                })
            } else {
                self.addLog(.warning, log: "No confirm property given for property \(property.name)")
                self.failTestCase(tc, error: nil)
            }
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
}
