//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

@class AylaHTTPTask;
@class AylaProperty;

#import <Foundation/Foundation.h>

#import "AylaDefines.h"
#import "AylaObject.h"
#import "AylaPropertyTriggerApp.h"

/**
 Enumerates the `AylaPropertyTrigger` comparison condition types.
 */
typedef NS_ENUM(NSInteger, AylaPropertyTriggerCompare) {
    /**
     * Unknown Property Trigger compare type
     */
    AylaPropertyTriggerCompareUnknown = -1,
    /**
     Triggers when the property value equals the trigger value.
     */
    AylaPropertyTriggerCompareEqualTo = 0,
    /**
     Triggers when the property value is greater than the trigger value.
     */
    AylaPropertyTriggerCompareGreaterThan,
    /**
     Triggers when the property value is less than the trigger value.
     */
    AylaPropertyTriggerCompareLessThan,
    /**
     Triggers when the property value is greater than or equal to the trigger value.
     */
    AylaPropertyTriggerCompareGreaterThanOrEqualTo,
    /**
     Triggers when the property value is less than or equal to trigger value.
     */
    AylaPropertyTriggerCompareLessThanOrEqualTo
};

/**
 Enumerates the type of triggers.
 */
typedef NS_ENUM(NSInteger, AylaPropertyTriggerType) {
    /**
     Unknown Property Trigger type
     */
    AylaPropertyTriggerTypeUnknown = -1,
    /**
     Triggers any time there is a new datapoint.
     */
    AylaPropertyTriggerTypeAlways = 0,
    /**
     Triggers if the value of the new datapoint is different from the existing one.
     */
    AylaPropertyTriggerTypeOnChange,
    /**
     Compares to a value specified in the trigger
     */
    AylaPropertyTriggerTypeCompareAbsolute
};

NS_ASSUME_NONNULL_BEGIN
/** @name Property Trigger Properties */

/**
 Describes the conditions under which the trigger will activate its Apps.
 */
@interface AylaPropertyTrigger : AylaObject
/**
 A nickname for the device.
 */
@property (nonatomic, strong) NSString *deviceNickname;
/**
 A nickname for the property.
 */
@property (nonatomic, strong) NSString *propertyNickname;
/**
 Indicates whether or not the trigger must fire if the condition is met.
 */
@property (nonatomic, assign) BOOL active;
/**
 Indicates the type of condition for the trigger.
 */
@property (nonatomic, assign) AylaPropertyTriggerType triggerType;
/**
 Describes the property value comparision type used in the trigger.
 */
@property (nonatomic, assign) AylaPropertyTriggerCompare compareType;
/**
 The target value of the trigger.
 */
@property (nonatomic, strong) NSString *value;
/**
 A reference to he parent `AylaProperty`
 */
@property (nonatomic, weak) AylaProperty *property ;
/**
 The NSDate when the trigger was fetched.
 */
@property (nonatomic, strong, readonly) NSDate *retrievedAt;
/**
 Duration the trigger is active
 */
@property (nonatomic, strong, readonly) NSString *period;
/**
 Datapoint type for the trigger value
 */
@property (nonatomic, strong, readonly) NSString *baseType;
/**
 Timestamp for when the trigger was last activated
 */
@property (nonatomic, strong, readonly) NSString *triggeredAt;

/** @name Trigger Type Methods Methods */

/**
 *Converts the `AylaPropertyTriggerType` enum value to the `NSString` representation used by the cloud.
 *
 * @param type The `AylaPropertyTriggerType` to convert.
 *
 * @return The `NSString` representation or "name" of the type or nil if the type is invalid or not supported.
 */
+ (NSString *)triggerTypeNameFromType:(AylaPropertyTriggerType)type;

/**
 * Converts the type name in an `NSString` to `AylaPropertyTriggerType` enum value.
 *
 * @param typeName The name of the type in an `NSString`
 *
 * @return The `AylaPropertyTriggerType` of the NSString or -1 if the string doesn't correspond to any type.
 */
+ (AylaPropertyTriggerType)triggerTypeFromName:(NSString *)typeName;

/**
 * Converts the specified `AylaPropertyTriggerCompare` type into the its `NSString` representation to be used by the cloud.
 *
 * @param type The `AylaPropertyTriggerCompare` type to convert.
 *
 * @return An `NSString` representation of the type or nil if the provided type is invalid or not supported.
 */
+ (NSString *)comparisonNameFromType:(AylaPropertyTriggerCompare)type;

/**
 * Converts the specified `NSString` into a corresponding `AylaPropertyTriggerCompare` value.
 *
 * @param comparisonName The comparison name as an `NSString`
 *
 * @return The `AylaPropertyTriggerCompare` value or nil if the specified string is invalid or not supported.
 */
+ (AylaPropertyTriggerCompare)comparisonTypeFromName:(NSString *)comparisonName;

/** @name Trigger App Methods */

/**
 * Creates an `AylaPropertyTriggerApp` in the cloud from the data contained in the specified `triggerApp` parameter.
 *
 * @param triggerApp   The trigger app to be created in the cloud.
 * @param successBlock A block to be called if the trigger app has been created successfully. Passed the created `AylaPropertyTriggerApp`
 * object returned from the cloud.
 * @param failureBlock A block to be called if the creation operation fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)createApp:(AylaPropertyTriggerApp *)triggerApp
                             success:(void (^)(AylaPropertyTriggerApp *createdApp))successBlock
                             failure:(void (^)(NSError *error))failureBlock;
/**
 * Fetches an `NSArray` of any existing `AylaPropertyTriggerApp` from the cloud.
 *
 * @param successBlock A block to be called if the trigger apps have been fetched successfully. Passed an `NSArray` containing the
 * (zero or more) fetched `AylaPropertyTriggerApp` objects returned from the cloud.
 * @param failureBlock A block to be called if the fetch operation fails. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)fetchApps:(void (^)(NSArray AYLA_GENERIC(AylaPropertyTriggerApp *) * apps))successBlock
                             failure:(void (^)(NSError *error))failureBlock;
/**
 * Updates the specified `AylaPropertyTriggerApp` in the cloud.
 *
 * @param app          The `AylaPropertyTriggerApp` that was previously fetched from the cloud and contains the desired changes.
 * @param successBlock A block to be called if the trigger app has been updated successfully. Passed the updated `AylaPropertyTriggerApp`
 * object returned from the cloud.
 * @param failureBlock A block to be called if the update operation fails. Passed an `NSError `describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)updateApp:(AylaPropertyTriggerApp *)app
                             success:(void (^)(AylaPropertyTriggerApp *updatedApp))successBlock
                             failure:(void (^)(NSError *error))failureBlock;
/**
 * Deletes an `AylaPropertyTriggerApp` from the cloud.
 *
 * @param app          The previously fetched `AylaPropertyTriggerApp` now to be deleted from the cloud.
 * @param successBlock A block to be called if the trigger has been deleted successfully.
 * @param failureBlock A block to be called if the delete operation fails. Passed an `NSError `describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)deleteApp:(AylaPropertyTriggerApp *)app
                             success:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock;
@end

FOUNDATION_EXPORT NSString *const kAylaTriggerCompareEqual;
FOUNDATION_EXPORT NSString *const kAylaTriggerCompareGreaterThan;
FOUNDATION_EXPORT NSString *const kAylaTriggerCompareLessThan;
FOUNDATION_EXPORT NSString *const kAylaTriggerCompareGreaterOrEqual;
FOUNDATION_EXPORT NSString *const kAylaTriggerCompareLessOrEqual;

FOUNDATION_EXPORT NSString *const kAylaTriggerTypeAlways;
FOUNDATION_EXPORT NSString *const kAylaTriggerTypeOnChange;
FOUNDATION_EXPORT NSString *const kAylaTriggerTypeCompareAbsolute;

NS_ASSUME_NONNULL_END