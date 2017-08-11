//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * AylaScheduleAction types
 */
FOUNDATION_EXPORT NSString *const AylaScheduleDirectionToDevice;
FOUNDATION_EXPORT NSString *const AylaScheduleDirectionFromDevice;

@class AylaHTTPTask;
@class AylaScheduleAction;
@class AylaDevice;

@interface AylaSchedule : AylaObject

/** @name Schedule Properties */

/**
 * The name of the schedule and used to uniquely identify it.
 */
@property (nonatomic, copy) NSString *name;

/**
 * User friendly schedule name for display purposes (optional, default = name)
 */
@property (nonatomic, copy, nullable) NSString *displayName;

/**
 * Direction: Either AylaScheduleDirectionToDevice or AylaScheduleDirectionFromDevice
 */
@property (nonatomic, copy) NSString *direction;

/**
 * Whether the schedule is active. (optional, default = YES)
 */
@property (nonatomic, assign, getter=isActive) BOOL active;

/**
 * Indicates that the schedule is set using the UTC time zone. (optional, default = NO)
 */
@property (nonatomic, assign, getter=isUsingUTC) BOOL utc;

/**
 * Date when the schedule will start running, formatted as "yyyy-mm-dd" (optional)
 */
@property (nonatomic, copy, nullable) NSString *startDate;

/**
 * Date when the schedule will stop running, formatted as "yyyy-mm-dd" (optional)
 */
@property (nonatomic, copy, nullable) NSString *endDate;

/**
 * Start time each day, in local time using 24-hour format "HH:mm:ss"
 */
@property (nonatomic, copy, nullable) NSString *startTimeEachDay;

/**
 * End time each day, in local time using 24-hour format "HH:mm:ss" (optional)
 */
@property (nonatomic, copy, nullable) NSString *endTimeEachDay;

/**
 * Time before end each day, in local time using 24-hour format "HH:mm:ss" (optional)
 */
@property (nonatomic, copy, nullable) NSString *timeBeforeEnd;

/**
 * The days of the week to run the schedule, 1 - 7 where 1 is Sunday and 7 is Saturday (optional)
 */
@property (nonatomic, strong, nullable) NSArray AYLA_GENERIC(NSNumber *) *daysOfWeek;

/**
 * The days in the month to run the schedule, 1 - 32 where 1 is the first day, 2 is the second day, etc.
 * 32 is a special value to represent the last day of the month. (optional)
 */
@property (nonatomic, strong, nullable) NSArray AYLA_GENERIC(NSNumber *) *daysOfMonth;

/**
 * The months of the year to run the schedule, 1 - 12 where 1 is January and 12 is December (optional)
 */
@property (nonatomic, strong, nullable) NSArray AYLA_GENERIC(NSNumber *) *monthsOfYear;

/**
 * The occurrences in the month that the schedule runs for each specified day of the week, 1 - 6
 * where 1 is the first occurrance, 2 is the second, etc. 6 is a special value to indicate the last
 * occurrecnce in the month. (optional)
 */
@property (nonatomic, strong, nullable) NSArray AYLA_GENERIC(NSNumber *) *dayOccurOfMonth;

/**
 * Absolute length of time in seconds for which the schedule will run. (optional)
 */
@property (nonatomic, strong, nullable) NSNumber *duration;

/**
 * Time between the start of each repeating duration, in seconds (optional)
 */
@property (nonatomic, strong, nullable) NSNumber *interval;

/**
 * Indicates that the schedule's actions are predetermined by the OEM template and cannot be dynamically created or deleted. (optional, default = NO)
 */
@property (nonatomic, assign) BOOL fixedActions;

/**
 * The parent `AylaDevice`
 */
@property (nonatomic, weak, readonly, nullable) AylaDevice *device;

/** @name Schedule Action Methods */
/**
 *  Retrieves all existing actions for this schedule from the cloud.
 *
 * @param successBlock   A block to be called if the request is successful. Passed an NSArray containing the retrieved AylaScheduleAction 
 * objects (if any) as returned by the cloud.
 * @param failureBlock   A block to be called if the request fails. Passed an NSError object describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)fetchAllScheduleActionsWithSuccess:(void (^)(NSArray AYLA_GENERIC(AylaScheduleAction *) *scheduleActions))successBlock
                                                      failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves any existing `AylaScheduleAction` objects for this schedule that match the specified name.
 *
 * @param name         The name of the actions to retrieve.
 * @param successBlock   A block to be called if the request is successful. Passed an `NSArray` containing the retrieved `AylaScheduleAction`
 * objects (if any) as returned by the cloud.
 * @param failureBlock   A block to be called if the request fails. Passed an `NSError` object describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)fetchScheduleActionsByName:(NSString *)name
                                              success:(void (^)(NSArray AYLA_GENERIC(AylaScheduleAction *) *scheduleActions))successBlock
                                              failure:(void (^)(NSError *error))failureBlock;

/**
 * Updates existing `AylaScheduleActions` for this schedule, this method will generate a separate API Call for each element in the 
 * `scheduleActionsToUpdate` array, success block will be called only if all updates succeed, if one or more fail, failure block
 *  will be called with a `userInfo` dictionary containing two keys: AylaRequestErrorBatchErrorsKey` and `AylaRequestErrorCompletedItemsKey` 
 *  with the items that failed and succeeded respectively.
 *
 * @param scheduleActionsToUpdate An `NSArray` containing the locally modified `AylaScheduleAction` objects to be updated on the cloud.
 * @param successBlock   A block to be called if the request is successful. Passed an `NSArray` containing the updated 
 * `AylaScheduleAction` objects (if any) as returned by the cloud.
 * @param failureBlock   A block to be called if the request fails. Passed an `NSError` object describing the failure.
 */
- (void)updateScheduleActions:(NSArray AYLA_GENERIC(AylaScheduleAction *) *)scheduleActionsToUpdate
                      success:(void (^)(NSArray AYLA_GENERIC(AylaScheduleAction *) *updatedScheduleActions))successBlock
                      failure:(void (^)(NSError *error))failureBlock;

/**
 * Create a new action for this schedule
 *
 * @param scheduleActionToCreate The `AylaScheduleAction` to be created on the cloud.
 * @param successBlock   A block to be called if the request is successful. Passed the newly created `AylaScheduleAction` object as
 * returned from the cloud.
 * @param failureBlock   A block to be called if the request fails. Passed an `NSError` object describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)createScheduleAction:(AylaScheduleAction *)scheduleActionToCreate
                                        success:(void (^)(AylaScheduleAction *createdScheduleAction))successBlock
                                        failure:(void (^)(NSError *error))failureBlock;

/**
 * Removes an existing action for this schedule from the cloud.
 *
 * @param scheduleAction The `AylaScheduleAction` to be removed.
 * @param successBlock   A block to be called if the request is successful.
 * @param failureBlock   A block to be called if the request fails. Passed an `NSError` object describing the failure.
 *
 * @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)deleteScheduleAction:(AylaScheduleAction *)scheduleAction
                                        success:(void (^)())successBlock
                                        failure:(void (^)(NSError *error))failureBlock;

/**
 * Removes all existing `AylaScheduleAction` objects for this schedule from the cloud.
 *
 * @param successBlock   A block to be called if the request is successful.
 * @param failureBlock   A block to be called if the request fails. Passed an `NSError` object describing the failure.
 */
- (void)deleteAllScheduleActionsWithSuccess:(void (^)())successBlock
                                    failure:(void (^)(NSError *error))failureBlock;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
