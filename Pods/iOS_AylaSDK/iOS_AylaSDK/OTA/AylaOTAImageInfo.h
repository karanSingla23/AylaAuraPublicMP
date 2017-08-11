//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a LAN OTA object from the Cloud for a specific Ayla device
 */
@interface AylaOTAImageInfo : AylaObject

/**
 * Download url of image file
 */
@property (nonatomic, copy, readonly) NSString *url;

/**
 * OTA image version.
 */
@property (nonatomic, copy, readonly) NSString *version;

/**
 * "s3" or "local", "local" requires auth_token to access.
 */
@property (nonatomic, copy, readonly) NSString *location;

/**
 * “module|host”
 */
@property (nonatomic, copy, readonly) NSString *type;

/**
 * OTA file size before encryption
 */
@property (nonatomic, copy, readonly) NSNumber *size;

/**
 * Get an new object with given data
 *
 * @param dictionary Data which contain all image information.
 * @param error      Error if build object fail.
 *
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error;

@end

NS_ASSUME_NONNULL_END