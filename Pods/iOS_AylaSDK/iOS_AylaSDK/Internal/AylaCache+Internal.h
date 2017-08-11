//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaCache.h"
#import "AylaSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const AylaCacheTypeLANConfigPrefix;
extern NSString *const AylaCacheTypeDevicePrefix;
extern NSString *const AylaCacheTypePropertyPrefix;
extern NSString *const AylaCacheTypeNodePrefix;
extern NSString *const AylaCacheTypeSetupPrefix;
extern NSString *const AylaCacheTypeGroupPrefix;

@interface AylaCache (Internal)

/**
 * get a cache from storage w/o a unique identifier
 * used to retrieve top level caches like devices and groups
 *
 * @param type - cache type (see `AylaCacheType`)
 * @return
 */
- (id)getData:(NSString *)key;

/**
 * get a cache from storage
 * used to retrieve device specific caches like properties and LAN config Info
 *
 * @param type - cache type (see `AylaCacheType`)
 * @param uniqueId - unique identifier appended to cache type prefix
 * @return
 */
- (id)getData:(AylaCacheType)type uniqueId:(NSString *)uniqueId;

/**
 *  Get cache key for retrieving data for this cache type.
 *
 *  @param type   Cache Type
 *  @param save   Unique id to be appended to the cache type prefix for this
 * entry.
 *
 *  @return A key which can be used to access data from this cache
 */
- (NSString *)getKey:(AylaCacheType)type uniqueId:(NSString *)uniqueId;

/**
 * save a cache from storage w/o unique name identifier
 * used to save top level caches like devices and groups
 *
 * @param type - The `AylaCacheType` to save
 * @param value - string data written to storage
 */
- (BOOL)save:(NSString *)name object:(id)value;

/**
 * save a cache from storage w/o unique name identifier
 * used to save device specific level caches like properties and LAN config info
 *
 * @param type - The `AylaCacheType` to save
 * @param uniqueId - appended to type base identifier, typically the device dsn
 * @param valueToCache - string data written to storage
 */
- (BOOL)save:(AylaCacheType)type
    uniqueId:(NSString *)uniqueId
   andObject:(id)valueToCache;

/**
 * Property used to aid testability by injecting an encryption key, only used during DEBUG
 */
@property (strong, nonatomic) NSString *_testSessionAccessToken;
@end
NS_ASSUME_NONNULL_END