//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Describes a timezone and its attributes
 */
@interface AylaTimeZone : AylaObject

/** @name Time Zone Properties */

/**
 *  Offset from UTC (Coordinated Universal Time). Format must be {+|-}HH:mm.
 */
@property (nonatomic, copy, readonly, nullable) NSString *utcOffset;

/**
 *  YES if the time zone observes DST (Daylight Saving Time).
 */
@property (nonatomic, assign, readonly) BOOL dst;

/**
 *  YES if DST is currently active for the time zone.
 */
@property (nonatomic, assign, readonly) BOOL dstActive;

/**
 *  Date and time (in UTC) of the next DST state change for the time zone.
 */
@property (nonatomic, strong, readonly, nullable) NSDate *dstNextChangeDate;

/**
 *  Standard time zone identifier string (e.g. "America/Los_Angeles") for the time zone.
 */
@property (nonatomic, copy, readonly, nullable) NSString *tzID;

@end

NS_ASSUME_NONNULL_END
