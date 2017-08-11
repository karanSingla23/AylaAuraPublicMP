//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDeviceNode;
@class AylaRegistrationCandidate;

/**
 * A specific type of `AylaDevice` that acts as a gateway to register and connect other non-network enabled `AylaDeviceNode` devices to 
 * the Ayla Service
 */
@interface AylaDeviceGateway : AylaDevice
/** @name Gateway Properties */

/** The list of nodes registered to this gateway */
@property (nonatomic, readonly, getter=nodes, nullable) NSArray *nodes;

/**
 * Use this method to get an `AylaDeviceNode` based on the node's DSN
 *
 * @param dsn The DSN of the requested `AylaDeviceNode`.
 *
 * @return The node that matches the given DSN. Will return nil if node cannot be found.
 */
- (nullable AylaDeviceNode *)getNodeWithDsn:(NSString *)dsn;

/** @name Node Methods */

/**
 * Opens the registration join window on the gateway for the specified period of time. This method does not return any
 * data.
 *
 * @param durationInSeconds  Duration the gateway should keep its join window open.
 * @param successBlock       A block to be called if the request is successful.
 * @param failureBlock       A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` which represents this request.
 */
- (nullable AylaConnectTask *)openRegistrationJoinWindow:(NSUInteger)durationInSeconds
                                                 success:(void (^)(void))successBlock
                                                 failure:(void (^)(NSError *_Nonnull error))failureBlock;
/** @name Node Registration Methods */

/**
 * Closes the registration join window on the gateway.
 *
 * @param successBlock       A block to be called if the request is successful.
 * @param failureBlock      A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` which represents this request.
 */
- (nullable AylaConnectTask *)closeRegistrationJoinWindow:(void (^)(void))successBlock
                                                  failure:(void (^)(NSError *error))failureBlock;

/**
 * Retrieves a list of the gateway's registrable candidate nodes from the Service.
 *
 * @param successBlock      A block to be called if the request is successful. Passed an `NSArray` of `AylaRegistrationCandidate` 
 * objects returned from the cloud.
 * @param failureBlock      A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` which represents this request.
 */
- (nullable AylaHTTPTask *)fetchCandidatesWithSuccess:
                               (void (^)(NSArray AYLA_GENERIC(AylaRegistrationCandidate *) * candidates))successBlock
                                              failure:(void (^)(NSError *error))failureBlock;
@end

NS_ASSUME_NONNULL_END
