//
//  AylaPartnerAuthorization.h
//  iOS_AylaSDK
//
//  Created by Kavita Khanna on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

@class AylaSystemSettings;

NS_ASSUME_NONNULL_BEGIN

/**
 * Notification about partner auth/access token status
 */
FOUNDATION_EXPORT NSString * const PartnerAuthTokenStatusNotification;

/**
 * Enum indicating partner auth status for logged in ayla user.
 */
typedef NS_ENUM(NSInteger, PartnerAuthTokenStatus) {
    /** User's partner access token refreshed */
    PartnerAuthTokenStatus_AuthTokenRefreshed = 0,
    /** User's partner access token could not be refreshed */
    PartnerAuthTokenStatus_AuthTokenNotRefreshed
};

/**
 * Base class for partner authorization for accessing partner cloud.
 * Use this as super class and create custom partner authorization class
 * subclassing this base class for each specific partner cloud.
 */
@interface AylaPartnerAuthorization : AylaObject <NSCoding>

/** Partner Id */
@property (nonatomic, strong, readonly) NSString *partnerId;

/** Name of the partner */
@property (nonatomic, strong, readonly) NSString *partnerName;

/** Partner Auth Endpoint URL */
@property (nonatomic, strong, readonly) NSString *partnerAuthUrl;

/** Partner auth/access token refresh URL */
@property (nonatomic, strong, readonly) NSString *partnerRefreshAuthTokenUrl;

/** Partner App Id for the mobile APP */
@property (nonatomic, strong, readonly) NSString *partnerAppId;

/** Partner App Secret for the mobile APP */
@property (nonatomic, strong, readonly) NSString *partnerAppSecret;

/** Partner Auth Token */
@property (nonatomic, strong, readonly) NSString *partnerAccessToken;

/** Partner Refresh Token */
@property (nonatomic, strong, readonly) NSString *partnerRefreshToken;

/** User role for current partner access */
@property (nonatomic, readonly, nullable) NSString *role;

/** Duration in seconds of how long after its creation the current partner auth token is valid */
@property (nonatomic, readonly) NSUInteger expiresIn;

/** NSDate at which the current partner auth token was created */
@property (nonatomic, readonly) NSDate *createdAt;

/**
 * Initialize base partner authorization with the specified parameters.
 *
 * @param partnerId                     Partner cloud Id
 * @param partnerName                   Partner name
 * @param partnerAuthUrl                Partner cloud auth URL endpoint
 * @param partnerAppId                  App Id given to this app by partner cloud
 * @param partnerAppSecret              App secret given to this app by partner cloud
 * @param partnerRefreshAuthTokenUrl    Partner cloud URL endpoint for auth token refreshing
 *
 * @return an initialized `AylaPartnerAuthorization` object
 */
- (instancetype)initWithPartnerId:(NSString *)partnerId
                      partnerName:(NSString *)partnerName
                   partnerAuthUrl:(NSString *)partnerAuthUrl
                     partnerAppId:(NSString *)partnerAppId
                 partnerAppSecret:(NSString *)partnerAppSecret
       partnerRefreshAuthTokenUrl:(NSString *)partnerRefreshAuthTokenUrl;

/** 
 * Logs-in to partner cloud using short-lived partner token retrieved from AylaIDP
 * Override this method in sub-class for custom login implementation for partner cloud.
 *
 * @param partnerToken Short-lived partner token to login to patner cloud
 * @param successBlock Success block called after successful auth to partner cloud. Passes in the created AylaPartnerAuthorization object
 * @param failureBlock Failure block called if auth fails to partner cloud
 */
- (void)loginToPartnerCloudWithToken:(NSString *)partnerToken
                             success:(void(^)(AylaPartnerAuthorization *partnerAuth))successBlock
                             failure:(void (^)(NSError *error))failureBlock;

/**
 * Use this method to calculate the remaining lifetime of the current partner auth token in seconds.
 * Override this method in sub-class for custom implementation for partner cloud.
 *
 * @return `NSTimeInterval` for the number of seconds left until the token expires.
 * Will return 0 if the access token has expired or the user has not yet loggedin.
 */
- (NSTimeInterval)secondsToExpiry;


/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
