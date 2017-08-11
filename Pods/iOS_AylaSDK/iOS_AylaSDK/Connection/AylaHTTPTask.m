//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaConnectTask+Internal.h"
#import "AylaDefines.h"
#import "AylaHTTPTask.h"

@interface AylaHTTPTask ()

@property (nonatomic, strong, readwrite) id task;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, readwrite, getter=type) AylaConnectTaskType type;
@property (nonatomic) NSRecursiveLock *lock;
@property BOOL started;

@end

@implementation AylaHTTPTask

@synthesize type = _type;

- (instancetype)initWithType:(AylaConnectTaskType)type
{
    return [self initWithTask:nil];
}

- (instancetype)initWithTask:(id)task
{
    self = [super initWithType:AylaConnectTaskTypeHTTP];
    if (!self) return nil;

    _lock = [[NSRecursiveLock alloc] init];
    _task = task;

    return self;
}

- (BOOL)start
{
    [self.lock lock];
    if (self.started) {
        [self.lock unlock];
        return YES;
    }

    [super start];

    // resume NSURLSessionTask to start the job
    [self.task resume];
    [self.lock unlock];

    return YES;
}

- (void)cancel
{
    [self.lock lock];

    [super cancel];

    // cancel NSURLSessionTask
    [self.task cancel];

    [self.lock unlock];
}

@end
