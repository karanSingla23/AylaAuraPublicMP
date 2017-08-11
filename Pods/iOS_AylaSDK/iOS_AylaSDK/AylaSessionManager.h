//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaAuthProvider.h"
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class AylaAuthorization;
@class AylaContact;
@class AylaDatum;
@class AylaDeviceManager;
@class AylaEmailTemplate;
@class AylaHTTPTask;
@class AylaNetworks;
@class AylaSessionManager;
@class AylaShare;
@class AylaUser;
@class AylaCache;

/** A protocol to enable being informed of changes in the objects managed by an
 * `AylaSessionManager` instance. */
@protocol AylaSessionManagerListener <NSObject>

/**
 * Notifies that the authorization has been refreshed. Applications that cache
 * authorization data should update their cache with the new value.
 *
 * @param sessionManager The `AylaSessionManager` object that has been
 * refreshed.
 * @param authorization The refreshed `AylaAuthorization` object
 */
- (void)sessionManager:(AylaSessionManager *)sessionManager
    didRefreshAuthorization:(AylaAuthorization *)authorization;

/**
 * Notifies that the session has been closed. If the session was closed due to
 * an error,
 * the error field will contain an `NSError` with the reason for the closure. If
 * the session
 * was closed because the user signed out, error will be null.
 *
 * @param sessionManager The `AylaSessionManager` object that has been closed.
 * @param error nil if an intentional sign out was successful. Otherwise the
 * `NSError` describing the cause of the session closure.
 */
- (void)sessionManager:(AylaSessionManager *)sessionManager
       didCloseSession:(nullable NSError *)error;
@end

/**
 * Manages data and objects associated with the currently authenticated session.
 *
 * Contains the methods to create and manage:
 *
 * - The `AylaUser` object associated with the currently logged in user and
 * authenticated session.
 * - `AylaDatum` objects used for User Datum (`AylaDatum` associated with a
 * particular `AylaUser`).
 * - `AylaContact` objects used to creating and sending notifications or shares
 * to another user.
 * - `AylaShare` objects used to grant access to one of the users registered
 * `AylaDevice`s to another user.
 *
 */

@interface AylaSessionManager : NSObject

/** @name AylaSessionManager Properties */
/** Currently used `AylaAuthorization` */
@property(nonatomic, readonly, nullable) AylaAuthorization *authorization;

/** Indicates whether the session has been loaded from cache (if
 * `allowOfflineUse` was set to true in SystemSettings and
 * authentication could not be performed agains  User service) */
@property(nonatomic, readonly, getter=isCachedSession) BOOL cachedSession;

/** Unique session name associated with the current session */
@property(nonatomic, readonly) NSString *sessionName;

/** SDK root, which retains the current `AylaSessionManager` instance */
@property(nonatomic, readonly, weak) AylaNetworks *sdkRoot;

/** `AylaDeviceManager` instance for the current session */
@property(nonatomic, readonly) AylaDeviceManager *deviceManager;

/** AylaCache instance for the current session */
@property(nonatomic, readonly) AylaCache *aylaCache;

/** Provider used to authenticate */
@property(nonatomic, readonly) id<AylaAuthProvider> authProvider;

/** @name AylaSessionManagerListener Methods */
/**
 * Add a listener which conforms to the `AylaConnectivityListener` protocol
 * @param listener  An object conforming to the `AylaConnectivityListener`
 * protocol that is to be added as a listener
 */
- (void)addListener:(id<AylaSessionManagerListener>)listener;

/**
 * Remove a listener which conforms to the `AylaSessionManagerListener` protocol
 * @param listener  An object conforming to the `AylaConnectivityListener`
 * protocol that is to be removed as a listener
 */
- (void)removeListener:(id<AylaSessionManagerListener>)listener;

/** @name AylaSessionManager Methods */

/**
 * Use this method to refresh the authorization of the current
 * `AylaSessionManager`
 *
 * @sa `[AylaSessionManagerListener sessionManager:didRefreshAuthorization:]`
 *
 * @param successBlock A block to be called when the request is successful.
 * Passed the
 * @param failureBlock A block to be called when the refresh operation fails.
 * Passed an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask task which represents this request.
 */
- (nullable AylaHTTPTask *)
refreshAuthorization:(void (^)(AylaAuthorization *authorization))successBlock
             failure:(void (^)(NSError *error))failureBlock;

/**
 * Use this method to log out of the current session. The current
 * `AylaSessionManager` instance will be removed from the
 * SDK once this request is processed, even in case of failure reported by the
 * cloud.
 *
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` task representing this request.
 *
 * @note Regardless of whether the cloud request succeeds or not, this method
 * will permanently shut down the current AylaSessionManager` instance.
 */
- (nullable AylaHTTPTask *)logoutWithSuccess:(void (^)(void))successBlock
                                     failure:
                                         (void (^)(NSError *error))failureBlock DEPRECATED_MSG_ATTRIBUTE("Please use shutDownWithSuccess:failure:");

/**
 * Shuts down the current session and logs out the user. If an error occurred when sending
 * the sign-out message to the cloud service, the session will still be closed and the user
 * will need to sign in again.
 *
 * @param successBlock Block to receive the results of the network sign-out call.
 * @param failureBlock Block to receive an error from the network sign-out call.
 * @return the `AylaHTTPTask` for this command. While the request to sign out from the server
 * may be canceled, the session will be closed regardless.
 */
- (nullable AylaHTTPTask *)shutDownWithSuccess:(void (^)(void))successBlock
                                       failure:(void (^)(NSError *error))failureBlock;

/**
 * @return YES if conneciton to DSS has been established.
 */
- (BOOL)isDSActive;

/**
 * Use this method to pause the current `AylaSessionManager`.
 */
- (void)pause;

/**
 * Use this method to resume the current `AylaSessionManager`.
 */
- (void)resume;

@end

@interface AylaSessionManager (User)
/** @name User and Account Methods */

/**
 * Use this method to retrieve existing user account information from the Ayla
 * Cloud Services. The user must be
 * authenticated via login, before calling this method.
 *
 * @param successBlock A block to be called when the request is successful.
 * Passed the fetched `AylaUser` object returned from the cloud.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 */
- (nullable AylaHTTPTask *)
fetchUserProfile:(void (^)(AylaUser *user))successBlock
         failure:(void (^)(NSError *err))failureBlock;

/**
 * Use this method to retrieve existing user account information from Ayla Cloud
 * Services. The user must be
 * authenticated, via login, before calling this method.
 *
 * @param user `AylaUser` object which contains all data for the current user.
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 */
- (nullable AylaHTTPTask *)updateUserProfile:(AylaUser *)user
                                     success:(void (^)(void))successBlock
                                     failure:
                                         (void (^)(NSError *err))failureBlock;

/**
 * Use this method to modify the user's email address.
 * The user must be authenticated/logged-in before calling this method.
 *
 * @param email        New email address
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 */
- (nullable AylaHTTPTask *)updateUserEmailAddress:(NSString *)email
                                          success:(void (^)(void))successBlock
                                          failure:(void (^)(NSError *err))
                                                      failureBlock;
/**
 * Deletes the account of the current user.
 *
 * @note This operation permanently deletes the user's account, account details,
 * and device records.  This cannot be undone.
 *
 * @param successBlock A block to be called when the request is successful.
 * @param failureBlock A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)deleteAccountWithSuccess:(void (^)(void))successBlock
                                            failure:(void (^)(NSError *err))
                                                        failureBlock;

/**
 * Updates the current user password with the new password string provided.
 *
 * @param currentPassword The current password.
 * @param newPassword     The new password.
 * @param successBlock    A block to be called when the request is successful.
 * @param failureBlock    A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request
 */
- (nullable AylaHTTPTask *)updatePassword:(NSString *)currentPassword
                              newPassword:(NSString *)newPassword
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *err))failureBlock;

@end
@interface AylaSessionManager (Contact)
/** @name AylaContact Methods */

/**
 * Creates the specified `AylaContact` in the cloud.
 *
 * @param contact         The `AylaContact` object that will be created in the
 * cloud
 * @param successBlock    A block to be called when the request is successful.
 * Passed the newly created `AylaContact`
 * object returned from the cloud.
 * @param failureBlock    A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
createContact:(AylaContact *)contact
      success:(void (^)(AylaContact *createdContact))successBlock
      failure:(void (^)(NSError *error))failureBlock;
/**
 *  Fetches the any existing `AylaContact` objects from the cloud.
 *
 * @param successBlock    A block to be called when the request is successful.
 * Passed an `NSArray` containing fetched
 * `AylaContact` objects, if any, returned from the cloud.
 * @param failureBlock    A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)fetchContacts:
                               (void (^)(NSArray AYLA_GENERIC(AylaContact *) *
                                         contacts))successBlock
                                 failure:(void (^)(NSError *error))failureBlock;
/**
 * Updates a contact in the cloud with the specified data.
 *
 * @param contact         The already modified `AylaContact` to be updated in
 * the cloud.
 * @param successBlock    A block to be called when the request is successful.
 * Passed the updated `AylaContact` object returned from the cloud.
 * @param failureBlock    A block to be called when the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
updateContact:(AylaContact *)contact
      success:(void (^)(AylaContact *updatedContact))successBlock
      failure:(void (^)(NSError *error))failureBlock;
/**
 *  Deletes the specified contact from the cloud.
 *
 *  @param contact      The `AylaContact` object to delete on the cloud
 *  @param successBlock A block to be called when the contact has been
 * successfully deleted.
 *  @param failureBlock A block to be called when the contact could not be
 * deleted. Passed an `NSError` describing the failure.
 *
 *  @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)deleteContact:(AylaContact *)contact
                                 success:(void (^)())successBlock
                                 failure:(void (^)(NSError *error))failureBlock;
@end

@interface AylaSessionManager (AylaShare)
/** @name AylaShare Methods */

/**
 * Creates a share in the cloud. You have to create an instance of `AylaShare`
 * first, with the designated initializer or
 * a helper method such as `[AylaDevice
 * aylaShareWithEmail:roleName:operation:startAt:endAt:]`
 *
 * @param share         The AylaShare instance to create in the cloud
 * @param emailTemplate The `AylaEmailTemplate` that will be used to send the
 * receiver an email informing them of the device
 * now being shared with them.
 * @param successBlock  A block to be called when the share has been
 * successfully created in the cloud. Passed the newly created
 * `AylaShare` object returned from the cloud.
 * @param failureBlock  A block to be called when the share could not be created
 * in the cloud. Passed an `NSError `describing the failure.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
  createShare:(AylaShare *)share
emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
      success:(void (^)(AylaShare *createdShare))successBlock
      failure:(void (^)(NSError *error))failureBlock;

/**
 * Creates a batch of `AylaShare` objects in the cloud with a single REST call.
 *
 * @param shares        An NSArray containing the `AylaShare` objects to create
 * in the cloud
 * @param emailTemplate The `AylaEmailTemplate` that will be used to send the
 * receiver(s) emails informing them of the device(s)
 * now being shared with them.
 * @param successBlock  A block to be called when the shares have been
 * successfully created in the cloud. Passed an `NSArray`
 * containing the newly created `AylaShare` objects returned from the cloud.
 * @param failureBlock  A block to be called when the shares could not be
 * created in the cloud. Passed an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
 createShares:(NSArray AYLA_GENERIC(AylaShare *) *)shares
emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
      success:(void (^)(NSArray AYLA_GENERIC(AylaShare *) *
                        createdShares))successBlock
      failure:(void (^)(NSError *error))failureBlock;
/**
 * Fetches the `AylaShare` objects for shared, owned resources.
 *
 * @param resourceName The resource type name, E.g.
 * `AylaShareResourceNameDevice`
 * @param resourceId   The ID of the resource to share (e.g 'dsn' for
 * `AylaDevice`)
 * @param expired      Indicates whether to fetch expired or valid shares as
 * well.
 * @param accepted     Indicates whete to fetch accepted or unaccepted shares
 * @param successBlock  A block to be called when the shares have been
 * successfully fetched from the cloud. Passed an `NSArray`
 * containing the fetched AylaShare objects returned from the cloud.
 * @param failureBlock  A block to be called when the shares could not be
 * fetched. Passed an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
fetchOwnedSharesWithResourceName:(NSString *)resourceName
                      resourceId:(nullable NSString *)resourceId
                         expired:(BOOL)expired
                        accepted:(BOOL)accepted
                         success:
                             (void (^)(NSArray<AylaShare *> *_Nonnull shares))
                                 successBlock
                         failure:
                             (void (^)(NSError *_Nonnull error))failureBlock;

/**
 * Fetches received `AylaShare` objects from the cloud.
 *
 * @param resourceName The resource type name, E.g.
 * `AylaShareResourceNameDevice`
 * @param resourceId   The ID of the resource to share (e.g 'dsn' for
 * `AylaDevice`)
 * @param expired      Indicates whether to fetch expired or valid shares as
 * well.
 * @param accepted     Indicates whete to fetch accepted or unaccepted shares
 * @param successBlock  A block to be called when the shares have been
 * successfully fetched from the cloud. Passed an `NSArray`
 * containing the fetched `AylaShare` objects returned from the cloud.
 * @param failureBlock  A block to be called when the shares could not be
 * fetched. Passed an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
fetchReceivedSharesWithResourceName:(NSString *)resourceName
                         resourceId:(nullable NSString *)resourceId
                            expired:(BOOL)expired
                           accepted:(BOOL)accepted
                            success:(void (^)(NSArray<AylaShare *>
                                                  *_Nonnull shares))successBlock
                            failure:
                                (void (^)(NSError *_Nonnull error))failureBlock;

/**
 * Fetches the `AylaShare` object with the specified `shareId` from the cloud
 *
 * @param shareId      The ID of the share to fetch.
 * @param successBlock  A block to be called when the shares have been
 * successfully fetched from the cloud. Passed the fetched `AylaShare `
 * object returned from the cloud.
 * @param failureBlock  A block to be called when the shares could not be
 * fetched. Passed an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
fetchShareWithId:(NSString *)shareId
         success:(void (^)(AylaShare *_Nonnull share))successBlock
         failure:(void (^)(NSError *_Nonnull error))failureBlock;

/**
 * Updates an existing `AylaShare` in the cloud.
 *
 * @param share         The locally modified `AylaShare` object to be updated in
 * the cloud
 * @param emailTemplate The `AylaEmailTemplate` to be used when formatting
 * emails sent to the receiver
 * @param successBlock  A block to be called when the shares have been
 * successfully updated on the cloud. Passed the updated `AylaShare`
 * object returned from the cloud.
 * @param failureBlock  A block to be called when the shares could not be
 * updated. Passed an `NSError` describing the failure.
 *
 * @return An AylaHTTPTask representing the request.
 */
- (nullable AylaHTTPTask *)
  updateShare:(AylaShare *)share
emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
      success:(void (^)(AylaShare *updatedShare))successBlock
      failure:(void (^)(NSError *error))failureBlock;

/**
 * Deletes an `AylaShare` from the cloud
 *
 * @param share         The `AylaShare` object to delete from the cloud
 * @param successBlock  A block to be called when the shares have been
 * successfully deleted from the cloud.
 * @param failureBlock  A block to be called when the shares could not be
 * deleted. Passed an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)deleteShare:(AylaShare *)share
                               success:(void (^)())successBlock
                               failure:(void (^)(NSError *error))failureBlock;
@end

@interface AylaSessionManager (UserDatum)
/** @name AylaDatum / User Daturm Methods */

/**
 * Creates a new `AylaDatum` object for the currently authenticated user.
 *
 * @param key          The key used to uniquely identify the datum.
 * @param value        The initial value for the datum.
 * @param successBlock A block to be called if the request is successful. Passed
 * the newly created `AylaDatum` object returned
 * from the cloud.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
createAylaDatumWithKey:(NSString *)key
                 value:(NSString *)value
               success:(void (^)(AylaDatum *createdDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock;

/**
 * Retrieves an existing `AylaDatum` object for the currently authenticated user
 * based on the input key.
 *
 * @param key The key of the `AylaDatum` object to retrieve.
 * @param successBlock A block which will be called with the retrieved datum
 * when the request is successful.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAylaDatumWithKey:(NSString *)key
              success:(void (^)(AylaDatum *datum))successBlock
              failure:(void (^)(NSError *error))failureBlock;

/**
 * Retrieves existing `AylaDatum` objects for the currently authenticated user
 * based on the input keys.
 *
 * @param keys         An `NSArray` containing the keys of the `AylaDatum`
 * objects to retrieve. If nil, retrieves all existing datum objects.
 * @param successBlock A block to be called if the request is successful. Passed
 * an `NSArray` containing the fetched `AylaDatum` objects
 * returned from the cloud, if any.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAylaDatumsWithKeys:(nullable NSArray AYLA_GENERIC(NSString *) *)keys
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock;

/**
 * Retrieves existing `AylaDatum` objects for the currently authenticated user
 * based on a wildcard match.
 *
 * @param wildcardedString A string where the "%" character defines wild cards
 * before or after the text to match in the datum key
 * @param successBlock A block to be called if the request is successful. Passed
 * an `NSArray` containing the fetched `AylaDatum` objects
 * returned from the cloud, if any.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAylaDatumsMatching:(NSString *)wildcardedString
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock;

/**
 * Retrieves all existing `AylaDatum` objects for the currently authenticated
 * user.
 *
 * @param successBlock  A block to be called if the request is successful.
 * Passed an `NSArray` containing the fetched AylaDatum objects
 * returned from the cloud, if any.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAllAylaDatumsWithSuccess:
    (void (^)(NSArray AYLA_GENERIC(AylaDatum *) * datums))successBlock
                      failure:(void (^)(NSError *error))failureBlock;

/**
 * Updates an existing `AylaDatum` object for the currently authenticated user
 * using on its key and a new value that it
 * should be assigned.
 *
 * @param key           The key of the datum to be updated.
 * @param value         The new value to assign to the datum.
 * @param successBlock  A block to be called if the request is successful.
 * Passed the updated `AylaDatum` object returned from the cloud.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
updateAylaDatumWithKey:(NSString *)key
               toValue:(NSString *)value
               success:(void (^)(AylaDatum *updatedDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock;

/**
 * Removes an existing `AylaDatum` object for the currently authenticated user
 * based on its key.
 *
 * @param key           The key of the datum to be removed.
 * @param successBlock  A block to be called if the request is successful.
 * @param failureBlock  A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)deleteAylaDatumWithKey:(NSString *)key
                                          success:(void (^)())successBlock
                                          failure:(void (^)(NSError *error))
                                                      failureBlock;

@end

NS_ASSUME_NONNULL_END
