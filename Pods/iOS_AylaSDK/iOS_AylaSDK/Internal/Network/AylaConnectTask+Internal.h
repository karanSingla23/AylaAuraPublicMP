//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaConnectTask.h"

@interface AylaConnectTask (Internal)

@property (nonatomic, readwrite) AylaConnectTask *chainedTask;

@property (nonatomic, readwrite) BOOL cancelled;
@property (nonatomic, readwrite) BOOL executing;
@property (nonatomic, readwrite) BOOL finished;

/**
 * Use this method to let a task retain itself.
 *
 * @note This method will deploy a retain cycle to gurantee current task will not be deallocated. Hence, method
 * -unretainSelf must be called in pair to release this retain cycle.
 */
- (void)retainSelf;

/**
 * Use this method to let a task unretain itself.
 */
- (void)unretainSelf;

@end
