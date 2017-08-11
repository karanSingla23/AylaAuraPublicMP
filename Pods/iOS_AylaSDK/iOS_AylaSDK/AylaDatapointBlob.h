//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDatapoint.h"

@class AylaDatapoint;
@class AylaHTTPTask;

NS_ASSUME_NONNULL_BEGIN

/**
 * AylaDatapointBlob is used for upload and download of file properties to service
 */
@interface AylaDatapointBlob : AylaDatapoint

/** URL of file in the local file system */
@property (nonatomic, strong, nullable) NSURL *localFileURL;


/** Data in the blob */
@property (nonatomic, strong, nullable) NSData *blobData;

/** Cloud url of the datapoint. */
@property (nonatomic, strong, readonly) NSURL *fileURL;

/** Declare if file has been uploaded completely. */
@property (nonatomic, assign, readonly) BOOL closed;

/**
 *  Location of Datapoint in Cloud to get the fileURL to Download
 */
@property (nonatomic, strong, readonly) NSURL *location;

/**
 *  Uploads the data or file in the receiver to the cloud.
 *
 *  @param uploadProgressBlock A block that will be called with the progress updates
 *  @param successBlock        A block that will be called when the upload succeeds
 *  @param failureBlock        A block that will be called when the upload fails
 *
 *  @return A started `AylaHTTPTask` representing the request.
 */
- (AylaHTTPTask *)uploadBlobWithProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                 success:(void (^)())successBlock
                                 failure:(void (^)(NSError *_Nonnull))failureBlock;
/**
 * Downloads the file from the cloud.
 *
 * @param filePath              A `NSURL` with the destination file URL
 * @param downloadProgressBlock A block called with the download progress updates
 * @param successBlock          A block that will be called when the download succeeds
 * @param failureBlock          A block that will be called when the download fails
 *
 *  @return A started `AylaHTTPTask` representing the request.
 */
- (AylaHTTPTask *)downloadToFile:(NSURL *)filePath
                        progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         success:(void (^)(NSURL *filePath))successBlock
                         failure:(void (^)(NSError *_Nonnull))failureBlock;
@end
NS_ASSUME_NONNULL_END
