//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaWifiScanResults.h"
#import "AylaWifiStatus.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Enumerates the possible status conditions for AylaSetup
 */
typedef NS_ENUM(uint32_t, AylaSetupStatus) {
    /**
     * Idle, ready to connect to a device.
     */
    AylaSetupStatusIdle,
    /**
     * Determining Device IP in AP Mode
     */
    AylaSetupStatusDeterminingLanIp,
    /**
     * Connecting to an AP Mode device.
     */
    AylaSetupStatusConnectingToDevice,
    /**
     * Connected to an AP Mode device.
     */
    AylaSetupStatusConnectedToDevice,
    /**
     * Disconnected from the device to be set up.
     */
    AylaSetupStatusDisconnectedFromDevice,
    /**
     * Observed an error during setup.
     */
    AylaSetupStatusError
};

/**
 Objects needing updates in WiFi State changes should implement this is the Protocol.
 */
@protocol AylaDeviceWifiStateChangeListener <NSObject>

/**
 Method called when there's an update on the WiFi state.

 @param state The new state.
 */
- (void)wifiStateDidChange:(NSString *)state;

@end

@class AylaConnectTask;
@class AylaNetworks;
@class AylaSetupDevice;
@class AylaWifiStatus;

/**
 * The `AylaSetup` class is used to connect to a device in AP mode. that is, a device that is not currently configured to join
 * a locally available Wi-Fi network. Devices that are not able to join a Wi-Fi network will put themselves into AP mode 
 * automatically and broadcast an SSID that is identifiable as an Ayla device.
 *
 * Once the user has connected their phone or tablet to the device's AP, the application can call `connectToNewDevice:failure:` to let the SDK
 * confirm the connection and setup the device.
 *
 * Then application could give a call to `startDeviceScanForAccessPoints:failure:` to let the device scan for visible Wi-Fi access points
 * and call `fetchDeviceAccessPoints:failure:` to fetch the scan result from the device. 
 * @note Some devices may need several seconds to complete the scan request. It's good practice to delay before making a `fetch` call.
 *
 * Once the user selects an SSID and enters the password, the application can invoke
 * `connectDeviceToServiceWithSSID:password:setupToken:latitude:longitude:success:failure:` to let the device connect to
 * that SSID.
 *
 * In order to confirm that the device has successfully connected to the Wi-Fi network, the method
 * `confirmDeviceConnectedWithTimeout:dsn:setupToken:success:failure:` can be called to verify the device's connection.
 *
 * The `-exit` can be manually called to manually top the setup of a device. The method will also be called automatically when `AylaSetup` is
 * going to be deallocated.
 */
@interface AylaSetup : NSObject

/** @name Setup Properties */

/** Current setup status. */
@property (nonatomic, assign, readonly) AylaSetupStatus status;

/** Local LAN IP Address of the setup device. The default IP will be determined as part of `connectToNewDevice:failure:` method */
@property (nonatomic, strong) NSString *setupDeviceLanIp;

/** Current linked `AylaSetupDevice` */
@property (nonatomic, strong, readonly, nullable) AylaSetupDevice *setupDevice;

/** @name Initializer Methods */

/**
 * Use this method to init a new setup instance with SDK root.
 *
 * @param sdkRoot Current SDK root (`AylaNetworks` instance).
 */
- (instancetype)initWithSDKRoot:(AylaNetworks *)sdkRoot;

/** @name Device Wi-Fi Setup Methods */

/**
 * Use this method to connect to a setup device which can be reached at the `setupDeviceLanIp`.
 *
 * @param successBlock A block to be called when the requests is successful. Passed the connected `AylaSetupDevice` object.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaConnectTask` instance which handles the request.
 */
- (void)connectToNewDevice:(void (^)(AylaSetupDevice *setupDevice))successBlock
                                         failure:(void (^)(NSError *error))failureBlock;

/**
 * Use this method to fetch setup device wifi status
 *
 * @param successBlock A block to be called when the requests is successful. Passed the fetched `AylaWifiStatus` object.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaConnectTask` instance which handles the request.
 */
- (nullable AylaConnectTask *)fetchDeviceWifiStatus:(void (^)(AylaWifiStatus *wifiStatus))successBlock
                                            failure:(void (^)(NSError *error))failureBlock;

/**
 * Initiates a scan for WiFi access points on the setup device. If successful, this call will tell the setup device to
 * start scanning for visible WiFi access points. The results of the scan can be obtained via a call to
 * `fetchDeviceAccessPoints:failure:`
 *
 * @param successBlock A block to be called when the requests is successful.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaConnectTask` instance which handles the request.
 */
- (nullable AylaConnectTask *)startDeviceScanForAccessPoints:(void (^)(void))successBlock
                                                     failure:(void (^)(NSError *error))failureBlock;

/**
 * Use this method to fetch observed access points by setup device.
 *
 * @param successBlock A block to be called when the requests is successful. Passed the fetched `AylaWifiScanResults` object.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaConnectTask` instance which handles the request.
 */
- (nullable AylaConnectTask *)fetchDeviceAccessPoints:(void (^)(AylaWifiScanResults *))successBlock
                                              failure:(void (^)(NSError *error))failureBlock;

/**
 * Use this method to connect a device to service
 *
 * @param SSID         SSID of the network the device will connect to.
 * @param password     Password for that SSID. Pass in nil if no password is required for that SSID.
 * @param setupToken   Setup token which will be used to confirm device connection to cloud service.
 * @param latitude     Optional latitude coordinate for the device's physical location
 * @param longitude    Optional longitude coordinate for the device's physical location
 * @param successBlock A block to be called when the requests is successful.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError `describing the failure.
 *
 * @return The AylaConnectTask instance which handles the request.
 */
- (nullable AylaConnectTask *)connectDeviceToServiceWithSSID:(NSString *)SSID
                                                    password:(nullable NSString *)password
                                                  setupToken:(NSString *)setupToken
                                                    latitude:(double)latitude
                                                  longitude:(double)longitude
                                                     success:(void (^)(AylaWifiStatus *status))successBlock
                                                     failure:(void (^)(NSError *error))failureBlock;

/**
 * Confirms that the setup device has connected to the Ayla service. Note this call will attempt to kill connection
 * between mobile device and setup device.
 *
 * @param timeoutInSeconds Timeout for this operation.
 * @param dsn              DSN of the device to confirm
 * @param setupToken       Setup token used in last call of
 * `connectDeviceToServiceWithSSID:password:setupToken:latitude:longitude:success:failure:`.
 * @param successBlock A block to be called when the requests is successful.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaConnectTask` instance which handles the request.
 */
- (nullable AylaConnectTask *)confirmDeviceConnectedWithTimeout:(NSTimeInterval)timeoutInSeconds
                                                            dsn:(NSString *)dsn
                                                     setupToken:(NSString *)setupToken
                                                        success:(void (^)(AylaSetupDevice *setupDevice))successBlock
                                                        failure:(void (^)(NSError *error))failureBlock;

/**
 * Used to exit the setup process.
 */
- (void)exit;


/**
 Adds an `AylaDeviceWifiStateChangeListener`

 @param listener The object conforming `AylaDeviceWifiStateChangeListener` that will receive updates
 */
- (void)addWiFiStateListener:(id<AylaDeviceWifiStateChangeListener>)listener;

/**
 Removes an `AylaDeviceWifiStateChangeListener`

 @param listener The object to remove as listener
 */
- (void)removeWiFiStateListener:(id<AylaDeviceWifiStateChangeListener>)listener;
@end

NS_ASSUME_NONNULL_END
