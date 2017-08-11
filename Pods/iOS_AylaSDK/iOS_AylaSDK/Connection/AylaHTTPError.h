//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ayla HTTP Error Domain
 */
FOUNDATION_EXPORT NSString *const AylaHTTPErrorDomain;

/**
 * This enumeration describes Ayla HTTP error codes
 */
typedef NS_ENUM(NSInteger, AylaHTTPErrorCode) {
    /** Unknown Issue */
    AylaHTTPErrorCodeUnknown = 0,

    /** Invalid response from service */
    AylaHTTPErrorCodeInvalidResponse = 1001,

    /** Request failed because connectivity was lost */
    AylaHTTPErrorCodeLostConnectivity = 1002,

    /**  Request was cancelled */
    AylaHTTPErrorCodeCancelled = 1003
};

FOUNDATION_EXPORT NSString *const AylaHTTPErrorHTTPResponseKey;  // Key to object of NSURLHTTPReponse
FOUNDATION_EXPORT NSString
    *const AylaHTTPErrorOrignialErrorKey;  // Key to another NSError object which reports this error.
FOUNDATION_EXPORT NSString *const AylaHTTPErrorResponseJsonKey;  // Key to serialzied JSON response

/**
 * Provides helpful methods to easily get information on HTTP Errors.
 */
@interface NSError (AylaHTTPError)
/** Returns whether the receiver is an HTTP error or not. */
@property (readonly, nonatomic, getter=isAyla_httpErrorResponse) BOOL ayla_httpErrorResponse;

/** Returns the Status of the HTTP Response */
@property (readonly, nonatomic) NSInteger ayla_httpStatusCode;

/** Returns the raw data returned by the server */
@property (readonly, nonatomic, nullable) NSData *ayla_serverResponseData;

/** Returns all the HTTP Headers in the Response */
@property (readonly, nonatomic, nullable) NSDictionary *ayla_httpHeaders;

/** Returns the whole HTTP Response */
@property (readonly, nonatomic, nullable) NSHTTPURLResponse *ayla_httpResponse;

/** Returns the localized description of the HTTP Error */
@property (readonly, nonatomic, nullable) NSString *ayla_httpErrorLocalizedDescription;
@end

NS_ASSUME_NONNULL_END
