//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaFieldChange.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDevice;

/**
 * An `AylaDeviceChange` is issued when change to device is captured when updating a device.
 *
 * The change object contains the `AylaDevice` that has changed, and a set of field names that have changed.
 * These lists may be empty if no items were changed.
 */
@interface AylaDeviceChange : AylaFieldChange

/** @name Device CHange Properties */

/** The `AylaDevice` that has changed */
@property (nonatomic, readonly) AylaDevice *device;

/** @name Initializer Methods */
/**
 * Init method for `AylaDeviceChange` with the relevant `AylaDevice` object as input
 * @param device The `AylaDevice` that has has undergone a change
 * @param changedFields An NSSet of NSString representations of the fields that changed
 */
- (instancetype)initWithDevice:(AylaDevice *)device changedFields:(NSSet *)changedFields NS_DESIGNATED_INITIALIZER;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END