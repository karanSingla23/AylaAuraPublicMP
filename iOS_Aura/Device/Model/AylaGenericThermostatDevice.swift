//
//  AylaGenericThermostatDevice.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 3/14/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

fileprivate let logTag = "AylaGenericThermostatDevice"
class AylaGenericThermostatDevice: AylaBLEDevice {
    public static let BLE_TSTAT_MODEL = "bledemo"
    static let SERVICE_GENERIC_THERMOSTAT = "28E7B565-0215-46D7-A924-B8E7C48EAB9B"
    
    enum TstatProperty :String {
        case acOn = "00:bletstat:ac_on"
        case heatOn = "00:bletstat:heat_on"
        case localTemp = "00:bletstat:local_temp"
        case tempSetpoint = "00:bletstat:temp_setpoint"
        case vacationMode = "00:bletstat:vacation_mode"
        
        static func fromCB(_ characteristic: CBCharacteristic) -> TstatProperty? {
            switch characteristic.uuid.uuidString {
            case "1950C6C9-6566-4608-8210-D712E3DF95B0":
                return .acOn
            case "1950C6C9-6566-4608-8210-D712E3DF95B1":
                return .heatOn
            case "1950C6C9-6566-4608-8210-D712E3DF95B2":
                return .localTemp
            case "1950C6C9-6566-4608-8210-D712E3DF95B3":
                return .tempSetpoint
            case "1950C6C9-6566-4608-8210-D712E3DF95B4":
                return .vacationMode
            default:
                return nil
            }
        }
        var name :String {
            get {
                return self.rawValue
            }
        }
        var uuid :CBUUID {
            get {
                switch self {
                case .acOn:
                    return CBUUID(string: "1950C6C9-6566-4608-8210-D712E3DF95B0")
                case .heatOn:
                    return CBUUID(string: "1950C6C9-6566-4608-8210-D712E3DF95B1")
                case .localTemp:
                    return CBUUID(string: "1950C6C9-6566-4608-8210-D712E3DF95B2")
                case .tempSetpoint:
                    return CBUUID(string: "1950C6C9-6566-4608-8210-D712E3DF95B3")
                case .vacationMode:
                    return CBUUID(string: "1950C6C9-6566-4608-8210-D712E3DF95B4")
                }
            }
        }
    }
    
    override func vendorCharacteristicsToFetch(for service: CBService) -> [CBUUID]? {
        return [ TstatProperty.acOn.uuid, TstatProperty.heatOn.uuid, TstatProperty.localTemp.uuid, TstatProperty.tempSetpoint.uuid, TstatProperty.vacationMode.uuid ]
    }
    
    override func vendorServicesToDiscover() -> [CBUUID] {
        return [ CBUUID(string: AylaGenericThermostatDevice.SERVICE_GENERIC_THERMOSTAT) ]
    }
    
    override func didUpdateValue(forVendorCharacteristic characteristic: CBCharacteristic, error: Error) {
        guard let thermostatCharacteristic = TstatProperty.fromCB(characteristic) else {
            AylaLogE(tag: logTag, flag: 0, message: "Update received for unknown characteristic: \(characteristic)")
            return
        }
        guard let property = getProperty(thermostatCharacteristic.name) as? AylaLocalProperty else {
            AylaLogE(tag: logTag, flag: 0, message: "Property \(thermostatCharacteristic.name) not found in managed properties")
            return
        }
        
        guard  let data = characteristic.value else {
            AylaLogE(tag: logTag, flag: 0, message:"Characteristic contais no value")
            return
        }
        
        var optionalValue :Any?
        
        switch thermostatCharacteristic {
        case .acOn, .heatOn, .vacationMode:
            var boolByte: Int8 = 0
            (data as NSData).getBytes(&boolByte, length: 1)
            optionalValue = boolByte != 0x0
        case .localTemp, .tempSetpoint:
            var int4B: Int32 = 0
            (data as NSData).getBytes(&int4B, length: 4)
            optionalValue = Int(int4B)
        }
        guard let value = optionalValue else {
            AylaLogE(tag: logTag, flag: 0, message:"Invalid characteristic data")
            return
        }
        
        let newDatapoint = AylaDatapoint(value: value)
        newDatapoint.dataSource = .cloud
        newDatapoint.createdAt = Date()
        newDatapoint.updatedAt = newDatapoint.createdAt
        
        guard let change = property.update(from: newDatapoint) else {
            AylaLogD(tag: logTag, flag: 0, message:"No changes in property \(property.name) with new value:\(value), original property value: \(property.originalProperty.value ?? "nil")")
            return
        }
        AylaLogD(tag: logTag, flag: 0, message:"Updated property \(property.name) with value:\(value), updated value \(property.value ?? "nil"), original property value: \(property.originalProperty.value ?? "nil")")
        property.pushUpdateToCloud(success: nil, failure: nil)

        notifyChanges(toListeners: [change]);
    }
    
    override func setValue(_ value: Any, for property: AylaLocalProperty, success successBlock: (() -> Void)?, failure failureBlock: ((Error) -> Void)? = nil) -> AylaGenericTask? {
        guard let tstatProperty = TstatProperty(rawValue: property.name) else {
            AylaLogE(tag: logTag, flag: 0, message: "An invalid local property was set")
            if failureBlock != nil {
                failureBlock!(AylaErrorUtils.error(withDomain: AylaRequestErrorDomain, code: AylaRequestErrorCode.invalidArguments.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("An invalid Local property was set", comment: "")]) as Error)
            }
            return nil
        }
        guard let characteristic = vendorCharacteristic(for: tstatProperty.uuid) else {
            AylaLogE(tag: logTag, flag: 0, message: "Characteristic not discovered yet")
            if failureBlock != nil {
                failureBlock!(AylaErrorUtils.error(withDomain: AylaRequestErrorDomain, code: AylaRequestErrorCode.preconditionFailure.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Characteristic not discovered yet", comment: "")]) as Error)
            }
            return nil
        }
        guard let value = value as? Int else {
            AylaLogE(tag: logTag, flag: 0, message: "Invalid value")
            if failureBlock != nil {
                failureBlock!(AylaErrorUtils.error(withDomain: AylaRequestErrorDomain, code: AylaRequestErrorCode.preconditionFailure.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Invalid value", comment: "")]) as Error)
            }
            return nil
        }
        var rawBytes :[UInt8]
        switch tstatProperty {
        case .acOn, .heatOn, .vacationMode:
            rawBytes = [UInt8(value)]
        default:
            rawBytes = [UInt8(value&0xFF),
                        UInt8((value>>0x8)&0xFF),
                        UInt8((value>>0x10)&0xFF),
                        UInt8((value>>0x18)&0xFF)
            ]
        }
        
        return self.write(NSData(bytes:rawBytes, length: rawBytes.count) as Data, to: characteristic, type: .withResponse, success: successBlock, failure:{ error in
            
            if (error as NSError).code == 14 { //this patch is to address an error being reported despite write happening
                self.peripheral.readValue(for: characteristic)
                guard let successBlock = successBlock else {
                    return
                }
                successBlock()
                return
            }
            guard let failureBlock = failureBlock else {
                return
            }
            failureBlock(error)
        })
    }
    
    override func otaReceived(_ otaCommand: AylaLocalOTACommand, filePath: URL) {
        AylaLogD(tag: logTag, flag: 0, message: "OTA Received: \(filePath)")
        setOTAStatus(0, commandId: otaCommand.commandId, success: {
            AylaLogI(tag: logTag, flag: 0, message: "OTA Acked")
        }) { (error) in
            AylaLogE(tag: logTag, flag: 0, message: "Failed to ack OTA")
        }
    }
}
