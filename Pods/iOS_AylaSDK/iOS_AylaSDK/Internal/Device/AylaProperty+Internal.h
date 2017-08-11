//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaProperty.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDatapoint;
@class AylaHTTPClient;
@class AylaLanCommand;
@class AylaPropertyChange;

@protocol AylaPropertyInternalDelegate<NSObject>

/**
 * Notify delagate that a datapoint is created to current property.
 */
- (void)property:(AylaProperty *)property
    didCreateDatapoint:(AylaDatapoint *)datapoint
        propertyChange:(AylaPropertyChange *)propertyChange;

/**
 * Compose a lan command for a datapoint to the given property.
 *
 * @param property        The property datapoint will be created to.
 * @param datapointParams Datapoint params of to-be-created datapoint.
 *
 * @return The composed lan command.
 */
- (AylaLanCommand *)property:(AylaProperty *)property
 lanCommandToCreateDatapoint:(AylaDatapointParams *)datapointParams;

/**
 * Let delegate to pass in a processing queue which property updates should be run on. This will be only called
 * once for each property.
 *
 * @note A serial queue is highly recommanded here since there is no other sychronous mechanisms in property.
 */
- (dispatch_queue_t)processingQueueForProperty:(AylaProperty *)property;

@end

@class AylaPropertyChange;
@interface AylaProperty (Internal)

@property (nonatomic, weak, readwrite) AylaDevice *device;
@property (nonatomic, weak, readwrite) id<AylaPropertyInternalDelegate> delegate;
@end

@interface AylaProperty ()
/**
 * Use this method to update a property with a copy from cloud.
 *
 * @param property The copy current property updates from.
 *
 * @return A AylaPropertyChange object to indicate if changes have been observed in this property.
 */
- (nullable AylaPropertyChange *)updateFrom:(AylaProperty *)property dataSource:(AylaDataSource)dataSource;

/**
 * Use this method to update a property from a datapoint
 *
 * @param datapoint A datapoint current property updates from.
 *
 * @return A AylaPropertyChange object to indicate if changes have been observed in this property.
 */
- (nullable AylaPropertyChange *)updateFromDatapoint:(AylaDatapoint *)datapoint;

/**
 * Calls `updateFromDatapoint` and then `property:didCreateDatapoint:propertyChange` in the `processingQueue`
 *
 * @param datapoint    The datapoint to use to update and notify
 * @param successBlock The block to execute after the tasks have been performed
 */
- (void)updateAndNotifyDelegateFromDatapoint:(AylaDatapoint *)datapoint successBlock:(void (^)())successBlock;

/**
 *  Returns the Cloud HTTP Client
 *
 *  @param error A pointer to an `NSError` variable to store an error in case of failure
 *
 *  @return The Cloud HTTP client.
 */
- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error;


/**
 Enables network profiling.
 */
+ (void)enableNetworkProfiler;
@end

NS_ASSUME_NONNULL_END
