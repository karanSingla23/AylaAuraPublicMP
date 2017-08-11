//
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class DeviceDetailProvider: NSObject, AylaDeviceDetailProvider {
    
    let deviceType_gateway = "Gateway"
    
    let oemModel_ledevb = "ledevb"
    let oemModel_generic = "generic"
    
    let ledevb_managedProperties = ["Blue_LED", "Green_LED", "Blue_button","Red_Led"]
    let genericGateway_managedProperties = ["join_enable", "join_status", "cmd", "log"]

    func monitoredPropertyNames(for device: AylaDevice) -> [Any]? {
        if device.oemModel == oemModel_ledevb {
            return ledevb_managedProperties as [AnyObject]?
        }
        else if device.oemModel == oemModel_generic && device.deviceType == deviceType_gateway {
            return genericGateway_managedProperties as [AnyObject]?
        }
        else if let propertyNames = device.properties?.keys {
            return Array(propertyNames) as [AnyObject]?;
        }
        return nil;
    }
}
