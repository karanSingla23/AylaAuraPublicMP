//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#ifndef _AylaNetworks_
#define _AylaNetworks_

#import "AylaDefines.h"

// Authorization
#import "AylaAuthorization.h"
#import "AylaCachedAuthProvider.h"
#import "AylaLoginManager.h"
#import "AylaUsernameAuthProvider.h"

// Components
#import "AylaDatapoint.h"
#import "AylaDevice.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceManager.h"
#import "AylaDeviceNode.h"
#import "AylaProperty.h"
#import "AylaRegistration.h"
#import "AylaRegistrationCandidate.h"
#import "AylaSessionManager.h"
#import "AylaUser.h"

// Changes
#import "AylaDeviceChange.h"
#import "AylaDeviceListChange.h"
#import "AylaPropertyChange.h"

// Utils
#import "AylaConnectivity.h"
#import "AylaErrorUtils.h"
#import "AylaLogManager.h"
#import "AylaSystemSettings.h"
#import "AylaSystemUtils.h"

// Plugins
#import "AylaDeviceClassPlugin.h"
#import "AylaDeviceListPlugin.h"


NS_ASSUME_NONNULL_BEGIN

/**
 * Device Class plugin identifier. Device class plugins implement the
 * AylaDeviceClassPlugin interface.
 */
extern NSString * const PLUGIN_ID_DEVICE_CLASS;

/**
 * Device List plugin identifier. Device list plugins implement the
 * {@link com.aylanetworks.aylasdk.plugin.DeviceListPlugin} interface and can be used to
 * manipulate the master device list within AylaDeviceManager.
 */
extern NSString * const PLUGIN_ID_DEVICE_LIST;

/**
 * AylaNetworks
 *
 * AylaNetworks is the entry point of Ayla Mobile SDK.
 * Application must initialize before accessing any features
 * provided in library.
 *
 * The SDK only maintains one instance of the AylaNetworks object.
 */
@interface AylaNetworks : NSObject

/** SDK system settings */
@property (nonatomic, readonly) AylaSystemSettings *systemSettings;

/** `AylaLoginManager` assigned to this instance */
@property (nonatomic, readonly) AylaLoginManager *loginManager;

/**
 * The AylaConnectivity instance that can be used to register for network state change notifications.
 */
@property (nonatomic, readonly) AylaConnectivity *connectivity;
/** @name Initializer Methods */

/**
 * Use this method to initialize a new SDK root (`AylaNetworks`) with the input system settings.
 * Since the library only retains one SDK root each time per instance, this method call will
 * always trigger a replacement of the existing root inside the library.  This also means the application itself 
 * must reset its life cycle with this newly initialized instance.
 *
 * @note +shared: will always return the latest `AylaNetworks` instance to have been
 * initialized by this method.
 *
 * @param settings An `AylaSystemSettings` object
 */
+ (instancetype)initializeWithSettings:(AylaSystemSettings *)settings;

/**
 * Returns an installed plug-in, if present
 * @param pluginId the ID of the plugin service to obtain
 * @return the AylaPlugin that was previously installed, or nil if not found
 */
- (id<AylaPlugin>)getPluginWithId:(NSString *)pluginId;

/**
 * Installs a plug-in into the Ayla SDK.  Plug-ins may be obtained by calling `getPlugInWithId`.
 * Installing a plug-in with the same ID as a previous one will overwrite it.
 *
 * @param plugin the plugin to install
 * @param pluginId The ID for this plug-in identifying its utility
 */
- (void)installPlugin:(id<AylaPlugin>)plugin id:(NSString *)pluginId;

/**
 * Use this method to get the session with the specified name if it exists.
 *
 * @param sessionName The `sessionName` registered by `AylaSessionManager`.
 *
 * @return The active `AylaSessionManager` which matches the give name. Will return `nil` if requested session manager is
 * not found.
 */
- (nullable AylaSessionManager *)getSessionManagerWithName:(NSString *)sessionName;

/** @name Properties */

/**
 * Use this method to get the shared instance.
 */
+ (instancetype)shared;

/**
 * Applications should call this method when it enters the background.
 */
- (void)pause;

/**
 * Applications should call this method to resume functionality when the app returns from the background.
 */
- (void)resume;

/**
 * Get the current version of the SDK.
 */
+ (NSString *)getVersion;

/**
 * Get the support email address.
 */
+ (NSString *)getSupportEmailAddress;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END

#endif /* _AylaNetworks_ */
