//
//  AylaNetworkProfiling.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"

/**
 Describes an object that will receive Cloud task updates from profiler
 */
@protocol AylaCloudTaskProfilerListener <NSObject>

/**
 Notifies when a task has started

 @param task the task that has started
 */
- (void)didStartTask:(NSURLSessionDataTask *)task;

/**
 Notifies when a task has succeeded

 @param task     the task that has succeeded
 @param duration network duration of the task
 */
- (void)didSucceedTask:(NSURLSessionDataTask *)task duration:(CFTimeInterval)duration;

/**
 Notifies when a task has failed

 @param task     the task that failed
 @param duration network duration of the task
 */
- (void)didFailTask:(NSURLSessionDataTask *)task duration:(CFTimeInterval)duration;
@end


/**
 Describes an object that will receive LAN task updates from profiler
 */
@protocol AylaLanTaskProfilerListener <NSObject>

/**
 Notifies when a task has started
 
 @param task the task that has started
 */
- (void)didStartLANTask:(AylaConnectTask *)task;

/**
 Notifies when a task has succeeded
 
 @param task     the task that has succeeded
 @param duration LAN duration of the task
 */
- (void)didSucceedLANTask:(AylaConnectTask *)task duration:(CFTimeInterval)duration;


/**
 Notifies when a task has failed
 
 @param task     the task that failed
 @param duration LAN duration of the task
 */
- (void)didFailLANTask:(AylaConnectTask *)task duration:(CFTimeInterval)duration;
@end


/**
 Forwards network time measurements of tasks to all listeners.
 */
@interface AylaProfiler : NSObject <AylaCloudTaskProfilerListener, AylaLanTaskProfilerListener>

/**
 @return Shared instance of the profiler
 */
+ (AylaProfiler *)sharedInstance;

/**
 Adds an object as listener

 @param listener The objet to be added as listener
 */
- (void)addListener:(id)listener;
@end
