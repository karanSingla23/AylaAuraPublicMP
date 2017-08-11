//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
@class AylaDatapoint;
/**
 * Describes the response to a `AylaDatapointBatchRequest`. When requesting a batched datapoint creation with
 * `[AylaDeviceManager createDatapointBatch:success:failure:]` an array of `AylaDatapointBatchResponse` objects will be returned
 * in the success block.
 */
@interface AylaDatapointBatchResponse : AylaObject

/** The HTTP Status code of the datapoint creation request */
@property (nonatomic, strong, readonly) NSNumber *statusCode;

/** The DSN of the device */
@property (nonatomic, strong, readonly) NSString *deviceDsn;

/** Name of the property */
@property (nonatomic, strong, readonly) NSString *propertyName;

/** The requested datapoint */
@property (nonatomic, strong, readonly) AylaDatapoint *datapoint;
@end
NS_ASSUME_NONNULL_END