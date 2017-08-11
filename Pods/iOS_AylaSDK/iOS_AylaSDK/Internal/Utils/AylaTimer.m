//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaTimer.h"

typedef void (^HandleBlock)(AylaTimer *timer);

@interface AylaTimer ()
@property (nonatomic, readwrite) NSTimeInterval timeIntervalMs;
@property (nonatomic, readwrite) NSTimeInterval leewayMs;
@property (nonatomic, readwrite) dispatch_queue_t queue;
@property (nonatomic, readwrite) dispatch_source_t timer;
@property (nonatomic, readwrite, copy) HandleBlock handleBlock;
@property (nonatomic, readwrite) BOOL isPolling;
@end

@implementation AylaTimer

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeIntervalMs
                              leeway:(NSTimeInterval)leewayMs
                               queue:(dispatch_queue_t)queue
                         handleBlock:(void (^)(AylaTimer *timer))handleBlock
{
    self = [super init];
    if (!self) return nil;

    _queue = queue;
    _timeIntervalMs = timeIntervalMs;
    _leewayMs = leewayMs;
    _handleBlock = [handleBlock copy];
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);

    return self;
}

- (void)startPollingWithDelay:(BOOL)delay
{
    @synchronized(self)
    {
        if (self.isPolling) {
            // If timer is already polling, skip this request.
            return;
        }

        // Setup timer and resume
        dispatch_source_set_timer(self.timer, dispatch_walltime(DISPATCH_TIME_NOW, delay? self.timeIntervalMs * NSEC_PER_MSEC:0),
                                  self.timeIntervalMs * NSEC_PER_MSEC, self.leewayMs * NSEC_PER_MSEC);

        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf.handleBlock(strongSelf);
            }
        });

        dispatch_resume(self.timer);
        self.isPolling = YES;
    }
}

- (void)stopPolling
{
    @synchronized(self)
    {
        if (self.isPolling) {
            dispatch_suspend(self.timer);
            self.isPolling = NO;
        }
    }
}

- (void)refreshWithTimeInterval:(NSTimeInterval)timeIntervalMs
                         leeway:(NSTimeInterval)leewayMs
                    handleBlock:(void (^)(AylaTimer *timer))handleBlock
{
    @synchronized(self)
    {
        BOOL wasPolling = NO;

        // If timer is polling suspend current polling
        if (self.isPolling) {
            dispatch_suspend(self.timer);
            self.isPolling = NO;
            wasPolling = YES;
        }

        self.timeIntervalMs = timeIntervalMs;
        self.leewayMs = leewayMs;
        self.handleBlock = handleBlock;

        if (wasPolling) {
            // Restart timer if current timer was polling before this api call.
            [self startPollingWithDelay:NO];
        }
    }
}

- (void)dealloc
{
    // Cancel timer
    dispatch_cancel(self.timer);
    
    // Resume timer to let canellation happen
    if(!self.isPolling) {
        dispatch_resume(self.timer);
    }
}

@end
