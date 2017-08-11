//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLanError.h"
#import "AylaJsonError.h"
#import "AylaRequestError.h"

NS_ASSUME_NONNULL_BEGIN

@class NSError;
/**
 * A helpful class to create SDK errors.
 */
@interface AylaErrorUtils : NSObject

/** @name Initializer Methods */

/**
 * Use this method to create an error object with domain, code and user info.
 * @param domain      Error domain.
 * @param code        Error code.
 * @param userInfo    Error user info.
 *
 * @return An initialized `NSError`
 */
+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;

/**
 * Use this method to create an error object with domain, code, user info and logging options
 *
 * @param domain      Error domain.
 * @param code        Error code.
 * @param userInfo    Error user info.
 * @param shouldLog   If this error should be logged.
 * @param tag         Assigned tag of this log message.
 * @param description Description which will be appended into the log message of this error.
 *
 * @return An initialized `NSError`
 */
+ (NSError *)errorWithDomain:(NSString *)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary *)userInfo
                   shouldLog:(BOOL)shouldLog
                      logTag:(nullable NSString *)tag
            addOnDescription:(nullable NSString *)description;
@end

// Exposed error descriptions
FOUNDATION_EXPORT NSString *const AylaErrorDescriptionIsInvalid;
FOUNDATION_EXPORT NSString *const AylaErrorDescriptionCanNotBeBlank;
FOUNDATION_EXPORT NSString *const AylaErrorDescriptionCanNotBeFound;
FOUNDATION_EXPORT NSString *const AylaErrorDescriptionNotReady;

NS_ASSUME_NONNULL_END
