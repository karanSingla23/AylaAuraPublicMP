//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"
#import "AylaDeviceDetailProvider.h"

NS_ASSUME_NONNULL_BEGIN

/** Default service type */
#define AYLA_SETTINGS_DEFAULT_SERVICE_TYPE AylaServiceTypeDevelopment

/** Default service type */
#define AYLA_SETTINGS_DEFAULT_SERVICE_LOCATION AylaServiceLocationUS

/** A string value which indicates an unconfigured setting */
#define AYLA_SETTINGS_NOT_ASSIGNED @"Not-Assigned"

/** A string value which indicates an unconfigured setting */
#define AYLA_SETTINGS_DEFAULT_NETWORK_TIMEOUT 5

#define AYLA_SETTINGS_DEFAULT_SETUP_DEVICE_IP @"192.168.0.1"

#define AYLA_SETTINGS_DEFAULT_DEVICE_SSID_REGEX @"((^Ayla)|(^Sina-Mobile)|(^T-Stat))-[0-9A-Fa-f]{12}";

#define AYLA_SETTINGS_DEFAULT_DSS_TYPE AylaDSSubscriptionTypeDatapoint;

/**
 *  Contains a list of system level settings. `AylaNetworks` must use
 *  an instance of this class to complete initialize.
 */
@interface AylaSystemSettings : NSObject<NSCopying>

/** @name System Settings Properties */

/** Application ID */
@property (nonatomic, copy) NSString *appId;

/** Application secret */
@property (nonatomic, copy) NSString *appSecret;

/** Service type */
@property (nonatomic) AylaServiceType serviceType;

/** Service location */
@property (nonatomic) AylaServiceLocation serviceLocation;

/** Default timeout for all calls */
@property (nonatomic) NSTimeInterval defaultNetworkTimeout;

/** An object which conforms to the `AylaDeviceDetailProvider` protocol */
@property (nonatomic) id<AylaDeviceDetailProvider> deviceDetailProvider;

/** Set if Mobile Data Stream Service (DSS) is required for this application */
@property (nonatomic) BOOL allowDSS;
/** Set the DSS subscription type, default is `AylaDSSubscriptionTypeDatapoint` only */
@property (nonatomic) AylaDSSubscriptionType dssSubscriptionType;

/**
 * Indicates whether LAN Login should be allowed.
 */
@property (nonatomic) BOOL allowOfflineUse;

/**
 * Regular expression used to determine if SDK is currently connected to a device
 */
@property (nonatomic, copy) NSString *deviceSSIDRegex;


/**
 * IP that will be used in case SDK fails to determine the device IP during WiFi setup
 */
@property (nonatomic, copy) NSString *fallbackDeviceLANIP;

/** @name Initializer Methods */

/**
 *  Use this method to get default system settings.
 *
 *  @return `AylaSystemSettings` object with default setting values.
 */
+ (instancetype)defaultSystemSettings;

@end

NS_ASSUME_NONNULL_END
