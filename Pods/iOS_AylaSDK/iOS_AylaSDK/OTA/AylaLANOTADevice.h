//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaHTTPTask.h"
#import "AylaOTAImageInfo.h"
#import "AylaObject.h"
#import "AylaSessionManager.h"

NS_ASSUME_NONNULL_BEGIN
@class AylaLANOTADevice;


/** Enumerates the different states for the LAN OTA */
typedef NS_ENUM(NSInteger, ImagePushStatus) {
    /** Initial status */
    ImagePushStatusInitial = -1,
    /** Image has been pushed */
    ImagePushStatusDone = 200,
    /** CRC Error */
    ImagePushStatusCRCError = 0x01,
    /** Failed to download */
    ImagePushStatusDownloadError = 0x09,
};

/**
 * Delegate for pushing status to Ayla device
 */
@protocol AylaLANOTADeviceDelegate<NSObject>

/**
 * Method called when image push status updated
 *
 * @param device Cureent LAN OTA device
 * @param status Current `ImagePushStatus`
 */
- (void)lanOTADevice:(AylaLANOTADevice *)device didUpdateImagePushStatus:(ImagePushStatus)status;

@end

/**
 * AylaLANOTADevice is used for updating an OTA Image. Three steps are needed to update an OTA
 * Image over LAN
 * 1. Fetch the OTA Image Info from the Cloud service by passing the dsn.
 * 2. Fetch the OTA Image file from the Cloud Service and store in the iOS phone/tablet.
 * 3. Push the OTA Image file from the iOS phone/tablet to Ayla Device over LAN.
 */
@interface AylaLANOTADevice : AylaObject

/** @name Setup Device Properties */

/** Device dsn */
@property (nonatomic, strong, readonly) NSString *dsn;

/** Device lan ip */
@property (nonatomic, strong, readonly) NSString *lanIP;

/** Delegate when push image to device status update */
@property (nonatomic, weak) id<AylaLANOTADeviceDelegate> delegate;

/** @name Device LAN OTA Methods */

/**
 * Get a LAN OTA Device by giving dsn and lan IP
 *
 * @param sessionManager Session manager
 * @param dsn   Device dsn
 * @param lanIP Device lan IP
 *
 */
- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager DSN:(NSString *)dsn lanIP:(NSString *)lanIP;

/**
 * Check local storage if image file for LAN OTA is available. Library only maintains one
 * copy of image file per device, regardless of how many times apps download image file for
 * the same device.  The latter version
 * will over-write the earlier one.
 *
 * @return YES if file exists, NO otherwise.
 */
- (BOOL)isOTAImageAvailable;

/**
 * Remove locally persisted OTA image file named as dsn. When the Lan OTA upgrade process
 * finishes successfully library will call this. However it is apps` responsibility to make sure the
 * image file would not be removed when being used.
 */
- (void)deleteOTAFile;

/**
 * Based on dsn, fetch the image information from Ayla Cloud. Note that this API does not download
 * the image file automatically, when to actually download the image is up to the app. There
 * is no expiration once the image file is created and signed.
 *
 * @param successBlock A block called when get the image info successful.
 * @param failureBlock A block called when request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)fetchOTAImageInfoWithSuccess:(void (^)(AylaOTAImageInfo *otaInfo))successBlock
                                                failure:(void (^)(NSError *error))failureBlock;

/**
 * Fetch OTA image from remote location. If there is already one copy locally, it will be
 * over-written.
 *
 * @param imageInfo    Model that contains all meta data of the image file.
 * @param downloadProgressBlock A block called whith progress updates
 * @param successBlock A block called when download the image file successful.
 * @param failureBlock A block called when request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)fetchOTAImageFile:(AylaOTAImageInfo *)imageInfo
                                    progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                     success:(void (^)(void))successBlock
                                     failure:(void (^)(NSError *error))failureBlock;

/**
 * Push the downloaded OTA image file to Ayla device.
 *
 * @param successBlock A block called when notify device to download image file successful.
 * @param failureBlock A block called when request fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)pushOTAImageToDeviceWithSuccess:(void (^)(void))successBlock
                                                   failure:(void (^)(NSError *_Nonnull))failureBlock;

@end

NS_ASSUME_NONNULL_END
