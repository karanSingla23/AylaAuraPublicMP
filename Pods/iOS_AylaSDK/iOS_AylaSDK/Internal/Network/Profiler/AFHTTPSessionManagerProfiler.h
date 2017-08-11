//
//  AFHTTPSessionManagerProfiler.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "AylaProfiler.h"


/**
 This class helps determine the network time it takes for a Cloud API to be performed. It's a replacement of AFHTTPSessionManager and is disabled by default.
 */
@interface AFHTTPSessionManagerProfiler : AFHTTPSessionManager

@end
