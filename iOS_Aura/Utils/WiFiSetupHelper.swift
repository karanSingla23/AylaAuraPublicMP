//
//  WiFiManager.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/12/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

typealias WiFiConfiguration = (device: AylaSetupDevice?, ssid :String, time :Date)
/// Use to keep track of the SSID configured during WiFi setup to compare it with
/// the WiFi the phone has reconnected.
class WiFiSetupHelper: NSObject {
    
    static let shared = WiFiSetupHelper()
    
    var configurationSent :WiFiConfiguration?
    
    
    /// Call this method when the ssid configuration has been sent to device
    ///
    /// - Parameter ssid: the ssid configured in the device
    func recordConfigurationSent(toDevice device:AylaSetupDevice?, withSSID ssid:String?) {
        guard let ssid = ssid else {
            return
        }
        
        self.configurationSent = (device: device, ssid: ssid, time: Date())
    }
    
    
    /// Returns whether the phone's current SSID is the same as the one sent to device
    var isCurrentSSIDSameAsSent :Bool {
        get {
            let currentSSID = AylaNetworkInformation.ssid()
            return currentSSID == self.configurationSent?.ssid
        }
    }
}

func goToWiFiSettings() {
    let settingsURLs = [ "prefs:root=WIFI", "App-Prefs:root=WIFI", UIApplicationOpenSettingsURLString ]
    for urlString in settingsURLs {
        let url = URL(string: urlString)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
}
