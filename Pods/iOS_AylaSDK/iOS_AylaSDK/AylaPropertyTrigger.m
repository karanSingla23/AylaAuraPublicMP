//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaPropertyTrigger+Internal.h"

#import "AylaDevice.h"
#import "AylaDeviceManager.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"
#import "AylaServiceApp+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "NSObject+Ayla.h"

@interface AylaPropertyTrigger ()
@property (strong, nonatomic) NSNumber *key;
@property (strong, nonatomic) NSNumber *propertyKey;

@property (strong, nonatomic) NSDate *retrievedAt;

@property (strong, nonatomic) NSString *period;
@property (strong, nonatomic) NSString *baseType;
@property (strong, nonatomic) NSString *triggeredAt;

@end

NSString *const kAylaTriggerTypeAlways = @"always";
NSString *const kAylaTriggerTypeOnChange = @"on_change";
NSString *const kAylaTriggerTypeCompareAbsolute = @"compare_absolute";

NSString *const kAylaTriggerCompareEqual = @"==";
NSString *const kAylaTriggerCompareGreaterThan = @">";
NSString *const kAylaTriggerCompareLessThan = @"<";
NSString *const kAylaTriggerCompareGreaterOrEqual = @">=";
NSString *const kAylaTriggerCompareLessOrEqual = @"<=";

NSString *const attrNamePropertyTriggerTriggerType = @"trigger_type";
NSString *const attrNamePropertyTriggerCompareType = @"compare_type";
NSString *const attrNamePropertyTriggerValue = @"value";
NSString *const attrNamePropertyTriggerDeviceNickname = @"device_nickname";
NSString *const attrNamePropertyTriggerPropertyNickname = @"property_nickname";
NSString *const attrNamePropertyTriggerActive = @"active";

@implementation AylaPropertyTrigger
+ (NSString *)triggerTypeNameFromType:(AylaPropertyTriggerType)type
{
    switch (type) {
        case AylaPropertyTriggerTypeAlways:
            return kAylaTriggerTypeAlways;
        case AylaPropertyTriggerTypeCompareAbsolute:
            return kAylaTriggerTypeCompareAbsolute;
        case AylaPropertyTriggerTypeOnChange:
            return kAylaTriggerTypeOnChange;
        default:
            break;
    }
    return nil;
}

+ (AylaPropertyTriggerType)triggerTypeFromName:(NSString *)typeName
{
    if ([typeName isEqualToString:kAylaTriggerTypeAlways]) {
        return AylaPropertyTriggerTypeAlways;
    }
    else if ([typeName isEqualToString:kAylaTriggerTypeCompareAbsolute]) {
        return AylaPropertyTriggerTypeCompareAbsolute;
    }
    else if ([typeName isEqualToString:kAylaTriggerTypeOnChange]) {
        return AylaPropertyTriggerTypeOnChange;
    }
    return AylaPropertyTriggerTypeUnknown;
}

+ (NSString *)comparisonNameFromType:(AylaPropertyTriggerCompare)type
{
    switch (type) {
        case AylaPropertyTriggerCompareEqualTo:
            return kAylaTriggerCompareEqual;
        case AylaPropertyTriggerCompareGreaterThan:
            return kAylaTriggerCompareGreaterThan;
        case AylaPropertyTriggerCompareGreaterThanOrEqualTo:
            return kAylaTriggerCompareGreaterOrEqual;
        case AylaPropertyTriggerCompareLessThan:
            return kAylaTriggerCompareLessThan;
        case AylaPropertyTriggerCompareLessThanOrEqualTo:
            return kAylaTriggerCompareLessOrEqual;
        default:
            break;
    }
    return nil;
}

+ (AylaPropertyTriggerCompare)comparisonTypeFromName:(NSString *)comparisonName
{
    if ([comparisonName isEqualToString:kAylaTriggerCompareEqual]) {
        return AylaPropertyTriggerCompareEqualTo;
    }
    else if ([comparisonName isEqualToString:kAylaTriggerCompareGreaterOrEqual]) {
        return AylaPropertyTriggerCompareGreaterThanOrEqualTo;
    }
    else if ([comparisonName isEqualToString:kAylaTriggerCompareGreaterThan]) {
        return AylaPropertyTriggerCompareGreaterThan;
    }
    else if ([comparisonName isEqualToString:kAylaTriggerCompareLessOrEqual]) {
        return AylaPropertyTriggerCompareLessThanOrEqualTo;
    }
    else if ([comparisonName isEqualToString:kAylaTriggerCompareLessThan]) {
        return AylaPropertyTriggerCompareLessThan;
    }
    return AylaPropertyTriggerCompareUnknown;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                              property:(nonnull AylaProperty *)property
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    if (self = [super init]) {
        _property = property;
        NSArray *propertyTrigger = [dictionary objectForKey:@"trigger"];

        if (propertyTrigger) {
            NSString *compareTypeName = AYLNilIfNull([propertyTrigger valueForKeyPath:@"compare_type"]);
            NSString *triggerType = AYLNilIfNull([propertyTrigger valueForKeyPath:@"trigger_type"]);

            _compareType = [AylaPropertyTrigger comparisonTypeFromName:compareTypeName];
            _period = ([propertyTrigger valueForKeyPath:@"period"] != [NSNull null])
                          ? [propertyTrigger valueForKeyPath:@"period"]
                          : @"";
            _triggerType = [AylaPropertyTrigger triggerTypeFromName:triggerType];
            _baseType = ([propertyTrigger valueForKeyPath:@"base_type"] != [NSNull null])
                            ? [propertyTrigger valueForKeyPath:@"base_type"]
                            : @"";
            _value = AYLNilIfNull([propertyTrigger valueForKeyPath:@"value"]);
            _triggeredAt = ([propertyTrigger valueForKeyPath:@"triggered_at"] != [NSNull null])
                               ? [propertyTrigger valueForKeyPath:@"triggered_at"]
                               : @"";
            _key = [propertyTrigger valueForKeyPath:@"key"];
            _active = [propertyTrigger valueForKeyPath:@"active"] != [NSNull null]
                          ? [(NSNumber *)[propertyTrigger valueForKeyPath:@"active"] boolValue]
                          : NO;

            _propertyKey = [[propertyTrigger valueForKeyPath:@"property_key"] nilIfNull];
            _retrievedAt = [NSDate date];
            _deviceNickname = [[propertyTrigger valueForKeyPath:@"device_nickname"] nilIfNull];
            _propertyNickname = [[propertyTrigger valueForKeyPath:@"property_nickname"] nilIfNull];
        }
        else if (error) {
            *error = [AylaErrorUtils
                errorWithDomain:AylaJsonErrorDomain
                           code:AylaJsonErrorCodeInvalidJson
                       userInfo:@{
                           AylaRequestErrorResponseJsonKey : @{@"trigger" : AylaErrorDescriptionCanNotBeFound}
                       }];
        }
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSString *triggerTypeName = [AylaPropertyTrigger triggerTypeNameFromType:self.triggerType];
    NSString *compareTypeName = [AylaPropertyTrigger comparisonNameFromType:self.compareType];
    NSDictionary *parameters = @{
        attrNamePropertyTriggerTriggerType : AYLNullIfNil(triggerTypeName),
        attrNamePropertyTriggerCompareType : AYLNullIfNil(compareTypeName),
        attrNamePropertyTriggerValue : AYLNullIfNil(self.value),
        attrNamePropertyTriggerDeviceNickname : AYLNullIfNil(self.deviceNickname),
        attrNamePropertyTriggerPropertyNickname : AYLNullIfNil(self.propertyNickname),
        attrNamePropertyTriggerActive : @(self.active)
    };
    return parameters;
}

//-----------------------------------------------------------
#pragma mark - AylaPropertyTriggerApp
//-----------------------------------------------------------
- (AylaHTTPTask *)createApp:(AylaPropertyTriggerApp *)app
                    success:(void (^)(AylaPropertyTriggerApp *_Nonnull))successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!app) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodePreconditionFailure
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey :
                           @{NSStringFromClass([AylaPropertyTriggerApp class]) : AylaErrorDescriptionIsInvalid}
                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"triggers/%@/trigger_apps.json", self.key];
    return [httpClient postPath:path
        parameters:[app toJSONDictionary]
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

            NSError *error = nil;
            AylaPropertyTriggerApp *createdApp =
                [[AylaPropertyTriggerApp alloc] initWithJSONDictionary:responseObject error:&error];
            if (error) {
                AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, NSStringFromSelector(_cmd));
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(createdApp);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)fetchApps:(void (^)(NSArray<AylaPropertyTriggerApp *> *_Nonnull))successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"triggers/%@/trigger_apps.json", self.key];
    return [httpClient getPath:path
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable appDictionaries) {
            NSMutableArray *apps = [NSMutableArray array];
            for (NSDictionary *appDictionary in appDictionaries) {
                NSError *error = nil;
                AylaPropertyTriggerApp *app =
                    [[AylaPropertyTriggerApp alloc] initWithJSONDictionary:appDictionary error:&error];
                if (error) {
                    AylaLogE([self logTag], 0, @"invalidResp:%@, %@", appDictionary, NSStringFromSelector(_cmd));
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failureBlock(error);
                    });
                    return;
                }
                [apps addObject:app];
            }

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(apps);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)updateApp:(AylaPropertyTriggerApp *)app
                    success:(void (^)(AylaPropertyTriggerApp *_Nonnull))successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!app) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodePreconditionFailure
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey :
                           @{NSStringFromClass([AylaPropertyTriggerApp class]) : AylaErrorDescriptionIsInvalid}
                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"trigger_apps/%@.json", app.key];
    return [httpClient putPath:path
        parameters:[app toJSONDictionary]
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

            NSError *error = nil;
            AylaPropertyTriggerApp *updatedApp =
                [[AylaPropertyTriggerApp alloc] initWithJSONDictionary:responseObject error:&error];
            if (error) {
                AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, NSStringFromSelector(_cmd));
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(updatedApp);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)deleteApp:(AylaPropertyTriggerApp *)app
                    success:(void (^)())successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!app) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodePreconditionFailure
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey :
                           @{NSStringFromClass([AylaPropertyTriggerApp class]) : AylaErrorDescriptionIsInvalid}
                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"trigger_apps/%@.json", app.key];
    return [httpClient deletePath:path
        parameters:[app toJSONDictionary]
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}
//-----------------------------------------------------------
#pragma mark - Http Client
//-----------------------------------------------------------
- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaHTTPClient *client =
        [self.property.device.deviceManager.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];

    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                            code:AylaRequestErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }

    return client;
}

- (NSString *)logTag
{
    return NSStringFromClass([self class]);
}
@end