//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

@implementation AylaObject

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    return [super init];
}

- (NSDictionary *)toJSONDictionary
{
    return @{};
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self.class alloc] initWithJSONDictionary:[self toJSONDictionary] error:nil];
}

@end
