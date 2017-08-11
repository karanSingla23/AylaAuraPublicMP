//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"
#import "AylaRole.h"
#import "AylaShareUserProfile.h"
/**
 * Enumerates the operations allowed to be performed by the `AylaShare` receiver
 */
typedef NS_ENUM(NSInteger, AylaShareOperation) {
    /** No Allowed Operation Specified */
    AylaShareOperationNone = 0,
    /**
     * Allows reading operation
     */
    AylaShareOperationReadOnly,
    /**
     * Allows reading and writing operations
     */
    AylaShareOperationReadAndWrite
};

NS_ASSUME_NONNULL_BEGIN
extern NSString *const AylaShareResourceNameDevice;
/**
 * Represents a resource (such as an `AylaDevice`) that is shared with another user.
 *
 * To share a resource with another account, an `AylaShare` object must be initialized with the
 * `initWithEmail:resourceName:resourceId:roleName:operation:startAt:endAt:` method or a helper method such as
 * `[AylaDevice aylaShareWithEmail:roleName:operation:startAt:endAt:]` and then created with
 * the `[AylaSessionManager createShare:emailTemplate:success:failure:]` method.
 */
@interface AylaShare : AylaObject

/** @name Share Properties */

/** The unique share ID, for this share, assigned by the cloud. */
@property (nonatomic, strong, readonly) NSString *id;

/** Indicates whether the share has been accepted by the recipient */
@property (nonatomic, assign, readonly) BOOL accepted;

/** The `NSDate` at which the share was accepted by the recipient */
@property (nonatomic, strong, readonly) NSDate *acceptedAt;

/** The unique grant ID associated with this share */
@property (nonatomic, strong, readonly) NSString *grantId;

/** Name of the resource class being shared. Ex: 'device', Required for creation. */
@property (nonatomic, strong, readonly) NSString *resourceName;

/** Unique identifier for the resource name being shared. For example, a DSN: 'AC000W0000001234'. Required for creation. */
@property (nonatomic, strong, readonly) NSString *resourceId;

/** The full name of the user role with which the device will be shared (ex. 'OEM::Ayla::Owner'). The targeted user will have this role.
 * You can specify either a role or an operation, not both. */
@property (nonatomic, strong, nullable) NSString *roleName;

/** Role (retrieved from service) */
@property (nonatomic, strong, readonly) AylaRole *role;

/** The target user id that created this share. Returned with create/POST & update/PUT operations */
@property (nonatomic, strong, readonly) NSString *userId;

/** The owner user id that created this share. Returned with create/POST & update/PUT operations */
@property (nonatomic, strong, readonly) NSString *ownerId;

/** Unique email address of the Ayla registered target user to share the named resource with, Required */
@property (nonatomic, strong, readonly) NSString *userEmail;

/** The owner of a shared resource info */
@property (nonatomic, strong, readonly) AylaShareUserProfile *ownerProfile;

/** The user of a shared resource info */
@property (nonatomic, strong, readonly) AylaShareUserProfile *userProfile;

/** Access permissions allowed: either `AylaShareOperationReadOnly` or `AylaShareOperationReadAndWrite`. Used with
 * create/POST & update/PUT operations. If none is specified (`AylaShareOperationNone`), the default access permitted is read only.
 * You can specify either a role or an operation, but not both.
 */
@property (nonatomic, assign) AylaShareOperation operation;

/** The `NSDate` at which this object was created. Returned with create/POST & update/PUT operations */
@property (nonatomic, strong, readonly) NSDate *createdAt;

/** The `NSDate` at which this object was last updated. Returned with update/PUT operations */
@property (nonatomic, strong, readonly) NSDate *updatedAt;

/** The `NSDate` (UTC DateTime value) at which this named resource will begin to be shared. Used with create/POST & update/PUT operations.
 * Ex: '2014-03-17 12:00:00'. Optional. If omitted, the resource will be shared immediately. 
 */
@property (nonatomic, strong, nullable) NSDate *startAt;

/** The `NSDate` (UTC DateTime value) at which this named resource will stop being shared. Used with create/POST & update/PUT operations.
 * Ex: '2020-03-17 12:00:00', Optional. If omitted, the resource will be shared until the share or named resource is deleted.
 */
@property (nonatomic, strong, nullable) NSDate *endAt;

/** @name Initializer Methods */

/**
 * Initializes the `AylaShare` instance with the provided parameters
 *
 * @param email        The email of the receiving user (with an existing account)
 * @param resourceName The type of the resource to share (e.g. `AylaShareResourceNameDevice`)
 * @param resourceId   The ID of the resource to share (e.g `dsn` for `AylaDevice`)
 * @param roleName     The full name of the user role with which the device will be shared (ex. 'OEM::Ayla::Owner'). The targeted user 
 * will have this role. Optional.
 * @param operation    An `AylaShareOperation` option, indicating the permissions (read or read/write) of the receiver.
 * @param startAt      The `NSDate` when the sharing will begin. Optional.
 * @param endAt        The `NSDate` when the sharing will end. Optional.
 *
 * @return An initialized instance of AylaShare that can be used to create an `AylaShare` in the cloud.
 * @sa `[AylaSessionManager createShare:emailTemplate:success:failure:]`
 */
- (instancetype)initWithEmail:(NSString *)email
                 resourceName:(NSString *)resourceName
                   resourceId:(NSString *)resourceId
                     roleName:(nullable NSString *)roleName
                    operation:(AylaShareOperation)operation
                      startAt:(nullable NSDate *)startAt
                        endAt:(nullable NSDate *)endAt NS_DESIGNATED_INITIALIZER;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
