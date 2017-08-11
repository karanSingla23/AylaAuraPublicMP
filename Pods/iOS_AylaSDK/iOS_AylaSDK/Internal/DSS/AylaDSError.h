//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ayla Request Error Domain
 */
FOUNDATION_EXPORT NSString* const AylaDSErrorDomain;

/**
 * This enumeration describes Ayla DS(Data Stream) error codes
 */
typedef NS_ENUM(NSInteger, AylaDSErrorCode) {
    AylaDSErrorCodeUnknown = 0,  // Unknown issue.
    AylaDSErrorCodeInvalidSubscription = 5001, // Invalid subscription.
    AylaDSErrorCodeWebSocketError = 5002,   // An error observed by web socket.
    AylaDSErrorCodeRefusedByCloud = 5003,   // Subscription was refused by cloud.
    AylaDSErrorCodeDeviceManagerNotFound = 5004,    // No device manager found.
    AylaDSErrorCodeDeviceManagerBadStatus = 5005    // Bad status from device manager.
};

FOUNDATION_EXPORT NSString* const
    AylaDSErrorOrignialErrorKey;  // Key to another NSError object which contains addtional details of this error.
FOUNDATION_EXPORT NSString* const
    AylaDSErrorResponseJsonKey;  // Key to serialzied JSON decription which describes this issue

NS_ASSUME_NONNULL_END