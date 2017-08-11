//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AylaSessionManager;

NS_ASSUME_NONNULL_BEGIN
/**
 * Protocol for devices that can use LAN mode.
 */
@protocol AylaLanSupportDevice <NSObject>

/** The DSN of the LAN mode capable device. */
@property(nonatomic, readonly) NSString *dsn;
/** The LAN mode authentication key of the device. */
@property(nonatomic, readonly, nullable) NSNumber *key;
/** The local LAN IP Address of the LAN mode capable device. */
@property(nonatomic, readonly, nullable) NSString *lanIp;
/** The AylaSessionManager responsible for the session the device runs under */
@property(nonatomic, readonly, nonnull) AylaSessionManager *sessionManager;
/** makes LAN mode temporarily disabled */
@property(nonatomic, assign, readwrite) BOOL disableLANUntilNetworkChanges;
@end

NS_ASSUME_NONNULL_END
