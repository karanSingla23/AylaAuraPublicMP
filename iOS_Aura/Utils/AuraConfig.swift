//
//  AuraConfig.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class AuraConfig {
    
    static let KeyCurrentConfig = "current_config"
    static let KeyCurrentConfigName = "current_config_name"
    
    static let ConfigNameStaging  = "US Staging"
    static let ConfigNameUSDev      = "US Development"
    static let ConfigNameUSField    = "US Field"
    static let ConfigNameUSDemo      = "US Demo"
    static let ConfigNameCNDev      = "CN Development"
    static let ConfigNameCNField    = "CN Field"
    static let ConfigNameEUDev      = "EU Development"
    static let ConfigNameEUField    = "EU Field"
    
    static let configStaging = ["appId": AuraOptions.AppIdStaging, "appSecret": AuraOptions.AppSecretStaging, "serviceType": "Staging", "serviceLocation": "US"]
    static let configUSDev = ["appId": AuraOptions.AppIdUSDev, "appSecret": AuraOptions.AppSecretUSDev, "serviceType": "Development", "serviceLocation": "US"]
    static let configUSField = ["appId": AuraOptions.AppIdUSField, "appSecret": AuraOptions.AppSecretUSField, "serviceType": "Field", "serviceLocation": "US"]
    static let configUSDemo = ["appId": AuraOptions.AppIdDemo, "appSecret": AuraOptions.AppSecretDemo, "serviceType": "Demo", "serviceLocation": "US"]
    static let configCNDev = ["appId": AuraOptions.AppIdCNDev, "appSecret": AuraOptions.AppSecretCNDev, "serviceType": "Development", "serviceLocation": "CN"]
    static let configCNField = ["appId": AuraOptions.AppIdCNField, "appSecret": AuraOptions.AppSecretCNField, "serviceType": "Field", "serviceLocation": "CN"]
    static let configEUDev = ["appId": AuraOptions.AppIdEUDev, "appSecret": AuraOptions.AppSecretEUDev, "serviceType": "Development", "serviceLocation": "EU"]
    static let configEUField = ["appId": AuraOptions.AppIdEUField, "appSecret": AuraOptions.AppSecretEUField, "serviceType": "Field", "serviceLocation": "EU"]
    
    
    static let defaultConfigurations = [
        AuraConfig(name: ConfigNameUSDev, config: configUSDev as NSDictionary),
        AuraConfig(name: ConfigNameUSField, config: configUSField as NSDictionary),
        AuraConfig(name: ConfigNameUSDemo, config: configUSDemo as NSDictionary),
        AuraConfig(name: ConfigNameCNDev, config: configCNDev as NSDictionary),
        AuraConfig(name: ConfigNameCNField, config: configCNField as NSDictionary),
        AuraConfig(name: ConfigNameEUDev, config: configEUDev as NSDictionary),
        AuraConfig(name: ConfigNameEUField, config: configEUField as NSDictionary),
    ]
    
    static let stagingConfig = AuraConfig(name: ConfigNameStaging, config: configStaging as NSDictionary)

    static let extendedDefaultConfigurations = [stagingConfig] + defaultConfigurations
    
    /**
     Save AuraConfig to UserDefaults
     */
    static func saveConfig(_ config: AuraConfig) {
        let defaults = UserDefaults.standard
        defaults.set(config.name, forKey: KeyCurrentConfigName)
        defaults.set(config.config, forKey: KeyCurrentConfig)
    }
    
    /**
     Get current saved Aura Config. If no configs saved, return US Development Config.
     */
    static func currentConfig() -> AuraConfig {
        let defaults = UserDefaults.standard
        if let savedConfig = defaults.object(forKey: KeyCurrentConfig) as? NSDictionary,
            let configName = defaults.string(forKey: KeyCurrentConfigName) {
            return AuraConfig(name: configName, config: savedConfig)
        }
        else {
            return defaultConfigurations[0]
        }
    }
    
    /**
     Returns a boolean indicating whether a custom AuraConfig is currently in use.
     */
    static func usingCustomConfig() -> Bool! {
        let defaults = UserDefaults.standard
        if (defaults.object(forKey: AuraConfig.KeyCurrentConfig) as? NSDictionary) != nil {
            if defaults.string(forKey: KeyCurrentConfigName) != ConfigNameUSDev {
                return true
            }
        }
        return false
    }
    
    var name:String!
    var config:NSDictionary!
    
    init (name:String, config:NSDictionary) {
        self.name = name
        self.config = config
    }
    
    func applyTo(_ settings: AylaSystemSettings) {
        settings.appId = config["appId"] as! String
        settings.appSecret = config["appSecret"] as! String
        
        if let type = config["serviceType"] as? String {
            switch type {
                
            case "Field":
                settings.serviceType = .field
                
            case "Staging":
                settings.serviceType = .staging
                
            case "Demo":
                settings.serviceType = .demo
                
            default:
                settings.serviceType = .development
            }
        }
        
        if let location = config["serviceLocation"] as? String {
            switch location {
            case "CN", "China":
                settings.serviceLocation = .CN
                
            case "EU", "Europe":
                settings.serviceLocation = .EU
                
            default:
                settings.serviceLocation = .US
            }
        }
        
        if let allowDSS = config["allowDSS"] as? Bool {
            settings.allowDSS = allowDSS
        }
        if let allowOfflineUse = config["allowOfflineUse"] as? Bool {
            settings.allowOfflineUse = allowOfflineUse
        }
        if let defaultNetworkTimeoutMs = config["defaultNetworkTimeoutMs"] as? Int {
            settings.defaultNetworkTimeout = Double(defaultNetworkTimeoutMs / 1000)
        }
    }
    
    static func createConfig(_ name:String, fromSettings settings:AylaSystemSettings, devices:[[String:AnyObject]]?) throws -> Data? {
        guard let inmutableConfig = settings.toConfigDictionary(name)
            else {
                return nil
        }
        let config = NSMutableDictionary(dictionary: inmutableConfig)
        
        if devices?.count > 0 {
            config["managedDevices"] = devices!
        }
        
        return try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
    }
}
