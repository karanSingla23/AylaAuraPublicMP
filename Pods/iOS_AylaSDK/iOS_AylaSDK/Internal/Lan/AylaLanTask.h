//
//  AylaLanTask.h
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/15/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaConnectTask.h"
#import "AylaDefines.h"
#import "AylaLanModule.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaLanCommand;
FOUNDATION_EXPORT const NSTimeInterval DEFAULT_LAN_TASK_TIME_OUT;
/**
 * AylaLanTask
 *
 * Each AylaLanTask instance represents a lan task.
 */
@interface AylaLanTask : AylaConnectTask

/** List of commands included in current task */
@property (nonatomic) NSArray AYLA_GENERIC(AylaLanCommand *) *commands;

/** Task path */
@property (nonatomic) NSString *path;

@property (nonatomic, weak) AylaLanModule *module;

/**
 * Init method. Note path is not used when composing lan requests.
 */
- (instancetype)initWithPath:(NSString *)path
                    commands:(NSArray AYLA_GENERIC(AylaLanCommand *) *)commands
                     success:(void (^)(id responseObject))successBlock
                     failure:(void (^)(NSError *_Nonnull error))failureBlock;
/**
 * Init method with a custom timeout. Note path is not used when composing lan requests.
 */
- (instancetype)initWithPath:(NSString *)path
                    commands:(NSArray AYLA_GENERIC(AylaLanCommand *) *)commands
                     timeout:(NSUInteger)timeout
                     success:(void (^)(id responseObject))successBlock
                     failure:(void (^)(NSError *_Nonnull error))failureBlock;

/**
 * Start task on a module.
 *
 * @return Return YES if task could be deployed.
 */
- (BOOL)start;

/**
 * Cancel current task.
 */
- (void)cancel;

/**
 * The timeout for the task 
 */
@property (nonatomic, readonly) NSUInteger timeoutInterval;

@end

NS_ASSUME_NONNULL_END