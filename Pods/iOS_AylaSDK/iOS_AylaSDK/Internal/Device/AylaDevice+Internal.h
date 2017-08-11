//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"
#import "AylaLanModule.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDeviceManager;
@class AylaLanTask;
@class AylaDeviceConnection;
@interface AylaDevice ()<AylaLanSupportDevice>

@end
@interface AylaDevice (Internal)<AylaLanModuleInternalDelegate>

/** Cloud side device identifier */
@property (nonatomic, readonly, nullable) NSNumber *key;

/** Lan Module */
@property (nonatomic, readonly, nullable) AylaLanModule *lanModule;

/**
 * Init method with device manager and JSON dictionary
 *
 * @param deviceManager The device manager who owns this object.
 * @param dictionary    JSON dictionary which contains info of current device.
 *
 * @return Initialized device object.
 */
- (instancetype)initWithDeviceManager:(AylaDeviceManager *)deviceManager
                       JSONDictionary:(NSDictionary *)dictionary
                                error:(NSError *__autoreleasing _Nullable *)error;

/**
 * Update device with another copy.
 */
- (void)updateFrom:(AylaDevice *)device dataSource:(AylaDataSource)dataSource;

/**
 * Update device with an `AylaDeviceConnection` object.
 */
- (void)updateFromConnection:(AylaDeviceConnection *)deviceConnection dataSource:(AylaDataSource)dataSource;

/**
 * Use this method to notify changes to all listeners.
 *
 * @param changes An array of changes.
 */
- (void)notifyChangesToListeners:(NSArray *)changes;

/**
 * Use this method to let device refresh its current sync strategy.
 */
- (void)dataSourceChanged:(AylaDataSource)dataSource;

/**
 * Use this method to enable lan session of current device.
 *
 * @return NO will be immidiately returned if any precondition of this reqeust is unsatisfied.
 */
- (BOOL)enableLanSession;

/**
 * Use this method to disable lan session of current device.
 */
- (void)disableLanSession;

/**
 * Use this method to detemine if lan mode is currently active.
 */
- (BOOL)isLanModeActive;

/**
 * Use this method to deploy a lan task on lan module of current device.
 */
- (BOOL)deployLanTask:(AylaLanTask *)lanTask error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/**
 * Shut down functionalities of current device
 *
 * @note this method should only be called from device manager when this device is no longer maitained by it.
 */
- (void)shutDown;

/**
 * Reads the properties from the cache
 */
- (void)readPropertiesFromCache;


/** 
 * Enables or disables LAN Session based on `lanModePermitted`, `disableLANUntilNetworkChanges`, 
 * `isTracking`, `grant`
 */
- (void)adjustLanSessionBasedOnPermitAndStatus;

/**
 * Use this method to get a appropriate AylaDevice class from input json dictionary
 *
 * @note Input json dictionary must contain contain attribute 'device_type'. Otherwise AylaDevice class will
 * be returned by default.
 */
+ (Class)deviceClassFromJSONDictionary:(NSDictionary *)dictionary;

/**
 * Get device processing queue
 */
+ (dispatch_queue_t)deviceProcessingQueue;


/**
 *  Returns the Cloud HTTP Client
 *
 *  @param error A pointer to an `NSError` variable to store an error in case of failure
 *  @return The Cloud HTTP client.
 */
- (nullable AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error;
@end

NS_ASSUME_NONNULL_END
