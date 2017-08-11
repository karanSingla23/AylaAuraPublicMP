//
//  AylaGenericTask.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/12/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaConnectTask.h"

/**
 Represents a generic task (protocol agnostic)
 */
@interface AylaGenericTask : AylaConnectTask

/**
 Initializes the task with a task, cancel block and a timeout
 
 @param taskBlock block of the task to perform
 @param cancelBlock Block called in case the task needs to be cancelled
 @param timeoutMS Timeout of the request
 @return an initialized task
 */
- (instancetype)initWithTask:(BOOL (^)())taskBlock cancel:(void (^)(BOOL timedOut))cancelBlock timeout:(NSInteger)timeoutMS;


/**
 Initializes the task with a task, cancel block and a timeout
 
 @param taskBlock block of the task to perform
 @param cancelBlock Block called in case the task needs to be cancelled
 @return an initialized task
 */
- (instancetype)initWithTask:(BOOL (^)())taskBlock cancel:(void (^)(BOOL timedOut))cancelBlock;

/**
 The task to perform
 */
@property (nonatomic, strong) BOOL(^taskBlock)();

/**
 Block called in case the task needs to be cancelled
 */
@property (nonatomic, strong) void (^cancelBlock)(BOOL timedOut);

@end
