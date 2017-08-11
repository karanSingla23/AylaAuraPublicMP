//
//  AylaDeviceCommand.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaDeviceCommand.h"
#import "AylaObject+Internal.h"
#import "AylaLocalOTACommand.h"
#import "AylaNetworks.h"

NSString * const CMD_OTA = @"ota";

@implementation AylaDeviceCommand
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing  _Nullable *)error {
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        _id = [dictionary[@"id"] integerValue];
        _type = dictionary[@"cmd_type"];
        _data = dictionary[@"data"];
        _deviceId = [dictionary[@"device_id"] integerValue];
        _method = dictionary[@"method"];
        _resource = dictionary[@"resource"];
        _ack = [dictionary[@"ack"] boolValue];
        _ackedAt = dictionary[@"acked_at"];
        _createdAt = dictionary[@"created_at"];
        _updatedAt = dictionary[@"updated_at"];
    }
    return self;
}

- (id)getCommand {
    if ([self.type isEqualToString:CMD_OTA]) {
        NSData *otaData = [(NSString *)self.data dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonParsingError = nil;
        NSDictionary *otaDictionary = [NSJSONSerialization JSONObjectWithData:otaData options:0 error:&jsonParsingError];
        if (jsonParsingError) {
            AylaLogE([self logTag], 0, @"OTA Parsing error: %@", jsonParsingError);
            return nil;
        }
        AylaLocalOTACommand *command = [[AylaLocalOTACommand alloc] initWithJSONDictionary:otaDictionary[@"ota"] error:nil];
        command.commandId = self.id;
        return command;
    }
    return nil;
}

- (NSString *)logTag {
    return NSStringFromClass([AylaDeviceCommand class]);
}
@end
