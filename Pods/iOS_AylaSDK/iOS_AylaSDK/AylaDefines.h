//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Current Library Version
 */
#define AYLA_SDK_VERSION @"5.6.00"

#if __has_feature(objc_generics) || __has_extension(objc_generics)
#define AYLA_GENERIC(...) <__VA_ARGS__>
#else
#define AYLA_GENERIC(...)
#endif

/**
 * Service types supported by Ayla Cloud Service
 */
typedef NS_ENUM(uint16_t, AylaServiceType) {
    
    /** Ayla Development Service */
    AylaServiceTypeDevelopment = 0,

    /** Ayla Field Service */
    AylaServiceTypeField,

    /** Ayla Staging Service. */
    AylaServiceTypeStaging,

    /** Ayla Demo Service */
    AylaServiceTypeDemo
};

/**
 * HTTP Client types
 */
typedef NS_ENUM(uint16_t, AylaHTTPClientType) {
    /** HTTP Client which connects to Device Service */
    AylaHTTPClientTypeDeviceService = 0,
    
    /** HTTP Client which connects to User Service */
    AylaHTTPClientTypeUserService = 1,
    
    /** HTTP Client which connects to Log Service */
    AylaHTTPClientTypeLogService = 2,
    
    /** HTTP Client which connects to Stream Service */
    AylaHTTPClientTypeStreamService = 3,
    
    /** HTTP Client which subscribes to Stream Service */
    AylaHTTPClientTypeMDSSService = 4
};

/**
 * Service locations supported by Ayla Cloud Service
 */
typedef NS_ENUM(uint16_t, AylaServiceLocation) {
    /** Ayla USA Service */
    AylaServiceLocationUS = 0,

    /** Ayla China Service */
    AylaServiceLocationCN = 1,

    /** Ayla EU Service */
    AylaServiceLocationEU = 2
};

/**
 * Enumerates the types of Ayla DataSources
 */
typedef NS_ENUM(uint16_t, AylaDataSource) {
    /** Data from cloud service */
    AylaDataSourceCloud = 1 << 0,

    /** Data from LAN Mode */
    AylaDataSourceLAN = 1 << 1,

    /** Data from data stream service */
    AylaDataSourceDSS = 1 << 2,

    /** Data from local cache */
    AylaDataSourceCache = 1 << 4
};

/**
 Enumerates the supported registration types.
 */
typedef NS_ENUM(NSInteger, AylaRegistrationType) {
    /**
     Not a real registration type; this value is used as a filter parameter to allow any registration type to be included
     in the results
     @see `[AylaRegistration fetchCandidateWithDSN:registrationType:success:failure:]`
     */
    AylaRegistrationTypeAny = 0,
    /**
     `AylaRegistrationTypeSameLan` is used when both the phone/tablet and the connected device are in the same LAN.
     Call `[AylaRegistration registerCandidate:success:failure:]` to get a candidate with this type of registration.
     */
    AylaRegistrationTypeSameLan,
    /**
     `AylaRegistrationTypeButtonPush` is similar to `AylaRegistrationTypeSameLan`, except the user must push a button on the
     connected device to make it available for registration. After pushing the button it will be available for registration  
     for a limited time.
     */
    AylaRegistrationTypeButtonPush,
    /**
     `AylaRegistrationTypeAPMode` can be used after performing Wi-Fi setup.
     */
    AylaRegistrationTypeAPMode,
    /**
     Requires a `registrationToken` to register the connected device.
     */
    AylaRegistrationTypeDisplay,
    /**
     Requires knowing the DSN of the candidate.
     */
    AylaRegistrationTypeDsn,
    /**
     Required for devices connected through an `AylaDeviceGateway`
     */
    AylaRegistrationTypeNode,
    /**
     `AylaRegistrationTypeNone` (OEM) registration type means pre-registered to an OEM based on device oem_model.
     */
    AylaRegistrationTypeNone
};

/**
 * Subscription types
 */
typedef NS_OPTIONS(uint16_t, AylaDSSubscriptionType) {
    /**
     * Subscription type of device connectivity.
     */
    AylaDSSubscriptionTypeConnectivity = 1 << 0,
    /**
     * Subscription type of datapoint update.
     */
    AylaDSSubscriptionTypeDatapoint = 1 << 1,
    /**
     * Subscription type of datapoint ack.
     */
    AylaDSSubscriptionTypeDatapointAck = 1 << 2,
};
