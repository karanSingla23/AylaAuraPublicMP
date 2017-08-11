//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ayla Setup Error Domain
 */
FOUNDATION_EXPORT NSString* const AylaSetupErrorDomain;

/**
 * This enumeration describes Ayla Setup error codes
 */
typedef NS_ENUM(NSInteger, AylaSetupErrorCode) {
    /** Unknown issue */
    AylaSetupErrorCodeUnknown = 0,
    
    /** Can't find setup device */
    AylaSetupErrorCodeNoDeviceFound = 5001
};

FOUNDATION_EXPORT NSString* const
    AylaSetupErrorOrignialErrorKey;  // Key to another NSError object which contains addtional details of this error.
FOUNDATION_EXPORT NSString* const
    AylaSetupErrorResponseJsonKey;  // Key to serialzied JSON decription which describes this issue

NS_ASSUME_NONNULL_END
