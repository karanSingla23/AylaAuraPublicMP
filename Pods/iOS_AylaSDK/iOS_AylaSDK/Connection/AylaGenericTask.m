//
//  AylaGenericTask.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/12/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaGenericTask.h"

@interface AylaGenericTask ()

@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, readwrite, getter=type) AylaConnectTaskType type;
@property (nonatomic) NSRecursiveLock *lock;
@property BOOL started;
@property (nonatomic, readwrite) NSInteger timeoutMS;
@end

@implementation AylaGenericTask

@synthesize type = _type;

- (instancetype)initWithType:(AylaConnectTaskType)type
{
    return [self initWithTask:nil cancel:nil timeout:0];
}

- (instancetype)initWithTask:(BOOL (^)())taskBlock cancel:(void (^)(BOOL))cancelBlock timeout:(NSInteger)timeoutMS
{
    self = [super initWithType:AylaConnectTaskTypeHTTP];
    if (!self) return nil;
    
    _lock = [[NSRecursiveLock alloc] init];
    _taskBlock = taskBlock;
    _cancelBlock = cancelBlock;
    _timeoutMS = timeoutMS;
    
    return self;
}

- (instancetype)initWithTask:(BOOL (^)())taskBlock cancel:(void (^)(BOOL))cancelBlock {
    return [self initWithTask:taskBlock cancel:cancelBlock timeout:0];
}

- (BOOL)start
{
    [self.lock lock];
    if (self.started) {
        [self.lock unlock];
        return YES;
    }
    
    [super start];
    
    if (self.timeoutMS > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeoutMS * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self timeout];
        });
    }
    
    BOOL taskResult = NO;
    if (self.taskBlock) {
        taskResult = self.taskBlock();
    }
    [self.lock unlock];
    
    return taskResult;
}

- (void)cancelWithTimeout:(BOOL)timedOut {
    
    [self.lock lock];
    
    [super cancel];
    
    if (self.cancelBlock) {
        self.cancelBlock(timedOut);
    }
    
    [self.lock unlock];
}

- (void)cancel
{
    [self cancelWithTimeout:NO];
}

- (void)timeout
{
    if (self.executing) {
        [self cancelWithTimeout:YES];
    }
}
@end
