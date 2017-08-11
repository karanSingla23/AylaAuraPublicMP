//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
@class AylaSchedule;
/**
 * Enumerates the point during a schedule's run at which the `AylaScheduleAction` will be activated.
 */
typedef NS_ENUM(NSUInteger, AylaScheduleActionFirePoint) {
    /** Unspecified Fire Point */
    AylaScheduleActionFirePointUnspecified = 0,
    
    /** Fire if the time is at the start of the range */
    AylaScheduleActionFirePointAtStart,
    
    /** Fire if the time is at the end of the range */
    AylaScheduleActionFirePointAtEnd,
    
    /** Fire if the time is within the range specified */
    AylaScheduleActionFirePointInRange
};

/**
 * AylaScheduleAction types
 */
FOUNDATION_EXPORT NSString *const AylaScheduleActionTypeProperty;

@interface AylaScheduleAction : AylaObject
/**
 * The key assigned by the cloud
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *key;

/**
 * Type of `AylaScheduleAction` (optional, default = `AylaScheduleActionTypeProperty`)
 * (currently only `AylaScheduleActionTypeProperty` supported)
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 * Associated property name (required when type is `AylaScheduleActionTypeProperty`)
 */
@property (nonatomic, copy) NSString *name;

/**
 * Value to set the property when an event fires
 */
@property (nonatomic, copy) id value;

/**
 * Associated property `baseType`
 * (currently only `AylaPropertyBaseTypeString`, `AylaPropertyBaseTypeInteger`, `AylaPropertyBaseTypeBoolean`, and `AylaPropertyBaseTypeDecimal` are supported)
 */
@property (nonatomic, copy) NSString *baseType;

/**
 * YES if this action is currently active (default = YES)
 */
@property (nonatomic, assign, getter=isActive) BOOL active;

/**
 * The point at which to fire the action
 */
@property (nonatomic, assign) AylaScheduleActionFirePoint firePoint;

/**
 * The parent `AylaSchedule`
 */
@property (nonatomic, weak, readonly) AylaSchedule *schedule;

/**
 * Initializes the action with the specified parameters
 *
 * @param name      The name of the schedule action
 * @param value     Value of the action
 * @param baseType  baseType of the `AylaProperty`
 * @param active    Indicates wether or not the action is active
 * @param firePoint Specifies the point at which the action will be triggered.
 * @param schedule  The schedule owning the action
 *
 * @return An initialized `AylaScheduleAction`
 */
- (instancetype)initWithName:(NSString *)name value:(id)value baseType:(NSString *)baseType active:(BOOL)active firePoint:(AylaScheduleActionFirePoint)firePoint schedule:(AylaSchedule *)schedule;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
