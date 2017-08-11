//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AylaListenerArray : NSObject

/**
 * Return an array of known listeners.
 */
- (NSArray *)listeners;

/**
 * Add a listener to array.
 *
 * @note Lisenter array is not responsible for retaining listeners, which means the library/application needs to manage
 * life cycle of its passed in listeners.
 */
- (void)addListener:(id)listener;

/**
 * Remove a listener.
 */
- (void)removeListener:(id)listener;

/**
 * Iterate all listeners which could respond to the passed in selector.
 */
- (void)iterateListenersRespondingToSelector:(SEL)selector block:(void (^)(id listener))handleBlock;

/**
 * Iterate all listeners which could respond to the passed in selector on a queue asychronously.
 *
 * @param queue The dispatch queue all selectors should run on.
 */
- (void)iterateListenersRespondingToSelector:(SEL)selector
                                asyncOnQueue:(dispatch_queue_t)queue
                                       block:(void (^)(id listener))handleBlock;

@end

NS_ASSUME_NONNULL_END