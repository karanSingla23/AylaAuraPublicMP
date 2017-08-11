//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaRole.h"

static NSString *const AylaRoleName = @"name";

@implementation AylaRole
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    AYLAssert(dictionary != nil, @"dictionary should not be nil");
    if (self = [super init]) {
        _name = dictionary[AylaRoleName];
    }
    return self;
}
@end
