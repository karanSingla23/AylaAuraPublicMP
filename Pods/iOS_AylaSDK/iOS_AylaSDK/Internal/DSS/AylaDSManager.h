//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDeviceManager.h"
#import "AylaDSError.h"
#import "AylaDSSubscription.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AylaDSState) {
    /** Initial state of the DSmanager */
    AylaDSStateUninitialized,
    
    /** `AylaDSManager` is initialized, and subscription is getting created */
    AylaDSStateInitialized,
    
    /** `AylaDSManager` is between start of create subscription and connection complete */
    AylaDSStateConnecting,
    
    /** Websocket connected */
    AylaDSStateConnected,
    
    /** Websocket disconnected. */
    AylaDSStateDisconnected
};

@class AylaDSManager;
@class AylaSessionManager;
@class AylaSystemSettings;

/**
 * DSS manager protocol
 */
@protocol AylaDSManagerListener<NSObject>

@optional
/**
 * Called when the DS manager has eastablished connection.
 */
- (void)didConnectDSManager:(AylaDSManager *)manager;

/**
 * Called when the DS manager attempts to open a new connection.
 */
- (void)connectingDSManager:(AylaDSManager *)manager;

/**
 * Called when dss manager is initialized.
 */
- (void)didInitializeDSManager:(AylaDSManager *)dsManager;

/**
 * Called when DS is disconnected due to a pause or an error occured in manager.
 */
- (void)dsManager:(AylaDSManager *)dsManager didDisconnectWithError:(NSError *)error;

/**
 * Called when a message is received by dss manager.
 */
- (void)dsManager:(AylaDSManager *)dsManager didReceiveMessage:(id)message;

@end

@interface AylaDSManager : NSObject<AylaDeviceManagerListener>

/** Weak reference to linked device manager. */
@property (nonatomic, weak, readonly, nullable) AylaDeviceManager *deviceManager;

/** Manager state. */
@property (nonatomic, assign, readonly) AylaDSState state;


/**
 Client used during Subscription tests
 */
@property (nonatomic, strong) AylaHTTPClient *testSubscriptionClient;

/**
 * Designated initializer of DSS manager.
 *
 * @param settings      System settings applied to dss manager
 * @param deviceManager Linked device manager.
 * @param httpClient    Http client which will be used to communicate with cloud service.
 */
- (instancetype)initWithSettings:(AylaSystemSettings *)settings
                   deviceManager:(AylaDeviceManager *)deviceManager
                      httpClient:(AylaHTTPClient *)httpClient NS_DESIGNATED_INITIALIZER;

/** Add a listener which conforms protocol `AylaDSManagerListener` */
- (void)addListener:(id<AylaDSManagerListener>)listener;

/** Remove a listener which conforms protocol `AylaDSManagerListener` */
- (void)removeListener:(id<AylaDSManagerListener>)listener;

/**
 * Use this method to resume paused DS connection
 */
- (void)resume;

/**
 * Use this method to pause DS connection
 */
- (void)pause;

// Unavailable methods
- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns YES if DSS is currently connected
 */
@property (readonly) BOOL isConnected;

/**
 * Returns YES if DSS is currently connecting
 */
@property (readonly) BOOL isConnecting;
@end

NS_ASSUME_NONNULL_END
