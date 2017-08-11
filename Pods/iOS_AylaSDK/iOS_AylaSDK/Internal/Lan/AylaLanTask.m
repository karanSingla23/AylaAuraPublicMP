//
//  AylaLanTask.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/15/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaConnectTask+Internal.h"
#import "AylaDefines_Internal.h"
#import "AylaLanCommand.h"
#import "AylaLanMessage.h"
#import "AylaLanModule.h"
#import "AylaLanTask.h"
#import "AylaTimer.h"

static dispatch_queue_t lan_task_processing_queue()
{
    static dispatch_queue_t lan_task_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lan_task_processing_queue =
            dispatch_queue_create("com.aylanetworks.lanTask.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    return lan_task_processing_queue;
}

const NSTimeInterval DEFAULT_LAN_TASK_TIME_OUT = 20.;

typedef void (^SuccessBlock)(id responseObject);
typedef void (^FailureBlock)(NSError *_Nonnull error);

@interface AylaLanTask ()

@property (nonatomic, strong, readwrite) id responseObject;

@property (readwrite) NSMutableArray *callbackList;

@property (copy) SuccessBlock successBlock;
@property (copy) FailureBlock failureBlock;

@property (nonatomic) NSRecursiveLock *lock;
@property (nonatomic) BOOL isCallbackInvoked;

@property (nonatomic) AylaTimer *timer;

@property (nonatomic) NSUInteger timeoutInterval;

@end

@implementation AylaLanTask

- (instancetype)initWithPath:(NSString *)path
                    commands:(NSArray AYLA_GENERIC(AylaLanCommand *) *)commands
                     success:(void (^)(id responseObject))successBlock
                     failure:(void (^)(NSError *_Nonnull error))failureBlock;

{
    return [self initWithPath:path
                     commands:commands
                      timeout:(DEFAULT_LAN_TASK_TIME_OUT + (self.commands.count >> 2)) * 1000.
                      success:successBlock
                      failure:failureBlock];
}

- (instancetype)initWithPath:(NSString *)path
                    commands:(NSArray<AylaLanCommand *> *)commands
                     timeout:(NSUInteger)timeout
                     success:(void (^)(id _Nonnull))successBlock
                     failure:(void (^)(NSError *_Nonnull))failureBlock
{
    self = [super initWithType:AylaConnectTaskTypeLAN];
    if (!self) return nil;

    _lock = [[NSRecursiveLock alloc] init];
    _path = path;
    _commands = [commands copy];
    _successBlock = [successBlock copy];
    _failureBlock = [failureBlock copy];
    _callbackList = [NSMutableArray array];
    _timeoutInterval = timeout;
    _timer = [[AylaTimer alloc] initWithTimeInterval:_timeoutInterval
                                              leeway:1000.
                                               queue:lan_task_processing_queue()
                                         handleBlock:^(AylaTimer *timer) {
                                             [self timerFired:timer];
                                         }];

    return self;
}

- (void)setupCommands
{
    for (AylaLanCommand *command in self.commands) {
        [command setCallbackBlock:^(AylaLanCommand *command, id responseObject, NSError *error) {
            if (error) {
                // When we hit an error, we will return the error and received messages
                [self invokeCallbackBlockWithResponse:self.callbackList error:error];
                return;
            }
            else {
                [self.callbackList addObject:responseObject ?: [NSNull null]];
            }
            // If we have received all message, call successBlock
            if (self.callbackList.count == self.commands.count) {
                [self invokeCallbackBlockWithResponse:self.callbackList error:nil];
            }
        }];
    }
}

- (void)invokeCallbackBlockWithResponse:(NSArray *)response error:(NSError *)error
{
    dispatch_async(lan_task_processing_queue(), ^{
        [self.lock lock];
        if (!self.isCallbackInvoked) {
            self.isCallbackInvoked = YES;
            self.finished = YES;

            if (!error) {
                // Call success block
                self.successBlock(response);
            }
            else {
                // Invalidate all pending commands
                for (AylaLanCommand *command in self.commands) {
                    [command cancel];
                }

                // Call failure block
                self.failureBlock(error);
            }
        }

        [self.lock unlock];
    });
}

- (BOOL)start
{
    [self.lock lock];

    AylaLanModule *module = self.module;
    if (!module) {
        return NO;
    }

    if (self.finished || self.cancelled) {
        return NO;
    }

    if (self.commands.count == 0) {
        // If there are no commands in task, return a success immidiately
        [self invokeCallbackBlockWithResponse:@[] error:nil];
        [self.lock unlock];
        return YES;
    }

    [self setupCommands];
    [self.timer startPollingWithDelay:YES];
    [module addTask:self];

    self.executing = YES;
    [self.lock unlock];
    return YES;
}

- (void)cancel
{
    [self.lock lock];

    if (!self.finished) {
        self.cancelled = YES;
        self.finished = YES;

        [self.timer stopPolling];
        [self invokeCallbackBlockWithResponse:nil
                                        error:[AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                                         code:AylaRequestErrorCodeCancelled
                                                                     userInfo:nil]];
    }
    [self.chainedTask cancel];

    [self.lock unlock];
}

- (void)timerFired:(AylaTimer *)timer
{
    [timer stopPolling];
    [self invokeCallbackBlockWithResponse:nil
                                    error:[AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                                     code:AylaRequestErrorCodeTimedOut
                                                                 userInfo:nil]];
}

@end
