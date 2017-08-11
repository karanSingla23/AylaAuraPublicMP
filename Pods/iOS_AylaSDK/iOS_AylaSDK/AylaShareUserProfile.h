//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * Describes the profile of an `AylaUser` sharing a resource
 */
@interface AylaShareUserProfile : AylaObject
/**
 * The first name of the user
 */
@property (nonatomic, readonly) NSString *firstName;
/**
 * The last name of the user
 */
@property (nonatomic, readonly) NSString *lastName;
/**
 * The registered email of the user
 */
@property (nonatomic, readonly) NSString *email;
@end
NS_ASSUME_NONNULL_END