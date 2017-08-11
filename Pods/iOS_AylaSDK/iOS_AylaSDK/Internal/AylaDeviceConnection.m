//
//  AylaDeviceConnection.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 5/17/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaDeviceConnection.h"
#import "AylaObject+Internal.h"
#import "NSObject+Ayla.h"

@implementation AylaDeviceConnection

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing  _Nullable *)error {
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        _eventTime = [dictionary[@"event_time"] nilIfNull];
        _userUUID = [dictionary[@"user_uuid"] nilIfNull];
        _status = [dictionary[@"status"] nilIfNull];
    }
    return self;
}
@end
