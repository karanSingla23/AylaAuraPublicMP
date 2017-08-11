//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaErrorUtils.h"
#import "AylaLogManager.h"
#import "NSObject+Ayla.h"

#define AYLAssert(condition, desc, ...)           \
    do {                                          \
        NSAssert(condition, desc, ##__VA_ARGS__); \
    } while (0)

/**
 * Useful macros for converting to and from JSON
 */
#define AYLNilIfNull(object) ([object nilIfNull])
#define AYLNilIfNullOrEmptyString(object) ((object == [NSNull null]) ? nil : ([object isEqualToString:@""] ? nil : object))
#define AYLNullIfNil(object) (object ?: [NSNull null])
