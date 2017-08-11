//
//  AylaDatum.h
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * A Key Value Pair used to store custom data about devices and users in the cloud.
 */
@interface AylaDatum : AylaObject

/** @name Datum Properties */

/** The key used to reference the datum. Max length is 255. */
@property (nonatomic, readonly, copy) NSString *key;

/** The value that is associated with the Key. Max length is 65535. */
@property (nonatomic, readonly, copy) NSString *value;

/** The date-time stamp when object was created. */
@property (nonatomic, readonly, strong) NSDate *createdAt;

/** The date-time stamp when object was last updated. */
@property (nonatomic, readonly, strong) NSDate *updatedAt;

@end

NS_ASSUME_NONNULL_END
