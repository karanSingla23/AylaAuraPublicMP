//
//  AylaLocalDeviceManager.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaGenericTask.h"
#import "AylaLocalDevice.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * Local Device Plugin for communications with devices outside of LAN / Internet, such as
 * Bluetooth LE devices. These plugins implement the AylaLocalDeviceManager interface.
 *
 * These plugins work with the Ayla Local Device SDK.
 */
extern NSString * const PLUGIN_ID_LOCAL_DEVICE;

/**
 Registration of a local device such as BLE device
 */
extern const NSInteger AylaRegistrationTypeLocal;

@protocol AylaLocalDeviceManager <AylaDeviceClassPlugin>

/**
 * Searches for AylaLocalDevices nearby. The returned list should contain AylaLocalDevices
 * that have been locally discovered. The returned devices may or may not be registered to
 * the user.
 *
 * @param hint Search-specific hint used to filter the set of returned devices. The format of
 *             this object is not defined, but may be used by subclasses to filter based on
 *             Bluetooth address ranges, GATT service IDs, etc.
 *
 * @param timeoutInMs Maximum time the search should take in ms
 * @param successBlock Listener to be notified with the results
 * @param failureBlock Listener to receive an error should one occur.
 *
 * @return an AylaHTTPTask object. This object may be used to cancel the operation before
 * the scan has completed.
 */
- (nullable AylaGenericTask *)findLocalDevicesWithHint:(nullable id)hint
                                            timeout:(NSInteger)timeoutInMs
                                            success:(void (^)(NSArray<AylaRegistrationCandidate *> *))successBlock
                                            failure:(void (^)(NSError *))failureBlock;

/**
 * Registers a local device with the Ayla service.
 *
 * @param device Device to register. This should have been returned from findLocalDevices.
 * @param sessionManager Session manager for the account this device should be registered to
 * @param successBlock Listener to receive the registered device upon success
 * @param failureBlock Listener to receive an error should one occur
 *
 * @return an AylaHTTPTask, which may be used to cancel the operation
 */
- (nullable  AylaConnectTask *)registerLocalDevice:(AylaRegistrationCandidate *) device
                                sessionManager:(AylaSessionManager *)sessionManager
                                       success:(void (^)(AylaLocalDevice *))successBlock
                                       failure:(void (^)(NSError *))failureBlock;

/**
 * Unregisters a local device with the Ayla service.
 *
 * @param sessionManager Session manager for the session owning this device
 * @param device Device to be unregistered
 * @param successBlock Listener called upon success
 * @param failureBlock Listener called with an error should one occur
 * @return the AylaHTTPTask, which may be used to cancel the operation
 */
- (nullable AylaConnectTask *)unregisterLocalDevice:(AylaLocalDevice *)device
                                  sessionManager:(AylaSessionManager *)sessionManager
                                         success:(void (^)())successBlock
                                         failure:(void (^)(NSError *))failureBlock;
@end
NS_ASSUME_NONNULL_END
