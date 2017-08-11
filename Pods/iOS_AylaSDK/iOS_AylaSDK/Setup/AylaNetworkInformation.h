//
//  AylaNetworkInformation.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 3/7/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 Provides information about the current network.
 */
@interface AylaNetworkInformation : NSObject

/**
 @return The name of the Current SSID
 */
+ (nullable NSString *)ssid;

/**
 Used to determine if the current SSID matches the regex of an Ayla device SSID.
 
 @param `deviceSSIDRegex` the regex to match
 @return YES if the current SSID matches `deviceSSIDRegex`, NO otherwise
 */
+ (BOOL)connectedToAPWithRegEx:(NSString *)deviceSSIDRegex;
@end

NS_ASSUME_NONNULL_END
