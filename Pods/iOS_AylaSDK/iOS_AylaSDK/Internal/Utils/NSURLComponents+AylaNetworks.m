//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "NSURLComponents+AylaNetworks.h"

@implementation NSURLComponents (AylaNetworks)
- (id)ayla_valueForQueryItem:(NSString *)item
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", item];
    NSURLQueryItem *queryItem = [[[self queryItems] filteredArrayUsingPredicate:predicate] firstObject];
    return queryItem.value;
}
@end
