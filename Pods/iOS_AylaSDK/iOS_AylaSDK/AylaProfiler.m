//
//  AylaProfiler.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/11/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaProfiler.h"
#import "AylaListenerArray.h"

@interface AylaProfiler ()

@property (nonatomic, strong) AylaListenerArray *listeners;
@end

@implementation AylaProfiler
+ (AylaProfiler *)sharedInstance {
    static dispatch_once_t onceToken;
    static AylaProfiler *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AylaProfiler alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _listeners = [[AylaListenerArray alloc] init];
    }
    return self;
}

- (void)addListener:(id)listener {
    [self.listeners addListener:listener];
}

- (void)didStartTask:(NSURLSessionDataTask *)task  {
    [self.listeners iterateListenersRespondingToSelector:_cmd block:^(id  _Nonnull listener) {
        [listener didStartTask:task];
    }];
}

- (void)didSucceedTask:(NSURLSessionDataTask *)task duration:(CFTimeInterval)duration {
    [self.listeners iterateListenersRespondingToSelector:_cmd block:^(id  _Nonnull listener) {
        [listener didSucceedTask:task duration:duration];
    }];
}

- (void)didFailTask:(NSURLSessionDataTask *)task duration:(CFTimeInterval)duration {
    [self.listeners iterateListenersRespondingToSelector:_cmd block:^(id  _Nonnull listener) {
        [listener didFailTask:task duration:duration];
    }];
}

- (void)didStartLANTask:(AylaConnectTask *)task {
    [self.listeners iterateListenersRespondingToSelector:_cmd block:^(id  _Nonnull listener) {
        [listener didStartLANTask:task];
    }];
}

- (void)didSucceedLANTask:(AylaConnectTask *)task duration:(CFTimeInterval)duration {
    [self.listeners iterateListenersRespondingToSelector:_cmd block:^(id  _Nonnull listener) {
        [listener didSucceedLANTask:task duration:duration];
    }];
}

- (void)didFailLANTask:(AylaConnectTask *)task duration:(CFTimeInterval)duration {
    [self.listeners iterateListenersRespondingToSelector:_cmd block:^(id  _Nonnull listener) {
        [listener didFailLANTask:task duration:duration];
    }];
}

@end
