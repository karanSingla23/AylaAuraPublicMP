//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaDeviceConnection.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceManager.h"
#import "AylaDSHandler.h"
#import "AylaDSMessage.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"

@implementation AylaDSHandler

- (instancetype)initWithDeviceManager:(AylaDeviceManager *)deviceManager
{
    self = [super init];
    if (!self) return self;

    _deviceManager = deviceManager;

    return self;
}

- (void)handleMessage:(AylaDSMessage *)message
{
    // Right now we only handle datapoint related data stream messages.
    switch (message.metadata.eventType) {
        case AylaDSMessageEventTypeDatapoint:
        case AylaDSMessageEventTypeDatapointAck:
            [self handleDatapointMessage:message];
            break;
        case AylaDSMessageEventTypeConnectivity:
            [self handleConnectivityMessage:message];
            break;
        default:
            break;
    }
}

- (void)handleDatapointMessage:(AylaDSMessage *)message
{
    NSString *dsn = message.metadata.dsn;
    NSString *propertyName = message.metadata.propertyName;
    AylaDatapoint *datapoint = message.datapoint;

    if (!dsn || !propertyName || !datapoint) {
        AylaLogE([self logTag], 0, @"Invalid msg(type:%d)", message.metadata.eventType);
        AylaLogD([self logTag], 0, @"Invalid msg - %@, %@, %@", dsn, propertyName, datapoint);
        return;
    }

    AylaDevice *device = self.deviceManager.devices[dsn];
    AylaProperty *property = device.properties[message.metadata.propertyName];

    // TODO: Api updateFromDatapoint: is not thead-safe in a concurrency environment. Should be deployed through device
    // queue or synchronization.
    if (!device.lanModule.isActive && property) {
        AylaPropertyChange *change = [property updateFromDatapoint:datapoint];
        if (change) {
            [device notifyChangesToListeners:@[ change ]];
        }
    }
}
- (void)handleConnectivityMessage:(AylaDSMessage *)message
{
    NSString *dsn = message.metadata.dsn;
    NSString *connectionStatus = message.connection.status;
    
    if (!dsn || !connectionStatus) {
        AylaLogE([self logTag], 0, @"Invalid msg(type:%d)", message.metadata.eventType);
        AylaLogD([self logTag], 0, @"Invalid msg - %@, %@", dsn, connectionStatus);
        return;
    }
    
    AylaDevice *device = [self.deviceManager.devices[dsn] copy];
    [device updateFromConnection:message.connection dataSource:AylaDataSourceDSS];
    
}

static const int RAW_STRING_LENGTH_CHECK = 3;
- (AylaDSMessage *)messageFromRawString:(NSString *)string
{
    // Check for keep alive or hearbeat.
    if (string.length <= RAW_STRING_LENGTH_CHECK) {
        return nil;
    }

    NSUInteger index = [string rangeOfString:@"|"].location;
    NSError *error;
    id json = [NSJSONSerialization
        JSONObjectWithData:[[string substringFromIndex:index + 1] dataUsingEncoding:NSUTF8StringEncoding]
                   options:0
                     error:&error];

    AylaDSMessage *message = nil;
    if (!error) {
        message = [[AylaDSMessage alloc] initWithJSONDictionary:json error:&error];
    }
    else {
        AylaLogE([self logTag], 0, @"Received invalid json(%ld).", error.code);
        AylaLogV([self logTag], 0, @"Invalid json - %@.", json);
    }

    return message;
}

- (NSString *)logTag
{
    return @"DSHandler";
}

@end
