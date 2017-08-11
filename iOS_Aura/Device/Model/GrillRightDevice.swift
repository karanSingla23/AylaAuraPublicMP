//
//  GrillRightDevice.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GrillRightDevice: AylaBLEDevice {
    private let logTag = "GrillRightDevice"
    static let timeFormat = "%02d:%02d:%02d"
    enum ControlMode: Int {
        case none = 0
        case meat
        case temp
        case time
        static func name(_ mode: ControlMode) -> String {
            switch mode {
            case none:
                return "None"
            case meat:
                return "Meat Profile"
            case temp:
                return "Temperature"
            case time:
                return "Cook Timer"
            }
        }
        var name: String {
            get {
                return ControlMode.name(self)
            }
        }
        
        static let caseCount = ControlMode.time.rawValue + 1
        
    }
    
    enum MeatType: Int {
        case none = 0
        case beef
        case veal
        case lamb
        case pork
        case chicken
        case turkey
        case fish
        case hamburger
        static func name(_ type: MeatType) -> String {
            switch type {
            case none:
                return "None"
            case beef:
                return "Beef"
            case veal:
                return "Veal"
            case lamb:
                return "Lamb"
            case pork:
                return "Pork"
            case chicken:
                return "Chicken"
            case turkey:
                return "Turkey"
            case fish:
                return "Fish"
            case hamburger:
                return "Hamburger"
            }
        }
        var name: String {
            get {
                return MeatType.name(self)
            }
        }
        
        static let caseCount = MeatType.hamburger.rawValue + 1
    }
    
    enum Doneness: Int {
        case none = 0
        case rare
        case mediumRare
        case medium
        case mediumWell
        case wellDone
        static func name(_ doneness: Doneness) -> String {
            switch doneness {
            case none:
                return "None"
            case rare:
                return "Rare"
            case mediumRare:
                return "Medium Rare"
            case medium:
                return "Medium"
            case mediumWell:
                return "Medium Well"
            case wellDone:
                return "Well Done"
            }
        }
        var name: String {
            get {
                return Doneness.name(self);
            }
        }
        
        static let caseCount = Doneness.wellDone.rawValue + 1
    }
    
    enum AlarmState: Int {
        case none = 0
        case almostDone
        case overdone
        
        static func name(_ state: AlarmState) -> String {
            switch state {
            case .none:
                return "None"
            case .almostDone:
                return "Almost Done"
            case .overdone:
                return "Overdone"
            }
        }
        var name: String {
            get {
                return AlarmState.name(self);
            }
        }
        
        static let caseCount = AlarmState.overdone.rawValue + 1
    }
    
    class Sensor: NSObject {
        init(device: GrillRightDevice, index: Int) {
            self.device = device
            self.index = index
        }
        var index: Int
        weak var device: GrillRightDevice!
        
        var currentTemp: Int? {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TEMP : GrillRightDevice.PROP_SENSOR2_TEMP)
                return device.value(for: property as! AylaLocalProperty) as? Int
            }
        }
        
        var alarmState: AlarmState {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_ALARM : GrillRightDevice.PROP_SENSOR2_ALARM) as! AylaLocalProperty
                let value = device.value(for: property)
                guard let intValue = value as? Int, let state = AlarmState(rawValue: intValue) else {
                    return AlarmState.none
                }
                return state
            }
        }
        
        var meatType: MeatType {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_MEAT : GrillRightDevice.PROP_SENSOR2_MEAT) as! AylaLocalProperty
                let value = device.value(for: property)
                guard let intValue = value as? Int, let meatType = MeatType(rawValue: intValue) else {
                    return MeatType.none
                }
                return meatType
            }
        }
        var doneness: Doneness {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_DONENESS : GrillRightDevice.PROP_SENSOR2_DONENESS)  as! AylaLocalProperty
                let value = device.value(for: property)
                guard let intValue64 = value as? Int64 else {
                    return Doneness.none
                }
                guard let doneness = Doneness(rawValue: Int(intValue64)) else {
                    return Doneness.none
                }
                return doneness
            }
        }
        var controlMode: ControlMode {
            get {
                
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_CONTROL_MODE : GrillRightDevice.PROP_SENSOR2_CONTROL_MODE)  as! AylaLocalProperty
                guard let intValue =  device.value(for: property) as? Int, let mode = ControlMode(rawValue: intValue) else {
                    return ControlMode.none
                }
                return mode
            }
        }
        var isCooking: Bool {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING)
                guard let isCooking = device.value(for: property as! AylaLocalProperty) as? Bool else {
                    return false
                }
                return isCooking
            }
        }
        var targetTime: String {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TIME : GrillRightDevice.PROP_SENSOR2_TARGET_TIME)
                return device.value(for: property as! AylaLocalProperty) as! String
            }
        }
        var currentTime: String {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TIME : GrillRightDevice.PROP_SENSOR2_TIME)
                return device.value(for: property as! AylaLocalProperty) as! String
            }
        }
        var currentHours:Int? {
            get {
                let components = self.currentTime.components(separatedBy: ":")
                if components.count != 3 {
                    return 0
                }
                return Int(components[0])
            }
        }
        
        var currentMinutes:Int? {
            get {
                let components = self.currentTime.components(separatedBy: ":")
                if components.count != 3 {
                    return 0
                }
                return Int(components[1])
            }
        }
        
        var currentSeconds:Int? {
            get {
                let components = self.currentTime.components(separatedBy: ":")
                if components.count != 3 {
                    return 0
                }
                return Int(components[2])
            }
        }
        var targetTemp: Int {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TEMP : GrillRightDevice.PROP_SENSOR2_TARGET_TEMP)
                return device.value(for: property as! AylaLocalProperty) as! Int
            }
        }
        var pctDone: Int {
            get {
                let property = device.getProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_PCT_DONE : GrillRightDevice.PROP_SENSOR2_PCT_DONE)
                guard let pctDone = device.value(for: property as! AylaLocalProperty) as? Int else {
                    return 0
                }
                return pctDone
            }
        }
    }
    
    var channel1: Sensor {
        get {
            return Sensor(device: self, index: 1)
        }
    }
    
    var channel2: Sensor {
        get {
            return Sensor(device: self, index: 2)
        }
    }
    
    fileprivate class InternalSensor: NSObject {
        private let logTag = "InternalSensor"
        init (sensor: InternalSensor) {
            super.init()
            self.device = sensor.device
            self.index = sensor.index
            self.name = sensor.name
            self.currentValue = sensor.currentValue
            self.currentTemp = sensor.currentTemp
            self.meatType = sensor.meatType
            self.doneness = sensor.doneness
            self.controlMode = sensor.controlMode
            self.targetTime = sensor.targetTime
            self.targetHours = sensor.targetHours
            self.targetMinutes = sensor.targetMinutes
            self.targetSeconds = sensor.targetSeconds
            self.currentHours = sensor.currentHours
            self.currentMinutes = sensor.currentMinutes
            self.currentSeconds = sensor.currentSeconds
            self.targetTemp = sensor.targetTemp
            self.pctDone = sensor.pctDone
            self.name = sensor.name
            self.cooking = sensor.cooking
            self.alarmState = sensor.alarmState
            
        }
        override init () {
            super.init()
        }
        weak var device: GrillRightDevice!
        var currentValue: Data!
        
        var currentTemp: Int?
        var alarmState = AlarmState.none
        var meatType = MeatType.none
        var doneness = Doneness.none
        var controlMode = ControlMode.none
        
        var isCooking : Bool {
            get {
                return cooking == 1
            }
        }
        
        var targetTime: String {
            get {
                return String(format: GrillRightDevice.timeFormat, self.targetHours ?? 0, self.targetMinutes ?? 0, self.targetSeconds ?? 0)
            }
            set {
                let components = newValue.components(separatedBy: ":")
                if components.count != 3 {
                    return
                }
                self.targetHours = Int(components[0])
                self.targetMinutes = Int(components[1])
                self.targetSeconds = Int(components[2])
            }
        }
        var targetHours: Int?
        var targetMinutes: Int?
        var targetSeconds: Int?
        
        // Current timer values
        var currentTime: String {
            get {
                return String(format: GrillRightDevice.timeFormat, self.currentHours ?? 0, self.currentMinutes ?? 0, self.currentSeconds ?? 0)
            }
        }
        
        var currentHours: Int?
        var currentMinutes: Int?
        var currentSeconds: Int?
        
        var targetTemp = 0
        var pctDone = 0
        var name: String?
        var index: Int!
        var cooking: Int?
        
        func updateProperty(_ propertyName: String, withValue value:AnyObject) -> AylaPropertyChange? {
            let newDatapoint = AylaDatapoint(value: value)
            newDatapoint.dataSource = .cloud
            newDatapoint.createdAt = Date()
            newDatapoint.updatedAt = newDatapoint.createdAt
            let property = device.getProperty(propertyName) as? AylaLocalProperty
            
            let change = property?.update(from: newDatapoint)
            AylaLogD(tag: logTag, flag: 0, message:"Updated property \(property?.name  ?? "nil") with value:\(value), updated value \(property?.value ?? "nil"), original property value: \(property?.originalProperty.value  ?? "nil")")
            if let property = property {
                property.pushUpdateToCloud(success: nil, failure: nil)
            }
            
            return change
        }
        
        func update(fromData data: Data) -> [AylaChange]? {
            var changes = [AylaChange]()
            
            //Current temperature
            var temp16: UInt16 = 0
            (data as NSData).getBytes(&temp16, range: NSRange(location: 12, length: 2))
            var temp = -1
            if temp16 != 0x8FFF { //0x8FFF = no sensor
                temp = Int(temp16)
            }
            
            if currentTemp == nil || temp != currentTemp! {
                self.currentTemp = temp
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TEMP : GrillRightDevice.PROP_SENSOR2_TEMP, withValue: temp as AnyObject) {
                    changes.append(change)
                }
            }
            AylaLogD(tag: logTag, flag: 0, message:"Current temperature: \(currentTemp != nil ? String(describing:currentTemp!) : "nil")")
            
            //isCooking
            var isCookingByte: Int8 = 0
            (data as NSData).getBytes(&isCookingByte, range: NSRange(location: 0, length: 1))
            isCookingByte = isCookingByte & 0x0F
            
            let alarmState = isCookingByte == 0x0B ? AlarmState.almostDone : isCookingByte == 0x0F ? AlarmState.overdone : AlarmState.none
            if alarmState != self.alarmState {
                self.alarmState = alarmState
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_ALARM : GrillRightDevice.PROP_SENSOR2_ALARM, withValue: alarmState.rawValue as AnyObject) {
                    changes.append(change)
                }
            }
            
            var isCooking = isCookingByte & 0x04 == 0x04 ? 1 : 0
            if alarmState != .none {
                isCooking = 1
            }
            if self.cooking == nil || isCooking != self.cooking! {
                self.cooking = isCooking
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_COOKING : GrillRightDevice.PROP_SENSOR2_COOKING, withValue: isCooking as AnyObject) {
                    changes.append(change)
                }
            }
            
            //Control Mode
            var controlModeByte: Int8 = 0
            (data as NSData).getBytes(&controlModeByte, range: NSRange(location: 0, length: 1))
            controlModeByte = controlModeByte & 0x03
            let controlMode = ControlMode(rawValue: Int(controlModeByte))
            if controlMode != self.controlMode {
                self.controlMode = controlMode!
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_CONTROL_MODE : GrillRightDevice.PROP_SENSOR2_CONTROL_MODE, withValue: controlMode!.rawValue as AnyObject) {
                    changes.append(change)
                }
            }
            
            //target temperature
            var targetTemp16: UInt16 = 0
            (data as NSData).getBytes(&targetTemp16, range: NSRange(location: 10, length: 2))
            var targetTemp = -1
            if targetTemp16 != 0x8FFF { //0x8FFF = no sensor
                targetTemp = Int(targetTemp16)
            }
            if self.targetTemp != targetTemp {
                self.targetTemp = targetTemp
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TEMP : GrillRightDevice.PROP_SENSOR2_TARGET_TEMP, withValue: targetTemp as AnyObject) {
                    changes.append(change)
                }
            }
            
            //Meat Type
            var meatByte: Int8 = 0
            (data as NSData).getBytes(&meatByte, range: NSRange(location: 1, length: 1))
            let meat = MeatType(rawValue: Int(meatByte))
            if meat != nil && meat != self.meatType {
                self.meatType = meat!
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_MEAT : GrillRightDevice.PROP_SENSOR2_MEAT, withValue: meat!.rawValue as AnyObject) {
                    changes.append(change)
                }
            }
            
            //Doneness
            var donenessByte: Int8 = 0
            (data as NSData).getBytes(&donenessByte, range: NSRange(location: 2, length: 1))
            let doneness = Doneness(rawValue: Int(donenessByte))
            if doneness != nil && doneness != self.doneness {
                self.doneness = doneness!
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_DONENESS : GrillRightDevice.PROP_SENSOR2_DONENESS, withValue: doneness!.rawValue as AnyObject) {
                    changes.append(change)
                }
            }
            
            var timeChanged = false
            var targetHours = 0
            (data as NSData).getBytes(&targetHours, range: NSRange(location: 3, length: 1))
            if self.targetHours == nil || targetHours != self.targetHours {
                self.targetHours = targetHours
                timeChanged = true
            }
            var targetMinutes = 0
            (data as NSData).getBytes(&targetMinutes, range: NSRange(location: 4, length: 1))
            if self.targetMinutes == nil || targetMinutes != self.targetMinutes {
                self.targetMinutes = targetMinutes
                timeChanged = true
            }
            var targetSeconds = 0
            (data as NSData).getBytes(&targetSeconds, range: NSRange(location: 5, length: 1))
            if self.targetSeconds == nil || targetSeconds != self.targetSeconds {
                self.targetSeconds = targetSeconds
                timeChanged = true
            }
            if timeChanged {
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TARGET_TIME : GrillRightDevice.PROP_SENSOR2_TARGET_TIME, withValue: self.targetTime as AnyObject) {
                    changes.append(change)
                }
            }
            
            timeChanged = false
            var currentHours = 0
            (data as NSData).getBytes(&currentHours, range: NSRange(location: 6, length: 1))
            if self.currentHours == nil || currentHours != self.currentHours {
                self.currentHours = currentHours
                timeChanged = true
            }
            var currentMinutes = 0
            (data as NSData).getBytes(&currentMinutes, range: NSRange(location: 7, length: 1))
            if self.currentMinutes == nil || currentMinutes != self.currentMinutes {
                self.currentMinutes = currentMinutes
                timeChanged = true
            }
            var currentSeconds = 0
            (data as NSData).getBytes(&currentSeconds, range: NSRange(location: 8, length: 1))
            if self.currentSeconds == nil || currentSeconds != self.currentSeconds {
                self.currentSeconds = currentSeconds
                timeChanged = true
            }
            if timeChanged {
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_TIME : GrillRightDevice.PROP_SENSOR2_TIME, withValue: self.currentTime as AnyObject) {
                    changes.append(change)
                }
            }
            
            //Percentage Done
            var pctDone16: UInt16 = 0
            (data as NSData).getBytes(&pctDone16, range: NSRange(location: 14, length: 2))
            let pctDone = Int(pctDone16)
            if self.pctDone != pctDone {
                self.pctDone = pctDone
                if let change = updateProperty(index == 1 ? GrillRightDevice.PROP_SENSOR1_PCT_DONE : GrillRightDevice.PROP_SENSOR2_PCT_DONE, withValue: pctDone as AnyObject) {
                    changes.append(change)
                }
            }
            
            self.currentValue = data
            return changes.count > 0 ? changes : nil
        }
    }
    
    class Command: NSObject {
        static func startCookingCommand(_ index: Int, mode: ControlMode) -> NSMutableData {
            return NSMutableData(bytes: [UInt8(0x83), UInt8(index), UInt8(mode.rawValue)], length: 3)
        }
        static func stopCookingCommand(_ index: Int) -> NSMutableData {
            return NSMutableData(bytes: [UInt8(0x84), UInt8(index), UInt8(0x00)], length: 3)
        }
        fileprivate static func setFields(_ sensor: InternalSensor) -> NSMutableData {
            var command = [UInt8](repeating: 0, count: 13)
            command[0] = UInt8(0x82)
            command[1] = UInt8(sensor.index)
            command[2] = UInt8(sensor.meatType.rawValue)
            command[3] = UInt8(sensor.doneness.rawValue)
            command[4] = UInt8(sensor.targetTemp & 0xFF)
            command[5] = UInt8((UInt16(sensor.targetTemp) & 0xFF00) >> 8)
            command[6] = UInt8(sensor.targetHours!)
            command[7] = UInt8(sensor.targetMinutes!)
            command[8] = UInt8(sensor.targetSeconds!)
            command[9] = UInt8(sensor.targetHours!)
            command[10] = UInt8(sensor.targetMinutes!)
            command[11] = UInt8(sensor.targetSeconds!)
            
            return NSMutableData(bytes: command, length: command.count)
        }
    }
    
    fileprivate lazy var sensor1: InternalSensor = {
        [unowned self] in
        let sensor = InternalSensor()
        sensor.device = self
        sensor.index = 1
        return sensor
        }()
    
    fileprivate lazy var sensor2: InternalSensor = {
        [unowned self] in
        let sensor = InternalSensor()
        sensor.device = self
        sensor.index = 2
        return sensor
        }()
    
    static let GRILL_RIGHT_MODEL:String = "GrillRight"
    static let GRILL_RIGHT_OEM:String = "OreSci"
    static let GRILL_RIGHT_OEM_MODEL:String = "GrillRight"
    static let GRILL_RIGHT_DEFAULT_NAME:String = "GrillRight Thermometer"
    static let SERVICE_GRILL_RIGHT:String = "2899FE00-C277-48A8-91CB-B29AB0F01AC4"
    
    // GrillRight custom UUIDs
    static let CHARACTERISTIC_ID_CONTROL = CBUUID(string: "28998E03-C277-48A8-91CB-B29AB0F01AC4");
    
    static let CHARACTERISTIC_ID_SENSOR1 = CBUUID(string: "28998E10-C277-48A8-91CB-B29AB0F01AC4");
    
    static let CHARACTERISTIC_ID_SENSOR2 = CBUUID(string: "28998E11-C277-48A8-91CB-B29AB0F01AC4");
    
    // Battery Service UUIDs
    static let SERVICE_BATTERY = CBUUID(string: "0000180F-0000-1000-8000-00805f9b34fb");
    
    static let CHARACTERISTIC_ID_BATTERY_LEVEL = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb");
    
    // Property names
    static let PROP_SENSOR1_TEMP:String = "00:grillrt:TEMP"
    static let PROP_SENSOR2_TEMP:String = "01:grillrt:TEMP"
    static let PROP_SENSOR1_MEAT:String = "00:grillrt:MEAT"
    static let PROP_SENSOR2_MEAT:String = "01:grillrt:MEAT"
    static let PROP_SENSOR1_DONENESS:String = "00:grillrt:DONENESS"
    static let PROP_SENSOR2_DONENESS:String = "01:grillrt:DONENESS"
    static let PROP_SENSOR1_TARGET_TEMP:String = "00:grillrt:TARGET_TEMP"
    static let PROP_SENSOR2_TARGET_TEMP:String = "01:grillrt:TARGET_TEMP"
    static let PROP_SENSOR1_PCT_DONE:String = "00:grillrt:PCT_DONE"
    static let PROP_SENSOR2_PCT_DONE:String = "01:grillrt:PCT_DONE"
    static let PROP_SENSOR1_COOKING:String = "00:grillrt:COOKING"
    static let PROP_SENSOR2_COOKING:String = "01:grillrt:COOKING"
    static let PROP_SENSOR1_TARGET_TIME:String = "00:grillrt:TARGET_TIME"
    static let PROP_SENSOR2_TARGET_TIME:String = "01:grillrt:TARGET_TIME"
    static let PROP_SENSOR1_TIME:String = "00:grillrt:TIME"
    static let PROP_SENSOR2_TIME:String = "01:grillrt:TIME"
    static let PROP_SENSOR1_CONTROL_MODE:String = "00:grillrt:CONTROL_MODE"
    static let PROP_SENSOR2_CONTROL_MODE:String = "01:grillrt:CONTROL_MODE"
    static let PROP_SENSOR1_ALARM:String = "00:grillrt:ALARM"
    static let PROP_SENSOR2_ALARM:String = "01:grillrt:ALARM"
    
    override var oemModel: String? {
        get {
            return super.oemModel ?? GrillRightDevice.GRILL_RIGHT_OEM_MODEL
        }
        set {
            super.oemModel = newValue
        }
    }
    
    override var model: String? {
        get {
            return super.model ?? GrillRightDevice.GRILL_RIGHT_MODEL
        }
        set {
            super.model = newValue
        }
    }
    override var productName: String? {
        get {
            return super.productName ?? GrillRightDevice.GRILL_RIGHT_DEFAULT_NAME
        }
        set {
            super.productName = newValue
        }
    }
    
    override var isConnectedLocal: Bool {
        get {
            return peripheral.state == .connected
        }
    }
    
    override func vendorCharacteristicsToFetch(for service: CBService) -> [CBUUID]? {
        return nil
    }
    
    var controlCharacteristic: CBCharacteristic?
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            switch characteristic.uuid {
            case GrillRightDevice.CHARACTERISTIC_ID_CONTROL:
                peripheral.setNotifyValue(true, for: characteristic)
                controlCharacteristic = characteristic
            case GrillRightDevice.CHARACTERISTIC_ID_SENSOR1:
                fallthrough
            case GrillRightDevice.CHARACTERISTIC_ID_SENSOR2:
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break;
            }
        }
    }
    
    override func servicesToDiscover() -> [CBUUID] {
        return [CBUUID(string: GrillRightDevice.SERVICE_GRILL_RIGHT)]
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        AylaLogI(tag: logTag, flag: 0, message:"Updated characteristic value: \(characteristic)")
        guard  let value = characteristic.value else {
            AylaLogE(tag: logTag, flag: 0, message:"Characteristic contais no value")
            return
        }
        var changes: [AylaChange]?
        switch characteristic.uuid {
        case GrillRightDevice.CHARACTERISTIC_ID_SENSOR1:
            changes = sensor1.update(fromData: value)
        case GrillRightDevice.CHARACTERISTIC_ID_SENSOR2:
            changes = sensor2.update(fromData: value)
        default:
            break
        }
        if let changes = changes {
            self.notifyChanges(toListeners: changes)
        }
    }
    override func value(for property: AylaLocalProperty) -> Any? {
        if !isConnectedLocal {
            return property.originalProperty.value as AnyObject?
        }
        switch property.name {
        case GrillRightDevice.PROP_SENSOR1_TEMP:
            return sensor1.currentTemp
        case GrillRightDevice.PROP_SENSOR1_MEAT:
            return sensor1.meatType.rawValue
        case GrillRightDevice.PROP_SENSOR1_DONENESS:
            return sensor1.doneness.rawValue
        case GrillRightDevice.PROP_SENSOR1_TARGET_TEMP:
            return sensor1.targetTemp
        case GrillRightDevice.PROP_SENSOR1_PCT_DONE:
            return sensor1.pctDone
        case GrillRightDevice.PROP_SENSOR1_COOKING:
            return sensor1.cooking == nil ? nil : sensor1.cooking! == 1
        case GrillRightDevice.PROP_SENSOR1_TARGET_TIME:
            return sensor1.targetTime
        case GrillRightDevice.PROP_SENSOR1_TIME:
            return sensor1.currentTime
        case GrillRightDevice.PROP_SENSOR1_CONTROL_MODE:
            return sensor1.controlMode.rawValue
        case GrillRightDevice.PROP_SENSOR1_ALARM:
            return sensor1.alarmState.rawValue
        case GrillRightDevice.PROP_SENSOR2_TEMP:
            return sensor2.currentTemp
        case GrillRightDevice.PROP_SENSOR2_MEAT:
            return sensor2.meatType.rawValue
        case GrillRightDevice.PROP_SENSOR2_DONENESS:
            return sensor2.doneness.rawValue
        case GrillRightDevice.PROP_SENSOR2_TARGET_TEMP:
            return sensor2.targetTemp
        case GrillRightDevice.PROP_SENSOR2_PCT_DONE:
            return sensor2.pctDone
        case GrillRightDevice.PROP_SENSOR2_COOKING:
            return sensor2.cooking == nil ? nil : sensor2.cooking! == 1
        case GrillRightDevice.PROP_SENSOR2_TARGET_TIME:
            return sensor2.targetTime
        case GrillRightDevice.PROP_SENSOR2_TIME:
            return sensor2.currentTime
        case GrillRightDevice.PROP_SENSOR2_CONTROL_MODE:
            return sensor2.controlMode.rawValue
        case GrillRightDevice.PROP_SENSOR2_ALARM:
            return sensor2.alarmState.rawValue
        default:
            return property.baseType.compare("string") == .orderedSame ? "" : 0
        }
    }
    
    override func setValue(_ value: Any, for property: AylaLocalProperty, success successBlock: (() -> Void)?, failure failureBlock: ((Error) -> Void)?) -> AylaGenericTask? {
        guard let controlCharacteristic = controlCharacteristic else {
            if let failureBlock = failureBlock {
                failureBlock(AylaErrorUtils.error(withDomain: AylaRequestErrorDomain, code: AylaRequestErrorCode.preconditionFailure.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Control characteristic was not discovered", comment: "")]) as Error)
            }
            return nil
        }
        if !isConnectedLocal {
            if let failureBlock = failureBlock {
                failureBlock(AylaErrorUtils.error(withDomain: AylaRequestErrorDomain, code: AylaRequestErrorCode.preconditionFailure.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Properties are read-only unless the device is connected locally", comment: "")]))
            }
            return nil
        }
        var command = NSMutableData();
        var sensorCopy: InternalSensor
        var index: Int
        var sensor: InternalSensor
        var update: (() -> ())?
        if property.name.contains("00:") {
            sensor = sensor1
            sensorCopy = InternalSensor(sensor: sensor1)
            index = 1
        } else {
            sensor = sensor2
            sensorCopy = InternalSensor(sensor: sensor2)
            index = 2
        }
        
        //cooking command has a different structure, so consider its case in a separate if instead of inside switch
        if  property.name.contains("COOKING") {
            guard let mode = ControlMode(rawValue: value as! Int) else {
                return nil
            }
            if mode == .none {
                command = Command.stopCookingCommand(index)
            } else {
                command = Command.startCookingCommand(index, mode: mode)
            }
            update = {
                sensor.controlMode = mode
            }
        } else {
            switch property.name {
            case (let p) where p.contains("MEAT"):
                guard let meatType = MeatType(rawValue: value as! Int) else {
                    return nil
                }
                sensorCopy.meatType = meatType
                update = {
                    sensor.meatType = meatType
                }
                
            case (let p) where p.contains("DONENESS"):
                guard let doneness = Doneness(rawValue: value as! Int) else {
                    return nil
                }
                sensorCopy.doneness = doneness
                update = {
                    sensor.doneness = doneness
                }
                
            case (let p) where p.contains("TARGET_TEMP"):
                guard let targetTemp = value as? Int else {
                    return nil
                }
                sensorCopy.targetTemp = targetTemp
                update = {
                    sensor.targetTemp = targetTemp
                }
                
            case (let p) where p.contains("TARGET_TIME"):
                guard let targetTime = value as? String else {
                    return nil
                }
                sensorCopy.targetTime = targetTime
                update = {
                    sensor.targetTime = targetTime
                }
                
            default:
                AylaLogD(tag: logTag, flag: 0, message:"Unknown property \(property.name)")
                return nil
            }
            command = Command.setFields(sensorCopy)
        }
        
        
        return self.write(command as Data, to: controlCharacteristic, type: CBCharacteristicWriteType.withResponse, success: {
            if let update = update {
                update()
            }
            if let successBlock = successBlock {
                successBlock()
            }
        }, failure: failureBlock)
    }
}
