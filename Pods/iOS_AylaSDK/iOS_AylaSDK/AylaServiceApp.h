//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//
@class AylaContact;

#import <Foundation/Foundation.h>

#import "AylaEmailTemplate.h"
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * Supported Service App Types
 */
typedef NS_ENUM(NSInteger, AylaServiceAppType) {
    /**
     * Unknown Service App Type
     */
    AylaServiceAppTypeUnknown = -1,
    /**
     * Email App Type
     */
    AylaServiceAppTypeEmail = 0,
    /**
     * SMS App Type
     */
    AylaServiceAppTypeSMS,
    /**
     * Push Notification App Type
     */
    AylaServiceAppTypePush,
    /**
     * Android push Notification App Type
     */
    AylaServiceAppTypePushAndroid,
    /**
     * Baidu push Notification App Type
     */
    AylaServiceAppTypePushBaidu,
};

/**
 Abstract classs for Applications performed by the service.
 */
@interface AylaServiceApp : AylaObject

/**
 The type of the application
 */
@property (nonatomic, readwrite) AylaServiceAppType type;

/**
 The ID of the receiving contact. If you specify a contact, do not specify parts of the contact's data individually.
 */
@property (nonatomic, strong, nullable) NSNumber *contactId;
/**
 The username of the contact
 */
@property (nonatomic, strong) NSString *username;
/** 
 Nickname of the AylaServiceApp to identify it. 
 */
@property (nonatomic, strong) NSString *nickname;
/**
 A message to be sent by the Application
 */
@property (nonatomic, strong) NSString *message;
/**
 The email of the receiver, do not specify this property if you specify a `contactId.
 */
@property (nonatomic, strong, nullable) NSString *email;
/**
  The template to be used with the email, required if the `type` is `AylaServiceAppTypeEmail`
 */
@property (nonatomic, strong, nullable) AylaEmailTemplate *emailTemplate;
/**
 The country code of the `phoneNumber` to send the SMS. Do not specify this property if you specify a `contactId.
 */
@property (nonatomic, strong, nullable) NSString *countryCode;
/**
 The phone number including area code of the receiver of the app. Do not specify this property if you specify a
 `contactId.
 */
@property (nonatomic, strong, nullable) NSString *phoneNumber;
/**
 The registration ID of the push notification. Required if `type` is `AylaServiceAppTypePush`.
 */
@property (nonatomic, strong, nullable) NSString *registrationId;
/**
 The application ID of the push notification. Required if `type` is `AylaServiceAppTypePush`.
 */
@property (nonatomic, strong, nullable) NSString *applicationId;
/**
 A custom alert sound emitted by the phone when the Push notification is received. Optional, used only if `type` is `AylaServiceAppTypePush`.
 */
@property (nonatomic, strong, nullable) NSString *pushSound;
/**
 Metadata to include with the Push notification. Optional.
 */
@property (nonatomic, strong, nullable) NSString *pushMetaData;
/**
 The NSDate at the moment the app was last fetched.
 */
@property (nonatomic, strong, readonly) NSDate *retrievedAt;

/**
 * Converts an `NSString` to its corresponding `AylaNotificationType`
 *
 * @param notificationName The NSString containing the `AylaNotificationType` name.
 *
 * @return The corresponding `AylaNotificationType`
 */
+ (AylaServiceAppType)notificationTypeFromName:(NSString *)notificationName;

/**
 * Converts an `AylaNotificationType` into its corresponding `NSString` representation
 *
 * @param type The `AylaNotificationType` to convert to `NSString` form
 *
 * @return An `NSString` representation of the `AylaNotificationType` name.
 */
+ (NSString *)notificationNameFromType:(AylaServiceAppType)type;

/**
 * Configures the receiver as `AylaServiceAppTypeSMS` for the specified `AylaContact` and `message`
 *
 * @param contact The `AylaContact` that will receive the SMS message
 * @param message The content of the SMS message the app will send
 */
- (void)configureAsSMSFor:(AylaContact *)contact message:(NSString *)message;

/**
 * Configures the receiver as `AylaServiceAppTypeEmail` for the specified AylaContact, message content, and an `AylaEmailTemplate` with
 * which to format any resulting email.
 *
 * @param contact       The `AylaContact` that will receive the email message.
 * @param message       The content of the email message the app will send.
 * @param username      A custom string to be sustituted for the `[[user_name]]` tag, if used, in the `emailTemplate` or `message`.
 * `AylaContact.firstName` or `AylaContact.displayName` may be a good source of this parameter.
 * @param emailTemplate An `AylaEmailTemplate` with the format specifications of the email.
 */
- (void)configureAsEmailfor:(AylaContact *)contact
                    message:(NSString *)message
                   username:(nullable NSString *)username
                   template:(nullable AylaEmailTemplate *)emailTemplate;

/**
 * Configures the receiver as `AylaServiceAppTypePush` with the specified parameters.
 *
 * @param message        The content of the Push Notification message.
 * @param registrationId The registration ID of the phone.
 * @param applicationId  The app ID for the push notification.
 * @param pushSound      The name of a custom alert sound the phone should emit when the notification is received. Pass nil to 
 * use the default sound.
 * @param pushMetadata   The metadata to include with the push notification or nil is not metadata is required.
 */
- (void)configureAsPushWithMessage:(NSString *)message
                    registrationId:(NSString *)registrationId
                     applicationId:(NSString *)applicationId
                         pushSound:(NSString *)pushSound
                      pushMetaData:(nullable NSString *)pushMetadata;
@end

FOUNDATION_EXPORT NSString *const kAylaNotificationTypeEmail;
FOUNDATION_EXPORT NSString *const kAylaNotificationTypeSMS;
FOUNDATION_EXPORT NSString *const kAylaNotificationTypePush;
FOUNDATION_EXPORT NSString *const kAylaNotificationTypePushAndroid;
FOUNDATION_EXPORT NSString *const kAylaNotificationTypePushBaidu;
NS_ASSUME_NONNULL_END
