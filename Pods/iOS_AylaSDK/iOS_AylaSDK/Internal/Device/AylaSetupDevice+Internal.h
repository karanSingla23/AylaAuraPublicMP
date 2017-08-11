//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaSetupDevice.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPServer;
@class AylaLanModule;
@class AylaWifiScanResults;
@class AylaWifiStatus;
@interface AylaSetupDevice (Internal)

/** Lan module which maintains lan session for current setup device */
@property (nonatomic, readonly) AylaLanModule *lanModule;

@property (nonatomic, readwrite) NSString *setupToken;
@property (nonatomic, readwrite) BOOL connectedStausFallback;

/**
 * Use this method to start lan session for this setup device.
 *
 * @param httpServer Http server on which lan session would be eastablished.
 * @param lanConfig  The lan config file which would be used by lan module.
 */
- (void)startLanSessionOnHttpServer:(AylaHTTPServer *)httpServer usingLanConfig:(AylaLanConfig *)lanConfig;

/**
 * Use this method to stop lan session for current device.
 */
- (void)stopLanSession;

/**
 * Updates receiver fields from the device passed in the parameter
 */
- (void)updateFrom:(AylaSetupDevice *)setupDevice;

#pragma mark - Secure setup
/**
 Initializes setup with the specified LAN IP during WiFi setup
 
 @param lanIP the IP of the device to setup
 @return The initialized instance of the AylaSetupDevice
 */
- (instancetype)initWithLANIP:(NSString *)lanIP;

/**
 * Fetches the device details securely.
 *
 * @param successBlock A block to be called when the requests is successful.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaLanTask` instance which handles the request.
 */
- (nullable AylaLanTask *)fetchDeviceDetailsLANWithSuccess:(void (^)())successBlock
                                          failure:(void (^)(NSError *))failureBlock;

/**
 * Securely initiates a scan for WiFi access points on the setup device. If successful, this call will tell the setup device to
 * start scanning for visible WiFi access points. The results of the scan can be obtained via a call to
 * `fetchDeviceAccessPoints:failure:`
 *
 * @param successBlock A block to be called when the requests is successful.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaLanTask` instance which handles the request.
 */
- (nullable AylaLanTask *)startDeviceScanForAccessPoints:(void (^)())successBlock
                                        failure:(void (^)(NSError *))failureBlock;

/**
 * Fetches the device details securely.
 *
 * @param time The new time for the device
 * @param successBlock A block to be called when the requests is successful.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaLanTask` instance which handles the request.
 */
- (nullable AylaLanTask *)updateNewDeviceTime:(NSNumber *)time
                             success:(void (^)())successBlock
                             failure:(void (^)(NSError *))failureBlock;

/**
 * Use this method to securely fetch observed access points by setup device.
 *
 * @param successBlock A block to be called when the requests is successful. Passed the fetched `AylaWifiScanResults` object.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaLanTask` instance which handles the request.
 */
- (nullable AylaLanTask *)fetchDeviceAccessPoints:(void (^)(AylaWifiScanResults *))successBlock
                                 failure:(void (^)(NSError *))failureBlock;

/**
 * Use this method to securely attempt to stop the AP from the device.
 *
 * @param successBlock A block to be called when the requests is successful. Passed the fetched `AylaWifiScanResults` object.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaLanTask` instance which handles the request.
 */
- (nullable AylaLanTask *)stopAPMode:(void (^)())successBlock
                    failure:(void (^)(NSError *))failureBlock;

/**
 * Use this method to fetch setup device wifi status
 *
 * @param successBlock A block to be called when the requests is successful. Passed the fetched `AylaWifiStatus` object.
 * @param failureBlock A block to be called when the request fails. Passed an `NSError` describing the failure.
 *
 * @return The `AylaLanTask` instance which handles the request.
 */
- (nullable AylaLanTask *)fetchWiFiStatus:(void (^)(AylaWifiStatus *wifiStatus))successBlock
                         failure:(void (^)(NSError *))failureBlock;
@end

NS_ASSUME_NONNULL_END
