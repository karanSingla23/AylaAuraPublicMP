//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaListenerArray.h"

@interface AylaListenerArray ()

@property (nonatomic, strong, readwrite) NSHashTable *listenerTable;

@end

@implementation AylaListenerArray

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    _listenerTable = [NSHashTable weakObjectsHashTable];

    return self;
}

- (void)addListener:(id)listener
{
    @synchronized (self) {
        [_listenerTable addObject:listener];
    }
}

- (void)removeListener:(id)listener
{
    @synchronized (self) {
        [_listenerTable removeObject:listener];
    }
}

- (NSArray *)listeners
{
    __block NSArray *listeners;
    @synchronized (self) {
        listeners = [_listenerTable allObjects];
    }
    return listeners;
}

- (void)iterateListenersRespondingToSelector:(SEL)selector block:(void (^)(id listener))handleBlock
{
    @autoreleasepool {
        for (id listener in self.listeners) {
            if ([listener respondsToSelector:selector]) {
                handleBlock(listener);
            }
        }
    }
}

- (void)iterateListenersRespondingToSelector:(SEL)selector
                                asyncOnQueue:(dispatch_queue_t)queue
                                       block:(void (^)(id listener))handleBlock
{
    NSArray *listeners = self.listeners;
    dispatch_async(queue, ^{
        @autoreleasepool {
            for (id listener in listeners) {
                if ([listener respondsToSelector:selector]) {
                    handleBlock(listener);
                }
            }
        }
    });
}

@end
