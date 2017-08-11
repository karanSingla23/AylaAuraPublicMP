//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Wifi connection errors
 */
typedef NS_ENUM(uint16_t, AylaWifiConnectionError) {
    /**
     * No error
     */
    AylaWifiConnectionErrorNoError = 0,
    /**
     * Resource problem, out of memory or buffers, perhaps temporary.
     */
    AylaWifiConnectionErrorResourceProblem = 1,
    /**
     * Connection timed out.
     */
    AylaWifiConnectionErrorConnectionTimedOut = 2,
    /**
     * Invalid key.
     */
    AylaWifiConnectionErrorInvalidKey = 3,
    /**
     * SSID not found.
     */
    AylaWifiConnectionErrorSSIDNotFound = 4,
    /**
     * Not authenticated via 802.11 or failed to associate with the AP.
     */
    AylaWifiConnectionErrorNotAuthenticated = 5,
    /**
     * Incorrect key
     */
    AylaWifiConnectionErrorIncorrectKey = 6,
    /**
     * Failed to get IP address from DHCP.
     */
    AylaWifiConnectionErrorDHCP_IP = 7,
    /**
     * Failed to get default gateway from DHCP.
     */
    AylaWifiConnectionErrorDHCP_GW = 8,
    /**
     * Failed to get DNS server from DHCP.
     */
    AylaWifiConnectionErrorDHCP_DNS = 9,
    /**
     * Disconnected by AP.
     */
    AylaWifiConnectionErrorDisconnected = 10,
    /**
     * Signal lost from AP (beacon miss).
     */
    AylaWifiConnectionErrorSignalLost = 11,
    /**
     * Service host lookup failed
     */
    AylaWifiConnectionErrorDeviceServiceLookup = 12,
    /**
     * Service GET was redirected
     */
    AylaWifiConnectionErrorDeviceServiceRedirect = 13,
    /**
     * Service connection timed out
     */
    AylaWifiConnectionErrorDeviceServiceTimedOut = 14,
    /**
     * No empty Wi-Fi profile slots
     */
    AylaWifiConnectionErrorNoProfileSlots = 15,
    /**
     * The security method used by the AP is not supported.
     */
    AylaWifiConnectionErrorSecNotSupported = 16,
    /**
     * The network type (e.g. ad-hoc) is not supported.
     */
    AylaWifiConnectionErrorNetTypeNotSupported = 17,
    /**
     * The server responded in an incompatible way.  The AP may be a Wi-Fi hotspot.
     */
    AylaWifiConnectionErrorServerIncompatible = 18,
    /**
     * Service authentication failed.
     */
    AylaWifiConnectionErrorServiceAuthFailure = 19,
    /**
     * Connection attempt is still in progress.
     */
    AylaWifiConnectionErrorInProgress = 20
};

/**
 * Each connection history represents one entry in connection history array.
 */
@interface AylaWifiConnectionHistory : AylaObject

/** The first and last characters of the SSID used */
@property (nonatomic, strong, readonly) NSString *ssidInfo;

/** BSSID in string */
@property (nonatomic, strong, readonly) NSString *bssid;

/** Error code of this connection history */
@property (nonatomic, assign, readonly) AylaWifiConnectionError error;

/** A readable string which describes error */
@property (nonatomic, strong, readonly, nullable) NSString *msg;

/** Device side time in milliseconds */
@property (nonatomic, assign, readonly) NSUInteger mtime;

/** Used ip Address */
@property (nonatomic, strong, readonly) NSString *ipAddress;

/** Netmask */
@property (nonatomic, strong, readonly) NSString *netmask;

/** Ip address of default route */
@property (nonatomic, strong, readonly) NSString *defaultRoute;

/** DNS servers */
@property (nonatomic, strong, readonly) NSArray *dnsServers;

@end

/**
 * Each Wifi Status represents wifi info fetched from setup device.
 */
@interface AylaWifiStatus : AylaObject

/** @name Wi-Fi Status Properties */

/** Device dsn */
@property (nonatomic, strong, readonly) NSString *dsn;

/** Current connected SSID */
@property (nonatomic, strong, readonly, nullable) NSString *connectedSsid;

/** Base url of device service */
@property (nonatomic, strong, readonly) NSString *deviceService;

/** Symbolic host name */
@property (nonatomic, strong, readonly, nullable) NSString *hostSymname;

/** Device MAC address */
@property (nonatomic, strong, readonly, nullable) NSString *mac;

/** Device side time in milliseconds */
@property (nonatomic, assign, readonly) NSUInteger mtime;

/** ANT */
@property (nonatomic, assign, readonly) int ant;

/** RSSI */
@property (nonatomic, assign, readonly) int rssi;

/** Bars */
@property (nonatomic, assign, readonly) int bars;

/** Base url of log service */
@property (nonatomic, strong, readonly, nullable) NSString *logService;

/** WPS status */
@property (nonatomic, strong, readonly, nullable) NSString *wps;

/** An array of received connection histories */
@property (nonatomic, strong, readonly) NSArray AYLA_GENERIC(AylaWifiConnectionHistory *) *connectHistory;

/** WiFi connection state */
@property (nonatomic, strong, readonly, nullable) NSString *state;
@end

NS_ASSUME_NONNULL_END
