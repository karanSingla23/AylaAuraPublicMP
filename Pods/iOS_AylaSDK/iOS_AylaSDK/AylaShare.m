//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaShare.h"
#import "AylaSystemUtils.h"

static NSString *const AylaShareOperationRead = @"read";
static NSString *const AylaShareOperationWrite = @"write";

static NSString *const attrNameId = @"id";
static NSString *const attrNameUserId = @"user_id";
static NSString *const attrNameOwnerId = @"owner_id";
static NSString *const attrNameGrantId = @"grant_id";
static NSString *const attrNameOwnerProfile = @"owner_profile";
static NSString *const attrNameUserProfile = @"user_profile";
static NSString *const attrNameUserEmail = @"user_email";
static NSString *const attrNameResourceName = @"resource_name";
static NSString *const attrNameResourceId = @"resource_id";
static NSString *const attrNameRoleName = @"role_name";  // key for the "role_name" string
static NSString *const attrNameAccepted = @"accepted";
static NSString *const attrNameStartDateAt = @"start_date_at";
static NSString *const attrNameEndDateAt = @"end_date_at";
static NSString *const attrNameOperation = @"operation";

static NSString *const attrNameReadWrite = @"write";
static NSString *const attrNameReadOnly = @"read";

static NSString *const attrNameCreatedAt = @"created_at";
static NSString *const attrNameUpdatedAt = @"updated_at";
static NSString *const attrNameAcceptedAt = @"accepted_at";
static NSString *const attrNameRoleDictionary =
    @"role";  // key for the "role" dictionary returned when fetching received shares

NSString *const AylaShareResourceNameDevice = @"device";

@implementation AylaShare
- (instancetype)initWithEmail:(NSString *)email
                 resourceName:(NSString *)resourceName
                   resourceId:(NSString *)resourceId
                     roleName:(NSString *)roleName
                    operation:(AylaShareOperation)operation
                      startAt:(NSDate *)startAt
                        endAt:(NSDate *)endAt
{
    AYLAssert(email != nil, @"Email should not be nil");
    AYLAssert(resourceName != nil, @"resourceName should not be nil");
    AYLAssert(resourceId != nil, @"resourceId should not be nil");
    AYLAssert(roleName == nil || operation == AylaShareOperationNone,
              @"roleName and operation cannot be both specified");
    if (self = [super init]) {
        _userEmail = email;
        _resourceName = resourceName;
        _resourceId = resourceId;
        _roleName = roleName;
        _operation = operation;
        _startAt = startAt;
        _endAt = endAt;
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSDateFormatter *aylaFormatter = AylaSystemUtils.defaultDateFormatter;
    NSMutableDictionary *dictionary = [@{
        attrNameResourceName : self.resourceName,
        attrNameResourceId : self.resourceId,
        attrNameRoleName : AYLNullIfNil(self.roleName),
        attrNameUserEmail : self.userEmail,
        attrNameAccepted : @(self.accepted),

        attrNameStartDateAt : AYLNullIfNil([aylaFormatter stringFromDate:self.startAt]),
        attrNameEndDateAt : AYLNullIfNil([aylaFormatter stringFromDate:self.endAt]),
    } mutableCopy];
    if (self.operation != AylaShareOperationNone) {
        dictionary[attrNameOperation] =
            self.operation == AylaShareOperationReadOnly ? attrNameReadOnly : attrNameReadWrite;
    }

    return @{ @"share" : dictionary };
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    NSDateFormatter *aylaFormatter = AylaSystemUtils.defaultDateFormatter;
    NSDictionary *share = dictionary[@"share"];
    if (self = [self initWithEmail:share[attrNameUserEmail]
                      resourceName:share[attrNameResourceName]
                        resourceId:share[attrNameResourceId]
                          roleName:nil
                         operation:[share[attrNameOperation] isEqualToString:AylaShareOperationWrite]
                                       ? AylaShareOperationReadAndWrite
                                       : AylaShareOperationReadOnly
                           startAt:[aylaFormatter dateFromString:AYLNilIfNull(share[attrNameStartDateAt])]
                             endAt:[aylaFormatter dateFromString:AYLNilIfNull(share[attrNameEndDateAt])]]) {
        _id = [(NSNumber *)share[attrNameId] stringValue];
        _grantId = [(NSNumber *)share[attrNameGrantId] stringValue];
        _createdAt = [aylaFormatter dateFromString:share[attrNameCreatedAt]];
        _updatedAt = [aylaFormatter dateFromString:share[attrNameUpdatedAt]];

        _accepted = [share[attrNameAccepted] boolValue];
        _acceptedAt = [aylaFormatter dateFromString:AYLNilIfNull(share[attrNameAcceptedAt])];

        _ownerId = [(NSNumber *)share[attrNameOwnerId] stringValue];

        _userId = [(NSNumber *)share[attrNameUserId] stringValue];

        _ownerProfile = [[AylaShareUserProfile alloc] initWithJSONDictionary:share[attrNameOwnerProfile] error:error];
        _userProfile = [[AylaShareUserProfile alloc] initWithJSONDictionary:share[attrNameUserProfile] error:error];

        NSDictionary *roleDictionary = share[attrNameRoleDictionary];
        if ([roleDictionary isKindOfClass:[NSDictionary class]]) {
            _role = [[AylaRole alloc] initWithJSONDictionary:roleDictionary error:error];
        }
    }
    return self;
}
@end
