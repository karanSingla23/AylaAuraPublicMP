//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
@class AylaProperty;
@class AylaDatapointParams;
/**
 * Describes a datapoint in a batched request to allow multiple datapoints to be created with a single Service API call.
 */
@interface AylaDatapointBatchRequest : AylaObject
/** @name Datapoint Batch Properties */

/**
 * The params of the datapoint to create.
 */
@property (nonatomic, strong, readonly) AylaDatapointParams *datapoint;
/**
 * The property that will receive the datapoint.
 */
@property (nonatomic, strong, readonly) AylaProperty *property ;


/** @name Initializer Methods*/

/**
 * Initializes a new instance of AylaDatapointBatchRequest.
 *
 * @param datapointParams The params of the datapoint to create.
 * @param property  The property that will receive the datapoint
 *
 * @return An initialized AylaDatapointBatchRequest to create in a batched request.
 */
- (instancetype)initWithDatapoint:(AylaDatapointParams *)datapointParams
                         property:(AylaProperty *)property NS_DESIGNATED_INITIALIZER;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
