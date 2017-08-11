//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"
NS_ASSUME_NONNULL_BEGIN
/**
 * Describes a role that may be used for Role Based Access Control (RBAC)
 */
@interface AylaRole : AylaObject

/** The role name */
@property (strong, nonatomic) NSString *name;
@end
NS_ASSUME_NONNULL_END