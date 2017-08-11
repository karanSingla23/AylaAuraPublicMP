//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDSMessage.h"
#import "AylaDSSubscription.h"
#import "AylaDatapoint+Internal.h"
#import "AylaDatapointBlob.h"
#import "AylaDefines_Internal.h"
#import "AylaDeviceConnection.h"
#import "AylaObject+Internal.h"
#import "AylaProperty.h"

static NSString *const AylaDSMessageAttrNameBaseType = @"base_type";
static NSString *const AylaDSMessageAttrNameDisplayName = @"display_name";
static NSString *const AylaDSMessageAttrNameEventType = @"event_type";
static NSString *const AylaDSMessageAttrNameOemId = @"oem_id";
static NSString *const AylaDSMessageAttrNameOemModel = @"oem_model";
static NSString *const AylaDSMessageAttrNamePropertyName = @"property_name";

static NSString *const attrNameFile = @"file";

static NSString *const AylaDSMessageEventTypeNameConnectivity = @"connectivity";
static NSString *const AylaDSMessageEventTypeNameDatapoint = @"datapoint";
static NSString *const AylaDSMessageEventTypeNameDatapointAck = @"datapointack";
static NSString *const AylaDSMessageEventTypeNameRegistration = @"registration";

@implementation AylaDSMessage

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return self;

    _seq = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(seq))]);
    _metadata = AYLNilIfNull([[AylaDSMetadata alloc]
        initWithJSONDictionary:dictionary[NSStringFromSelector(@selector(metadata))]
                         error:nil]);

    id datapointInJson = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(datapoint))]);

    // check the datapoint dictionary content to see if the datapoint is of Blob type
    Class datapointClass = [AylaDatapoint class];
    if (datapointInJson[attrNameFile]) {
        datapointClass = [AylaDatapointBlob class];
    }

    _datapoint =
        datapointInJson
            ? [[datapointClass alloc] initWithJSONDictionary:datapointInJson dataSource:AylaDataSourceDSS error:nil]
            : nil;

    id connectionInJson = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(connection))]);
    _connection = connectionInJson ?
            [[AylaDeviceConnection alloc] initWithJSONDictionary:connectionInJson error:nil]
            : nil;
    return self;
}

- (NSString *)logTag
{
    return @"DSMessage";
}

@end

@implementation AylaDSMetadata

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return self;

    _baseType = AYLNilIfNull(dictionary[AylaDSMessageAttrNameBaseType]);
    _displayName = AYLNilIfNull(dictionary[AylaDSMessageAttrNameDisplayName]);
    _dsn = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(dsn))]);
    _eventType = [self eventTypeFromString:AYLNilIfNull(dictionary[AylaDSMessageAttrNameEventType])];
    _oemId = AYLNilIfNull((dictionary[AylaDSMessageAttrNameOemId]));
    _oemModel = AYLNilIfNull(dictionary[AylaDSMessageAttrNameOemModel]);
    _propertyName = AYLNilIfNull(dictionary[AylaDSMessageAttrNamePropertyName]);

    return self;
}

- (AylaDSMessageEventType)eventTypeFromString:(NSString *)string
{
    AylaDSMessageEventType type = AylaDSMessageEventTypeUnknown;
    if ([string isEqualToString:AylaDSMessageEventTypeNameConnectivity]) {
        type = AylaDSMessageEventTypeConnectivity;
    }
    else if ([string isEqualToString:AylaDSMessageEventTypeNameDatapoint]) {
        type = AylaDSMessageEventTypeDatapoint;
    }
    else if ([string isEqualToString:AylaDSMessageEventTypeNameDatapointAck]) {
        type = AylaDSMessageEventTypeDatapointAck;
    }

    return type;
}

@end
