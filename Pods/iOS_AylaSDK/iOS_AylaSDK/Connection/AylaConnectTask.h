//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Connection Task Type
 */
typedef NS_ENUM(uint8_t, AylaConnectTaskType) {
    /** HTTP task type */
    AylaConnectTaskTypeHTTP,

    /** LAN task type */
    AylaConnectTaskTypeLAN,

    /** DSS task type */
    AylaConnectTaskTypeDSS
};

/**
 * Abstract Class for connection tasks
 */
@interface AylaConnectTask : NSObject

/** Task type */
@property (nonatomic, readonly) AylaConnectTaskType type;

/** If task is executing */
@property (nonatomic, readonly) BOOL executing;

/** If task is cancelled */
@property (nonatomic, readonly) BOOL cancelled;

/** If task if finished */
@property (nonatomic, readonly) BOOL finished;

/** 
 * Init method for an `AylaConnectTask` instance given a specified `AylaConnectTaskType` 
 *
 * @param type An `AylaConnectTaskType`
 * @return The `AylaConnectTask` based on the provided `NSURLSessionTask`
 */
- (instancetype)initWithType:(AylaConnectTaskType)type NS_DESIGNATED_INITIALIZER;

/**
 * Use this method to start a task.
 *
 * @return YES will be returned if this task is started.
 */
- (BOOL)start;

/**
 * Use this method to cancel a task.
 */
- (void)cancel;

@end
