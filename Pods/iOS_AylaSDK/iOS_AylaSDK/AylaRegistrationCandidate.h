//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN
/**
 Represents an `AylaDevice` before it is registered. When registering a candidate its `registrationType` must be
 considered in order to obtain an `AylaRegistrationCandidate`. See the documentation on `AylaRegistration` to get more
 details on how to register a candidate.
 */
@interface AylaRegistrationCandidate : NSObject

/**
 * Initialize an AylaRegistrationCandidate based on an NSDictionary of its intended attibutes.
 * @param dictionary An NSDictionary of the `AylaRegistrationCandidate`'s intended attibutes
 * @return An initialized `AylaRegistrationCandidate` object.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * The timestamp for the time the device last connected to the Ayla Cloud.
 */
@property (nonatomic, readonly, nullable) NSString *connectedAt;

/**
 * The device type of the candidate device
 */
@property (nonatomic, readonly, nullable) NSString *deviceType;

/**
 * The DSN of the candidate device
 */
@property (nonatomic, nullable) NSString *dsn;

/**
 * The candidate's local LAN IP address.
 */
@property (nonatomic, nullable) NSString *lanIp;

/** 
 * Optional Latitude coordinate for the device's physical location
 */
@property (strong, nonatomic, nullable) NSString *lat;

/** 
 * Optional Longitude coordinate for the device's physical location
 */
@property (strong, nonatomic, nullable) NSString *lng;

/**
 * The model of the candidate
 */
@property (nonatomic, readonly, nullable) NSString *model;

/**
 * The OEM model of the candidate
 */
@property (nonatomic, readonly, nullable) NSString *oemModel;

/**
 * The Product Class of the candidate
 */
@property (nonatomic, readonly, nullable) NSString *productClass;

/**
 * The name of the candidate.
 */
@property (nonatomic, readonly, nullable) NSString *productName;


/**
 * Set the registration token in this property, this token is automatically fetched when using
 * `AylaRegistrationTypeSameLan` and `AylaRegistrationTypeButtonPush`; when using `AylaRegistrationTypeDisplay` you must
 * set it to the token shown in the device display.
 */
@property (strong, nonatomic, nullable) NSString *registrationToken;

/**
 * Setup token is set by the library after a successful WiFi setup.
 */
@property (strong, nonatomic, nullable) NSString *setupToken;

/**
 * The registration type determines what parameters are necessary and then sent to the Ayla Cloud to register, see
 * `AylaRegistrationType` for descriptions of the differenty types and `AylaRegistration` or a description of how to
 * properly configure this candidate with a specific `AylaRegistrationType`
 */
@property (readwrite, nonatomic) AylaRegistrationType registrationType;

@end
NS_ASSUME_NONNULL_END
