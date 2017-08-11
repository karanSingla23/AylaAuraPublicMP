//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaConnectTask.h"
#import "AylaHTTPError.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Each HTTP task represents a HTTP(S) request.
 */
@interface AylaHTTPTask : AylaConnectTask

/** @name Task Properties */

/** Task object which handles implementations */
@property (nonatomic, strong, readonly) id task;

/** Response (result) of current HTTP task */
@property (nonatomic, strong, readonly) id responseObject;

/** @name Initializer Methods */
/**
 * Init method with a task object as input.
 *
 * @note Currently `AylaHTTPTask` only accepts `NSURLSessionTask` as task input.
 *
 * @param task An `NSURLSessionTask`
 * @return The `AylaHTTPTask` based on the provided `NSURLSessionTask`
 */
- (instancetype)initWithTask:(nullable id)task NS_DESIGNATED_INITIALIZER;

/**
 * Use this method to start a HTTP task.
 */
- (BOOL)start;

/**
 * Use this method to cancel a started HTTP task.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
