//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaNetworks.h"
#import "AylaDefines_Internal.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPClient;
@class AylaSessionManager;
@interface AylaNetworks (Internal)

/**
 * Register a session manager to SDK
 */
- (void)addSessionManager:(AylaSessionManager *)sessionManager;

/**
 * Remove a session manager from SDK
 */
- (void)removeSessionManager:(AylaSessionManager *)sessionManager;

@end

NS_ASSUME_NONNULL_END
