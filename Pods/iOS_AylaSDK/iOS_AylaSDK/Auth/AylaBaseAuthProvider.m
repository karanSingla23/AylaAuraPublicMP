//
//  AylaBaseAuthProvider.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBaseAuthProvider.h"
#import "AylaHTTPClient.h"
#import "AylaSessionManager+Internal.h"
#import "AylaNetworks+Internal.h"
#import "AylaUser.h"
#import "AylaObject+Internal.h"

@implementation AylaBaseAuthProvider
- (AylaHTTPTask *)authenticateWithLoginManager:(AylaLoginManager *)loginManager success:(void (^)(AylaAuthorization * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    NSAssert(NO, @"This method must be overriden in subclass");
    return nil;
}

- (AylaHTTPTask *)signOutWithSessionManager:(AylaSessionManager *)sessionManager
                                    success:(void (^)(void))successBlock
                                    failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaHTTPClient *httpClient =
    [sessionManager getHttpClientWithType:AylaHTTPClientTypeUserService];
    
    // Remove self from SDK root.
    [sessionManager.sdkRoot removeSessionManager:sessionManager];
    
    if (!httpClient) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          NSStringFromSelector(@selector(httpClients)) :
                                              AylaErrorDescriptionCanNotBeFound
                                          }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    return [httpClient postPath:@"users/sign_out.json"
                     parameters:@{ @"user": @{ @"access_token": sessionManager.authorization.accessToken } }
                        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                            
                            AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                                     NSStringFromSelector(_cmd));
                            dispatch_async(dispatch_get_main_queue(), ^{
                                successBlock();
                            });
                        }
                        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                            
                            AylaLogE([self logTag], 0, @"err:%@, %@", error,
                                     NSStringFromSelector(_cmd));
                            dispatch_async(dispatch_get_main_queue(), ^{
                                failureBlock(error);
                            });
                        }];
}

- (AylaHTTPTask *)updateUserProfile:(AylaUser *)user sessionManager:(AylaSessionManager *)sessionManager
                            success:(void (^)(void))successBlock
                            failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaHTTPClient *httpClient =
    [sessionManager getHttpClientWithType:AylaHTTPClientTypeUserService];
        
    if (!httpClient) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          NSStringFromSelector(@selector(httpClients)) :
                                              AylaErrorDescriptionCanNotBeFound
                                          }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    return [httpClient putPath:@"users.json"
                    parameters:@{
                                 @"user" : [user toJSONDictionary]
                                 }
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           
                           AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                                    NSStringFromSelector(_cmd));
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock();
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           
                           AylaLogE([self logTag], 0, @"err:%@, %@", error,
                                    NSStringFromSelector(_cmd));
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

- (AylaHTTPTask *)deleteAccountWithSessionManager:(AylaSessionManager *)sessionManager success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaHTTPClient *httpClient =
    [sessionManager getHttpClientWithType:AylaHTTPClientTypeUserService];
    
    // Remove self from SDK root.
    [sessionManager.sdkRoot removeSessionManager:sessionManager];
    
    if (!httpClient) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          NSStringFromSelector(@selector(httpClients)) :
                                              AylaErrorDescriptionCanNotBeFound
                                          }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    NSString *path = @"users.json";
    return [httpClient deletePath:path
                       parameters:nil
                          success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                              [sessionManager.sdkRoot removeSessionManager:sessionManager];
                              AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                                       NSStringFromSelector(_cmd));
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  successBlock();
                              });
                          }
                          failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                              
                              AylaLogE([self logTag], 0, @"err:%@, %@", error,
                                       NSStringFromSelector(_cmd));
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  failureBlock(error);
                              });
                          }];
}

- (NSString *)logTag {
    return NSStringFromClass([self class]);
}
@end
