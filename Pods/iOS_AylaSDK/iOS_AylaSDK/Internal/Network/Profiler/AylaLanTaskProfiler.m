//
//  AylaLanTaskProfiler.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLanTaskProfiler.h"
#import <QuartzCore/QuartzCore.h>
@class AylaLanCommand;
@implementation AylaLanTaskProfiler


- (instancetype)initWithPath:(NSString *)path commands:(NSArray<AylaLanCommand *> *)commands success:(void (^)(id _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    CFTimeInterval startTime = CACurrentMediaTime();
    __weak AylaLanTaskProfiler *_self = self;
    return [super initWithPath:path commands:commands success:^(id  _Nonnull responseObject) {
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"LAN Task Success: %@: Total Runtime: %g s", path, endTime - startTime);
        [[AylaProfiler sharedInstance] didSucceedLANTask:_self duration:endTime - startTime];
        successBlock(responseObject);
    } failure:^(NSError * _Nonnull error) {
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"LAN Task Failure: %@: Total Runtime: %g s", path, endTime - startTime);
        [[AylaProfiler sharedInstance] didFailLANTask:_self duration:endTime - startTime];
        failureBlock(error);
    }];
}

- (instancetype)initWithPath:(NSString *)path commands:(NSArray<AylaLanCommand *> *)commands timeout:(NSUInteger)timeout success:(void (^)(id _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    CFTimeInterval startTime = CACurrentMediaTime();
    __weak AylaLanTaskProfiler *_self = self;
    return [super initWithPath:path commands:commands timeout:timeout success:^(id  _Nonnull responseObject) {
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"LAN Task Success: %@: Total Runtime: %g s", path, endTime - startTime);
        [[AylaProfiler sharedInstance] didSucceedLANTask:_self duration:endTime - startTime];
        successBlock(responseObject);
    } failure:^(NSError * _Nonnull error) {
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"LAN Task Failure: %@: Total Runtime: %g s", path, endTime - startTime);
        [[AylaProfiler sharedInstance] didFailLANTask:_self duration:endTime - startTime];
        failureBlock(error);
    }];
}
@end
