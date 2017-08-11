//
//  AylaListChange.h
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaChange.h"
#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDevice;

/**
 * An `AylaListChange` object represents changes to an item's container.
 *
 * The change object contains sets of items that were added and identifiers of items that were removed. These lists may 
 * be empty if no items were added or removed.
 */
@interface AylaListChange : AylaChange

/** @name List Change Properties */

/** Set of added devices */
@property (nonatomic, readonly) NSSet * addedItems;

/** Set of removed devices */
@property (nonatomic, readonly) NSSet * removedItemIdentifiers;

/** @name Initializer Methods */

/**
 * Initializer method with added items and identifiers of removed items.
 *
 * @param addedItems              An `NSSet` containing newly added items
 * @param removedItemIdentifiers  An `NSSet` containing identifiers of now removed items.
 */
- (instancetype)initWithAddedItems:(NSSet *)addedItems
                       removeItems:(NSSet *)removedItemIdentifiers;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
