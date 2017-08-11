//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^ContinueBlock)();
typedef void (^StopBlock)();
/**
 Provides a mechanism to repeat a task.
 When implementing the `pollBlock` make sure to call `continueBlock` or `stopBlock`.
 Call `start` to begin the polling after the `delay`.
 */
@interface AylaPoll : NSObject
/**
 * Initializes the instance with the specified `pollBlock`, a delay in seconds between each call, a tiemout in seconds
 * before the tiemoutBlock is called and the poll is stopped.
 *
 * @param pollBlock     The block to repeat, make sure to call `continueBlock` to perform the next repetition or make
 * `*stop = YES;`
 * to stop the poll before the timeout is reached.
 * @param delay     The delay in seconds before each time the block is performed (including the first one)
 * @param seconds      The timeout in seconds.
 * @param timeoutBlock The block that will be called in case of timeout
 *
 * @return An initialized instance.
 */
- (instancetype)initWithPollBlock:(void (^)(ContinueBlock continueBlock, BOOL *stop, NSInteger repetition))pollBlock
                            delay:(NSTimeInterval)delay
                          timeout:(NSTimeInterval)seconds
                     timeoutBlock:(void (^)())timeoutBlock NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
/**
 * Begins to poll after the value specified in `delay` in the `initWithPollBlock:repeat:delay:` method.
 */
- (void)start;
@end
NS_ASSUME_NONNULL_END