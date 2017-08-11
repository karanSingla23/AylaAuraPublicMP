//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
/**
 Represents a template for sending emails on the Ayla Service. Templates are used when a notification is sent to an email address.
 */
@interface AylaEmailTemplate : AylaObject

/** @name Email Template Properties */
/** The ID the template has in Ayla Dashboard. */
@property (nonatomic, strong) NSString *id;

/** The subject of the email. */
@property (nonatomic, strong, nullable) NSString *subject;

/** The HTML Body of the email that will be replaced if the template has a tag to replace it with this value. */
@property (nonatomic, strong, nullable) NSString *bodyHTML;

/** @name Initializer Methods */

/**
 * Initializes the instance with the specified paramters.
 *
 * @param id       The id of the Template in the cloud.
 * @param subject  The subject of the email.
 * @param bodyHTML An optional `NSString` to be replaced in the Body HTML tag in the template.
 *
 * @return An initialized `AylaEmailTemplate` instance.
 */
- (instancetype)initWithId:(NSString *)id subject:(nullable NSString *)subject bodyHTML:(nullable NSString *)bodyHTML;


/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END