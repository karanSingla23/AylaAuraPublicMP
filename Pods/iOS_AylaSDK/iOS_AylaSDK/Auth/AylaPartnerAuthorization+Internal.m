//
//  AylaPartnerAuthorization+Internal.m
//  iOS_AylaSDK
//
//  Created by Kavita Khanna on 5/22/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaPartnerAuthorization+Internal.h"
#import "AylaHTTPClient.h"
#import "AylaErrorUtils.h"

@implementation AylaPartnerAuthorization (Internal)

#pragma mark -
#pragma mark - Test Methods

/** Methods for testing partner cloud sign-in using Ayla partner testing service */

- (void)testLoginToPartnerCloudWithToken:(NSString *)partnerToken
                          systemSettings:(AylaSystemSettings *)settings
                                 success:(void(^)(AylaPartnerAuthorization *partnerAuth))successBlock
                                 failure:(void (^)(NSError *error))failureBlock
{
    NSString *PartnerTokenKey = @"token";
    NSString *PartnerAppIdKey = @"app_id";
    NSString *PartnerAppSecret = @"app_secret";
    NSUInteger networkTimeout = 10;
    
    NSString *path = @"api/v1/token_sign_in";
    AylaHTTPClient *partnerServiceHttpClient = [AylaHTTPClient serviceClientWithBaseUrl:self.partnerAuthUrl andSystemSettings:settings usingHTTPS:YES withDefaultTimeout:networkTimeout];
    
    [partnerServiceHttpClient postPath:path
                            parameters:@{ PartnerTokenKey : partnerToken, PartnerAppIdKey : self.partnerAppId, PartnerAppSecret : self.partnerAppSecret }
                               success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                                   NSError *error = nil;
                                   [self testUpdateWithJSONDictionary:responseObject error:&error];
                                   
                                   if(!error) {
                                       if(successBlock) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               successBlock(self);
                                           });
                                       }
                                   }
                                   else {
                                       if(failureBlock) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               failureBlock(error);
                                           });
                                       }
                                   }
                               }
                               failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                                   if(failureBlock) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           failureBlock(error);
                                       });
                                   }
                               }];
}

- (void)testUpdateWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *_Nullable __autoreleasing *)error
{
    if(!dictionary) {
        NSMutableDictionary *errorDictionary = [NSMutableDictionary dictionary];
        errorDictionary[@"EmptyResponse"] = AylaErrorDescriptionCanNotBeBlank;
        NSError *emptyResError = [NSError errorWithDomain:AylaJsonErrorDomain
                                                     code:AylaJsonErrorCodeInvalidJson
                                                 userInfo:@{AylaRequestErrorResponseJsonKey : errorDictionary}];
        if (error != NULL) {
            *error = emptyResError;
        }
        return;
    }
    
    [self setValue:[dictionary objectForKey:@"access_token"] forKey:@"partnerAccessToken"];
    [self setValue:[dictionary objectForKey:@"refresh_token"] forKey:@"partnerRefreshToken"];
    [self setValue:[dictionary objectForKey:@"role"] forKey:@"role"];
    [self setValue:[dictionary objectForKey:@"expires_in"] forKey:@"expiresIn"]; // Cloud returns an expiration time
    
    [self setValue:[NSDate date] forKey:@"createdAt"];
    
    if (self.partnerId.length == 0 || self.partnerAccessToken.length == 0 || self.partnerRefreshToken.length == 0 || !self.createdAt || self.expiresIn == 0) {
        
        [self setValue:@"" forKey:@"partnerAccessToken"];
        [self setValue:@"" forKey:@"partnerRefreshToken"];
        
        NSMutableDictionary *errDictionary = [NSMutableDictionary dictionary];
        if (!self.partnerAccessToken) {
            errDictionary[NSStringFromSelector(@selector(partnerAccessToken))] = AylaErrorDescriptionCanNotBeBlank;
        }
        if (!self.partnerRefreshToken) {
            errDictionary[NSStringFromSelector(@selector(partnerRefreshToken))] = AylaErrorDescriptionCanNotBeBlank;
        }
        if (self.expiresIn == 0) {
            errDictionary[NSStringFromSelector(@selector(expiresIn))] = AylaErrorDescriptionIsInvalid;
        }
        
        NSError *createdError = [NSError errorWithDomain:AylaJsonErrorDomain
                                                    code:AylaJsonErrorCodeInvalidJson
                                                userInfo:@{AylaRequestErrorResponseJsonKey : errDictionary}];
        if (error != NULL) {
            *error = createdError;
        }
    }
}

@end
