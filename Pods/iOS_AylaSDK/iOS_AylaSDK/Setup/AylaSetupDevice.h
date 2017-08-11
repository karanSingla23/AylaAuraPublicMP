//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"
#import "AylaLanSupportDevice.h"
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents an device that is used by discovered by AylaSetup. This device should only be used
 * during the WiFi setup process and is not considered part of the user's set of devices.
 */
@interface AylaSetupDevice : AylaObject<AylaLanSupportDevice>

/** @name Setup Device Properties */

/** Device dsn */
@property (nonatomic, strong, readonly) NSString *dsn;

/** Device lan ip */
@property (nonatomic, strong, readonly) NSString *lanIp;

/** Device MAC address */
@property (nonatomic, strong, readonly, nullable) NSString *mac;

/** Device model */
@property (nonatomic, strong, readonly) NSString *model;

/** Device key assigned by cloud service */
@property (nonatomic, strong, readonly, nullable) NSNumber *key;

/** Device service url */
@property (nonatomic, strong, readonly, nullable) NSString *deviceService;

/** Setup features supported by current device */
@property (nonatomic, strong, readonly, nullable) NSArray AYLA_GENERIC(NSString *) * features;

/** MTime at which the module last successfully connected to the service */
@property (nonatomic, strong, readonly, nullable) NSNumber *lastConnectMtime;

/** Time at which the module last successfully connected to the service */
@property (nonatomic, strong, readonly, nullable) NSNumber *lastConnectTime;

/** Current mtime */
@property (nonatomic, strong, readonly, nullable) NSNumber *mtime;

/** Module version */
@property (nonatomic, strong, readonly, nullable) NSString *version;

/** Api version */
@property (nonatomic, strong, readonly, nullable) NSString *apiVersion;

/** Build version */
@property (nonatomic, strong, readonly, nullable) NSString *build;

/** If SDK is connected to this device */
@property (nonatomic, assign, readonly) BOOL connected;

/** Registration type that must be used to register the device */
@property (nonatomic, assign, readonly) AylaRegistrationType registrationType;

/** The device type of the setup device */
@property (nonatomic, strong, readonly, nullable) NSString *deviceType;

/**
 * Regular expression used to determine if SDK is currently connected to a device
 */
@property (nonatomic, strong) NSString *deviceSSIDRegex;
@end

NS_ASSUME_NONNULL_END
