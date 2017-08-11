//
//  AylaDevice+Extensible.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDevice+Extensible.h"
NSString *const AylaDeviceConnectionStatusOnline = @"Online";
NSString *const AylaDeviceConnectionStatusOffline = @"Offline";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation AylaDevice (Extensible)
@dynamic key;
@dynamic productName;
@dynamic model;
@dynamic dsn;
@dynamic oemModel;
@dynamic deviceType;
@dynamic connectedAt;
@dynamic mac;
@dynamic lanIp;
@dynamic swVersion;
@dynamic ssid;
@dynamic productClass;
@dynamic ip;
@dynamic lanEnabled;
@dynamic connectionStatus;
@dynamic templateId;
@dynamic lat;
@dynamic lng;
@dynamic userId;
@dynamic moduleUpdatedAt;
@dynamic lanModeUnavailable;

- (instancetype)initExtensible {
    return [super init];
}
@end
#pragma clang diagnostic pop
