//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AylaSessionManager;

NS_ASSUME_NONNULL_BEGIN
/**
 *  Key to specify a DSN to clear in `clear:withParams:`
 */
FOUNDATION_EXPORT NSString *const AylaCacheParamDeviceDsn;

/**
 *  Enumerates the Cache types, types can be combined into a bitmask.
 */
typedef NS_ENUM(NSInteger, AylaCacheType) {
  /**
   *  Caches the Devices
   */
  AylaCacheTypeDevice = 0x01,
  /**
   *  Caches the device properties
   */
  AylaCacheTypeProperty = 0x02,
  /**
   *  Caches the LAN Mode Configuration
   */
  AylaCacheTypeLANConfig = 0x04,
  /**
   *  Caches the device during WiFi Setup & Registration
   */
  AylaCacheTypeSetup = 0x08,
  /**
   *  Caches Groups
   */
  AylaCacheTypeGroup = 0x10,
  /**
   *  Caches Nodes of a Gateway
   */
  AylaCacheTypeNode = 0x20,
  /**
   *  Represents all type of caches
   */
  AylaCacheTypeAll = 0xFF
};

/**
 * `AylaCache` class controls caching in Ayla SDK. `AylaCache` allows devices
 * and properties to be saved so they are
 * available when service connectivity is not available. Typical use case is in
 * LAN-login feature (device access without
 * service authentication)
 */
@interface AylaCache : NSObject

/**
 * Initializer for AylaCache. Must be provided the AylaSessionManager's session
 * name for the session
 * to be cached
 * @param sessionName The name of the session
 */
- (instancetype)initWithSessionName:(NSString *)sessionName;

/**
 *  @return Returns NO if no caching is enabled, YES if at least one type of
 * caching is enabled.
 */
- (BOOL)cachingEnabled;

/**
 * Determine if a particular cache(s) is/are enabled
 * @param mask a bitmask of the caches to check (from `AylaCacheType` e.g. `AylaCacheTypeNode`, `AylaCacheTypeNode | AylaCacheTypeDevice`)
 * @return true if the caches to check are enabled
 */
- (BOOL)cachingEnabled:(NSInteger)mask;

/**
 * @warning - enabling/disabling individual caches may lead to unexpected behavior, consider clearCache() instead
 * Enables cache(s) in the mask of `AylaCacheType`
 * @param mask a bitmask of the caches to enable (from `AylaCacheType` e.g. `AylaCacheTypeNode`, `AylaCacheTypeNode | AylaCacheTypeDevice`)
 */
- (void)enable:(NSInteger)mask;

/**
 * @warning - disabling/enabling individual caches may lead to unexpected behavior, consider clearCache() instead
 * Disables cache(s) in the mask of `AylaCacheType`
 * @param mask  a bitmask of the caches to disable (from `AylaCacheType` e.g. `AylaCacheTypeNode`, `AylaCacheTypeNode | AylaCacheTypeDevice`)
 */
- (void)disable:(NSInteger)mask;

/**
 * Clears (deletes) all caches
 */
- (void)clearAll;

/**
 * Clears (deletes) caches in the mask of `AylaCacheType`
 * @param mask a bitmask of the caches to clear (from `AylaCacheType` e.g. `AylaCacheTypeNode`, `AylaCacheTypeNode | AylaCacheTypeDevice`)
 */
- (void)clear:(NSInteger)mask;

/**
 * Clear caches based on AML_CACHE_XXXXX
 * @param mask a bitmask of the caches to clear
 * @param params to specify what to be cleaned (e.g. `AylaCacheParamDeviceDsn`)
 * @warning mask only supports `AylaCacheTypeProperty`
 */
- (void)clear:(NSInteger)mask withParams:(NSDictionary *)params;

/**
 * @return  a bitmask of the currently enabled caches (from `AylaCacheType` e.g.
 `AylaCacheTypeNode`,
 `AylaCacheTypeNode | AylaCacheTypeDevice`)
 */
- (NSInteger)caches;
@end
NS_ASSUME_NONNULL_END
