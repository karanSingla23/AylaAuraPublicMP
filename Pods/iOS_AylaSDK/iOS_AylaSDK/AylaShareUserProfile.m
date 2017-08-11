//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaShareUserProfile.h"

static NSString *const AylaShareUserFirstName = @"firstname";
static NSString *const AylaShareUserLastName = @"lastname";
static NSString *const AylaShareUserEmail = @"email";

@implementation AylaShareUserProfile
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    AYLAssert(dictionary != nil, @"dictionary should not be nil");
    self = [super init];
    if (self) {
        _firstName = dictionary[AylaShareUserFirstName];
        _lastName = dictionary[AylaShareUserLastName];
        _email = dictionary[AylaShareUserEmail];
    }
    return self;
}
@end
