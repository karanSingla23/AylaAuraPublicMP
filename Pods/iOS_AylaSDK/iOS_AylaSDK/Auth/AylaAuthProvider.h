//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPTask;
@class AylaSessionManager;
@class AylaUser;
@class AylaLoginManager;
@class AylaAuthorization;

/**
 * An `AylaAuthProvider` performs the steps necessary to authenticate a user. The `AylaAuthProvider`
 * object is passed into `AylaLoginManager`
 * which will call the `authenticateWithLoginManager:success:failure:` method and
 * get the response. The LoginManager at that point will start up the system using the provided
 * authorization credentials.
 */
@protocol AylaAuthProvider <NSObject>

/**
 * Called by AylaSessionManager to sign out the user.
 *
 * @param sessionManager The session manager calling the method
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 *
 * @return An `AylaConnectTask` task representing this request.
 *
 * @note Regardless of whether the cloud request succeeds or not, this method
 * will permanently shut down the current AylaSessionManager` instance.
 */
- (nullable AylaHTTPTask *)signOutWithSessionManager:(AylaSessionManager *)sessionManager
                                                 success:(void (^)(void))successBlock
                                                 failure:(void (^)(NSError *error))failureBlock;

/**
 * Called by AylaSessionManager to update the user profile on the Ayla service or external
 * identity provider service (for SSO users) to match the fields in the provided AylaUser.
 *
 * @param user `AylaUser` object which contains all data for the current user.
 * @param sessionManager The session manager calling the method
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 */
- (nullable AylaHTTPTask *)updateUserProfile:(AylaUser *)user
                              sessionManager:(AylaSessionManager *)sessionManager
                                     success:(void (^)(void))successBlock
                                     failure:(void (^)(NSError *err))failureBlock;

/**
 * Called by AylaSessionManager to delete a user account from Ayla service or the external
 * identity provider (for SSO users).
 *
 * @note This operation permanently deletes the user's account, account details,
 * and device records.  This cannot be undone.
 *
 * @param sessionManager The session manager calling the method
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)deleteAccountWithSessionManager:(AylaSessionManager *)sessionManager
                                                   success:(void (^)(void))successBlock
                                                   failure:(void (^)(NSError *err))failureBlock;

/**
 * Called by AylaLoginManager, this method should perform the necessary operations to sign in
 * a user. On successful sign-in, the method should call the provided listener via
 * {@link com.aylanetworks.aylasdk.auth.AylaAuthProvider.AuthProviderListener#didAuthenticate
 * didAuthenticate}
 * and provide the AylaAuthorization object with the necessary authenticated credentials.
 *
 * @param loginManager The loginManager that called the authenticate method
 * @param successBlock A block called when the authentication was successful.
 * @param failureBlock A block called whe nthe authentication failed.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)authenticateWithLoginManager:(AylaLoginManager *)loginManager
                                       success:(void (^)(AylaAuthorization *authorization))successBlock
                                       failure:(void (^)(NSError *error))failureBlock;
@end

DEPRECATED_MSG_ATTRIBUTE("AylaAuthProvider class has been deprecated, use id<AylaAuthProvider> to refer to a class conforming to AylaAuthProvider protocol instead")
typedef id<AylaAuthProvider> AylaAuthProvider;
NS_ASSUME_NONNULL_END
