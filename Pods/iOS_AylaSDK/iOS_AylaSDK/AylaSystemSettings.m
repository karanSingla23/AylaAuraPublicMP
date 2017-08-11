//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaSystemSettings.h"

@implementation AylaSystemSettings

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    _appId = AYLA_SETTINGS_NOT_ASSIGNED;
    _appSecret = AYLA_SETTINGS_NOT_ASSIGNED;
    _serviceType = AYLA_SETTINGS_DEFAULT_SERVICE_TYPE;
    _serviceLocation = AYLA_SETTINGS_DEFAULT_SERVICE_LOCATION;
    _defaultNetworkTimeout = AYLA_SETTINGS_DEFAULT_NETWORK_TIMEOUT;
    _fallbackDeviceLANIP = AYLA_SETTINGS_DEFAULT_SETUP_DEVICE_IP;
    _deviceSSIDRegex = AYLA_SETTINGS_DEFAULT_DEVICE_SSID_REGEX;
    _dssSubscriptionType = AYLA_SETTINGS_DEFAULT_DSS_TYPE;

    return self;
}

+ (instancetype)defaultSystemSettings
{
    return [[self alloc] init];
}

// <NSCopying>
- (id)copyWithZone:(NSZone *)zone
{
    AylaSystemSettings *copy = [[[self class] allocWithZone:zone] init];

    copy.allowDSS = self.allowDSS;
    copy.appId = self.appId;
    copy.appSecret = self.appSecret;
    copy.serviceType = self.serviceType;
    copy.serviceLocation = self.serviceLocation;
    copy.deviceDetailProvider = self.deviceDetailProvider;
    copy.fallbackDeviceLANIP = self.fallbackDeviceLANIP;

    return copy;
}

@end
