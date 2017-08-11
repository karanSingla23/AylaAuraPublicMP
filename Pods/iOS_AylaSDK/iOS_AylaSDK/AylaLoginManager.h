//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaAuthProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaAuthorization;
@class AylaEmailTemplate;
@class AylaHTTPTask;
@class AylaSessionManager;
@class AylaSystemSettings;
@class AylaUser;
@class AylaHTTPClient;

/**
 * AylaLoginManager
 *
 * The Login Manager provides authentication methods to help application authenticate user identity and obtain access to
 * Ayla Service.
 */
@interface AylaLoginManager : NSObject

/** System settings */
@property (nonatomic, readonly) AylaSystemSettings *settings;

/** @name Login Methods */

/**
 * Use this method to provide user access to the devices registered with their Ayla account.
 *
 * @param authProvider A valid `AylaAuthProvider` which will handle the authentication process.
 * @param sessionName  Unique Name for the session. If a session with this name already exists, the existing session
 * will be closed before opening this one.
 * @param successBlock A block to be called after the login request is successful. Passed fetched `AylaAuthorization` and
 * initialized `AylaSessionManager` objects.
 * @param failureBlock A block to be called if the login operation fails. Passed an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask` object which represents this request
 */
- (AylaHTTPTask *)loginWithAuthProvider:(id<AylaAuthProvider>)authProvider
                            sessionName:(NSString *)sessionName
                                success:(void (^)(AylaAuthorization *authorization,
                                                  AylaSessionManager *sessionManager))successBlock
                                failure:(void (^)(NSError *error))failureBlock;

/** @name Account Management Methods */

/**
 * Creates a new account using the information in the `user` parameter. A sign up confirmation email will be constructed 
 * and formatted using the `emailTemplate` parameter to specify an existing template, and email will be sent to the address 
 * specified in the `email` property of `user` in the cloud.
 *
 * @param user          The `AylaUser` with the necessary account information
 * @param emailTemplate The `AylaEmailTemplate` to be used for the creation of the sign up confirmation email
 * @param successBlock  A block to be called after the signup request is successful.
 * @param failureBlock  A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)signUpWithUser:(AylaUser *)user
                            emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
                                  success:(void (^)())successBlock
                                  failure:(void (^)(NSError *error))failureBlock;

/**
 * Resends the Sign Up Confirmation email to the specified email address. If the email isn't associated with
 * an existing unconfirmed account, the server returns an error with the description.
 *
 * @param email         The email address of the unconfirmed account which is to receive the new confirmation email.
 * @param emailTemplate The `AylaEmailTemplate` to use for the confirmation email
 * @param successBlock  A block to be called if the request is successful.
 * @param failureBlock  A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)resendConfirmationEmail:(NSString *)email
                                     emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
                                           success:(void (^)())successBlock
                                           failure:(void (^)(NSError *error))failureBlock;

/**
 * Confirms the account using the confirmation token contained in the confirmation email.
 *
 * @param token         The token received in the confirmation email.
 * @param successBlock  A block to be called if the request is successful
 * @param failureBlock  A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)confirmAccountWithToken:(NSString *)token
                                           success:(void (^)())successBlock
                                           failure:(void (^)(NSError *error))failureBlock;

/**
 * Requests a password reset email be sent to the specified email address.. The received email will contain a 
 * password reset token that must be passed to resetPasswordTo:token:success:failure: along with the new 
 * password to complete the process.
 *
 * @param email         The email address of the account targeted for password reset.
 * @param emailTemplate The `AylaEmailTemplate` to use for the password reset email.
 * @param successBlock  A block to becalled if the request is successful.
 * @param failureBlock  A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)requestPasswordReset:(NSString *)email
                                  emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
                                        success:(void (^)())successBlock
                                        failure:(void (^)(NSError *error))failureBlock;

/**
 * Resets the password to the one passed as the password parameter. Requires a password reset token sent in a password reset
 * email.
 *
 * @param password      The new password for the account.
 * @param token         The Password reset token received in the email
 * @param successBlock  A block to be called if the request is successful
 * @param failureBlock  A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)resetPasswordTo:(NSString *)password
                                     token:(NSString *)token
                                   success:(void (^)())successBlock
                                   failure:(void (^)(NSError *error))failureBlock;
/**
 * Get HTTP client from login manager.
 */
- (AylaHTTPClient *)getHTTPClient;
@end

NS_ASSUME_NONNULL_END
