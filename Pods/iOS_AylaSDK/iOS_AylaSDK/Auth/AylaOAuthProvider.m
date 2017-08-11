//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaOAuthProvider.h"

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

static NSString *const AylaOAuthTypeNameGoogle = @"google_provider";
static NSString *const AylaOAuthTypeNameFacebook = @"facebook_provider";

static NSString *const AylaOAuthParamAuthMethod = @"auth_method";
static NSString *const AylaOAuthParamApplication = @"application";

static NSString *const AylaOAuthParamAppId = @"app_id";
static NSString *const AylaOAuthParamAppSecret = @"app_secret";

static NSString *const AylaOAuthParamUser = @"user";

NSString *const AylaOAuthRedirectUriRemote = @"http%3A%2F%2Fmobile.aylanetworks.com%2F";
NSString *const AylaOAuthRedirectUriLocal = @"http%3A%2F%2Flocalhost:9000%2F";

NSString *const AylaOAuthURLParamCode = @"code";
NSString *const AylaOAuthURLParamError = @"error";
NSString *const AylaOAuthURLParamErrorAccessDenied = @"access_denied";

@interface AylaOAuthProvider ()

@property (nonatomic, assign) AylaOAuthType type;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) void (^failureBlock)(NSError *error);
@property (nonatomic, strong) void (^successBlock)(AylaAuthorization *authorization);
@property (nonatomic, weak) AylaLoginManager *loginManager;
@end

@interface AylaOAuthProvider (WKNavigationDelegate)<WKNavigationDelegate>
@end

@implementation AylaOAuthProvider
+ (instancetype)providerWithWebView:(WKWebView *)webView type:(AylaOAuthType)type
{
    AylaOAuthProvider *provider = [[self alloc] init];
    provider.type = type;
    provider.webView = webView;
    return provider;
}

+ (NSString *)authNameFromType:(AylaOAuthType)type
{
    switch (type) {
        case AylaOAuthTypeFacebook:
            return AylaOAuthTypeNameFacebook;
        case AylaOAuthTypeGoogle:
            return AylaOAuthTypeNameGoogle;
    }
    return nil;
}

- (AylaHTTPTask *)authenticateWithLoginManager:(AylaLoginManager *)loginManager
                                       success:(void (^)(AylaAuthorization *_Nonnull))successBlock
                                       failure:(void (^)(NSError *_Nonnull))failureBlock
{
    self.loginManager = loginManager;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    
    return [self fetchProviderURLWithSuccess:^(NSString *urlString) {

        NSURL *url = [NSURL
            URLWithString:[NSString stringWithFormat:@"%@&redirect_uri=%@",
                                                     urlString,
                                                     self.type == AylaOAuthTypeGoogle ? AylaOAuthRedirectUriLocal
                                                                                      : AylaOAuthRedirectUriRemote]];
        self.webView.navigationDelegate = self;

        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];

    }
                                     failure:failureBlock];
}

- (AylaHTTPTask *)fetchProviderURLWithSuccess:(void (^)(NSString *))successBlock
                                      failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSString *authMethod = [AylaOAuthProvider authNameFromType:self.type];
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
            failureBlock(error);
        });
        return nil;
    }
    else if (!authMethod) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(type)) : AylaErrorDescriptionIsInvalid}
                                   }];

        AylaLogE([self logTag], 0, @"%@%@", NSStringFromSelector(_cmd), error);
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSDictionary *params = @{
        AylaOAuthParamUser : @{
            AylaOAuthParamAuthMethod : authMethod,
            AylaOAuthParamApplication : @{
                AylaOAuthParamAppId : loginManager.settings.appId,
                AylaOAuthParamAppSecret : loginManager.settings.appSecret
            }
        }
    };
    NSString *path = @"users/sign_in.json";
    return [[loginManager getHTTPClient] postPath:path
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSString *urlString = [responseObject objectForKey:@"url"];
            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(urlString);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"OAuth err %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)authenticateAgainstServiceWithCode:(NSString *)code
{
    NSString *authMethod = [AylaOAuthProvider authNameFromType:self.type];
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
    else if (!authMethod) {
        invalidParameter = NSStringFromSelector(@selector(type));
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
        @"redirect_url" : self.type == AylaOAuthTypeGoogle ? AylaOAuthRedirectUriLocal : AylaOAuthRedirectUriRemote,
        @"app_id" : loginManager.settings.appId,
        @"provider" : authMethod
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
    return NSStringFromClass([AylaOAuthProvider class]);
}
@end

@implementation AylaOAuthProvider (WKNavigationDelegate)
- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;

    // when the user has successfully logged into the OAuth provider, he will be redirected to the corresponding URI,
    // the following statement determines if the webView has been redirected indicating success.
    BOOL didRedirect =
        [[url absoluteString]
            rangeOfString:[NSString
                              stringWithFormat:@"%@%@",
                                               [(self.type == AylaOAuthTypeGoogle
                                                     ? AylaOAuthRedirectUriLocal
                                                     : AylaOAuthRedirectUriRemote)stringByRemovingPercentEncoding],
                                               @"?"]]
            .location != NSNotFound;
    if (didRedirect) {
        // Once redirected, the query part of the URL wil contain the authorization code or an error
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSString *errorValue = [urlComponents ayla_valueForQueryItem:AylaOAuthURLParamError];
        if (errorValue != nil) {
            AylaRequestErrorCode errorCode = AylaRequestErrorCodeUnknown;
            if ([errorValue isEqualToString:AylaOAuthURLParamErrorAccessDenied]) {
                errorCode = AylaRequestErrorCodeCancelled;
            }

            NSError *error = [AylaErrorUtils
                errorWithDomain:AylaRequestErrorDomain
                           code:errorCode
                       userInfo:@{
                           AylaRequestErrorResponseJsonKey : @{NSStringFromSelector(@selector(error)) : errorValue}
                       }];
            AylaLogE([self logTag], 0, @"OAuth err %@", error);

            dispatch_async(dispatch_get_main_queue(), ^{
                self.failureBlock(error);
            });
        }
        else {
            NSString *code = [urlComponents ayla_valueForQueryItem:AylaOAuthURLParamCode];
            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                [self authenticateAgainstServiceWithCode:code];
            });
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}
@end
