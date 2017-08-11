//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/**
 Contains helper methods and utilities for AylaNetworks SDK.
 */
@interface NSString (AylaNetworks)
/**
 Strips the leading zeros in the string. E.g. @"001" -> @"1"

 @return A string with the leading zeroes stripped
 */
- (NSString *)ayla_stringByStrippingLeadingZeroes;

@end
NS_ASSUME_NONNULL_END
