//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDatapointParams.h"
#import "AylaObject.h"
#import "AylaPropertyTrigger.h"
#import "AylaPropertyChange.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Defines base types for properties
 */
FOUNDATION_EXPORT NSString *const AylaPropertyBaseTypeInteger;
FOUNDATION_EXPORT NSString *const AylaPropertyBaseTypeString;
FOUNDATION_EXPORT NSString *const AylaPropertyBaseTypeBoolean;
FOUNDATION_EXPORT NSString *const AylaPropertyBaseTypeDecimal;
FOUNDATION_EXPORT NSString *const AylaPropertyBaseTypeFloat;
FOUNDATION_EXPORT NSString *const AylaPropertyBaseTypeFile;

@class AylaConnectTask;
@class AylaDatapoint;
@class AylaDevice;
@class AylaHTTPTask;

@interface AylaProperty : AylaObject
/** @name AylaProperty Properties */

/** A reference to the device that owns the property */
@property (nonatomic, weak, readonly) AylaDevice *device;

/** Property Name */
@property (nonatomic, strong, readonly) NSString *name;

/** The property's base type (AylaPropertyBaseTypeString, etc) */
@property (nonatomic, strong, readonly) NSString *baseType;

/** Property Type */
@property (nonatomic, strong, readonly) NSString *type;

/** Direction. That is from device ("output") or to device ("input") */
@property (nonatomic, strong, readonly) NSString *direction;

/** The name for the property that will be displayed to app's user.*/
@property (nonatomic, strong, readonly) NSString *displayName;

/** Last updated data timestamp */
@property (nonatomic, strong, readonly, nullable) NSDate *dataUpdatedAt;

/** If Datapoint Ack has been enabled for current property  */
@property (nonatomic, assign, readonly) BOOL ackEnabled;

/** Timestamp indicating when datapoint ack was received. */
@property (nonatomic, strong, readonly, nullable) NSDate *ackedAt;

/** Datapoint ack status */
@property (nonatomic, assign, readonly) NSInteger ackStatus;

/** Datapoint ack message */
@property (nonatomic, assign, readonly) NSInteger ackMessage;

/** The most recent datapoint */
@property (nonatomic, readonly) AylaDatapoint *datapoint;

/** The AylaDataSource representing the service used to last update this property's status. */
@property (nonatomic, assign, readonly) AylaDataSource lastUpdateSource;

/** Passthrough property to the value in the most recent datapoint */
@property (copy, readonly, nullable) id value;

/** Passthrough property to the metadata in the most recent datapoint */
@property (nonatomic, copy, readonly) NSDictionary *metadata;

/** @name Datapoint Methods */

/**
 * Creates an `AylaDatapoint` for this property with the supplied data. If the device has an active LAN session, the request
 * will be sent via the LAN. Otherwise it will be sent via cloud.
 *
 * @param datapointParams Parameters of the datapoint to be created.
 * @param successBlock A block to be called if the request is successful. Passed the created `AylaDataPoint` object.
 * @param failureBlock A block to be called if the request fails. Passed an `NSError` object describing the failure.
 */
- (nullable AylaConnectTask *)createDatapoint:(AylaDatapointParams *)datapointParams
                                      success:(void (^)(AylaDatapoint * createdDatapoint))successBlock
                                      failure:(void (^)(NSError *error))failureBlock;

/**
 * Creates a datapoint for this property through the cloud, usin the supplied datapoint parameters.
 *
 * @param datapointParams Parameters of datapoint to be created.
 * @param successBlock A block to be called if the request is successful. Passed the created `AylaDataPoint` object.
 * @param failureBlock A block to be called if the request fails. Passed an `NSError` object describing the failure.
 */
- (nullable AylaConnectTask *)createDatapointCloud:(AylaDatapointParams *)datapointParams
                                           success:(void (^)(AylaDatapoint * createdDatapoint))successBlock
                                           failure:(void (^)(NSError *error))failureBlock;

/**
 * Creates an `AylaDatapoint` for this property through a LAN session, using the supplied datapoint parameters.
 *
 * @param datapointParams Parameters of the datapoint to be created.
 * @param successBlock A block to be called if the datapoint creation is successful. Passed the created `AylaDataPoint` object.
 * @param failureBlock A block to be called if the datapoint creation fails. Passed an `NSError` object describing the failure.
 */
- (nullable AylaConnectTask *)createDatapointLAN:(AylaDatapointParams *)datapointParams
                                         success:(void (^)(AylaDatapoint *createdDatapint))successBlock
                                         failure:(void (^)(NSError *error))failureBlock;
/**
 * Fetches an `AylaDatapoint` with the specified ID
 *
 * @param datapointId  The ID of the existing `AylaDatapoint` to fetch
 * @param successBlock A block to be called if the datapoint creation is successful. Passed the created `AylaDataPoint` object.
 * @param failureBlock A block to be called if the datapoint creation fails. Passed an `NSError` object describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)fetchDatapointWithId:(NSString *)datapointId
                               success:(void (^)(AylaDatapoint * fetchedDatapoint))successBlock
                               failure:(void (^)(NSError *error))failureBlock;

/**
 Fetches a collection of datapoints for this property from the server.

 @param count Number of datapoints to fetch. If zero, will fetch the maximum number of datapoints allowed in a single API call (MAX_DATAPOINT_COUNT).
 @param from Date of earliest datapoint to fetch. May be nil.
 @param to Date of the latest datapoint to fetch. May be null.
 @param successBlock A block to be called if the datapoint have been fetched. Passes the received `AylaDataPoint` array.
 @param failureBlock A block to be called if the datapoint fetch fails. Passed an `NSError` object describing the failure.
 
 @return A started `AylaHTTPTask` representing the request.
 */
- (AylaHTTPTask *)fetchDatapointsWithCount:(NSInteger)count
                                      from:(nullable NSDate *)from
                                        to:(nullable NSDate *)to
                                   success:(nullable void (^)(NSArray<AylaDatapoint *>*fetchedDatapoint))successBlock
                                   failure:(nullable void (^)(NSError *error))failureBlock;

/** @name Property Trigger Methods */
/**
 * Creates an `AylaPropertyTrigger` in the cloud from the data in the trigger parameter.
 *
 * @param trigger      The `AylaPropertyTrigger` to be created in the cloud.
 * @param successBlock A block to be called if the trigger creation is successful. Passed the created `AylaPropertyTrigger` object.
 * @param failureBlock A block to be called if the trigger creation fails. Passed an `NSError` object describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the call.
 */
- (nullable AylaHTTPTask *)createTrigger:(AylaPropertyTrigger *)trigger
                                 success:(void (^)(AylaPropertyTrigger *createdTrigger))successBlock
                                 failure:(void (^)(NSError *err))failureBlock;
/**
 * Fetches any existing `AylaPropertyTrigger` objects from the cloud.
 *
 * @param successBlock A block to be called if the triggers are successfully fetched. Passed a non-nil `NSArray` containing the (zero or more) fetched `AylaPropertyTrigger` objects.
 * @param failureBlock A block to be called if the fetch operation fails. Passed an `NSError` object describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)fetchTriggersWithSuccess:
                               (void (^)(NSArray AYLA_GENERIC(AylaPropertyTrigger *) * triggers))successBlock
                                            failure:(void (^)(NSError *error))failureBlock;

/**
 * Deletes an existing `AylaPropertyTrigger` from the cloud.
 *
 * @param trigger      An `AylaPropertyTrigger` that was previously fetched from the cloud, which will be deleted.
 * @param successBlock A block to be called if the trigger is successfully deleted.
 * @param failureBlock A block to be called if the trigger deletion fails. Passed an `NSError` object describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)deleteTrigger:(AylaPropertyTrigger *)trigger
                                 success:(void (^)())successBlock
                                 failure:(void (^)(NSError *_Nonnull))failureBlock;

/**
 * Updates an existing `AylaPropertyTrigger` in the cloud.
 *
 * @param trigger      The trigger previously fetched from the cloud and modified, that is now to be updated.
 * @param successBlock A block to be called if the trigger is updated successfully. Passed updated `AylaPropertyTrigger` object.
 * @param failureBlock A block to be called if the update operation fails. Passed an `NSError` object describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)updateTrigger:(AylaPropertyTrigger *)trigger
                                 success:(void (^)(AylaPropertyTrigger *updatedTrigger))successBlock
                                 failure:(void (^)(NSError *_Nonnull))failureBlock;


/**
 * Updates the property state from another property
 *
 * @param property The property to update from
 * @param dataSource The source of the update
 * @return The changes performed to the receiver
 */
- (AylaPropertyChange *)updateFrom:(AylaProperty *)property dataSource:(AylaDataSource)dataSource;
@end

@interface AylaProperty (NSCoding) <NSCoding>
@end

NS_ASSUME_NONNULL_END
