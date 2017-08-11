//
//  AylaNetworkInformation.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 3/7/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaNetworkInformation.h"
#import "NSObject+Ayla.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation AylaNetworkInformation
+ (NSDictionary *)information {
    
    NSArray *iface = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSDictionary* info = (__bridge_transfer id) CNCopyCurrentNetworkInfo((__bridge CFStringRef)([iface objectAtIndex:0]));
    return info;
}

+ (NSString *)ssid {
    return [[[self information][@"SSID"] nilIfNull] copy];
}


+ (BOOL)connectedToAPWithRegEx:(NSString *)deviceSSIDRegex {
    NSString *ssid = [AylaNetworkInformation ssid];
    if (ssid == nil) {
        return NO;
    }
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:deviceSSIDRegex
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:ssid
                                                        options:0
                                                          range:NSMakeRange(0, [ssid length])];
    return numberOfMatches == 0 ? NO : YES;
}
@end
