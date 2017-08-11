//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaGrant.h"
#import "AylaObject+Internal.h"
#import "AylaSystemUtils.h"
#import "NSString+AylaNetworks.h"

static NSString *const attrNameEndDateAt = @"end_date_at";
static NSString *const attrNameOperation = @"operation";
static NSString *const attrNameRole = @"role";
static NSString *const attrNameShareId = @"share_id";
static NSString *const attrNameStartDateAt = @"start_date_at";
static NSString *const attrNameUserId = @"user_id";

static NSString *const AylaShareOperationRead = @"read";
static NSString *const AylaShareOperationWrite = @"write";

@implementation AylaGrant
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        NSDateFormatter *aylaFormatter = AylaSystemUtils.defaultDateFormatter;
        _userId = dictionary[attrNameUserId];
        _shareId = dictionary[attrNameShareId];
        _operation = [AYLNilIfNull(dictionary[attrNameOperation]) isEqualToString:AylaShareOperationRead]
                         ? AylaShareOperationReadOnly
                         : AylaShareOperationReadAndWrite;
        _startDate = [aylaFormatter dateFromString:AYLNilIfNull(dictionary[attrNameStartDateAt])];
        _endDate = [aylaFormatter dateFromString:AYLNilIfNull(dictionary[attrNameEndDateAt])];
        _role = AYLNilIfNull(dictionary[attrNameRole]);
    }
    return self;
}

- (NSString *)description
{
    return [NSString
        stringWithFormat:@"AylaGrant: {\nuserId: %@ \noperation: %@ \nstartDate: %@ \nendDate: %@ \nrole:%@ \n}",
                         self.userId,
                         @(self.operation),
                         self.startDate,
                         self.endDate,
                         self.role];
}

@end
