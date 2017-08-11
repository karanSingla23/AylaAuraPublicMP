//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ayla Lan Error Domain
 */
FOUNDATION_EXPORT NSString* const AylaLanErrorDomain;

/**
 * This enumeration describes Ayla Lan error codes
 */
typedef NS_ENUM(NSInteger, AylaLanErrorCode) {
    /** Unknown issue */
    AylaLanErrorCodeUnknown = 0,
    
    /** Error in key generation */
    AylaLanErrorCodeKeyGenerationFailure = 4001,
    
    /** Config file is empty */
    AylaLanErrorCodeEmptyConfig = 4002,
    
    /** Requires cloud service reachability */
    AylaLanErrorCodeRequireCloudReachability = 4003,
    
    /** Lan mode is not enabled on device */
    AylaLanErrorCodeLanNotEnabled = 4004,
    
    /** Config file is empty on cloud */
    AylaLanErrorCodeLanConfigEmptyOnCloud = 4005,
    
    /** Can't match key info fetched from device */
    AylaLanErrorCodeUnmatchedKeyInfo = 4006,
    
    /** Session message is timed out */
    AylaLanErrorCodeMobileSessionMsgTimeOut = 4020,
    
    /** Connection request is not supported by device */
    AylaLanErrorCodeDeviceNotSupport = 4021,
    
    /** Device is at a different Lan */
    AylaLanErrorCodeDeviceDifferentLan = 4022,
    
    /** Invalid response from device */
    AylaLanErrorCodeDeviceResponseError = 4023,
    
    /** Encryption error */
    AylaLanErrorCodeEncryptionFailure = 4024,
    
    /** Pause session because SDK observes a duplicate lan ip */
    AylaLanErrorCodePausedByDuplicateLanIp = 4025,
    
    /** Internal error - Device can not be found */
    AylaLanErrorCodeLibraryNilDevice = 4050,
    
    /** Internal error - Invalid params */
    AylaLanErrorCodeLibraryInvalidParam = 4051,
    
    /** Internal error - Bad cloud response */
    AylaLanErrorCodeCloudInvalidResp = 4052
};

FOUNDATION_EXPORT NSString* const
AylaLanErrorOrignialErrorKey;  // Key to another NSError object which contains addtional details of this error.
FOUNDATION_EXPORT NSString* const
AylaLanErrorResponseJsonKey;  // Key to serialzied JSON decription which describes this issue
FOUNDATION_EXPORT NSString* const
AylaLanErrorStatusCode;  // Key to status code
FOUNDATION_EXPORT NSString* const
AylaLanErrorFailedCommand;  // Key to the command which caused error to this request.

NS_ASSUME_NONNULL_END
