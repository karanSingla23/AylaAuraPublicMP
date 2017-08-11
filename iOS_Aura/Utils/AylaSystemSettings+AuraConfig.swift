//
//   AylaSystemSettings+AuraConfig.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 9/2/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

extension AylaServiceType {
    func name() -> String? {
        switch self {
            
        case .field:
            return "Field"
            
        case .staging:
            return "Staging"
            
        case .development:
            return "Development"
            
        case .demo:
            return "Demo"
        }
    }
}

extension AylaServiceLocation {
    func name() -> String? {
        switch self {
        case .CN:
            return "China"
            
        case .EU:
            return "Europe"
            
        case .US:
            return "USA"
        }
    }
}

extension AylaServiceLocation {
    func locationForName(_ name:String!) -> AylaServiceLocation! {
        switch name {
        case "China", "CN":
            return .CN
            
        case "Europe", "EU":
            return .EU
            
        case "United States", "US", "USA":
            return .US
            
        default:
            return .US
        }
    }
}


extension AylaSystemSettings {
    public func toConfigDictionary(_ name:String) -> Dictionary<String, AnyObject>?{
        guard let serviceType = self.serviceType.name()
            else {
                return nil
        }
        
        
        guard let serviceLocation = self.serviceLocation.name()
            else {
                return nil
        }
        
        
        let dictionary = [
            "allowDSS": allowDSS,
            "allowOfflineUse": allowOfflineUse,
            "appId": appId,
            "appSecret": appSecret,
            "defaultNetworkTimeoutMs": defaultNetworkTimeout,
            "name": name,
            "serviceLocation": serviceLocation,
            "serviceType": serviceType
        ] as [String : Any]
        return dictionary as Dictionary<String, AnyObject>
    }
    
    public func aura_copy () -> AylaSystemSettings {
        let auraCopy = AylaSystemSettings()
        auraCopy.appId = appId
        auraCopy.appSecret = appSecret
        auraCopy.serviceType = serviceType
        auraCopy.serviceLocation = serviceLocation
        auraCopy.defaultNetworkTimeout = defaultNetworkTimeout
        auraCopy.deviceDetailProvider = deviceDetailProvider
        auraCopy.allowDSS = allowDSS
        auraCopy.allowOfflineUse = allowOfflineUse
        return auraCopy
    }
}
