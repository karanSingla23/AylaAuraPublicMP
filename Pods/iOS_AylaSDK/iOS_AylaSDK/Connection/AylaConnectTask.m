//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaConnectTask.h"
#import "AylaDefines.h"

@interface AylaConnectTask ()

@property (nonatomic, readwrite) AylaConnectTask *chainedTask;

@property (nonatomic, readwrite) BOOL cancelled;
@property (nonatomic, readwrite) BOOL executing;
@property (nonatomic, readwrite) BOOL finished;

/** Property which is used by api retainSelf/unretrainSelf */
@property (nonatomic, readwrite) AylaConnectTask *me;

@end

@implementation AylaConnectTask

- (instancetype)init
{
    return [self initWithType:AylaConnectTaskTypeHTTP];
}

- (instancetype)initWithType:(AylaConnectTaskType)type
{
    self = [super init];
    if(!self) return nil;
    
    _type = type;
    
    return self;
}

- (BOOL)start
{
    _executing = YES;
    return YES;
}

- (void)cancel
{
    _executing = NO;
    _cancelled = YES;
    _finished = YES;
    [self.chainedTask cancel];
}

- (void)retainSelf
{
    self.me = self;
}

- (void)unretainSelf
{
    self.me = nil;
}

@end
