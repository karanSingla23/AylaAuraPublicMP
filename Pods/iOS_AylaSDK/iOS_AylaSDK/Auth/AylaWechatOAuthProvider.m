//
//  AylaWechatOAuthProvider.m
//  iOS_AylaSDK
//
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaWechatOAuthProvider.h"

#import "AylaAuthProvider.h"
#import "AylaAuthorization.h"
#import "AylaDefines_Internal.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaLogManager.h"
#import "AylaLoginManager+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaSystemSettings.h"
#import "NSURLComponents+AylaNetworks.h"

static NSString *const AylaOAuthTypeNameWechat = @"wechat_provider";
static NSString *const AylaWechatRedirectPath  = @"sessions/post_process_provider_auth";

@interface AylaWechatOAuthProvider ()

@property (nonatomic, copy) NSString *authCode;
@property (nonatomic, strong) void (^failureBlock)(NSError *error);
@property (nonatomic, strong) void (^successBlock)(AylaAuthorization *authorization);
@property (nonatomic, weak) AylaLoginManager *loginManager;

@end

@implementation AylaWechatOAuthProvider

+ (instancetype)providerWithAuthCode:(NSString *)authCode
{
    AylaWechatOAuthProvider *provider = [[self alloc] init];
    provider.authCode = authCode;
    return provider;
}

- (AylaHTTPTask *)authenticateWithLoginManager:(AylaLoginManager *)loginManager
                                       success:(void (^)(AylaAuthorization *_Nonnull))successBlock
                                       failure:(void (^)(NSError *_Nonnull))failureBlock
{
    self.loginManager = loginManager;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    
    return [self authenticateAgainstServiceWithCode: self.authCode];
}

- (AylaHTTPTask *)authenticateAgainstServiceWithCode:(NSString *)code
{
    NSString *invalidParameter = nil;
    
    AylaLoginManager *loginManager = self.loginManager;
    if (!loginManager) {
        NSError *error = [AylaErrorUtils
                          errorWithDomain:AylaRequestErrorDomain
                          code:AylaRequestErrorCodePreconditionFailure
                          userInfo:@{
                                     AylaRequestErrorResponseJsonKey :
                                         @{NSStringFromSelector(@selector(loginManager)) : AylaErrorDescriptionIsInvalid}
                                     }];
        AylaLogE([self logTag], 0, @"%@%@", NSStringFromSelector(_cmd), error);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.failureBlock(error);
        });
        return nil;
    }
    else if (!code) {
        invalidParameter = NSStringFromSelector(@selector(code));
    }
    
    if (invalidParameter) {
        NSError *error = [AylaErrorUtils
                          errorWithDomain:AylaRequestErrorDomain
                          code:AylaRequestErrorCodeInvalidArguments
                          userInfo:@{
                                     AylaRequestErrorResponseJsonKey : @{invalidParameter : AylaErrorDescriptionIsInvalid}
                                     }];
        AylaLogE([self logTag], 0, @"%@%@", NSStringFromSelector(_cmd), error);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.failureBlock(error);
        });
        return nil;
    }
    
    NSString *path = @"users/provider_auth.json";
    NSDictionary *params = @{
        @"code" : code,
        @"app_id" : loginManager.settings.appId,
        @"provider" : AylaOAuthTypeNameWechat,
        @"redirect_url" : [self userServiceUrlWithPath:AylaWechatRedirectPath]
    };
    
    return [[loginManager getHTTPClient] postPath:path
           parameters:params
              success:^(AylaHTTPTask *_Nonnull task, id _Nullable loginResponse) {
                  NSError *error;
                  AylaLogD([self logTag], 0, @"%@", [loginResponse description]);
                  AylaAuthorization *authorization =
                  [[AylaAuthorization alloc] initWithJSONDictionary:loginResponse error:&error];
                  if (error) {
                      AylaLogE([self logTag], 0, @"%@%@", NSStringFromSelector(_cmd), error);
                      dispatch_async(dispatch_get_main_queue(), ^{
                          self.failureBlock(error);
                      });
                  }
                  else {
                      AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
                      dispatch_async(dispatch_get_main_queue(), ^{
                          self.successBlock(authorization);
                      });
                  }
              }
              failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                  AylaLogE([self logTag], 0, @"%@%@", NSStringFromSelector(_cmd), error);
                  dispatch_async(dispatch_get_main_queue(), ^{
                      self.failureBlock(error);
                  });
              }];
}

- (NSString *)logTag
{
    return NSStringFromClass([AylaWechatOAuthProvider class]);
}

/**
 Get full url of path.
 */
- (NSString *)userServiceUrlWithPath:(NSString *)path
{
    NSAssert(self.loginManager, @"LoginManager is null");
    NSString *baseUrl = self.loginManager.getHTTPClient.baseURL.absoluteString;
    return [NSString stringWithFormat:@"%@%@", baseUrl, path];
}

@end
