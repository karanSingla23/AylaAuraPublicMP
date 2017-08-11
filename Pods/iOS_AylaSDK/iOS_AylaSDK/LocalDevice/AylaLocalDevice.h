//
//  AylaLocalDevice.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaGenericTask.h"
#import "AylaDevice+Extensible.h"
#import "AylaLocalProperty.h"
#import "AylaLocalOTACommand.h"

NS_ASSUME_NONNULL_BEGIN
extern NSString const *OTATypeHostMCU;
/**
 Represents a local device
 */
@interface AylaLocalDevice : AylaDeviceNode

/**
 Connects SDK with the localDevice

 @param successBlock A block called when the device has been connected
 @param failureBlock A block called when the device failed to connect
 @return A task representing the requesst
 */
- (AylaGenericTask *)connectLocalWithSuccess:(void (^)())successBlock
                                     failure:(void (^)(NSError *))failureBlock;


/**
 Disconnects SDK with the localDevice
 
 @param successBlock A block called when the device has been disconnected
 @param failureBlock A block called when the device failed to disconnect
 @return A task representing the requesst
 */
- (AylaGenericTask *)disconnectLocalWithSuccess:(nullable void (^)())successBlock
                                        failure:(nullable void (^)(NSError *))failureBlock;


/**
 Sets the property value in the local device

 @param value the value to set
 @param property The property to set
 @param successBlock A block called when the property value has been set
 @param failureBlock A block called when the property value failed to be set
 @return A task representing the requesst
 */
- (nullable AylaGenericTask *)setValue:(id)value
                           forProperty:(AylaLocalProperty *)property
                               success:(nullable void (^)())successBlock
                               failure:(nullable void (^)(NSError *))failureBlock;


/**
 Returns the value for the property

 @param property The property to return its value
 @return The value of the property
 */
- (nullable id)valueForProperty:(AylaLocalProperty *)property;

/**
 * Called by the local device when a local connection is established, this method checks the
 * Ayla device service to see if there any pending commands for this device. Implementers of
 * LocalDevice classes should call this method whenever a local connection has been established.
 */
- (void)checkQueuedCommands;

/**
 * Developers should implement this method to handle an OTA image update. This method will be
 * called when an OTA image has been detected and downloaded. Once the image has been
 * downloaded, the OTA command should be acknowledged by calling `ackCommand`.
 * @param otaCommand Command contained within the device command, in this case an OTA command
 * @param filePath Local path to the file containing the OTA image
 */
- (void)otaReceived:(AylaLocalOTACommand *)otaCommand filePath:(NSURL *)filePath;


/**
 * Update the status of an OTA Command.
 *
 * @param status 0 if successful, otherwise the status will be the error code
 * @param otaType Available types: `OTATypeHostMCU`
 * @param success Listener called if the operation is successful
 * @param failure Listener called if the operation failed
 * @return the `AylaHTTPTask`, which may be used to cancel the operation
 */
- (nullable AylaHTTPTask *)setOTAStatus:(NSInteger)status commandId:(NSInteger)commandId success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failure;

/**
 Indicates whether the device is connected to SDK
 */
@property (nonatomic, readonly) BOOL isConnectedLocal;

/**
 Hardware address of the local device
 */
@property (nonatomic, strong, nullable) NSString *hardwareAddress;

/**
 * Indicates whether or not this device requires additional local configuration. This might
 * be Bluetooth pairing, mobile device authentication with the IoT device, etc. Devices that
 * require local configuration should return true from this method until the local
 * configuration steps have been completed.
 *
 * @return false if no additional local configuration is requried, true if local
 * configuration is required to interact with the local device
 */
@property (nonatomic, readonly) BOOL requiresLocalConfiguration;
@end
NS_ASSUME_NONNULL_END
