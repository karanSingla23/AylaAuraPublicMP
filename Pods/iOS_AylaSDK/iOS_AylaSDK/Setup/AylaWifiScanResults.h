//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"
#import "AylaObject.h"

/**
 * Represents a Wi-Fi scan result in `results` list of an AylaWifiScanResults instance.
 */
@interface AylaWifiScanResult : AylaObject

/** SSID in string */
@property (nonatomic, strong) NSString *ssid;

/** SSID type */
@property (nonatomic, strong, readonly) NSString *type;

/** Chanel this SSID is on */
@property (nonatomic, assign, readonly) int chan;

/** Signal strength */
@property (nonatomic, assign, readonly) int signal;

/** Bars */
@property (nonatomic, assign, readonly) int bars;

/** A string which describes security type of this SSID */
@property (nonatomic, strong, readonly) NSString *security;

/** BSSID in string */
@property (nonatomic, strong, readonly) NSString *bssid;

@end

/**
 * Represents Wi-Fi scan results fetched from setup device.
 */
@interface AylaWifiScanResults : AylaObject

/** MTime at which this results is scanned by setup device */
@property (nonatomic, assign, readonly) NSUInteger mtime;

/** List of scanned results */
@property (nonatomic, strong, readonly) NSArray AYLA_GENERIC(AylaWifiScanResult *) * results;

@end
