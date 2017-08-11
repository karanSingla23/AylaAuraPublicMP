//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * Contains all the attributes of a user registered on the Ayla Cloud
 */
@interface AylaUser : AylaObject

/** @name User Properties */
/** User's email address */
@property (nonatomic, copy) NSString *email;

/** User's password for registration */
@property (nonatomic, copy) NSString *password;

/** User's first name */
@property (nonatomic, copy) NSString *firstName;

/** User's last name */
@property (nonatomic, copy) NSString *lastName;

/** User's country code in phone number */
@property (nonatomic, copy, nullable) NSString *phoneCountryCode;

/** User's phone number */
@property (nonatomic, copy, nullable) NSString *phone;

/** User's company name */
@property (nonatomic, copy, nullable) NSString *company;

/** User's address - street address */
@property (nonatomic, copy, nullable) NSString *street;

/** User's address - city */
@property (nonatomic, copy, nullable) NSString *city;

/** User's address - state/province */
@property (nonatomic, copy, nullable) NSString *state;

/** User's address - zip code/postal code */
@property (nonatomic, copy, nullable) NSString *zip;

/** User's address - country */
@property (nonatomic, copy, nullable) NSString *country;

/** User's Ayla Development Kit number */
@property (nonatomic, copy, nullable) NSNumber *devKitNum;

/** NSDate at which this user account was created */
@property (nonatomic, copy, nullable) NSDate *createdAt;

/** If terms & conditions has been accepted by user. */
@property (nonatomic, assign) BOOL termsAccepted;

/** @name Initializer Methods */
/**
 * Initializes the `AylaUser` with the minimal fields required for registration or updating information.
 *
 * @param email     The email of the user
 * @param password  The password of the new account. Optional while updating account
 * @param firstName The first name of the user
 * @param lastName  The last name of the user
 *
 * @return An initialized `AylaUser` instance to be used in Sign Up.
 * @sa `[AylaLoginManager signUpWithUser:emailTemplate:success:failure:]`
 */
- (instancetype)initWithEmail:(NSString *)email
                     password:(nullable NSString *)password
                    firstName:(NSString *)firstName
                     lastName:(NSString *)lastName;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END