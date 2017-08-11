//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDeviceManager.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPServer;
@class AylaSessionManager;
@interface AylaDeviceManager (Internal)

/** Lan HTTP server */
@property (nonatomic, readonly) AylaHTTPServer *lanServer;

/**
 * Init method with a session manager.
 *
 * @param sessionManager The session manager who owns current device manager.
 */
- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager;

/**
 * Use this method to start poll timer.
 */
- (void)startPollTimer;

/**
 * Use this method to stop poll timer.
 */
- (void)stopPollTImer;

/**
 * Use this api to shut down functionalities of current device manager.
 */
- (void)shutDown;

/**
 Adds the specified devices to the deviceManager

 @param devices An array of `AylaDevice` instances to be added to the device Manager.
 */
- (void)addDevices:(NSArray AYLA_GENERIC(AylaDevice *) *)devices;

/**
 Removes the specified devices from the deviceManager

 @param devices An array of `AylaDevice` instances to be removed from the device Manager.
 */
- (void)removeDevices:(NSArray AYLA_GENERIC(AylaDevice *) *)devices;


/**
 Fetches the device properties and strats device tracking

 @param device The device to set up
 @param completionBlock A block called when the setup finishes, takes an `NSError` parameter in case of failure
 */
- (void)setupDevice:(AylaDevice *)device completionBlock:(nullable void (^)(NSError *error))completionBlock;
@end

NS_ASSUME_NONNULL_END
