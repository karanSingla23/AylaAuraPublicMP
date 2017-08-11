//
//  Constants.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation

let AuraSessionOneName = "SessionOne"
let AuraUsernameKeychainKey = "AuraUsername"

let AuraDeviceSetupDSNKeychainKey = "AuraSetupDSN"
let AuraDeviceSetupTokenKeychainKey = "AuraSetupToken"

struct AuraNotifications {
    static let SharesChanged = "DeviceSharesChangedNotification"
    static let WechatOAuthResponse = "WechatOAuthResponseNotification"
}

struct AuraOptions {
    static let EasterEgg    = "aylarocks"
    
    /** The AppIDs and AppSecrets below are created using the OEM Dashboard in the Apps tab.
     // Note there is an OEM Dashboard per Ayla region and sevice.
     // The link to the region OEM dashboard is included as a comment above the appId/appSecret assignment.
     // Only use a OEM Dashboard for OEM scoped activities like appId, APNS Cert association, email templates, etc.
     // Don't use a OEM Dashboard to change your test device as the user scope mismatch will cause permission errors.
     // Use the app you are developing or the Developer Site for individual device changes and testing.
    */
    
    // The Ayla Staging Service is for Ayla employees only
    // OEM Dashboard: https://test-dashboard.ayladev.com
    // Developer Site: https://staging-developer.ayladev.com
    static let AppIdStaging     = "aura_0dfc7900-dev-id"
    static let AppSecretStaging = "aura_0dfc7900-dev-Dc3OtN_li7Xdepo_7SmXbcjCXxM"
    
    // Use same as Staging
    static let AppIdDemo     = "aura_0dfc7900-dev-id"
    static let AppSecretDemo = "aura_0dfc7900-dev-Dc3OtN_li7Xdepo_7SmXbcjCXxM"

    // OEM Dashboard:  https://dashboardInternal.aylanetworks.com
    // Developer Site: https://developer.aylanetworks.com
    static let AppIdUSDev     = "aura-id"
    static let AppSecretUSDev = "aura-1_DkR0acNwWjilHQZXKTsOkdSFg"
    
    // OEM Dashboard:  https://dashboardField.aylanetworks.com
    // Developer Site: Development on field service is not allowed
    static let AppIdUSField     = "aura-id"
    static let AppSecretUSField = "aura-1_DkR0acNwWjilHQZXKTsOkdSFg"

    // OEM Dashboard: https://dashboardinternal.ayla.com.cn
    // Developer Site: https://developer.ayla.com.cn/
    static let AppIdCNDev     = "aura_0dfc7900-cn-id"
    static let AppSecretCNDev = "aura_0dfc7900-cn-he7ncN42HIKZwugpftx-Y_qeWqw"
    
    // OEM Dashboard: https://dashboard.ayla.com.cn/
    // Developer Site: Development on field service is not allowed
    static let AppIdCNField     = "aura_0dfc7900-cn-id"
    static let AppSecretCNField = "aura_0dfc7900-cn-he7ncN42HIKZwugpftx-Y_qeWqw"
    
    // OEM Dashboard: None - Use USA development service
    // Developer Site: None - Use USA development service
    static let AppIdEUDev     = "aura_0dfc7900-eu-id"
    static let AppSecretEUDev = "aura_0dfc7900-eu-KfOrfhadpSZcjr_dgmpQlC5MoU0"
    
    // OEM Dashboard: https://dashboard-field-eu.aylanetworks.com
    // Developer Site: Development on field service is not allowed
    static let AppIdEUField     = "aura_0dfc7900-eu-id"
    static let AppSecretEUField = "aura_0dfc7900-eu-KfOrfhadpSZcjr_dgmpQlC5MoU0"
    
    static let KeyServiceLocation = "service_location"
    static let KeyServiceType     = "service_type"
    
    static let WechatAppId = "wxe450e4ee1187148c"
}
