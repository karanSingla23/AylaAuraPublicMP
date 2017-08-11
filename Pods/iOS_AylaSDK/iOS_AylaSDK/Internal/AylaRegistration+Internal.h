//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaRegistration.h"

NS_ASSUME_NONNULL_BEGIN
@interface AylaRegistration (Internal)
/**
 Fetches the registration token from the candidate.

 @param candidate    The `AylaRegistrationCandidate` to be asked for its registration token
 @param successBlock A block called when the token is successfully fetched.
 @param failureBlock A block called when the token fetching fails.

 @return A started `AylaHTTPTask` to fetch the token.
 */
- (nullable AylaHTTPTask *)fetchRegistrationTokenForCandidate:(AylaRegistrationCandidate *)candidate
                                                      success:(void (^)(NSString *))successBlock
                                                      failure:(void (^)(NSError *))failureBlock;
/**
 Returns the name of the class for tagging log output

 @return The name of the class
 */
- (NSString *)logTag;

/**
 Returns the HTTP client for the instance.

 @param error *Optional*. Lets caller pass a pointer to a NSError to receive the error in case of failure.

 @return An instance of AylaHTTPClient of the `AylaHTTPClientTypeDeviceService` or nil if the client could not be
 created.
 */
- (nullable AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error;

/**
 Fetches registration candidate with the specified dsn, or any if you pass nil for the targetDsn, this method is used
 when registering a device with `AylaRegistrationTypeSameLan` or `AylaRegistrationTypeButtonPush`.

 @param targetDsn              The DSN of the target candidate or nil if any candidate should be fetched.
 @param registrationType        The `AylaRegistrationType` of the target to be fetched or `AylaRegistrationTypeAny` to
 fetch candidates with any registration type.
 @param successBlock           A block called when a candidate matching the criteria has been fetched
 @param candidate            The fetched candidate.
 @param failureBlock           A block called when the candidate fetching fails.
 @param error                The error that occurred during the fetch

 @return A started `AylaHTTPTask`
 */
- (nullable AylaHTTPTask *)fetchCandidatesWithDSN:(nullable NSString *)targetDsn
                                 registrationType:(AylaRegistrationType)registrationType
                                          success:(void (^)(NSArray AYLA_GENERIC(AylaRegistrationCandidate *) *
                                                            candidates))successBlock
                                          failure:(void (^)(NSError *error))failureBlock;
@end
NS_ASSUME_NONNULL_END