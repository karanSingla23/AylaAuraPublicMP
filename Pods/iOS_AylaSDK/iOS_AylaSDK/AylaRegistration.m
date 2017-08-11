//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaRegistration+Internal.h"

#import "AylaDevice+Internal.h"
#import "AylaDeviceManager+Internal.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaLanTask.h"
#import "AylaRegistrationCandidate.h"
#import "AylaSessionManager+Internal.h"

NSString *const AylaRegistrationErrorDomain = @"AylaRegistrationErrorDomain";
NSString *const AylaRegistrationErrorResponseJsonKey = @"AylaRegistrationErrorResponseJsonKey";

@interface AylaRegistration ()

@property (nonatomic, strong, nullable) AylaHTTPClient *moduleClient;
@end

@implementation AylaRegistration
+ (NSString *)registrationNameFromType:(AylaRegistrationType)registrationType
{
    switch (registrationType) {
        case AylaRegistrationTypeAPMode:
            return @"AP-Mode";
        case AylaRegistrationTypeButtonPush:
            return @"Button-Push";
        case AylaRegistrationTypeDisplay:
            return @"Display";
        case AylaRegistrationTypeDsn:
            return @"Dsn";
        case AylaRegistrationTypeNode:
            return @"Node";
        case AylaRegistrationTypeSameLan:
            return @"Same-LAN";
        default:
            nil;
    }
    return nil;
}

+ (AylaRegistrationType)registrationTypeFromName:(NSString *)registrationTypeName
{
    if ([registrationTypeName isEqualToString:@"AP-Mode"]) {
        return AylaRegistrationTypeAPMode;
    }
    if ([registrationTypeName isEqualToString:@"Button-Push"]) {
        return AylaRegistrationTypeButtonPush;
    }
    if ([registrationTypeName isEqualToString:@"Display"]) {
        return AylaRegistrationTypeDisplay;
    }
    if ([registrationTypeName isEqualToString:@"Dsn"]) {
        return AylaRegistrationTypeDsn;
    }
    if ([registrationTypeName isEqualToString:@"Node"]) {
        return AylaRegistrationTypeNode;
    }
    if ([registrationTypeName isEqualToString:@"Same-LAN"]) {
        return AylaRegistrationTypeSameLan;
    }
    return AylaRegistrationTypeAny;
}

- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager
{
    if (self = [super init]) {
        _sessionManager = sessionManager;
    }
    return self;
}

- (AylaHTTPTask *)fetchCandidateWithDSN:(NSString *)targetDsn
                       registrationType:(AylaRegistrationType)registrationType
                                success:(void (^)(AylaRegistrationCandidate *_Nonnull))successBlock
                                failure:(void (^)(NSError *_Nonnull))failureBlock
{
    return [self fetchCandidatesWithDSN:targetDsn
                       registrationType:registrationType
                                success:^(NSArray<AylaRegistrationCandidate *> *_Nonnull candidates) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        successBlock([candidates firstObject]);
                                    });
                                }
                                failure:failureBlock];
}

- (AylaHTTPTask *)registerCandidate:(AylaRegistrationCandidate *)targetDevice
                            success:(void (^)(AylaDevice *_Nonnull))successBlock
                            failure:(void (^)(NSError *_Nonnull))failureBlock
{
    AylaLogI([self logTag], 0, @"%@:%@, %@", @"targetDsn", targetDevice.dsn, @"registerNewDevice");

    void (^preconditionFail)(SEL property) = ^(SEL property) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRegistrationErrorDomain
                                       code:AylaRegistrationErrorCodePreconditionFailure
                                   userInfo:@{
                                       AylaRegistrationErrorResponseJsonKey :
                                           @{NSStringFromSelector(property) : AylaErrorDescriptionIsInvalid}
                                   }];
        AylaLogE([self logTag],
                 0,
                 @"%@:%@, %@",
                 @"failed",
                 error.localizedDescription,
                 @"registerNewDevice.preconditionFail");
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
    };

    AylaHTTPTask * (^registerCandidate)() = ^{
        return [self registerDeviceWithDSN:targetDevice.dsn
                         registrationToken:targetDevice.registrationToken
                                setupToken:targetDevice.setupToken
                                  latitude:targetDevice.lat
                                 longitude:targetDevice.lng
                                   success:successBlock
                                   failure:failureBlock];
    };

    switch (targetDevice.registrationType) {
        case AylaRegistrationTypeButtonPush: {
            if (targetDevice.dsn != nil) {
                return registerCandidate();
            }
            else {
                preconditionFail(@selector(dsn));
            }
        } break;
        case AylaRegistrationTypeAny:
        case AylaRegistrationTypeSameLan: {
            // for these registration types we need to fetch the registration token
            return [self fetchRegistrationTokenForCandidate:targetDevice
                                                    success:^(NSString *_Nonnull regToken) {
                                                        targetDevice.registrationToken = regToken;
                                                        registerCandidate();
                                                    }
                                                    failure:failureBlock];
        } break;
        case AylaRegistrationTypeAPMode: {
            if (targetDevice.setupToken != nil) {
                return registerCandidate();
            }
            else {
                preconditionFail(@selector(setupToken));
            }
        } break;
        case AylaRegistrationTypeDisplay: {
            if (targetDevice.registrationToken != nil) {
                return registerCandidate();
            }
            else {
                preconditionFail(@selector(registrationToken));
            }
        } break;
        case AylaRegistrationTypeDsn: {
            if (targetDevice.dsn != nil) {
                return registerCandidate();
            }
            else {
                preconditionFail(@selector(dsn));
            }
        } break;
        case AylaRegistrationTypeNode: {
            if (targetDevice.dsn != nil) {
                return registerCandidate();
            }
            else {
                preconditionFail(@selector(dsn));
            }
        } break;
        default: {
            preconditionFail(@selector(registrationType));
        } break;
    }
    return nil;
}

- (AylaHTTPTask *)registerDeviceWithDSN:(NSString *)dsn
                      registrationToken:(NSString *)registrationToken
                             setupToken:(NSString *)setupToken
                               latitude:(NSString *)latitude
                              longitude:(NSString *)longitude
                                success:(void (^)(AylaDevice *device))successBlock
                                failure:(void (^)(NSError *error))failureBlock
{
    NSString *path = @"devices.json";
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    if (dsn) {
        [mutableParams setObject:dsn forKey:@"dsn"];
    }
    if (setupToken) {
        [mutableParams setObject:setupToken forKey:@"setup_token"];
    }
    if (registrationToken) {
        [mutableParams setObject:registrationToken forKey:@"regtoken"];
    }
    if (latitude) {
        [mutableParams setObject:latitude forKey:@"lat"];
    }
    if (longitude) {
        [mutableParams setObject:longitude forKey:@"lng"];
    }
    NSDictionary *params = [NSDictionary dictionaryWithObject:mutableParams forKey:@"device"];
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    AylaLogD([self logTag],
             0,
             @"%@:%@, %@:%@, %@",
             NSStringFromSelector(@selector(dsn)),
             dsn,
             NSStringFromSelector(@selector(registrationToken)),
             registrationToken,
             /* NSStringFromSelector(@selector(setupToken)), setupToken, */ NSStringFromSelector(_cmd));

    return [httpClient postPath:path
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaDeviceManager *deviceManager = self.sessionManager.deviceManager;
            NSDictionary *deviceDictionary = [responseObject valueForKey:@"device"];
            Class deviceClass = [AylaDevice deviceClassFromJSONDictionary:deviceDictionary];
            AylaDevice *device =
                [[deviceClass alloc] initWithDeviceManager:deviceManager JSONDictionary:deviceDictionary error:nil];

            [deviceManager addDevices:@[ device ]];
            [deviceManager setupDevice:device completionBlock:nil];
            AylaLogI(
                [self logTag], 0, @"%@:%@, %@", NSStringFromSelector(@selector(dsn)), dsn, @"registerDevice.postPath");
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(device);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

@end
