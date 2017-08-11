//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * AylaDiscovery
 * 
 * A class which handles mDNS queries.
 */
@interface AylaDiscovery : NSObject

+ (void)getDeviceLanIpWithHostName:(NSString *)deviceHostName
                           timeout:(NSTimeInterval)timeout
                       resultBlock:(void (^)(NSString *lanIp, NSString *deviceHostName))resultBlock;

+ (void)cancelDiscovery;

@end
