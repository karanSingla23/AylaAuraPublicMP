//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaObject.h"
@class AylaDevice;
@class AylaHTTPTask;
@class AylaDeviceNotificationApp;

/**
 Describes supported Device notification types.
 */
typedef NS_ENUM(NSInteger, AylaDeviceNotificationType) {
    /**
     Unknown notification type
     */
    AylaDeviceNotificationTypeUnknown = -1,
    /**
     Notification triggered when the device connects to the Ayla Cloud
     */
    AylaDeviceNotificationTypeOnConnect = 0,
    /**
     Notification triggered when the device changes its IP address.
     */
    AylaDeviceNotificationTypeIPChange,
    /**
     Notification triggered when the device loses its connection to the Service
     */
    AylaDeviceNotificationTypeOnConnectionLost,
    /**
     Notification triggered when the connection to the Service is restored
     */
    AylaDeviceNotificationTypeOnConnectionRestore
};
NS_ASSUME_NONNULL_BEGIN
/**
 `AylaDeviceNotification` describes an `AylaDevice` condition under which a notification will be triggered. You need to
 `createApp:success:failure:` with an `AylaDeviceNotificationApp` to specify what kind of notification you'd like to
 get.
 */
@interface AylaDeviceNotification : AylaObject

/** @name Device Notification Properties */

/** Notification type. @see `AylaDeviceNotificationType` */
@property (nonatomic, assign) AylaDeviceNotificationType type;

/** A nickname for the associated device. */
@property (nonatomic, strong) NSString *deviceNickname;

/** The number of seconds for which the condition must be active before notification is sent. Minimum is 300 seconds. */
@property (nonatomic, assign) NSUInteger threshold;

/** Complete URL to which the property value must be forwarded. (only for on_connect and ip_change types) */
@property (nonatomic, strong) NSString *url;

/** Username for basic authoriation if required for the service. */
@property (nonatomic, strong) NSString *username;

/** Password for basic auth required for the service. */
@property (nonatomic, strong) NSString *password;

/** Custom message for this notification type along default message. */
@property (nonatomic, strong) NSString *message;

/** Device associated with the notification */
@property (nonatomic, weak) AylaDevice *device;

/** @name Notification App Methods */

/**
 * Converts an `AylaDeviceNotificationType` into its corresponding `NSString` representation
 *
 * @param notificationType The `AylaDeviceNotificationType` to convert to `NSString` form
 *
 * @return An `NSString` representation of the `AylaDeviceNotificationType` name.
 */
+ (NSString *)deviceNotificationNameFromType:(AylaDeviceNotificationType)notificationType;

/**
 * Converts an `NSString` to its corresponding `AylaDeviceNotificationType`
 *
 * @param notificationName The NSString containing the `AylaDeviceNotificationType` name.
 *
 * @return The corresponding `AylaDeviceNotificationType`
 */
+ (AylaDeviceNotificationType)deviceNotificationTypeFromName:(NSString *)notificationName;

/**
 * Creates an `AylaDeviceNotificationApp`, first you must create a new instance (`[[AylaDeviceNotificationApp alloc]
 * init]`), configure its properties individually or preferrably use a configure method like `configureAsSMSFor:message:`
 *
 * @param app          The App to create in the cloud
 * @param success      A block called when the app has been created in the cloud. Passed the newly created `AylaDeviceNotificationApp` object.
 * @param failureBlock A block called when the app could not be created in the cloud. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`.
 */
- (nullable AylaHTTPTask *)createApp:(AylaDeviceNotificationApp *)app
                             success:(void (^)(AylaDeviceNotificationApp *createdApp))success
                             failure:(void (^)(NSError *error))failureBlock;
/**
 * Fetches the existing `AylaDeviceNotificationApp` from the cloud for the receiver.
*
 * @param successBlock A block called when the method fetches the `NSArray` of `AylaDeviceNotificationApp`.
 * @param failureBlock A block called when the method fails to fetch the `NSArray` of `AylaDeviceNotificationApp`.
 *
 * @return A started `AylaHTTPTask`.
 */
- (nullable AylaHTTPTask *)fetchApps:(void (^)(NSArray AYLA_GENERIC(AylaDeviceNotificationApp *) * apps))successBlock
                             failure:(void (^)(NSError *error))failureBlock;
/**
 *Updates the specified `AylaDeviceNotificationApp` in the cloud with the changes in it.
 *
 * @param app          The locally modified`AylaDeviceNotificationApp` to update in the cloud.
 * @param success      A block called when the `AylaDeviceNotificationApp` has been successfully updated. Passed the 
 * updated `AylaDeviceNotificationApp` object.
 *
 * @param failureBlock A block called when the App could not be updated. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */
- (nullable AylaHTTPTask *)updateApp:(AylaDeviceNotificationApp *)app
                             success:(void (^)(AylaDeviceNotificationApp *updatedApp))success
                             failure:(void (^)(NSError *error))failureBlock;
/**
 * Deletes the specified `AylaDeviceNotificationApp` from the cloud.
 *
 * @param app          The `AylaDeviceNotificationApp` to be deleted.
 * @param success      A block called when the `AylaDeviceNotificationApp` has been successfully deleted.
 * @param failureBlock A block called when the `AylaDeviceNotificationApp` could not be deleted. Passed an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */
- (nullable AylaHTTPTask *)deleteApp:(AylaDeviceNotificationApp *)app
                             success:(void (^)())success
                             failure:(void (^)(NSError *error))failureBlock;
@end
NS_ASSUME_NONNULL_END
