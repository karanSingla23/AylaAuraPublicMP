//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ayla Request Error Domain
 */
FOUNDATION_EXPORT NSString* const AylaRequestErrorDomain;

/**
 * This enumeration describes Ayla Request error codes
 */
typedef NS_ENUM(NSInteger, AylaRequestErrorCode) {
    /** Unknown issue */
    AylaRequestErrorCodeUnknown = 0,
    
    /** One or more invalid arguments */
    AylaRequestErrorCodeInvalidArguments = 2001,
    
    /** Request can't be process because one or more preconditon failure */
    AylaRequestErrorCodePreconditionFailure = 2002,
    
    /** Request has been cancelled */
    AylaRequestErrorCodeCancelled = 2003,
    
    /** Request has been timed out */
    AylaRequestErrorCodeTimedOut = 2004,
    
    /** Batch request succeded for only a subset of the items */
    AylaRequestErrorCodeIncomplete = 2005
};

FOUNDATION_EXPORT NSString* const
    AylaRequestErrorOrignialErrorKey;   // Key to another NSError object which contains addtional details of this error.
FOUNDATION_EXPORT NSString* const
    AylaRequestErrorResponseJsonKey;    // Key to serialzied JSON decription which describes this issue
FOUNDATION_EXPORT NSString* const
    AylaRequestErrorCompletedItemsKey;  // Key to a NSArray of the items that were successfully processed in an incomplete batch request (AylaRequestErrorCodeIncomplete)
FOUNDATION_EXPORT NSString* const
    AylaRequestErrorBatchErrorsKey;     // Key to a NSArray of the NSErrors returned for the failed items in an incomplete batch request (AylaRequestErrorCodeIncomplete)

NS_ASSUME_NONNULL_END
