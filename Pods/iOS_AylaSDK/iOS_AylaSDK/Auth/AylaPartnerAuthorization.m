//
//  AylaPartnerAuthorization.m
//  iOS_AylaSDK
//
//  Created by Kavita Khanna on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaPartnerAuthorization.h"
#import "AylaErrorUtils.h"
#import "AylaObject+Internal.h"
#import "AylaIDPAuthProvider.h"
#import "AylaNetworks.h"
#import "AylaHTTPClient.h"

@implementation AylaPartnerAuthorization

NSString * const PartnerAuthTokenStatusNotification = @"PartnerAuthTokenStatusNotification";
NSTimeInterval networkTimeout = 10;
const NSUInteger DEFAULT_PARTNER_AUTH_TOKEN_REFRESH_THRESHOULD_SEC = 900; // 15 mins

#pragma mark - 
#pragma mark - NSCoding implementation

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _partnerId = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerId))];
        _partnerName = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerName))];
        _partnerAuthUrl = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerAuthUrl))];
        _partnerRefreshAuthTokenUrl = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerRefreshAuthTokenUrl))];
        _partnerAppId = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerAppId))];
        _partnerAppSecret = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerAppSecret))];
        _partnerAccessToken = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerAccessToken))];
        _partnerRefreshToken = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(partnerRefreshToken))];
        _role = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(role))];
        _expiresIn = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(expiresIn))] unsignedIntegerValue];
        _createdAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(createdAt))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.partnerId forKey:NSStringFromSelector(@selector(partnerId))];
    [aCoder encodeObject:self.partnerName forKey:NSStringFromSelector(@selector(partnerName))];
    [aCoder encodeObject:self.partnerAuthUrl forKey:NSStringFromSelector(@selector(partnerAuthUrl))];
    [aCoder encodeObject:self.partnerRefreshAuthTokenUrl forKey:NSStringFromSelector(@selector(partnerRefreshAuthTokenUrl))];
    [aCoder encodeObject:self.partnerAppId forKey:NSStringFromSelector(@selector(partnerAppId))];
    [aCoder encodeObject:self.partnerAppSecret forKey:NSStringFromSelector(@selector(partnerAppSecret))];
    [aCoder encodeObject:self.partnerAccessToken forKey:NSStringFromSelector(@selector(partnerAccessToken))];
    [aCoder encodeObject:self.partnerRefreshToken forKey:NSStringFromSelector(@selector(partnerRefreshToken))];
    [aCoder encodeObject:self.role forKey:NSStringFromSelector(@selector(role))];
    [aCoder encodeObject:@(self.expiresIn) forKey:NSStringFromSelector(@selector(expiresIn))];
    [aCoder encodeObject:self.createdAt forKey:NSStringFromSelector(@selector(createdAt))];
}

#pragma mark -
#pragma mark - Initialization

- (instancetype)initWithPartnerId:(NSString *)partnerId
                      partnerName:(NSString *)partnerName
                   partnerAuthUrl:(NSString *)partnerAuthUrl
                     partnerAppId:(NSString *)partnerAppId
                 partnerAppSecret:(NSString *)partnerAppSecret
       partnerRefreshAuthTokenUrl:(NSString *)partnerRefreshAuthTokenUrl
{
    self = [super init];
    if(self) {
        _partnerId = partnerId;
        _partnerName = partnerName;
        _partnerAuthUrl = partnerAuthUrl;
        _partnerAppId = partnerAppId;
        _partnerAppSecret = partnerAppSecret;
        _partnerRefreshAuthTokenUrl = partnerRefreshAuthTokenUrl;
    }
    return self;
}

#pragma mark -
#pragma mark - Public APIs

// Override in sub-class
- (void)loginToPartnerCloudWithToken:(NSString *)partnerToken
                             success:(void (^)(AylaPartnerAuthorization * _Nonnull partnerAuth))successBlock
                             failure:(void (^)(NSError *error))failureBlock
{
    // Override in sub-class
    
    // Reference Code:
    // partnerServiceHttpClient should be configured with full endpoint url for partner login API
    /*AylaHTTPClient *partnerServiceHttpClient = [AylaHTTPClient serviceClientWithUrl:_partnerAuthUrl withDefaultTimeout:networkTimeout];
    [partnerServiceHttpClient postPath:@""
                            parameters:@{ PartnerTokenKey : partnerToken, PartnerAppIdKey : self.partnerAppId, PartnerAppSecret : self.partnerAppSecret }
                                success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                                        
                                    // Setup refreshing of partner Auth token for every partner auth object
                                    [self setupRefreshingAuthToken];
                                    
                                    // Update partner authorization object with retrieved auth data in responseObject
                                    NSError *error = nil;
                                    [self updateAuthorizationWithAuthData:responseObject error:&error];
                                    
                                    if(successBlock) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            successBlock(self);
                                        });
                                    }
                                }
                                failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                                    if(failureBlock) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            failureBlock(error);
                                        });
                                    }
                                }];*/
}

// Override in sub-class
- (void)updateAuthorizationWithAuthData:(id)responseObj error:(NSError *_Nullable __autoreleasing *)error
{
    // Override in sub-class
    // Update authorization object with retrieved auth data from partner cloud sign-in API.
}

- (NSTimeInterval)secondsToExpiry
{
    NSTimeInterval interval =
    [[self.createdAt dateByAddingTimeInterval:self.expiresIn] timeIntervalSinceDate:[NSDate date]];
    return interval > 0 ? interval : 0;
}

#pragma mark -
#pragma mark - Refresh PartnerAuthToken Methods 

/**
 * Implement refresh token methods in partner specific custom auth sub-class.
 * These methods refresh partner auth token at regular intervals based on partner specification.
 * The following code can be used as reference code.
 */

// Helper selector method
- (void)performRefreshingAuthToken {
    [self setupRefreshingAuthToken];
}

// Call this method to hook up refreshing partner auth/access token at regular time intervals
- (void)setupRefreshingAuthToken
{
    NSTimeInterval expireInterval = [self secondsToExpiry];
    
    void (^timerBlock)(AylaPartnerAuthorization *, NSTimeInterval tmInterval) = ^(AylaPartnerAuthorization *authObject, NSTimeInterval tmInterval)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Cancel any existing ones and schedule a new validatation with a delay.
            [NSObject cancelPreviousPerformRequestsWithTarget:authObject
                                                     selector:@selector(performRefreshingAuthToken)
                                                       object:nil];
            [authObject performSelector:@selector(performRefreshingAuthToken)
                                  withObject:nil
                                  afterDelay:tmInterval];
        });
    };
    
    // If remaining time of current authorization is shorter than threshold,
    // do a refresh immidiately
    if (expireInterval < DEFAULT_PARTNER_AUTH_TOKEN_REFRESH_THRESHOULD_SEC)
    {
        __weak typeof(self) weakSelf = self;
        [self refreshPartnerAuthorizationWithSuccess:^ {
            
            // Notify delegate that partner auth/access token has refreshed
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{@"PartnerId" : weakSelf.partnerId, @"PartnerAuthTokenStatus" : @(PartnerAuthTokenStatus_AuthTokenRefreshed)};
                [[NSNotificationCenter defaultCenter] postNotificationName:PartnerAuthTokenStatusNotification object:nil userInfo:userInfo];
            });
        }
          failure:^(NSError *error) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  NSDictionary *userInfo = @{@"PartnerId" : weakSelf.partnerId,
                                             @"PartnerAuthTokenStatus" : @(PartnerAuthTokenStatus_AuthTokenNotRefreshed),
                                             @"Error" : error};
                  [[NSNotificationCenter defaultCenter] postNotificationName:PartnerAuthTokenStatusNotification object:nil userInfo:userInfo];
              });
          }];
    }
    else {
        // Otherwise, setup refresh timer
        timerBlock(self, expireInterval);
    }
}

- (void)refreshPartnerAuthorizationWithSuccess:(void (^)())successBlock
                                       failure:(void (^)(NSError *error))failureBlock
{
    NSDictionary *refreshParams = @{ @"refresh_token" : self.partnerRefreshToken ?: @"" };
    AylaHTTPClient *partnerRefreshAuthTokenServiceHttpClient = [AylaHTTPClient serviceClientWithUrl:self.partnerRefreshAuthTokenUrl withDefaultTimeout:networkTimeout];
    
    __weak typeof(self) weakSelf = self;
    [partnerRefreshAuthTokenServiceHttpClient postPath:@""
                                             parameters:refreshParams
                                                success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                                                    
                                                    if(!responseObject) {
                                                        // Create an error object if returned response is empty
                                                        NSMutableDictionary *errDictionary = [NSMutableDictionary dictionary];
                                                        errDictionary[@"Error"] = AylaErrorDescriptionIsInvalid;
                                                        
                                                        NSError *createdError = [NSError errorWithDomain:AylaJsonErrorDomain
                                                                                                    code:AylaJsonErrorCodeInvalidJson
                                                                                                userInfo:@{AylaRequestErrorResponseJsonKey : errDictionary}];
                                                        failureBlock(createdError);
                                                    }
                                                    else {
                                                        NSDictionary *responseObjectDict = (NSDictionary *)responseObject;
                                                        NSString *accessToken = [responseObjectDict objectForKey:@"access_token"];
                                                        NSInteger expiresIn = [[responseObjectDict objectForKey:@"expires_in"] integerValue];
                                                        
                                                        [weakSelf updatePartnerAuthorizationWithRefreshedAccessToken:accessToken andExpiresInTime:expiresIn];
                                                        
                                                        if(successBlock) {
                                                            successBlock();
                                                        }
                                                    }
                                                }
                                                failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                                                    if(failureBlock) {
                                                        failureBlock(error);
                                                    }
                                                }];
}

- (void)updatePartnerAuthorizationWithRefreshedAccessToken:(NSString *)accessToken andExpiresInTime:(NSInteger)accessTokenExpiresIn
{
    _partnerAccessToken = accessToken;
    _expiresIn = accessTokenExpiresIn;
    
    _createdAt = [NSDate date];
}

@end
