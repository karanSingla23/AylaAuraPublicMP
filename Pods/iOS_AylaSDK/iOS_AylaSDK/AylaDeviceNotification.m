//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDeviceNotification+Internal.h"

#import "AylaDevice+Internal.h"
#import "AylaDeviceManager+Internal.h"
#import "AylaDeviceNotificationApp.h"
#import "AylaHTTPClient.h"
#import "AylaObject+Internal.h"
#import "AylaSessionManager+Internal.h"

@interface AylaDeviceNotification ()

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSNumber *deviceKey;
@end

@implementation AylaDeviceNotification

static NSString *const attrDeviceNotificationId = @"id";
static NSString *const attrDeviceNotificationDeviceNickname = @"device_nickname";
static NSString *const attrDeviceNotificationType = @"notification_type";
static NSString *const attrDeviceNotificationThreshold = @"threshold";
static NSString *const attrDeviceNotificationUrl = @"url";
static NSString *const attrDeviceNotificationUserName = @"username";
static NSString *const attrDeviceNotificationPassword = @"password";
static NSString *const attrDeviceNotificationMessage = @"message";
static NSString *const attrDeviceNotificationDeviceKey = @"device_key";

NSString *const kAylaDeviceNotificationTypeOnConnect = @"on_connect";
NSString *const kAylaDeviceNotificationTypeIPChange = @"ip_change";
NSString *const kAylaDeviceNotificationTypeOnConnectionLost = @"on_connection_lost";
NSString *const kAylaDeviceNotificationTypeOnConnectionRestore = @"on_connection_restore";

+ (NSString *)deviceNotificationNameFromType:(AylaDeviceNotificationType)notificationType
{
    switch (notificationType) {
        case AylaDeviceNotificationTypeIPChange:
            return kAylaDeviceNotificationTypeIPChange;
        case AylaDeviceNotificationTypeOnConnect:
            return kAylaDeviceNotificationTypeOnConnect;
        case AylaDeviceNotificationTypeOnConnectionLost:
            return kAylaDeviceNotificationTypeOnConnectionLost;
        case AylaDeviceNotificationTypeOnConnectionRestore:
            return kAylaDeviceNotificationTypeOnConnectionRestore;
        default:
            break;
    }
    return nil;
}

+ (AylaDeviceNotificationType)deviceNotificationTypeFromName:(NSString *)notificationName
{
    if ([notificationName isEqualToString:kAylaDeviceNotificationTypeIPChange]) {
        return AylaDeviceNotificationTypeIPChange;
    }
    else if ([notificationName isEqualToString:kAylaDeviceNotificationTypeOnConnect]) {
        return AylaDeviceNotificationTypeOnConnect;
    }
    else if ([notificationName isEqualToString:kAylaDeviceNotificationTypeOnConnectionLost]) {
        return AylaDeviceNotificationTypeOnConnectionLost;
    }
    else if ([notificationName isEqualToString:kAylaDeviceNotificationTypeOnConnectionRestore]) {
        return AylaDeviceNotificationTypeOnConnectionRestore;
    }
    return AylaDeviceNotificationTypeUnknown;
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *toServiceDictionary = [NSMutableDictionary new];
    [toServiceDictionary setObject:[AylaDeviceNotification deviceNotificationNameFromType:self.type]
                            forKey:attrDeviceNotificationType];
    [toServiceDictionary setObject:AYLNullIfNil(self.deviceNickname) forKey:attrDeviceNotificationDeviceNickname];

    switch (self.type) {
        case AylaDeviceNotificationTypeOnConnectionLost:
        case AylaDeviceNotificationTypeOnConnectionRestore:
            [toServiceDictionary setObject:self.threshold ? @(self.threshold) : [NSNull null]
                                    forKey:attrDeviceNotificationThreshold];
            break;
        case AylaDeviceNotificationTypeIPChange:
        case AylaDeviceNotificationTypeOnConnect:
            [toServiceDictionary setObject:AYLNullIfNil(self.url) forKey:attrDeviceNotificationUrl];
            [toServiceDictionary setObject:AYLNullIfNil(self.username) forKey:attrDeviceNotificationUserName];
            [toServiceDictionary setObject:AYLNullIfNil(self.password) forKey:attrDeviceNotificationPassword];
        default:
            break;
    }
    return @{ @"notification" : toServiceDictionary };
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                device:(nonnull AylaDevice *)device
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    if (self = [super init]) {
        _id = [dictionary objectForKey:attrDeviceNotificationId];
        _type = [AylaDeviceNotification
            deviceNotificationTypeFromName:[dictionary objectForKey:attrDeviceNotificationType]];

        _deviceNickname = [dictionary objectForKey:attrDeviceNotificationDeviceNickname] != [NSNull null]
                              ? [dictionary objectForKey:attrDeviceNotificationDeviceNickname]
                              : nil;
        _threshold = [dictionary objectForKey:attrDeviceNotificationThreshold] != [NSNull null]
                         ? [[dictionary objectForKey:attrDeviceNotificationThreshold] unsignedIntegerValue]
                         : 0;
        _url = [dictionary objectForKey:attrDeviceNotificationUrl] != [NSNull null]
                   ? [dictionary objectForKey:attrDeviceNotificationUrl]
                   : nil;
        _username = [dictionary objectForKey:attrDeviceNotificationUserName] != [NSNull null]
                        ? [dictionary objectForKey:attrDeviceNotificationUserName]
                        : nil;
        _password = [dictionary objectForKey:attrDeviceNotificationPassword] != [NSNull null]
                        ? [dictionary objectForKey:attrDeviceNotificationPassword]
                        : nil;
        ;
        _message = [dictionary objectForKey:attrDeviceNotificationMessage] != [NSNull null]
                       ? [dictionary objectForKey:attrDeviceNotificationMessage]
                       : nil;

        _deviceKey = [dictionary objectForKey:attrDeviceNotificationDeviceKey];

        _device = device;
    }
    return self;
}

//-----------------------------------------------------------
#pragma mark - AylaDeviceNotificationApp
//-----------------------------------------------------------
- (AylaHTTPTask *)createApp:(AylaDeviceNotificationApp *)app
                    success:(void (^)(AylaDeviceNotificationApp *_Nonnull))successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!app) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodePreconditionFailure
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey :
                           @{NSStringFromClass([AylaDeviceNotificationApp class]) : AylaErrorDescriptionIsInvalid}
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
    NSString *path = [NSString stringWithFormat:@"notifications/%@/notification_apps.json", self.id];
    return [httpClient postPath:path
        parameters:[app toJSONDictionary]
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

            NSError *error = nil;
            AylaDeviceNotificationApp *createdApp =
                [[AylaDeviceNotificationApp alloc] initWithJSONDictionary:responseObject error:&error];
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

- (AylaHTTPTask *)fetchApps:(void (^)(NSArray<AylaDeviceNotificationApp *> *_Nonnull))successBlock
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
    NSString *path = [NSString stringWithFormat:@"notifications/%@/notification_apps.json", self.id];
    return [httpClient getPath:path
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable appDictionaries) {
            NSMutableArray *apps = [NSMutableArray array];
            for (NSDictionary *appDictionary in appDictionaries) {
                NSError *error = nil;
                AylaDeviceNotificationApp *app =
                    [[AylaDeviceNotificationApp alloc] initWithJSONDictionary:appDictionary error:&error];
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

- (AylaHTTPTask *)updateApp:(AylaDeviceNotificationApp *)app
                    success:(void (^)(AylaDeviceNotificationApp *_Nonnull))successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!app) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodePreconditionFailure
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey :
                           @{NSStringFromClass([AylaDeviceNotificationApp class]) : AylaErrorDescriptionIsInvalid}
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
    NSString *path = [NSString stringWithFormat:@"notifications/%@/notification_apps/%@.json", self.id, app.id];
    return [httpClient putPath:path
        parameters:[app toJSONDictionary]
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

            NSError *error = nil;
            AylaDeviceNotificationApp *updatedApp =
                [[AylaDeviceNotificationApp alloc] initWithJSONDictionary:responseObject error:&error];
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

- (AylaHTTPTask *)deleteApp:(AylaDeviceNotificationApp *)app
                    success:(void (^)())successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!app) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodePreconditionFailure
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey :
                           @{NSStringFromClass([AylaDeviceNotificationApp class]) : AylaErrorDescriptionIsInvalid}
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
    NSString *path = [NSString stringWithFormat:@"notifications/%@/notification_apps/%@.json", self.id, app.id];
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
        [self.device.deviceManager.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];

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
