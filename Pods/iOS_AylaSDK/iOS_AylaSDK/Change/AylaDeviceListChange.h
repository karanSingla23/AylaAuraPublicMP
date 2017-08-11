//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaListChange.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDevice;

/**
 * An `AylaDeviceListChange` object is used whenever the `deviceList` held by `AylaDeviceManager` has items added
 * or removed from the list.
 *
 * The change object contains sets of `AylaDevices` that were added and removed. These lists may be empty if no items were
 * added or removed.
 */
@interface AylaDeviceListChange : AylaListChange

/** @name Device List Change Properties */

/** Set of added `AylaDevices` */
@property (nonatomic, readonly) NSSet AYLA_GENERIC(AylaDevice *) * addedItems;

/** Set of dsns of removed devices (as devices are no longer present) */
@property (nonatomic, readonly) NSSet AYLA_GENERIC(NSString *) * removedItemIdentifiers;

/** @name Initializer Methods */

/**
 * Init method with added devices and removed devices
 *
 * @param addedDevices    An `NSSet` containing newly added `AylaDevice`s
 * @param removedDevices  An `NSSet` containing now removed `AylaDevice`s
 */
- (instancetype)initWithAddedDevices:(NSSet AYLA_GENERIC(AylaDevice *) *)addedDevices
                       removeDevices:(NSSet AYLA_GENERIC(AylaDevice *) *)removedDevices NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
