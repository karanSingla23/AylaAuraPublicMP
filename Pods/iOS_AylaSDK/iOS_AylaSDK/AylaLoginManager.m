//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaAuthProvider.h"
#import "AylaAuthorization.h"
#import "AylaNetworks+Internal.h"
#import "AylaEmailTemplate.h"
#import "AylaHTTPClient.h"
#import "AylaLoginManager.h"
#import "AylaObject+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemSettings.h"
#import "AylaUser.h"

static NSString *const attrNameUser = @"user";
static NSString *const attrNameEmail = @"email";
static NSString *const attrNameApplication = @"application";
static NSString *const attrNameAppId = @"app_id";
static NSString *const attrNameAppSecret = @"app_secret";
static NSString *const attrNamePassword = @"password";
static NSString *const attrNamePasswordConfirmation = @"password_confirmation";
static NSString *const attrNamePasswordResetToken = @"reset_password_token";
static NSString *const attrNameSignupConfirmationToken = @"confirmation_token";

@interface AylaLoginManager ()

@property (nonatomic, weak, readwrite) AylaNetworks *sdkRoot;
@property (nonatomic, readwrite) AylaSystemSettings *settings;
@property (nonatomic) AylaHTTPClient *httpClient;

@end

@implementation AylaLoginManager

- (instancetype)initWithSDKRoot:(AylaNetworks *)sdkRoot
{
    self = [super init];
    if (!self) return nil;

    _sdkRoot = sdkRoot;
    _settings = sdkRoot.systemSettings;
    _httpClient = [AylaHTTPClient userServiceClientWithSettings:self.settings usingHTTPS:YES];

    return self;
}

- (AylaHTTPTask *)loginWithAuthProvider:(id<AylaAuthProvider>)authProvider
                            sessionName:(NSString *)sessionName
                                success:(void (^)(AylaAuthorization *authorization,
                                                  AylaSessionManager *sessionManager))successBlock
                                failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(sessionName, @"Session name must not be nil");

    return [authProvider authenticateWithLoginManager:self
        success:^(AylaAuthorization *authorization) {
            AylaSessionManager *sessionManager = [[AylaSessionManager alloc] initWithAuthProvider:authProvider
                                                                                    authorization:authorization
                                                                                      sessionName:sessionName
                                                                                          sdkRoot:self.sdkRoot];
            [self.sdkRoot addSessionManager:sessionManager];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(authorization, sessionManager);
            });
        }
        failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)refreshAuthorization:(AylaAuthorization *)authorization
                               success:(void (^)(AylaAuthorization *authorization))successBlock
                               failure:(void (^)(NSError *error))failureBlock
{
    NSDictionary *refreshParams = @{ @"refresh_token" : authorization.refreshToken ?: @"" };
    return [self.httpClient postPath:@"users/refresh_token.json"
        parameters:@{
            @"user" : refreshParams
        }
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSError *error;
            AylaAuthorization *auth = [[AylaAuthorization alloc] initWithJSONDictionary:responseObject error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(auth);
                });
            }
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)signUpWithUser:(AylaUser *)user
                   emailTemplate:(AylaEmailTemplate *)emailTemplate
                         success:(void (^)())successBlock
                         failure:(void (^)(NSError *error))failureBlock
{
    if (!user) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(user)) : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSMutableDictionary *userParams = [[user toJSONDictionary] mutableCopy];
    userParams[attrNameApplication] =
        @{attrNameAppId : self.settings.appId, attrNameAppSecret : self.settings.appSecret};

    NSMutableDictionary *params = [@{ attrNameUser : userParams } mutableCopy];
    if (emailTemplate != nil) {
        [params addEntriesFromDictionary:[emailTemplate toJSONDictionary]];
    }

    NSString *path = @"users.json";
    return [self.httpClient postPath:path
        parameters:params
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

- (AylaHTTPTask *)resendConfirmationEmail:(NSString *)email
                            emailTemplate:(AylaEmailTemplate *)emailTemplate
                                  success:(void (^)())successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    if (!email) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(email)) : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSMutableDictionary *params = [@{
        attrNameUser : @{
            attrNameEmail : email,
            attrNameApplication : @{attrNameAppId : self.settings.appId, attrNameAppSecret : self.settings.appSecret}
        }
    } mutableCopy];
    if (emailTemplate != nil) {
        [params addEntriesFromDictionary:[emailTemplate toJSONDictionary]];
    }

    NSString *path = @"users/confirmation.json";
    return [self.httpClient postPath:path
        parameters:params
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

- (AylaHTTPTask *)confirmAccountWithToken:(NSString *)token
                                  success:(void (^)())successBlock
                                  failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!token) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodeInvalidArguments
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey : @{@"confirmation_token" : AylaErrorDescriptionIsInvalid}
                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *path = @"users/confirmation.json";

    NSDictionary *params = @{attrNameSignupConfirmationToken : token};

    return [self.httpClient putPath:path
        parameters:params
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

- (AylaHTTPTask *)requestPasswordReset:(NSString *)email
                         emailTemplate:(AylaEmailTemplate *)emailTemplate
                               success:(void (^)())successBlock
                               failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!email) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(email)) : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSMutableDictionary *params = [@{
        attrNameUser : @{
            attrNameEmail : email,
            attrNameApplication : @{attrNameAppId : self.settings.appId, attrNameAppSecret : self.settings.appSecret}
        }
    } mutableCopy];
    if (emailTemplate != nil) {
        [params addEntriesFromDictionary:[emailTemplate toJSONDictionary]];
    }

    NSString *path = @"users/password.json";
    return [self.httpClient postPath:path
        parameters:params
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

- (AylaHTTPTask *)resetPasswordTo:(NSString *)password
                            token:(NSString *)token
                          success:(void (^)())successBlock
                          failure:(void (^)(NSError *_Nonnull error))failureBlock
{
    NSString *badParam = nil;
    if (password.length < 1) {
        badParam = NSStringFromSelector(@selector(password));
    }
    else if (token.length < 1) {
        badParam = @"token";
    }
    if (badParam) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey : @{badParam : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *path = @"users/password.json";

    NSDictionary *params = @{
        attrNameUser :
            @{attrNamePassword : password, attrNamePasswordConfirmation : password, attrNamePasswordResetToken : token}
    };

    return [self.httpClient putPath:path
        parameters:params
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

- (AylaHTTPClient *)getHTTPClient
{
    return self.httpClient;
}

- (NSString *)logTag
{
    return NSStringFromClass([self class]);
}
@end
