//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"
#import "AylaShare.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * The object representing that which 'grants' an `AylaUser` control over another user's device
 * @sa AylaShare
 */
@interface AylaGrant : AylaObject
/** @name Grant Properties */

/**  The user ID of the receiving user, the one to whom access is granted. Returned by
 * create/POST & update/PUT operations
 */
@property (nonatomic, strong, readonly) NSString *userId;

/**  The unique share id associated with this grant */
@property (nonatomic, strong, readonly, nullable) NSString *shareId;

/**  Access permissions allowed: either read or write. Used with create/POST & update/PUT operations. */
@property (nonatomic, assign, readonly) AylaShareOperation operation;

/**  When this named resource will begin to be shared. Used with create/POST & update/PUT operations. 
 * Ex: '2014-03-17 12:00:00'
 */
@property (nonatomic, strong, readonly) NSDate *startDate;

/**  When this named resource will stop being shared. Used with create/POST & update/PUT operations. Ex: '2020-03-17
 * 12:00:00', Optional. If omitted, the resource will be shared until the share or named resource is deleted. UTC
 * DateTime value 
 */
@property (nonatomic, strong, readonly, nullable) NSDate *endDate;

/** Role the share was created with. */
@property (nonatomic, strong, readonly, nullable) NSString *role;
@end
NS_ASSUME_NONNULL_END