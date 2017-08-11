//
//  AylaNetworks+Utils.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/12/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK
extension AylaNetworks {
    
    /// Aura extension of initialize with local device support
    ///
    /// - Parameters:
    ///   - settings: Settings of the SDK
    ///   - enableLocalDevices: true if local device plugin should be installed, false otherwise
    static func initialize(_ settings: AylaSystemSettings, withLocalDevices enableLocalDevices: Bool) {
        AylaNetworks.initialize(with: settings)
        
        if enableLocalDevices {
            let localDeviceManager = AuraLocalDeviceManager();
            AylaNetworks.shared().installPlugin(localDeviceManager, id: PLUGIN_ID_DEVICE_CLASS)
            AylaNetworks.shared().installPlugin(localDeviceManager, id: AuraLocalDeviceManager.PLUGIN_ID_LOCAL_DEVICE)
            AylaNetworks.shared().installPlugin(localDeviceManager, id: PLUGIN_ID_DEVICE_LIST)
        }
    }
}
