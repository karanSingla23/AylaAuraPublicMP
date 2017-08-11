//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Timer class which encapsulate dispatch_timers and provide A list of convenient methods.
 */
@interface AylaTimer : NSObject

@property (nonatomic, readonly) NSTimeInterval timeIntervalMs;
@property (nonatomic, readonly) NSTimeInterval leewayMs;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) BOOL isPolling;
@property (nonatomic) int tag;

/**
 * Init Method
 *
 * @param timerIntervalMs Poll interval in millionseconds.
 * @param leeway Poll leeway in millionseconds
 * @param queue Dispatch queue this timer should be deployed on.
 * @param handleBlock A handle block which will be invoked when timer gets fired.
 */
- (instancetype)initWithTimeInterval:(NSTimeInterval)timeIntervalMs
                              leeway:(NSTimeInterval)leewayMs
                               queue:(dispatch_queue_t)queue
                         handleBlock:(void (^)(AylaTimer *timer))handleBlock NS_DESIGNATED_INITIALIZER;

/**
 * Use this method to start current timer
 */
- (void)startPollingWithDelay:(BOOL)delay;

/**
 * Use this method to stop current timer
 */
- (void)stopPolling;

/**
 * Use this method to adjust current timer. This method does three steps:
 * 1) Suspend current timer
 * 2) Update variables based on input.
 * 3) Restart timer if it was polling.
 */
- (void)refreshWithTimeInterval:(NSTimeInterval)timeIntervalMs
                         leeway:(NSTimeInterval)leewayMs
                    handleBlock:(void (^)(AylaTimer *timer))handleBlock;

// Unavailable methods
- (instancetype)init NS_UNAVAILABLE;
@end
