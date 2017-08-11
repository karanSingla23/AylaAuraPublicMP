//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint+Internal.h"
#import "AylaDatapointBlob.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaLogManager.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"
#import "AylaSystemUtils.h"
#import "NSObject+Ayla.h"

static NSString *const attrNameId = @"id";
static NSString *const attrNameValue = @"value";
static NSString *const attrNameCreatedAt = @"created_at";
static NSString *const attrNameAckAt = @"acked_at";
static NSString *const attrNameAckStatus = @"ack_status";
static NSString *const attrNameAckMessage = @"ack_message";
static NSString *const attrNameCreatedAtFromDevice = @"created_at_from_device";
static NSString *const attrNameMetadata = @"metadata";
static NSString *const attrNameUpdatedAt = @"updated_at";
static NSString *const attrNameDevTimeMs = @"dev_time_ms";
static NSString *const attrNameEcho = @"echo";

@interface AylaDatapoint ()
@property (nonatomic, readwrite) NSString *id;
@property (nonatomic, readwrite, copy) id value;
@property (nonatomic, readwrite) NSDictionary *metadata;
@property (nonatomic, readwrite) NSDate *createdAt;
@property (nonatomic, readwrite) NSDate *updatedAt;
@property (nonatomic, readwrite) NSDate *ackedAt;
@property (nonatomic, readwrite) NSInteger ackStatus;
@property (nonatomic, readwrite) NSInteger ackMessage;
@property (nonatomic, readwrite) NSDate *createdAtFromDevice;
@property (nonatomic, readwrite) AylaDataSource dataSource;
/** Device time from modules */
@property (nonatomic, readwrite) NSDate *devTimeMs;
@property (nonatomic, weak) AylaProperty *property ;
@end

@implementation AylaDatapoint

- (instancetype)initWithValue:(id)value {
    if (self = [super init]) {
        _value = value;
        _createdAt = [NSDate date];
        _updatedAt = _createdAt;
        _createdAtFromDevice = _createdAt;
    }
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaLogW([self logTag],
             0,
             @"Method initWithJSONDictionary:error: is not recommanded for AylaDatapoint, use "
             @"initWithJSONDictionary:dataSource:error: instead");
    return [self initWithJSONDictionary:dictionary dataSource:AylaDataSourceCloud error:error];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                            dataSource:(AylaDataSource)dataSource
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;

    NSDictionary *datapointInJson = dictionary;
    NSDictionary *responseJsonError = nil;
    if (datapointInJson) {
        NSDateFormatter *timeFormater = [AylaSystemUtils defaultDateFormatter];
        _id = [datapointInJson[attrNameId] nilIfNull];
        _createdAt = [timeFormater dateFromString:[datapointInJson[attrNameCreatedAt] nilIfNull]];
        _updatedAt = [timeFormater dateFromString:[datapointInJson[attrNameUpdatedAt] nilIfNull]];
        _echo = [[datapointInJson[attrNameId] nilIfNull] boolValue];
        if (_updatedAt == nil) {
            _updatedAt = [NSDate date];
        }

        // When createAt is not found and dataUpdatedAt is availble, assign the same timestamp from dataUpdatedAt
        // to createdAt
        if (!_createdAt && _updatedAt) {
            _createdAt = _updatedAt;
        }

        _value = [datapointInJson[attrNameValue] nilIfNull];
        if (!_value) {
            responseJsonError = @{ NSStringFromSelector(@selector(value)) : AylaErrorDescriptionIsInvalid };
        }

        _metadata = [datapointInJson[attrNameMetadata] nilIfNull];

        // ACK related attributes
        NSDate *ackedAt = [timeFormater dateFromString:[datapointInJson[attrNameAckAt] nilIfNull]];
        if (ackedAt != nil) {
            _ackedAt = ackedAt;
            _ackStatus = [[datapointInJson[attrNameAckStatus] nilIfNull] integerValue];
            _ackMessage = [[datapointInJson[attrNameAckMessage] nilIfNull] integerValue];
        }

        _createdAtFromDevice = [timeFormater dateFromString:[datapointInJson[attrNameCreatedAtFromDevice] nilIfNull]];

        if (datapointInJson[attrNameDevTimeMs]) {
            NSTimeInterval timeInterval = [datapointInJson[attrNameDevTimeMs] longLongValue] / 1000.0;
            _devTimeMs = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
        }
    }
    else {
        responseJsonError = @{ @"json" : AylaErrorDescriptionCanNotBeBlank };
    }

    if (responseJsonError) {
        NSError *foundError = [AylaErrorUtils errorWithDomain:AylaJsonErrorDomain
                                                         code:AylaJsonErrorCodeInvalidJson
                                                     userInfo:@{
                                                         AylaJsonErrorResponseJsonKey : responseJsonError
                                                     }
                                                    shouldLog:YES
                                                       logTag:[self logTag]
                                             addOnDescription:@"init"];
        if (error) {
            *error = foundError;
        }
    }
    _dataSource = dataSource;
    return self;
}

/**
 * Compose a to cloud json dectionary
 */
- (NSDictionary *)toCloudJSONDictionary
{
    return @{ NSStringFromSelector(@selector(value)) : self.value ?: [NSNull null] };
}

- (NSString *)logTag
{
    return @"Datapoint";
}
@end

@implementation AylaDatapoint (NSCoding)
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _createdAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(createdAt))];
        _id = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(id))];
        _value = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(value))];
        _metadata = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(metadata))];
        _updatedAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(updatedAt))];
        _ackedAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackedAt))];
        _ackStatus = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackStatus))] integerValue];
        _ackMessage = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackMessage))] integerValue];
        _echo = [aDecoder decodeBoolForKey:attrNameEcho];
        _createdAtFromDevice = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(createdAtFromDevice))];
        _dataSource = AylaDataSourceCache;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdAt forKey:NSStringFromSelector(@selector(createdAt))];
    [aCoder encodeObject:_id forKey:NSStringFromSelector(@selector(id))];
    [aCoder encodeObject:_value forKey:NSStringFromSelector(@selector(value))];
    [aCoder encodeObject:_metadata forKey:NSStringFromSelector(@selector(metadata))];
    [aCoder encodeObject:_updatedAt forKey:NSStringFromSelector(@selector(updatedAt))];
    [aCoder encodeObject:_ackedAt forKey:NSStringFromSelector(@selector(ackedAt))];
    [aCoder encodeObject:@(_ackStatus) forKey:NSStringFromSelector(@selector(ackStatus))];
    [aCoder encodeBool:_echo forKey:attrNameEcho];
    [aCoder encodeObject:_createdAtFromDevice forKey:NSStringFromSelector(@selector(createdAtFromDevice))];
}
@end
