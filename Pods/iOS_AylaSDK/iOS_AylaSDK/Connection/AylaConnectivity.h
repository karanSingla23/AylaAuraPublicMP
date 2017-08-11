//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AylaConnectTask;
@class AylaConnectivity;
@class AylaListenerArray;
@class AylaSystemSettings;

/**
 * The available states of Network Reachability.
 */
typedef NS_ENUM(NSInteger, AylaNetworkReachabilityStatus) {
    /**
     * Unknown status.
     */
    AylaNetworkReachabilityStatusUnknown = -1,
    /**
     * Network is not reachable.
     */
    AylaNetworkReachabilityStatusNotReachable = 0,
    /**
     * Network is reachable via WWAN
     */
    AylaNetworkReachabilityStatusReachableViaWWAN = 1,
    /**
     * Network is reachable via Wi-Fi
     */
    AylaNetworkReachabilityStatusReachableViaWiFi = 2,
};

/** A notification to be sent when connectivity has been enabled and a network change has been observed */
FOUNDATION_EXPORT NSString *const AylaConnectivityNetworkChangeNotification;

/**
 * Connectivity listener protocol.
 */
@protocol AylaConnectivityListener<NSObject>

/**
 * Inform listener a network change has been observed.
 *
 * @param connectivity       The `AylaConnectivity` object which sent out this request.
 * @param reachabilityStatus The updated `AylaNetworkReachabilityStatus` description
 */
- (void)connectivity:(AylaConnectivity *)connectivity
    didObserveNetworkChange:(AylaNetworkReachabilityStatus)reachabilityStatus;

@end

/**
 * Connectivity is a helpful class to detect or monitor changes in network status.
 *
 * It provides a listener interface for other components to monitor network changes. It also provides other methods to
 * help determine the reachability of the Ayla Cloud Service.
 */
@interface AylaConnectivity : NSObject

/** @name Initializer Methods */

/**
 * Use this method to init a new connectivity instance
 *
 * @param settings The `AylaSystemSettings`to be used for this `AylaConnectivity` instance
 */
- (instancetype)initWithSettings:(AylaSystemSettings *)settings;


/** @name Listener Methods */

/**
 * Add a listener which conforms to the `AylaConnectivityListener` protocol
 * @param listener  An object that conforms to the `AylaConnectivityListener` protocol that is to be added as a listener
 */
- (void)addListener:(id<AylaConnectivityListener>)listener;

/**
 * Remove a listener which conforms to the `AylaConnectivityListener` protocol
 * @param listener  An object that conforms to the `AylaConnectivityListener` protocol that is to be removed as a listener
 */
- (void)removeListener:(id<AylaConnectivityListener>)listener;

/** @name Network Monitoring Methods */

/**
 * Start monitoring network changes
 */
- (void)startMonitoringNetworkChanges;

/**
 * Stop monitoring network changes
 */
- (void)stopMonitoringNetworkChanges;

/**
 * Use this method to determine the reachability of the Ayla Cloud Service.
 *
 * @param responseBlock A block to be called when reachablity to cloud has been determined. Passed two `boolean`s, one indicating whether
 * the cloud service was reachable, and another indicating if the request was cancelled.
 *
 * @return A `AylaConnectTask` object which handles this request.
 */
- (AylaConnectTask *)determineServiceReachability:(void (^)(BOOL isReachable, BOOL cancelled))responseBlock;

@end

NS_ASSUME_NONNULL_END