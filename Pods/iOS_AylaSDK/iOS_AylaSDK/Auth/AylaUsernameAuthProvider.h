//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaBaseAuthProvider.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * `AylaUsernameAuthProvider` allows authorization to the Ayla Service using a username and password.
 */
@interface AylaUsernameAuthProvider : AylaBaseAuthProvider

/** @name AuthProviderProperties */

/** User's email address */
@property (nonatomic, readonly) NSString *username;

/** User's password */
@property (nonatomic, readonly) NSString *password;

/** @name Initializer Methods */

/**
 * Use this method to create a AylaUsernameAuthProvider instance.
 *
 * @param username User's email address.
 * @param password User's password.
 */
+ (instancetype)providerWithUsername:(NSString *)username password:(NSString *)password;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
