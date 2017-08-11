//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaSystemSettings;

/**
 * AylaSystemUtils
 *
 * A container of helpful methods which are widely used by the SDK.
 */
@interface AylaSystemUtils : NSObject

/** @name Service URL Methods */

/**
 * Get HTTP(S) user service base url with input system settings
 *
 * @param settings `AylaSystemSettings` object which is going to be used to
 * compose the url.
 * @param isSecure If this is a HTTPS connection.
 *
 * @return Generated user service base url.
 */
+ (NSString *)userServiceBaseUrl:(AylaSystemSettings *)settings
                        isSecure:(BOOL)isSecure;

/**
 * Get HTTP(S) device service base url with input system settings
 *
 * @param settings `AylaSystemSettings `object which is going to be used to
 * compose the url.
 * @param isSecure If this is a HTTPS connection.
 *
 * @return Generated device service base url.
 */
+ (NSString *)deviceServiceBaseUrl:(AylaSystemSettings *)settings
                          isSecure:(BOOL)isSecure;

/**
 * Get HTTP(S) log service base url with input system settings
 *
 * @param settings `AylaSystemSettings` object which is going to be used to
 * compose the url.
 * @param isSecure If this is a HTTPS connection.
 *
 * @return Generated log service base url.
 */
+ (NSString *)logServiceBaseUrl:(AylaSystemSettings *)settings
                       isSecure:(BOOL)isSecure;

/**
 * Get HTTP(S) stream service base url with input system settings
 *
 * @param settings `AylaSystemSettings` object which is going to be used to
 * compose the url.
 * @param isSecure If this is a HTTPS connection.
 *
 * @return Generated stream service base url.
 *
 * @note Because of the inconsistency on cloud side, api version is not added in
 * stream service url.
 */
+ (NSString *)streamServiceBaseUrl:(AylaSystemSettings *)settings
                          isSecure:(BOOL)isSecure;

/**
 * Get HTTP(S) stream subscription service base url with input system settings
 *
 * @param settings `AylaSystemSettings` object which is going to be used to
 * compose the url.
 * @param isSecure If this is a HTTPS connection.
 *
 * @return Generated stream service base url.
 *
 * @note Because of the inconsistency on cloud side, api version is not added in
 * stream service url.
 */
+ (NSString *)mdssSubscriptionServiceBaseUrl:(AylaSystemSettings *)settings
                          isSecure:(BOOL)isSecure;

/**
 * Get HTTP(S) device base url with input lan ip.
 *
 * @param lanIp The local LAN IP address of the device.
 * @param isSecure If this is a HTTPS connection.
 *
 * @return Generated device base url.
 */
+ (NSString *)deviceBaseUrlWithLanIp:(NSString *)lanIp isSecure:(BOOL)isSecure;

/**
 * Get base url for service reachability check.
 * @param settings the `AylaSystemSettings` that will be used to to compose the
 * url
 *
 * @return Generated reachability url.
 */
+ (NSString *)reachabilityBaseUrlWithSettings:(AylaSystemSettings *)settings;

/** @name Utility Methods */

/**
 * Get default data formatter
 */
+ (NSDateFormatter *)defaultDateFormatter;

/**
 * Get LAN IP Address of current mobile phone/tablet device.
 *
 * @return Return NSString representation of the current LAN IP address. Nil
 * will be returned if no LAN IP is found.
 */
+ (nullable NSString *)getLanIp;

/**
 * @param sessionName The name of the session
 * @return The path to the device archives directory
 */
+ (NSString *)deviceArchivesPathForSession:(NSString *)sessionName;

/**
 * @param sessionName The name of the session
 * @return The path to the devices archive
 */
+ (NSString *)devicesArchiveFilePathForSession:(NSString *)sessionName;

/**
 * Get HTTP(S) service base url constructed using given parameters.
 *
 * @param baseURL Base URL string
 * @param serviceLocation AylaServiceLocation
 * @param isSecure BOOL indicating if the service endpoint is secure
 *
 * @return Generated service base url
 */
+ (NSString *)serviceBaseUrl:(NSString *)baseURL
             serviceLocation:(AylaServiceLocation)serviceLocation
                    isSecure:(BOOL)isSecure;

@end

NS_ASSUME_NONNULL_END
