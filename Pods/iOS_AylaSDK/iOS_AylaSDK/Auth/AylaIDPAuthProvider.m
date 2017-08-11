//
//  AylaIDPAuthProvider.m
//  iOS_AylaSDK
//
//  Created by Kavita Khanna on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaIDPAuthProvider.h"
#import "AylaHTTPClient.h"
#import "AylaLogManager.h"
#import "AylaErrorUtils.h"
#import "AylaAuthorization.h"
#import "AylaNetworks.h"
#import "AylaSessionManager+Internal.h"

@interface AylaIDPAuthProvider ()
@property (nonatomic, strong) AylaSessionManager *sessionManager;
@end

@implementation AylaIDPAuthProvider

NSString * const IDPPartnerIdsKey = @"partner_ids";
NSString * const IDPPartnerTokensKey = @"partner_tokens";
NSString * const IDPPartnerIdKey = @"partner_id";
NSString * const IDPPartnerTokenKey = @"partner_token";

#pragma mark -
#pragma mark - Initializer

- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager
{
    self = [super init];
    if(self) {
        _sessionManager = sessionManager;
    }
    return self;
}

#pragma mark - 
#pragma mark - Public APIs

- (void)getPartnerTokensForPartnerIds:(NSArray<NSString *> *)partnerIds
                              success:(void (^)(NSDictionary<NSString *,NSString *> * _Nonnull))successBlock
                              failure:(void (^)(NSError * _Nonnull))failureBlock
{
    NSDictionary *params = @{ IDPPartnerIdsKey : [NSArray arrayWithArray:partnerIds] };
    
    NSString *path = @"api/v1/partner_tokens.json";
    
    __weak typeof(self) weakSelf = self;
    AylaHTTPClient *httpClient = [self.sessionManager getHttpClientWithType:AylaHTTPClientTypeUserService];
    [httpClient getPath:path
            parameters:params
               success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                   NSDictionary *resultDict = [weakSelf partnerTokensPerPartnerIdsFromJSONDictionary:responseObject];
                   if(resultDict.count > 0) {
                       NSDictionary *partnerTokensPerPartnerId = [NSDictionary dictionaryWithDictionary:resultDict];
                       dispatch_async(dispatch_get_main_queue(), ^{
                           successBlock(partnerTokensPerPartnerId);
                       });
                   }
                   else {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           successBlock([NSDictionary new]);
                       });
                   }
               }
               failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                   AylaLogE([AylaIDPAuthProvider logTag], 0, @"err:%@, %@", error,
                            NSStringFromSelector(_cmd));
                   
                   dispatch_async(dispatch_get_main_queue(), ^{
                       failureBlock(error);
                   });
               }];
}

+ (NSString *)logTag
{
    return @"AylaIDPAuthProvider";
}

#pragma mark - 
#pragma mark - JSON Methods

- (NSDictionary *)partnerTokensPerPartnerIdsFromJSONDictionary:(NSDictionary *)responseObjectDict
{
    NSMutableDictionary *resultDict = nil;
    
    if(!responseObjectDict) {
        return nil;
    }
    resultDict = [NSMutableDictionary new];
    
    // Response dictionary contains array of dictionaries with partner_id & partner_token
    NSArray *arrayOfDictionaries = [responseObjectDict objectForKey:IDPPartnerTokensKey];
    if(arrayOfDictionaries)
    {
        for(NSDictionary *partnerIdWithTokenDict in arrayOfDictionaries) {
            NSString *partnerId = partnerIdWithTokenDict[IDPPartnerIdKey];
            NSString *partnerToken = partnerIdWithTokenDict[IDPPartnerTokenKey];
            if(partnerId.length > 0 && partnerToken.length > 0) {
                [resultDict setObject:partnerToken forKey:partnerId];
            }
        }
    }
    return resultDict;
}

@end
