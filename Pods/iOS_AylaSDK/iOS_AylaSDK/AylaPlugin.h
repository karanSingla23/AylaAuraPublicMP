//
//  AylaPlugin.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/7/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaSessionManager;

NS_ASSUME_NONNULL_BEGIN

/**
 * AylaPlugin is the base interface for the Ayla Mobile SDK plugin system. Plugins may be
 * installed in the SDK via calls to `[AylaNetworks installPlugin:id:]
 *
 * Any object implementing this interface may be installed as a plugin. The objects will be
 * called via the AylaPlugin interfaces when the SDK is initialized, paused, resumed or shut down.
 *
 * Installed plugins may be obtained from the AylaNetworks singleton object by calling
 * `[AylaNetworks  getPluginWithId:].
 */
@protocol AylaPlugin <NSObject>

/**
 @return plugin name
 */
- (NSString *)pluginName;

/**
 * Called when the provided `AylaSessionManager` has successfully started a session (signed in)
 * @param pluginId ID the plugin was registered with
 * @param sessionManager Session manager for the session that just signed in
 */
- (void)initializePlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager;

/**
 * Called when the SDK is paused
 * @param pluginId ID the plugin was registered with
 * @param sessionManager SessionManager for the session that is being paused
 */- (void)pausePlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager;

/**
 * Called when the SDK is resumed
 * @param pluginId ID the plugin was registered with
 * @param sessionManager SessionManager for the session that is being resumed
 */
- (void)resumePlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager;

/**
 * Called when a session is shut down (signed out)
 * @param pluginId ID the plugin was registered with
 * @param sessionManager SessionManager for the session that is being ended
 */
- (void)shutDownPlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager;
@end
NS_ASSUME_NONNULL_END
