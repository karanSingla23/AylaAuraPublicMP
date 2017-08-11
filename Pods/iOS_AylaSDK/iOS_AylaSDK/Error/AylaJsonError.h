//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ayla JSON Error Domain
 */
FOUNDATION_EXPORT NSString* const AylaJsonErrorDomain;

/**
 * This enumeration describes Ayla JSON error codes
 */
typedef NS_ENUM(NSInteger, AylaJsonErrorCode) {
    /** Unknown issue */
    AylaJsonErrorCodeUnknown = 0,
    
    /** Invalid Json */
    AylaJsonErrorCodeInvalidJson = 3001
};

FOUNDATION_EXPORT NSString* const
    AylaJsonErrorOrignialErrorKey;  // Key to another NSError object which contains addtional details of this error.
FOUNDATION_EXPORT NSString* const
    AylaJsonErrorResponseJsonKey;  // Key to serialzied JSON decription which describes this issue

NS_ASSUME_NONNULL_END
