//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaFieldChange.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaProperty;

/**
 * An `AylaPropertyChange` object represents a captured value change for a property.
 *
 * The change object contains the `AylaProperty` that has changed, and a set of field names that have changed. 
 * These lists may be empty if no items were changed.
 */
@interface AylaPropertyChange : AylaFieldChange

/** @name Proeprty Change Properties */

/** The changed property */
@property (nonatomic, readonly) AylaProperty *property ;

/**
 * Init method for `AylaPropertyChange` with the relevant `AylaProperty` object as input
 * @param property The `AylaProperty` that has has undergone a change
 * @param fields An NSSet of `NSString` representations of the fields that changed
 */
- (instancetype)initWithProperty:(AylaProperty *)property
                   changedFields:(NSSet AYLA_GENERIC(NSString *) *)fields NS_DESIGNATED_INITIALIZER;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END