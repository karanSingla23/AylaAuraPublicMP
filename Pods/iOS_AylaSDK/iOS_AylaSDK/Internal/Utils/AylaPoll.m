//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaPoll.h"

@interface AylaPoll ()
@property (nonatomic, strong) void (^pollBlock)
    (ContinueBlock _Nonnull continueBlock, BOOL *_Nonnull stop, NSInteger repetition);
@property (nonatomic, strong) void (^timeoutBlock)();
@property (nonatomic, strong) NSDate *timeoutDate;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, assign) NSInteger repetitionNumber;
@property (nonatomic, assign) BOOL stop;
@end

@implementation AylaPoll
- (instancetype)initWithPollBlock:(void (^)(ContinueBlock _Nonnull, BOOL *_Nonnull, NSInteger))pollBlock
                            delay:(NSTimeInterval)delay
                          timeout:(NSTimeInterval)seconds
                     timeoutBlock:(void (^)())timeoutBlock
{
    if (self = [super init]) {
        _pollBlock = pollBlock;
        _timeoutBlock = timeoutBlock;
        _delay = delay;
        _timeout = seconds;
    }
    return self;
}

- (void)start
{
    self.stop = NO;
    self.timeoutDate = [NSDate dateWithTimeIntervalSinceNow:self.timeout];
    [self continuePoll];
}

- (void)continuePoll
{
    if ([self.timeoutDate compare:[NSDate date]] == NSOrderedAscending) {
        dispatch_async(dispatch_get_main_queue(), _timeoutBlock);
        return;
    }
    if (!self.stop) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.pollBlock(
                    ^{
                        [self continuePoll];
                    },
                    &_stop,
                    ++self.repetitionNumber);
            });
    }
}
@end
