//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaHTTPTask.h"
#import "AylaLanSupportDevice.h"
#import "AylaObject.h"
#import "AylaShare.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AylaChange;
@class AylaDatum;
@class AylaDevice;
@class AylaDeviceManager;
@class AylaDeviceNotification;
@class AylaGrant;
@class AylaProperty;
@class AylaSchedule;
@class AylaTimeZone;

/**
 *  Device listener protocol
 */
@protocol AylaDeviceListener <NSObject>

/**
 *  Called when a device's status has changed. This includes property changes,
 * device changes, etc.
 *
 *  @param device The `AylaDevice` that had changes.
 *  @param change The `AylaChange` object representing the device change.
 */
- (void)device:(AylaDevice *)device didObserveChange:(AylaChange *)change;

/**
 *  Called whenever an error has occured for the current device.
 *
 *  @param device The `AylaDevice` that encountered the error.
 *  @param error `NSError` encountered on this device.
 */
- (void)device:(AylaDevice *)device didFail:(NSError *)error;

@optional
/**
 * Called when LAN state for this device has changed.
 *
 * @param device The `AylaDevice` for which LAN state has changed.
 * @param isActive true if LAN mode is active on the device, false otherwise
 */
- (void)device:(AylaDevice *)device didUpdateLanState:(BOOL)isActive;

@end

/**
 * Describes a device registered to the Ayla Service, including its properties.
 */
@interface AylaDevice : AylaObject <AylaLanSupportDevice>

/** @name Device Properties*/

/** Reference to the `AylaDeviceManager` instance to which this device belongs.
 */
@property(nonatomic, weak, readonly, nullable) AylaDeviceManager *deviceManager;

/** Reference to the AylaSessionManager instance to which this device belongs */
@property(nonatomic, weak, readonly, nullable)
    AylaSessionManager *sessionManager;

/** Device Product Name */
@property(nonatomic, readonly, nullable) NSString *productName;

/** Device Module */
@property(nonatomic, readonly, nullable) NSString *model;

/** Device Serial Number */
@property(nonatomic, readonly, nullable) NSString *dsn;

/** Device OEM Model */
@property(nonatomic, readonly, nullable) NSString *oemModel;

/** Device Type */
@property(nonatomic, readonly, nullable) NSString *deviceType;

/** Last time the device connected to the Ayla Serivce */
@property(nonatomic, readonly, nullable) NSDate *connectedAt;

/** Device MAC address */
@property(nonatomic, readonly, nullable) NSString *mac;

/** Device Local IP Address */
@property(nonatomic, readonly, nullable) NSString *lanIp;

/** Software version running on the device */
@property(nonatomic, readonly, nullable) NSString *swVersion;

/** SSID of the Access Point the device is connected to */
@property(nonatomic, readonly, nullable) NSString *ssid;

/** Device Product Class */
@property(nonatomic, readonly, nullable) NSString *productClass;

/** Public external WAN IP Address */
@property(nonatomic, readonly, nullable) NSString *ip;

/** Is LAN Mode enabled on the service */
@property(nonatomic, readonly, nullable) NSNumber *lanEnabled;

/** Near realtime indicator of device to service connectivity. Values are
 * "Online" or "OffLine" */
@property(nonatomic, readonly, nullable) NSString *connectionStatus;

/** Template ID associated with this device */
@property(nonatomic, readonly, nullable) NSNumber *templateId;

/** Latitude coordinate for the device's physical location */
@property(nonatomic, readonly, nullable) NSString *lat;

/** Longitude coordinate for the device's physical location */
@property(nonatomic, readonly, nullable) NSString *lng;

/** ID nuber of the User who has registered this device */
@property(nonatomic, readonly, nullable) NSNumber *userId;

/** The last time any attribute was updated */
@property(nonatomic, readonly, nullable) NSString *moduleUpdatedAt;

/** Device Properties */
@property(nonatomic, readonly, getter=properties, nullable)
    NSDictionary *properties;

/** If tracking is active for the device */
@property(nonatomic, readonly) BOOL isTracking;

/** Whether LAN mode is currently permitted for this device. */
@property(nonatomic, readwrite) BOOL lanModePermitted;

/** The grant for this device, if one is present. */
@property(nonatomic, readonly, nullable) AylaGrant *grant;

/** The DataSource representing the service used to last update this device
 * status. */
@property(nonatomic, assign, readonly) AylaDataSource lastUpdateSource;

/**
 * Requests a factory reset of the device. If successful, the device will be reset.
 *
 * @param successBlock A block that will be called when the request was sent.
 * @param failureBlock A block that will be called when something goes wrong.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)factoryResetWithSuccess:(void (^)())successBlock
                                           failure:(void (^)(NSError *error))
                                                   failureBlock;

/** @name Device Listener Methods */

/** Add a listener, an object that conforms to the `AylaDeviceListener` protocol
 * @param listener the object that conforms to the `AylaDeviceListener` protocol
 */
- (void)addListener:(id<AylaDeviceListener>)listener;

/** Remove an existing listener, an object that conforms to the
 * `AylaDeviceListener` protocol
 * @param listener the object that conforms to the `AylaDeviceListener` protocol
*/
- (void)removeListener:(id<AylaDeviceListener>)listener;

/** @name Device Methods*/

/**
 * Updates the product name of the receiver.
 *
 * @param newName      The name to assign to the device.
 * @param successBlock A block that will be called when the name has been
 * successfully updated.
 * @param failureBlock A block that will be called when the name couldn't be
 * updated.
 *
 * @return An `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)updateProductNameTo:(NSString *)newName
                                       success:(void (^)())successBlock
                                       failure:(void (^)(NSError *error))
                                                   failureBlock;
/** @name Device Property Methods */

/**
 * Fetches the `AylaProperty` (with latest `AylaDatapoint` values) corresponding
 * to the provided list of property names from the
 * cloud service or over LAN. If all of the provided property names are
 * LAN-enabled and the device is in LAN mode, the properties
 * will be fetched directly from the device. Providing nil will fetch all
 * available properties.
 *
 * @param propertyNames      `NSArray` of names of properties to fetch, or nil
 * to fetch all properties
 * @param successBlock       A block to be called if the request is successful.
 * Passed an `NSArray` containing fetched `AylaProperty` objects.
 * @param failureBlock       A block to be called if the request fails. Passed
 * an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` which represents this request.
 */
- (nullable AylaConnectTask *)
fetchProperties:(nullable NSArray AYLA_GENERIC(NSString *) *)propertyNames
        success:(void (^)(NSArray AYLA_GENERIC(AylaProperty *) *
                          properties))successBlock
        failure:(void (^)(NSError *error))failureBlock;

/**
 * Fetches the provided property values (latest datapoint) from the cloud
 * service. Providing nil will fetch all available properties.
 *
 * @param propertyNames      `NSArray` of names of properties to fetch, or nil
 * to fetch all properties
 * @param successBlock       A block to be called if the request is successful.
 * Passed an `NSArray` containing the fetched `AylaProperty` objects.
 * @param failureBlock       A block to be called if the request fails. Passed
 * an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` which represents this request.
 */
- (nullable AylaConnectTask *)
fetchPropertiesCloud:(nullable NSArray *)propertyNames
             success:
                 (void (^)(NSArray AYLA_GENERIC(AylaProperty *) *))successBlock
             failure:(void (^)(NSError *))failureBlock;

/**
 * Fetches the provided property values (latest datapoint) from the device via
 * the LAN. Providing nil will fetch all available
 * properties.
 *
 * @param propertyNames      `NSArray` of names of properties to fetch, or nil
 * to fetch all properties
 * @param successBlock       A block to be called if the request is successful.
 * Passed an `NSArray` containing the fetched `AylaProperty` objects.
 * @param failureBlock       A block to be called if the request fails. Passed
 * an `NSError` describing the failure.
 *
 * @return An `AylaConnectTask` task which represents this request.
 */
- (nullable AylaConnectTask *)
fetchPropertiesLAN:(NSArray AYLA_GENERIC(NSString *) *)propertyNames
           success:
               (void (^)(NSArray AYLA_GENERIC(AylaProperty *) *))successBlock
           failure:(void (^)(NSError *))failureBlock;
/** @name Device Notification Methods */

/**
* Creates an `AylaDeviceNotification` in the cloud from the data in the passed
* instance.
*
* @param deviceNotification An instance of `AylaDeviceNotification` that was
* created locally.
* @param successBlock       A block to be called when the notification has been
* created successully in the cloud. Passed an
* `AylaDeviceNotification` as created on the Service.
* @param failureBlock       A block to be called when the notification could not
* be created in the cloud. Passed an `NSError` describing the failure.
*
* @return A started `AylaHTTPTask` representing the request.
*/
- (nullable AylaHTTPTask *)
createNotification:(AylaDeviceNotification *)deviceNotification
           success:(void (^)(AylaDeviceNotification *createdNotification))
                       successBlock
           failure:(void (^)(NSError *error))failureBlock;

/**
 *  Fetches the existing `AylaDeviceNotification` for the receiver from the
 * cloud.
 *
 *  @param successBlock A block to be called after the notifications have been
 * successfully retrieved. Passed a non-nil
 * `NSArray` containing zero or more fetched `AylaDeviceNotification` objects.
 *  @param failureBlock A block to be called if the fetch operation fails.
 * Passed an `NSError` describing the failure.
 *
 *  @return A started `AylaHTTPTask` representing the request.
 */

- (nullable AylaHTTPTask *)
fetchNotifications:(void (^)(NSArray AYLA_GENERIC(AylaDeviceNotification *) *
                             notifications))successBlock
           failure:(void (^)(NSError *error))failureBlock;

/**
 * Updates an existing `AylaDeviceNotification` in the cloud.
 *
 * @param deviceNotification An existing `AylaDeviceNotification` that has been
 * modified.
 * @param successBlock       A block to be called if the notification update
 * succeeds. Passed the updated `AylaDeviceNotification`
 * @param failureBlock       A block to be called if the update operation fails.
 * Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */

- (nullable AylaHTTPTask *)
updateNotification:(AylaDeviceNotification *)deviceNotification
           success:(void (^)(AylaDeviceNotification *updatedNotification))
                       successBlock
           failure:(void (^)(NSError *error))failureBlock;

/**
 * Deletes an existing `AylaDeviceNotification` from the cloud.
 *
 * @param deviceNotification An AylaDeviceNotification that was fetched from the
 * cloud, which will be deleted.
 * @param successBlock       A block called when the device notification was
 * successfully deleted.
 * @param failureBlock       A block called when the `AylaDeviceNotification`
 * could not be deleted. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaHTTPTask *)
deleteNotification:(AylaDeviceNotification *)deviceNotification
           success:(void (^)())successBlock
           failure:(void (^)(NSError *error))failureBlock;
/** @name Device Status Methods */

/**
 * Starts tracking for property changes.
 *
 * @return YES if tracking could be started or was already active, false if
 * polling is not permitted on this device.
 */
- (BOOL)startTracking;

/**
 * Stop tracking for property changes.
 *
 * @return YES if tracking could be started or was already active, false if
 * polling is not permitted on this device.
 */
- (void)stopTracking;

/**
 * @return YES if LAN mode is currently active for this device.
 */
- (BOOL)isLanModeActive;

#pragma mark -
#pragma mark AylaDatum
/** @name Device Datum Methods */

/**
 * This method is used to unregister an `AylaDevice`. It unregisters the device
 * from the user account.
 *
 * @param successBlock       A block called when the device was successfully
 * deleted from user account.
 * @param failureBlock       A block called when request fails. Passed an
 * `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
- (nullable AylaConnectTask *)unregisterWithSuccess:(void (^)(void))successBlock
                                            failure:(void (^)(NSError *error))
                                                     failureBlock;

/**
 *  Creates a new datum for this device.
 *
 *  @param key          The key used to uniquely identify the datum.
 *  @param value        The initial value for the datum.
 *  @param successBlock A block to be called if the request is successful.
 * Passed the newly created `AylaDatum` object.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
createAylaDatumWithKey:(NSString *)key
                 value:(NSString *)value
               success:(void (^)(AylaDatum *createdDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves an existing datum object for this device based on the input key.
 *
 *  @param key The key of the datum object to retrieve.
 *  @param successBlock A block to be called if the request is successful.
 * Passed the fetched `AylaDatum` object.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAylaDatumWithKey:(NSString *)key
              success:(void (^)(AylaDatum *datum))successBlock
              failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves existing datum objects for this device corresponding to the input
 * keys.
 *
 *  @param keys         An array of the keys of the datum objects to retrieve.
 * If nil, retrieves all datum objects.
 *  @param successBlock A block to be called with the retrieved datum objects
 * when the request is successful. Passed a non-nil `NSArray` containing zero or
 * more fetched `AylaDatum` objects.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAylaDatumsWithKeys:(nullable NSArray AYLA_GENERIC(NSString *) *)keys
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves existing datum objects for this device based on a wildcard match.
 *
 *  @param wildcardedString A string where the `%` character defines wild cards
 * before or after the text to match in the datum key
 *  @param successBlock A block to be called when the request is successful.
 * Passed a non-nil `NSArray` containing the fetched AylaDatum objects.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAylaDatumsMatching:(NSString *)wildcardedString
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves all existing datum objects for this device.
 *
 *  @param successBlock A block to be called when the request is successful.
 * Passed a non-nil `NSArray` containing the fetched `AylaDatum `objects.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAllAylaDatumsWithSuccess:
    (void (^)(NSArray AYLA_GENERIC(AylaDatum *) * datums))successBlock
                      failure:(void (^)(NSError *error))failureBlock;

/**
 * Updates an existing datum object for this device.
 *
 *  @param key          The key of the datum to be updated.
 *  @param value      The new value to assign to the datum.
 *  @param successBlock A block to be called when the request is successful.
 * Passed the updated `AylaDatum` object.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
updateAylaDatumWithKey:(NSString *)key
               toValue:(NSString *)value
               success:(void (^)(AylaDatum *updatedDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock;

/**
 * Removes an existing datum object for this device.
 *
 *  @param key          The key of the datum to be removed.
 *  @param successBlock A block which will be called when the delete request is
 * successful.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)deleteAylaDatumWithKey:(NSString *)key
                                          success:(void (^)())successBlock
                                          failure:(void (^)(NSError *error))
                                                      failureBlock;

#pragma mark -
#pragma mark AylaSchedule
/** @name Schedule Methods */

/**
 *  Retrieves all the schedules for this device.
 *
 *  @param successBlock A block to be called when the request is successful.
 * Passed a non-nil NSArray containing the fetched `AylaSchedule` objects (if
 * any).
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchAllSchedulesWithSuccess:
    (void (^)(NSArray AYLA_GENERIC(AylaSchedule *) * schedules))successBlock
                     failure:(void (^)(NSError *error))failureBlock;

/**
 * Retrieves an existing schedule object for this device based on the provided
 * name.
 *
 *  @param scheduleName The name of the schedule to retrieve
 *  @param successBlock A block to be called when the request is successful.
 * Passed a the fetched `AylaSchedule` objects.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchScheduleByName:(NSString *)scheduleName
            success:(void (^)(AylaSchedule *schedule))successBlock
            failure:(void (^)(NSError *error))failureBlock;

/**
 * Updates a schedule for this device.
 *
 *  @param scheduleToUpdate The schedule set with updated values.
 *  @param successBlock A block to be called when the request is successful.
 * Passed the updated `AylaSchedule` object.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
updateSchedule:(AylaSchedule *)scheduleToUpdate
       success:(void (^)(AylaSchedule *updatedSchedule))successBlock
       failure:(void (^)(NSError *error))failureBlock;

/**
 * Convenience method to enable a schedule for this device.
 *
 *  @param scheduleToEnable The schedule to enable
 *  @param successBlock A block to be called when the request is successful.
 * Passed the enabled `AylaSchedule` object.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
enableSchedule:(AylaSchedule *)scheduleToEnable
       success:(void (^)(AylaSchedule *enabledSchedule))successBlock
       failure:(void (^)(NSError *error))failureBlock;

/**
 *  Convenience method to disable a schedule for this device.
 *
 *  @param scheduleToDisable The schedule to disable
 *  @param successBlock A block to be called when the request is successful.
 * Passed the disabled `AylaSchedule` object.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
disableSchedule:(AylaSchedule *)scheduleToDisable
        success:(void (^)(AylaSchedule *disabledSchedule))successBlock
        failure:(void (^)(NSError *error))failureBlock;

#pragma mark -
#pragma mark AylaShare
/** @name Sharing Methods */

/**
 * Helper method to initialize an instance of `AylaShare` with the provided
 * parameters; the returned object can be used
 * with `[AylaSessionManager createShare:emailTemplate:success:failure:]` to
 * create the share in the cloud.
 *
 * @param email     The email of an existing user who will receive the share.
 * @param roleName  The full name of the user role with which the device will be
 * shared (ex. 'OEM::Ayla::Owner'). The targeted user will
 * have this role.
 * @param operation An `AylaShareOperation` option, indicating the permissions
 * (read or read/write) of the receiver.
 * @param startAt   The `NSDate` when the sharing will begin
 * @param endAt     The `NSDate` when the sharing will end
 *
 * @return An initialized instance of `AylaShare` that can be used to create a
 * share in the cloud.
 */
- (AylaShare *)aylaShareWithEmail:(NSString *)email
                         roleName:(nullable NSString *)roleName
                        operation:(AylaShareOperation)operation
                          startAt:(nullable NSDate *)startAt
                            endAt:(nullable NSDate *)endAt;

/**
 * Fetches any existing shares of the device.
 *
 * @param expired      Indicates whether to fetch expired or valid shares.
 * @param accepted     Indicates whether to fetch accepted or unaccepted shares.
 * @param successBlock A block to be called if the request was successful.
 * Passed an `NSArray` containing the fetched `AylaShare` objects
 * @param failureBlock A block to be called if the fetch request fails. Passed
 * an `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchSharesWithExpired:(BOOL)expired
              accepted:(BOOL)accepted
               success:
                   (void (^)(NSArray<AylaShare *> *_Nonnull shares))successBlock
               failure:(void (^)(NSError *_Nonnull error))failureBlock;

#pragma mark -
#pragma mark AylaTimeZone
/** @name Device Time Zone Methods */

/**
 *  Fetch the time zone for this device.
 *
 *  @param successBlock A block to be called if the request was successful.
 * Passed the fetched `AylaTimeZone`
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
fetchTimeZoneWithSuccess:(void (^)(AylaTimeZone *timeZone))successBlock
                 failure:(void (^)(NSError *error))failureBlock;

/**
 *  Updates the time zone for this device.
 *
 *  @param tzID   Standard time zone identifier string (e.g.
 * "America/Los_Angeles")
 *  @param successBlock A block to be called if the request was successful.
 * Passed the updated `AylaTimeZone`.
 *  @param failureBlock A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)
updateTimeZoneTo:(NSString *)tzID
         success:(void (^)(AylaTimeZone *timeZone))successBlock
         failure:(void (^)(NSError *error))failureBlock;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

@end

@interface AylaDevice (NSCoding) <NSCoding>

@end

@interface AylaDevice (Deprecations)

/**
 *  Removes an existing schedule for this device (but only from the cloud).
 *
 *  @param schedule       The schedule to be removed.
 *  @param successBlock   A block to be called when the delete request is
 * successful.
 *  @param failureBlock   A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)deleteSchedule:(AylaSchedule *)schedule
                                  success:(void (^)())successBlock
                                  failure:(void (^)(NSError *error))failureBlock
DEPRECATED_MSG_ATTRIBUTE("Deleting schedules is not supported, change them from the template");

/**
 *  Creates a new schedule for this device (but only on the cloud).
 *
 *  @param scheduleToCreate The schedule to be created.
 *  @param successBlock     A block to be called when the request is successful.
 * Passed the created `AylaSchedule` object.
 *  @param failureBlock     A block to be called if the request fails. Passed an
 * `NSError` describing the failure.
 *
 *  @return The `AylaHTTPTask` that was spawned.
 */
- (nullable AylaHTTPTask *)createSchedule:(AylaSchedule *)scheduleToCreate
                                  success:(void (^)(AylaSchedule *createdSchedule))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
DEPRECATED_MSG_ATTRIBUTE("Creating schedules is not supported, change them from the template");
@end
NS_ASSUME_NONNULL_END
