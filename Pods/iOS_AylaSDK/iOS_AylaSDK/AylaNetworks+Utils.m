//
//  AylaNetworks+Utils.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/12/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaNetworks+Utils.h"
#import "AylaProperty+Internal.h"
#import "AylaHTTPClient.h"

@implementation AylaNetworks (Utils)

+ (void)enableNetworkProfiler {
    [AylaHTTPClient enableNetworkProfiler];
    [AylaProperty enableNetworkProfiler];
}
@end
