//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaAuthProvider.h"
#import "AylaAuthorization.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaLogManager.h"
#import "AylaLoginManager+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaSystemSettings.h"
#import "AylaUsernameAuthProvider.h"

@implementation AylaUsernameAuthProvider

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (!self) return nil;

    _username = username;
    _password = password;

    return self;
}

+ (instancetype)providerWithUsername:(NSString *)username password:(NSString *)password
{
    return [[self alloc] initWithUsername:username password:password];
}

- (AylaHTTPTask *)authenticateWithLoginManager:(AylaLoginManager *)loginManager
                                       success:(void (^)(AylaAuthorization *authorization))successBlock
                                       failure:(void (^)(NSError *error))failureBlock;
{
    AylaSystemSettings *currentSysSettings = loginManager.settings;
    NSDictionary *loginParams = @{
        @"user" : @{
            @"email" : self.username,
            @"password" : self.password,
            @"application" : @{@"app_id" : currentSysSettings.appId, @"app_secret" : currentSysSettings.appSecret}
        }
    };

    return [[loginManager getHTTPClient] postPath:@"users/sign_in.json"
        parameters:loginParams
        success:^(AylaHTTPTask *httpTask, id loginResponse) {
            NSError *error;
            AylaAuthorization *authorization =
                [[AylaAuthorization alloc] initWithJSONDictionary:loginResponse error:&error];
            if (error) {
                AylaLogE([self.class logTag], 0, @"auth init err %@", error);
                failureBlock(error);
            }
            else {
                successBlock(authorization);
            }
        }
        failure:^(AylaHTTPTask *httpTask, NSError *error) {
            failureBlock(error);
        }];
}

+ (NSString *)logTag
{
    return @"UsenameAuthProvider";
}

@end
