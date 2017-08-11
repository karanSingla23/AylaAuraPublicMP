//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaChange.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A `AylaFieldChange` object contains a list of the names of fields of an object that have changed.
 */
@interface AylaFieldChange : AylaChange

/** @name Field Change Properties */

/** Set of changed fields */
@property (nonatomic, readonly) NSSet *changedFields;

/** @name Initializer Methods */

/**
 * Init method with changed fields.
 * @param changedFields An `NSSet` containing the fields that changed
 * @return An initialized `AylaFieldChange` instance
 */
- (instancetype)initWithChangedFields:(NSSet *)changedFields;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END