//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

@class AylaSessionManager;
@class AylaHTTPClient;
@class AylaHTTPTask;
@class AylaRegistrationCandidate;
@class AylaDevice;

#import <Foundation/Foundation.h>
#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN
/**
 Performs tasks necessary to register an `AylaDevice`.

 To register a device you need to follow these steps:
 
 1. Prepare its `AylaRegistrationCandidate`.
    There are several kinds of `AylaRegistrationType` .
    - For `AylaRegistrationTypeSameLan` or `AylaRegistrationTypeButtonPush`, use `[AylaRegistration fetchCandidateWithDSN:registrationType:success:failure:]` to fetch a candidate from the cloud before registering it.
    - For `AylaRegistrationTypeNode`, first fetch candidates from a registered `AylaDeviceGateway` using `[AylaDeviceGateway fetchCandidatesWithSuccess:failure:]`.
    - For `AylaRegistrationTypeDisplay`, instantiate an `AylaRegistrationCandidate` and assign its `AylaRegistrationCandidate.registrationType` and `AylaRegistrationCandidate.registrationToken` properties.
    - For `AylaRegistrationTypeDsn`, instantiate an `AylaRegistrationCandidate` and assign its `AylaRegistrationCandidate.dsn` property.
 2. Pass the received candidate to `registerCandidate:success:failure:` to complete the process.

 */
@interface AylaRegistration : NSObject
/**
 * Returns the corresponding `NSString` for a `AylaRegistrationType`
 *
 * @param registrationType The type to convert to string
 *
 * @return The corresponding string
 */
+ (nullable NSString *)registrationNameFromType:(AylaRegistrationType)registrationType;

/**
 * Returns an `AylaRegistrationType` for the given string
 *
 * @param registrationTypeName The "name" of the registration type
 *
 * @return The `AylaRegistrationType` corresponding to the string.
 */
+ (AylaRegistrationType)registrationTypeFromName:(NSString *)registrationTypeName;

/** @name Initializer Methods */

/**
 * Initializes an instance with the specified `AylaSessionManager`
 *
 * @param sessionManager The active `AylaSessionManager` used to initialize the instance. Must not be nil.
 *
 * @return An initialized `AylaRegistration` instance.
 */
- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager;


/** @name Candidate Registration Methods*/

/**
 * Fetches a registration candidate with the specified dsn, or any if you pass nil for the targetDsn, this method is used
 * when registering a device with `AylaRegistrationTypeSameLan` or `AylaRegistrationTypeButtonPush`.
 *
 * @param targetDsn              The DSN of the target candidate or nil if any candidate should be fetched.
 * @param registrationType        The `AylaRegistrationType` of the target to be fetched or `AylaRegistrationTypeAny` to fetch candidates with any registration type.
 * @param successBlock           A block to be called if a candidate matching the criteria has been fetched. Passed the `AylaRegistrationCandidate` object received from the cloud.
 * @param failureBlock           A block to be called if the fetch operation fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */


- (nullable AylaHTTPTask *)fetchCandidateWithDSN:(nullable NSString *)targetDsn
                                registrationType:(AylaRegistrationType)registrationType
                                         success:(void (^)(AylaRegistrationCandidate *candidate))successBlock
                                         failure:(void (^)(NSError *error))failureBlock;
/**
 * Registers the specified `AylaRegistrationCandidate` to the account.
 *
 * @param candidate The `AylaRegistrationCandidate` to register, see the class documentation for information on how to
 * obtain the candidate.
 * @param successBlock A block to be called if the candidate has been registered successully. Passed the `AylaDevice` object for
 * the newly registered device, returned from the cloud.
 * @param failureBlock A block to be called when the candidate registration failed. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */
- (nullable AylaHTTPTask *)registerCandidate:(AylaRegistrationCandidate *)candidate
                                     success:(void (^)(AylaDevice *device))successBlock
                                     failure:(void (^)(NSError *error))failureBlock;

/** @name Registration Properties */

/**
 A reference to the `AylaSessionManager` associated with this instance
 */
@property (nonatomic, weak, readonly) AylaSessionManager *sessionManager;
@end

/**
 Enumerates the error codes that may be returned during registration
 */
typedef NS_ENUM(NSInteger, AylaRegistrationErrorCode) {
    /** Indicates a Precondition failure */
    AylaRegistrationErrorCodePreconditionFailure = 2002,

};

extern NSString *const AylaRegistrationErrorDomain;
extern NSString *const AylaRegistrationErrorResponseJsonKey;

NS_ASSUME_NONNULL_END
