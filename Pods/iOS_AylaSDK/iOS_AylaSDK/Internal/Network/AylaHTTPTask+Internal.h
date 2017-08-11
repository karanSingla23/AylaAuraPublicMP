//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaHTTPTask.h"

@interface AylaHTTPTask (Internal)

/** Task object which handles implementations */
@property (nonatomic, strong, readwrite) id task;

/** Response(result) of current HTTP task */
@property (nonatomic, strong, readwrite) id responseObject;

@end
