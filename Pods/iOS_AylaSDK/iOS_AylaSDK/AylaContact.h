//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const AylaContactAcceptNotReq;
FOUNDATION_EXPORT NSString * const AylaContactAcceptReq;
FOUNDATION_EXPORT NSString * const AylaContactAcceptPending;
FOUNDATION_EXPORT NSString * const AylaContactAcceptAccepted;
FOUNDATION_EXPORT NSString * const AylaContactAcceptDenied;
/**
 Represents a contact to be used with `AylaDeviceNotificationApp` or `AylaPropertyTriggerApp`
 */
@interface AylaContact : AylaObject

/** @name Contact Properties */

/** Contact ID */
@property (nonatomic, strong, readonly) NSNumber *id;

/** Contact first name */
@property (nonatomic, strong) NSString *firstName;

/** Contact last name */
@property (nonatomic, strong) NSString *lastName;

/** Contact display name */
@property (nonatomic, strong, nullable) NSString *displayName;

/** Contact email address */
@property (nonatomic, strong, nullable) NSString *email;

/** Contact phone number's country code */
@property (nonatomic, strong, nullable) NSString *phoneCountryCode;

/** Contact phone number */
@property (nonatomic, strong, nullable) NSString *phoneNumber;

/** Contact address - street address */
@property (nonatomic, strong, nullable) NSString *streetAddress;

/** Contact address - ZIP code / Postal Code */
@property (nonatomic, strong, nullable) NSString *zipCode;

/** Contact address - country */
@property (nonatomic, strong, nullable) NSString *country;

/** Status of email notification accceptance. Could be one of followings: AylaContactAcceptNotReq, AylaContactAcceptReq,
 * AylaContactAcceptPending, AylaContactAcceptAccepted, AylaContactAcceptDenied */
@property (nonatomic, strong, nullable) NSString *emailAccept;

/** If email notifications have been enabled for current contact. */
@property (nonatomic, assign) BOOL emailNotification;

/** Status of SMS notification accestance. Could be one of followings: AylaContactAcceptNotReq, AylaContactAcceptReq,
 * AylaContactAcceptPending, AylaContactAcceptAccepted, AylaContactAcceptDenied */
@property (nonatomic, strong, nullable) NSString *smsAccept;

/** If SMS notifications have been enabled for current contact. */
@property (nonatomic, assign) BOOL smsNotification;

/** If Push notifications have been enabled for current contact. */
@property (nonatomic, assign) BOOL pushNotification;

/** Contact metadata */
@property (nonatomic, strong, nullable) NSString *metadata;

/** Contact notes */
@property (nonatomic, strong, nullable) NSString *notes;

/** Array of devices' OEM Models */
@property (nonatomic, strong, nullable) NSArray *oemModels;

/** Last update time */
@property (nonatomic, strong, readonly) NSString *updatedAt;

@end
NS_ASSUME_NONNULL_END