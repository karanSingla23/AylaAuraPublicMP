//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaAuthProvider.h"
#import "AylaBaseAuthProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaAuthorization;

/**
 * A type of `AylaAuthProvider` that uses cached credentials to sign in. If your application is saving the
 * `AylaAuthorization` in order  to log the user in automatically on subsequent runs of the app, this
 * object can be initialized with the cached credentials and passed to `AylaLoginManager`
 * to sign-in the user.
 *
 * The `AylaCachedAuthProvider` will refresh the provided credentials as part of the sign-in process if
 * the cloud is available.
 *
 * This class allows for offline sign-in if the cloud service is available. If the cloud service
 * is not available, and the `AylaSystemSettings` object was initialized with `allowOfflineUse` set to true, the
 * provider will allow the sign-in operation to succeed.
 *
 * While the cloud service is unavailable, the system will attempt to return cached data to
 * API requests whenever possible. Not all data is cached, however, so the application should
 * always be prepared to receive error responses to any API request.
 */
@interface AylaCachedAuthProvider : AylaBaseAuthProvider

/** @name Cached Auth Provider Properties */


/** Cached credential */
@property (nonatomic, readonly) AylaAuthorization *cachedAuthorization;

/** @name Initializer Methods */

/**
 * Use this method to create a `AylaCachedAuthProvider` instance.
 *
 * @param authorization Cached authorization.
 */
+ (instancetype)providerWithAuthorization:(AylaAuthorization *)authorization;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
