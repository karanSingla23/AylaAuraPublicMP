//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"
#import "AylaDeviceDetailProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDatapointBatchRequest;
@class AylaDatapointBatchResponse;
@class AylaDevice;
@class AylaDeviceListChange;
@class AylaDeviceManager;
@class AylaHTTPTask;
@class AylaListenerArray;
@class AylaRegistration;
@class AylaSessionManager;

/**
 * Available states of `AylaDeviceManager`.
 */
typedef NS_ENUM(uint16_t, AylaDeviceManagerState) {
    /** Initial state of the DeviceManager */
    AylaDeviceManagerStateUninitialized,
    
    /** Fetching the list of devices from the cloud service */
    AylaDeviceManagerStateFetchingDeviceList,
    
    /** Fetching the current list of property values */
    AylaDeviceManagerStateFetchingDeviceProperties,
    
    /** Initialization complete */
    AylaDeviceManagerStateReady,
    
    /** Unable to initialize, usually due to the inability */
    AylaDeviceManagerStateError,
    
    /** Paused by application. */
    AylaDeviceManagerStatePaused,
    
    /** Shut down by application/SDK. */
    AylaDeviceManagerStateShutDown
};

/** A protocol to enable being informed of changes in the objects managed by an `AylaDeviceManager` instance. */
@protocol AylaDeviceManagerListener<NSObject>

/**
 * Called when the `AylaDeviceManager` has completed initialization. When this method is called,
 * the device manager has the complete set of devices and their properties available.
 *
 * @param deviceManager  The current `AylaDeviceManager` instance
 * @param deviceFailures A map of the DSNs of devices that failed to be initialized to the
 *                      specific error that caused initialization failure. If a
 *                      device's properties were not available, or details could not be
 *                      fetched about a particular device, the DSN of that device will be
 *                      included in the `deviceFailures` map.
 *
 *                      If all devices could be initialized, the `deviceFailures` map will
 *                      be empty.
 */
- (void)deviceManager:(AylaDeviceManager *)deviceManager
      didInitComplete:(NSDictionary AYLA_GENERIC(NSString *, NSError *) *)deviceFailures;

/**
 * Called when `AylaDeviceManager` could not complete initialization. This usually occurs
 * when the DeviceManager is unable to fetch the list of devices from the cloud and does
 * not have the device list cached.
 *
 * `AylaDeviceManager` will be in the Error state when this notification is received. The
 * state `AylaDeviceManager` was in when the failure occurred will be passed via the
 * `-failureState` argument to this method.
 *
 * @param deviceManager  The `AylaDeviceManager` instance that failed to init completely
 * @param error `NSError` that occurred
 */
- (void)deviceManager:(AylaDeviceManager *)deviceManager didInitFailure:(NSError *)error;

/**
 * Called whenever the list of devices in `AylaDeviceManager` has changed. The change object can be queried to
 * find the devices that were added or removed from the device list.
 *
 * @param deviceManager  The `AylaDeviceManager` instance that saw a change
 * @param change The {@link DeviceListChange} object containing
 *              information about the devices that were added or removed.
 */
- (void)deviceManager:(AylaDeviceManager *)deviceManager didObserveDeviceListChange:(AylaDeviceListChange *)change;

/**
 *  Called whenever the DeviceManager changes state.
 *
 *  @param deviceManager The deviceManager instance whose status has changed
 *  @param oldState      State the DeviceManager was in before the change
 *  @param newState      Current state of the DeviceManager
 */
- (void)deviceManager:(AylaDeviceManager *)deviceManager
    deviceManagerStateChanged:(AylaDeviceManagerState)oldState
                     newState:(AylaDeviceManagerState)newState;
@end

/** `AylaDeviceManager` is the primary organizer of device data.
 *
 * An application should always query the session's `AylaDeviceManager` instance for devices and their associated properties.
 * `AylaDeviceManager` will maintain a list of devices that have either been registered by the
 * user or shared to the user (via the device's `AylaGrant`).
 */
@interface AylaDeviceManager : NSObject
/** @name Device Manager Properties */
/** `NSDictionary` containing all available `AylaDevice`s */
@property (nonatomic, strong, readonly, getter=devices) NSDictionary *devices;

/** Specific `AylaDeviceDetailProvider` used in the current `AylaDeviceManager` instance */
@property (nonatomic, strong, readonly) id<AylaDeviceDetailProvider> deviceDetailProvider;

/** The notification queue to be used for posting notifications. Main queue will be used if this is not set by
 * the application */
@property (nonatomic, assign, null_resettable) dispatch_queue_t notificationQueue;

/** Reference to the `AylaSessionManager` instance that owns this `AylaDeviceManager` instance */
@property (nonatomic, weak, readonly) AylaSessionManager *sessionManager;

/** Object for handling device registration tasks */
@property (nonatomic, readonly) AylaRegistration *registration;

/** YES if we are polling the service for device list changes */
@property (nonatomic, readonly, getter=isPolling) BOOL isPolling;

/**
 * `AylaDeviceManagerState` of the current `AylaDeviceManager` instance. 
 *
 * On startup, `AylaDeviceManager` goes through several states to
 * fetch the list of devices and their properties. When all devices have been updated, the
 * state moves to `AylaDeviceManagerStateReady` and any `AylaDeviceManagerListener`s are notified that initialization is complete.
 */
@property (nonatomic, readonly) AylaDeviceManagerState state;

/**
 * Set to YES once we have gone through the initialization process once. This is useful for
 * when we have to run through the init phases again, like when devices are added or we come
 * back from the background, and need to know if we have fetched a good device list or not.
 */
@property (nonatomic, readonly, getter=hasInitialized) BOOL hasInitialized;

/**
 * Indicates whether the current device list has been read from Cache, and might be stale.
 */
@property (nonatomic, readonly, getter=isCachedDeviceList) BOOL cachedDeviceList;

/** @name Listener Methods */

/** Add a listener which conforms to the `AylaDeviceManagerListener` protocol 
 * 
 * @param listener The `AylaDeviceManagerListener` protocol conforming object to be added.
 */
- (void)addListener:(id<AylaDeviceManagerListener>)listener;

/** Remove a listener which conforms to the `AylaDeviceManagerListener` protocol
 *
 * @param listener The `AylaDeviceManagerListener` protocol conforming object to be removed as a listener.
 */
- (void)removeListener:(id<AylaDeviceManagerListener>)listener;

/** @name Fetch Device Method */

/**
 * Use this method to let DeviceManager sync the device list with Cloud service
 *
 * @param successBlock   A block to be called if the request is successful.
 * @param failureBlock   A block to be called if the request fails. Passed an `NSError` describing the failure.
 *
 * @return A AylaHTTPTask object which represents this request.
 */
- (nullable AylaHTTPTask *)fetchDevices:(void (^)(NSArray AYLA_GENERIC(AylaDevice *) * devices))successBlock
                                failure:(void (^)(NSError *error))failureBlock;

/** @name Life Cycle Methods */

/**
 * Use this method to pause current `AylaDeviceManager`.
 */
- (void)pause;

/**
 * Use this method to resume current `AylaDeviceManager`.
 */
- (void)resume;

/** @name Polling Methods */

/**
 * Starts polling operations. This includes polling of the device service for updates to the
 * device list as well as polling each device's properties for changes.
 */
- (void)startPolling;

/**
 * Stops polling operations. Any devices that are polling will be stopped, and the
 * DeviceManager will stop polling for device list changes.
 */
- (void)stopPolling;


//-----------------------------------------------------------
#pragma mark - Datapoint Batches
//-----------------------------------------------------------
/** @name Batch Datapoint Methods */
/**
 * Creates a batch of datapoints from the specified `NSArray` of `AylaDatapointBatchRequest` with a single service call.
 *
 * @param datapointBatch  An `NSArray` of `AylaDatapointBatchRequest` objects with the datapoints to create.
 * @param successBlock    A block called when the datapoint batch was successfully created.
 * @param failureBlock    A block called when the batch failed to be created. Passed an `NSError` describing the failure.
 *
 * @return A started  `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)createDatapointBatch:(NSArray AYLA_GENERIC(AylaDatapointBatchRequest *) *)datapointBatch
                                        success:(void (^)(NSArray AYLA_GENERIC(AylaDatapointBatchResponse *) *
                                                          datapoints))successBlock
                                        failure:(void (^)(NSError *error))failureBlock;

/** Method Unavailable, Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Adds devices to the device manager. This should only be called internally after a device
 * has been registered to the account.
 *
 * @param devices Devices that were just registered
 */
- (void)addDevices:(NSArray *)devices;

/**
 * Internal method called when a device is unregistered. Listeners will be notified that the
 * device list has changed.
 * @param devices Devices that were unregistered
 */
- (void)removeDevices:(NSArray *)devices;
@end

@class AylaAlertFilter;
@class AylaAlertHistory;
@interface AylaDeviceManager (AlertHistory)

/**
 * Fetches list of alerts sent to the user for this device.
 *
 * @param dsn          DSN of the device for which the alert history is to be fetched. The device must be currently registered to this user.
 * @param paginated    YES if paginated. NO otherwise.
 * @param perPage      Number of entries per page. This will be ignored if paginated is false.
 * @param pageNumber   Page number to request. This will be ignored if paginated is false.
 * @param filter       Filter to apply to the result. (Optional). An `AylaAlertFilter` object passed to this request will apply the filter set in the object to the result from this method.
 * @param successBlock A block called when the alert history was successfully fetched.
 * @param failureBlock A block called when the alert history failed to be fetched. Passes an `NSError` describing the failure.
 *
 * @return A started  `AylaHTTPTask` representing the request.
 */
- (AylaHTTPTask *)fetchAlertHistoryWithDSN:(NSString *)dsn paginated:(BOOL)paginated number:(NSInteger)perPage page:(NSInteger)pageNumber alertFilter:(nullable AylaAlertFilter *)filter success:(void (^)(NSArray AYLA_GENERIC(AylaAlertHistory *) * alertHistory))successBlock
                                   failure:(void (^)(NSError *error))failureBlock;

/**
 * Fetches list of alerts sent to the user for this device.
 *
 * @param dsn          DSN of the device for which the alert history is to be fetched. The device must be currently registered to this user.
 * @param paginated    YES if paginated. NO otherwise.
 * @param perPage      Number of entries per page. This will be ignored if paginated is false.
 * @param pageNumber   Page number to request. This will be ignored if paginated is false.
 * @param filter       Filter to apply to the result. (Optional). An `AylaAlertFilter` object passed to this request will apply the filter set in the object to the result from this method.
 * @param sortParams Dictionary with key-value pairs specifying sorting orders for results returned from the API. For default order, use null value for this parameter. To sort by a field, use key "order_by" and value as field name. eg: To get results in descending order of sent_at field, use map "order_by": "sent_at", "order": "desc" And to get results in ascending order of sent_at field, use map "order_by": "sent_at", "order": "asc".
 * @param successBlock A block called when the alert history was successfully fetched.
 * @param failureBlock A block called when the alert history failed to be fetched. Passes an `NSError` describing the failure.
 *
 * @return A started  `AylaHTTPTask` representing the request.
 */
- (AylaHTTPTask *)fetchAlertHistoryWithDSN:(NSString *)dsn paginated:(BOOL)paginated number:(NSInteger)perPage page:(NSInteger)pageNumber alertFilter:(nullable AylaAlertFilter *)filter sortParams:(nullable NSDictionary *)sortParams success:(void (^)(NSArray AYLA_GENERIC(AylaAlertHistory *) * alertHistory))successBlock
                                   failure:(void (^)(NSError *error))failureBlock;
@end

NS_ASSUME_NONNULL_END
