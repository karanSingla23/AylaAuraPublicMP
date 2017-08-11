//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "NSString+AylaNetworks.h"

@implementation NSString (AylaNetworks)
- (NSString *)ayla_stringByStrippingLeadingZeroes
{
    NSRange range = [self rangeOfString:@"^0*" options:NSRegularExpressionSearch];
    NSString *strippedString = [self stringByReplacingCharactersInRange:range withString:@""];

    return strippedString;
}

@end
