//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaScheduleAction.h"

#import "AylaDefines_Internal.h"
#import "AylaDevice.h"
#import "AylaDeviceManager.h"
#import "AylaHTTPClient.h"
#import "AylaObject+Internal.h"
#import "AylaProperty.h"
#import "AylaSchedule+Internal.h"
#import "AylaSessionManager+Internal.h"

NSString *const AylaScheduleActionTypeProperty = @"SchedulePropertyAction";

static NSString *const AylaScheduleActionAttrNameScheduleAction = @"schedule_action";

static NSString *const AylaScheduleActionAttrNameType           = @"type";
static NSString *const AylaScheduleActionAttrNameBaseType       = @"base_type";
static NSString *const AylaScheduleActionAttrNameValue          = @"value";
static NSString *const AylaScheduleActionAttrNameName           = @"name";
static NSString *const AylaScheduleActionAttrNameInRange        = @"in_range";
static NSString *const AylaScheduleActionAttrNameAtStart        = @"at_start";
static NSString *const AylaScheduleActionAttrNameAtEnd          = @"at_end";
static NSString *const AylaScheduleActionAttrNameActive         = @"active";
static NSString *const AylaScheduleActionAttrNameKey            = @"key";

static NSString *const AylaScheduleActionAttrFirePoint          = @"firePoint";

@interface AylaScheduleAction ()

@property (nonatomic, strong) NSNumber *key;
@property (nonatomic, weak) AylaSchedule *schedule;

@end

@implementation AylaScheduleAction

- (instancetype)initWithName:(NSString *)name value:(id)value baseType:(NSString *)baseType active:(BOOL)active firePoint:(AylaScheduleActionFirePoint)firePoint schedule:(AylaSchedule *)schedule {
    if (self = [super init]) {
        _name = name;
        _value = value;
        _baseType = baseType;
        _active = active;
        _firePoint = firePoint;
        _schedule = schedule;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _active = YES;
        _type = AylaScheduleActionTypeProperty;
    }
    
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    
    if (self) {
        NSDictionary *scheduleActionDict = dictionary[AylaScheduleActionAttrNameScheduleAction];
        
        if (scheduleActionDict) {
            _type = AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameType]);
            
            _baseType = AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameBaseType]);
            
            _value = AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameValue]);
            
            _name = AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameName]);
            
            _active = [AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameActive]) boolValue];
            
            if ([AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameAtStart]) boolValue]) {
                _firePoint = AylaScheduleActionFirePointAtStart;
            } else if ([AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameAtEnd]) boolValue]) {
                _firePoint = AylaScheduleActionFirePointAtEnd;
            } else if ([AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameInRange]) boolValue]) {
                _firePoint = AylaScheduleActionFirePointInRange;
            }
            
            _key = AYLNilIfNull(scheduleActionDict[AylaScheduleActionAttrNameKey]);
        }
    }
    
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary schedule:(AylaSchedule *)schedule error:(NSError *__autoreleasing _Nullable *)error
{
    AYLAssert(schedule, @"schedule cannot be nil!");
    
    self = [self initWithJSONDictionary:dictionary error:error];
    
    if (self) {
        _schedule = schedule;
    }
    
    return self;
}

#pragma mark -
#pragma mark Internal APIs

- (BOOL)isValid:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    NSError *scheduleActionError = nil;
    
    NSMutableDictionary *errorResponseInfo = [NSMutableDictionary new];
    
    if ([self.type isEqualToString:AylaScheduleActionTypeProperty]) {
        if (![self.name length]) {
            errorResponseInfo[AylaScheduleActionAttrNameName] = AylaErrorDescriptionCanNotBeBlank;
        }
    }
    
    if (![self.baseType length]) {
        errorResponseInfo[AylaScheduleActionAttrNameBaseType] = AylaErrorDescriptionCanNotBeBlank;
    } else if (![[self supportedBaseTypes] containsObject:self.baseType]) {
        errorResponseInfo[AylaScheduleActionAttrNameBaseType] = AylaErrorDescriptionIsInvalid;
    }
    
    if (!self.value) {
        errorResponseInfo[AylaScheduleActionAttrNameValue] = AylaErrorDescriptionCanNotBeBlank;
    }
    
    if ((self.firePoint < AylaScheduleActionFirePointAtStart) || (self.firePoint > AylaScheduleActionFirePointInRange)) {
        errorResponseInfo[AylaScheduleActionAttrFirePoint] = AylaErrorDescriptionIsInvalid;
    }
    
    if ([errorResponseInfo count]) {
        scheduleActionError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                         code:AylaRequestErrorCodeInvalidArguments
                                                     userInfo:@{
                                                                AylaRequestErrorResponseJsonKey : errorResponseInfo
                                                                }
                                                    shouldLog:YES
                                                       logTag:[self logTag]
                                             addOnDescription:@"invalidScheduleAction"];
    }
    
    if (error) {
        *error = scheduleActionError;
    }
    
    return (scheduleActionError == nil);
}

- (BOOL)hasKey:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    NSError *keyError = nil;
    
    NSMutableDictionary *errorResponseInfo = [NSMutableDictionary new];
    
    if (!self.key) {
        errorResponseInfo[AylaScheduleActionAttrNameKey] = AylaErrorDescriptionCanNotBeBlank;
    }    
    
    if ([errorResponseInfo count]) {
        keyError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                              code:AylaRequestErrorCodePreconditionFailure
                                          userInfo:@{
                                                     AylaRequestErrorResponseJsonKey : errorResponseInfo
                                                     }
                                         shouldLog:YES
                                            logTag:[self logTag]
                                  addOnDescription:@"invalidScheduleActionKey"];
    }
    
    if (error) {
        *error = keyError;
    }
    
    return (keyError == nil);
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    if (self.type) {
        dict[AylaScheduleActionAttrNameType] = self.type;
    }
    
    dict[AylaScheduleActionAttrNameBaseType] = AYLNullIfNil(self.baseType);
    
    if (self.value) {
        dict[AylaScheduleActionAttrNameValue] = AYLNullIfNil(self.value);
    }
    
    dict[AylaScheduleActionAttrNameName] = AYLNullIfNil(self.name);
    
    dict[AylaScheduleActionAttrNameActive] = @(self.isActive);
    
    if (self.key) {
        dict[AylaScheduleActionAttrNameKey] = self.key;
    }
    
    // First clear out all the firePoint bools (to remove any prior setting)...
    dict[AylaScheduleActionAttrNameAtStart] = @(NO);
    dict[AylaScheduleActionAttrNameAtEnd] = @(NO);
    dict[AylaScheduleActionAttrNameInRange] = @(NO);

    // ...and then set the desired one
    switch (self.firePoint) {
        case AylaScheduleActionFirePointAtStart:
            dict[AylaScheduleActionAttrNameAtStart] = @(YES);
            break;
            
        case AylaScheduleActionFirePointAtEnd:
            dict[AylaScheduleActionAttrNameAtEnd] = @(YES);
            break;
            
        case AylaScheduleActionFirePointInRange:
            dict[AylaScheduleActionAttrNameInRange] = @(YES);
            break;
            
        default:
            break;
    }
    
    return [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithDictionary:dict] forKey:AylaScheduleActionAttrNameScheduleAction];
}

- (id)copyWithZone:(NSZone *)zone
{
    AylaScheduleAction *copy = [super copyWithZone:zone];
    
    copy.schedule = self.schedule;
    
    return copy;
}

- (nullable AylaHTTPTask *)updateWithSuccess:(void (^)(AylaScheduleAction *updatedScheduleAction))successBlock
                                     failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"failureBlock cannot be NULL!");
    
    NSError *error = nil;
    
    if (![self isValid:&error])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"schedule_actions/%@.json", self.key];
    
    return [httpClient putPath:path
                    parameters:[self toJSONDictionary]
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           AylaScheduleAction *action = [[AylaScheduleAction alloc] initWithJSONDictionary:responseObject schedule:self.schedule error:nil];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock(action);
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

- (nullable AylaHTTPTask *)deleteWithSuccess:(void (^)())successBlock
                                     failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"failureBlock cannot be NULL!");
    
    NSError *error = nil;
    
    if (![self hasKey:&error])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"schedule_actions/%@.json", self.key];
    
    return [httpClient deletePath:path
                    parameters:nil
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock();
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

#pragma mark -
#pragma mark Utilities

- (NSArray *)supportedBaseTypes
{
    return @[AylaPropertyBaseTypeBoolean, AylaPropertyBaseTypeString, AylaPropertyBaseTypeInteger, AylaPropertyBaseTypeDecimal];
}

- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaHTTPClient *client = [self.schedule.device.deviceManager.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];
    
    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                            code:AylaRequestErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }
    
    return client;
}

- (NSString *)logTag
{
    return @"Schedule";
}

@end
