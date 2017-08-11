//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "NSObject+Ayla.h"

@implementation NSObject (Ayla)

- (instancetype)nilIfNull
{
    return self != [NSNull null] ? self : nil;
}

@end
