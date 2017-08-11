//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Class containing session authorization information. Objects of this type are returned from
 * `AylaAuthProvider` objects when used to sign-in.
 *
 * Authorizations may be cached and used to initialize a `AylaCachedAuthProvider` object, which
 * can be passed to signIn api of `AylaLoginManager` to refresh the previous authorization.
 */
@interface AylaAuthorization : AylaObject <NSCoding>

/** @name Authorization Properties */
/** User's access token */
@property (nonatomic, readonly) NSString *accessToken;

/** User's refresh token */
@property (nonatomic, readonly) NSString *refreshToken;

/** User role for current session */
@property (nonatomic, readonly, nullable) NSString *role;

/** User role tags for current session */
@property (nonatomic, readonly, nullable) NSArray *roleTags;

/** Duration in seconds of how long after its creation the current access token is valid */
@property (nonatomic, readonly) NSUInteger expiresIn;

/** NSDate at which the current access token was created */
@property (nonatomic, readonly) NSDate *createdAt;

/**
 * Use this method to calculate the remaining lifetime of the current access token in seconds.
 *
 * @return `NSTimeInterval` for the number of seconds left until the token expires. Will return 0 if the access token has expired or the user has not yet logged in.
 */
- (NSTimeInterval)secondsToExpiry;

/**
 * Initialize authorization with the specified dicitonary
 *
 * @param dictionary The dictionary returned by the cloud
 * @param error      Variable where the error would be written on failure
 *
 * @return an initialized `AylaAuthorization`
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
