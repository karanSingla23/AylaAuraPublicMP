//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"
#import "AylaSystemSettings.h"
#import "AylaSystemUtils.h"

#import <arpa/inet.h>
#import <ifaddrs.h>

// Ayla Service URLs
#define AYLA_USER_SERVICE_BASE_URL_FIELD @"user-field.aylanetworks.com"
#define AYLA_USER_SERVICE_BASE_URL_DEVELOPMENT @"user-dev.aylanetworks.com"
#define AYLA_USER_SERVICE_BASE_URL_STAGING @"staging-user.ayladev.com"
#define AYLA_USER_SERVICE_BASE_URL_DEMO @"staging-user.ayladev.com"

#define AYLA_DEVICE_SERVICE_BASE_URL_FIELD @"ads-field.aylanetworks.com"
#define AYLA_DEVICE_SERVICE_BASE_URL_DEVELOPMENT @"ads-dev.aylanetworks.com"
#define AYLA_DEVICE_SERVICE_BASE_URL_STAGING @"staging-ads.ayladev.com"
#define AYLA_DEVICE_SERVICE_BASE_URL_DEMO @"staging-ads.ayladev.com"

#define AYLA_LOG_SERVICE_BASE_URL_FIELD @"log.aylanetworks.com"
#define AYLA_LOG_SERVICE_BASE_URL_DEVELOPMENT @"log.aylanetworks.com"
#define AYLA_LOG_SERVICE_BASE_URL_STAGING @"staging-log.ayladev.com"
#define AYLA_LOG_SERVICE_BASE_URL_DEMO @"staging-log.ayladev.com"

#define AYLA_STREAM_SERVICE_BASE_URL_FIELD @"stream-field.aylanetworks.com"
#define AYLA_STREAM_SERVICE_BASE_URL_DEVELOPMENT @"stream.aylanetworks.com"
#define AYLA_STREAM_SERVICE_BASE_URL_STAGING @"staging-mdstr2.ayladev.com"
#define AYLA_STREAM_SERVICE_BASE_URL_DEMO @"staging-dstr.ayladev.com"

static NSString *const https = @"https://";
static NSString *const http = @"http://";
static NSString *const serviceDomainUS = @".aylanetworks.com";
static NSString *const serviceDomainCN = @".ayla.com.cn";
static NSString *const serviceDomainEUSuffix = @"-eu";

static NSString *documentsDirectory = nil;

@implementation AylaSystemUtils

/**
 * Get HTTP(S) user service base url with in-use system settings
 */
+ (NSString *)userServiceBaseUrl:(AylaSystemSettings *)settings
                        isSecure:(BOOL)isSecure {
    static NSDictionary *userServiceUrlMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userServiceUrlMap = @{
                              @(AylaServiceLocationUS): @{
                                      @(AylaServiceTypeField): @"https://user-field.aylanetworks.com/",
                                      @(AylaServiceTypeDevelopment): @"https://user-dev.aylanetworks.com/",
                                      @(AylaServiceTypeStaging): @"https://staging-user.ayladev.com/",
                                      @(AylaServiceTypeDemo): @"https://staging-user.ayladev.com/"
                                      },
                              @(AylaServiceLocationCN) : @{
                                      @(AylaServiceTypeField): @"https://user-field.ayla.com.cn/",
                                      @(AylaServiceTypeDevelopment): @"https://user-dev.ayla.com.cn/",
                                      @(AylaServiceTypeStaging): @"https://staging-user.ayladev.com.cn/",
                                      @(AylaServiceTypeDemo): @"https://staging-user.ayladev.com.cn/"
                                      },
                              
                              @(AylaServiceLocationEU) : @{
                                      @(AylaServiceTypeField): @"https://user-field-eu.aylanetworks.com/",
                                      @(AylaServiceTypeDevelopment): @"https://user-dev.aylanetworks.com/",
                                      @(AylaServiceTypeStaging): @"https://staging-user.ayladev.com/",
                                      @(AylaServiceTypeDemo): @"https://staging-user.ayladev.com/"
                                      }
                              };
    });
    NSString *url = userServiceUrlMap[@(settings.serviceLocation)][@(settings.serviceType)];
    if (!isSecure) {
        url = [url stringByReplacingOccurrencesOfString:https withString:http];
    }
    return url;
}

/**
 * Get HTTP(S) device service base url with in-use system settings
 */
+ (NSString *)deviceServiceBaseUrl:(AylaSystemSettings *)settings
                          isSecure:(BOOL)isSecure {
    static NSDictionary *deviceServiceUrlMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        deviceServiceUrlMap = @{
                                @(AylaServiceLocationUS): @{
                                        @(AylaServiceTypeField): @"https://ads-field.aylanetworks.com/",
                                        @(AylaServiceTypeDevelopment): @"https://ads-dev.aylanetworks.com/",
                                        @(AylaServiceTypeStaging): @"https://staging-ads.ayladev.com/",
                                        @(AylaServiceTypeDemo): @"https://staging-ads.ayladev.com/"
                                        },
                                @(AylaServiceLocationCN): @{
                                        @(AylaServiceTypeField): @"https://ads-field.ayla.com.cn/",
                                        @(AylaServiceTypeDevelopment): @"https://ads-dev.ayla.com.cn/",
                                        @(AylaServiceTypeStaging): @"https://staging-ads.ayladev.com.cn/",
                                        @(AylaServiceTypeDemo): @"https://staging-ads.ayladev.com.cn/"
                                        },
                                @(AylaServiceLocationEU): @{
                                        @(AylaServiceTypeField): @"https://ads-eu.aylanetworks.com/",
                                        @(AylaServiceTypeDevelopment): @"https://ads-dev.aylanetworks.com/",
                                        @(AylaServiceTypeStaging): @"https://staging-ads.ayladev.com/",
                                        @(AylaServiceTypeDemo): @"https://staging-ads.ayladev.com/"
                                        }
                              };
    });
    NSString *url = [deviceServiceUrlMap[@(settings.serviceLocation)][@(settings.serviceType)] stringByAppendingFormat:@"api%@/",
                                                      [self cloudAPIVersion]];
    if (!isSecure) {
        url = [url stringByReplacingOccurrencesOfString:https withString:http];
    }
    return url;
}

/**
 * Get HTTP(S) log service base url with in-use system settings
 */
+ (NSString *)logServiceBaseUrl:(AylaSystemSettings *)settings
                       isSecure:(BOOL)isSecure {
    static NSDictionary *logServiceUrlMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logServiceUrlMap = @{
                             @(AylaServiceLocationUS): @{
                                     @(AylaServiceTypeField): @"https://log.aylanetworks.com/",
                                     @(AylaServiceTypeDevelopment): @"https://log.aylanetworks.com/",
                                     @(AylaServiceTypeStaging): @"https://staging-log.ayladev.com/",
                                     @(AylaServiceTypeDemo): @"https://staging-log.ayladev.com/"
                                     },
                             @(AylaServiceLocationCN): @{
                                     @(AylaServiceTypeField): @"https://log.ayla.com.cn/",
                                     @(AylaServiceTypeDevelopment): @"https://log.ayla.com.cn/",
                                     @(AylaServiceTypeStaging): @"https://staging-log.ayladev.com.cn/",
                                     @(AylaServiceTypeDemo): @"https://staging-log.ayladev.com.cn/"
                                     },
                             @(AylaServiceLocationEU): @{
                                     @(AylaServiceTypeField): @"https://log-eu.aylanetworks.com/",
                                     @(AylaServiceTypeDevelopment): @"https://log-eu.aylanetworks.com/",
                                     @(AylaServiceTypeStaging): @"https://staging-log-eu.ayladev.com/",
                                     @(AylaServiceTypeDemo): @"https://staging-log-eu.ayladev.com/"
                                     }
                             };
    });
    NSString *url = [logServiceUrlMap[@(settings.serviceLocation)][@(settings.serviceType)] stringByAppendingFormat:@"api/%@/",
                     [self cloudAPIVersion]];
    if (!isSecure) {
        url = [url stringByReplacingOccurrencesOfString:https withString:http];
    }
    return url;
}

/**
 * Get HTTP(S) DSS service base url with in-use system settings
 */
+ (NSString *)streamServiceBaseUrl:(AylaSystemSettings *)settings
                          isSecure:(BOOL)isSecure {
    static NSDictionary *dsServiceUrlMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dsServiceUrlMap = @{
                              @(AylaServiceLocationUS): @{
                                      @(AylaServiceTypeField): @"https://mstream-field.aylanetworks.com/",
                                      @(AylaServiceTypeDevelopment): @"https://mstream-dev.aylanetworks.com/",
                                      @(AylaServiceTypeStaging): @"https://staging-mstream.ayladev.com/",
                                      @(AylaServiceTypeDemo): @"https://staging-mstream.ayladev.com/"
                                      },
                              @(AylaServiceLocationCN) : @{
                                      @(AylaServiceTypeField): @"https://mstream-field.ayla.com.cn/",
                                      @(AylaServiceTypeDevelopment): @"https://mstream-dev.ayla.com.cn/",
                                      @(AylaServiceTypeStaging): @"https://staging-mstream.ayladev.com/",
                                      @(AylaServiceTypeDemo): @"https://staging-mstream.ayladev.com/"
                                      },
                              
                              @(AylaServiceLocationEU) : @{
                                      @(AylaServiceTypeField): @"https://mstream-field-eu.aylanetworks.com/",
                                      @(AylaServiceTypeDevelopment): @"https://mstream-dev.aylanetworks.com/",
                                      @(AylaServiceTypeStaging): @"https://staging-mstream.ayladev.com/",
                                      @(AylaServiceTypeDemo): @"https://staging-mstream.ayladev.com/"
                                      }
                              };
    });
    
    NSString *url = dsServiceUrlMap[@(settings.serviceLocation)][@(settings.serviceType)];
    if (!isSecure) {
        url = [url stringByReplacingOccurrencesOfString:https withString:http];
    }
    return url;
}


/**
 * Get HTTP(S) mDSS REST service base url with in-use system settings
 */
+ (NSString *)mdssSubscriptionServiceBaseUrl:(AylaSystemSettings *)settings
                                    isSecure:(BOOL)isSecure {
    static NSDictionary *dsSubscriptionServiceUrlMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dsSubscriptionServiceUrlMap = @{
                            @(AylaServiceLocationUS): @{
                                    @(AylaServiceTypeField): @"https://mdss-field.aylanetworks.com/",
                                    @(AylaServiceTypeDevelopment): @"https://mdss-dev.aylanetworks.com/",
                                    @(AylaServiceTypeStaging): @"https://staging-mdss.ayladev.com/",
                                    @(AylaServiceTypeDemo): @"https://staging-mdss.ayladev.com/",
                                    },
                            @(AylaServiceLocationCN) : @{
                                    @(AylaServiceTypeField): @"https://mdss-field.ayla.com.cn/",
                                    @(AylaServiceTypeDevelopment): @"https://mdss-dev.ayla.com.cn/",
                                    @(AylaServiceTypeStaging): @"https://staging-mdss.ayladev.com/",
                                    @(AylaServiceTypeDemo): @"https://staging-mdss.ayladev.com/",
                                    },
                            
                            @(AylaServiceLocationEU) : @{
                                    @(AylaServiceTypeField): @"https://mdss-field-eu.aylanetworks.com/",
                                    @(AylaServiceTypeDevelopment): @"https://mdss-dev.aylanetworks.com/",
                                    @(AylaServiceTypeStaging): @"https://staging-mdss.ayladev.com/",
                                    @(AylaServiceTypeDemo): @"https://staging-mdss.ayladev.com/",
                                    }
                            };
    });
    
    NSString *url = dsSubscriptionServiceUrlMap[@(settings.serviceLocation)][@(settings.serviceType)];
    if (!isSecure) {
        url = [url stringByReplacingOccurrencesOfString:https withString:http];
    }
    return url;
}

+ (NSString *)reachabilityBaseUrlWithSettings:(AylaSystemSettings *)settings {
  // Use device service to determine service reachability.
  NSString *url = [self deviceServiceBaseUrl:settings isSecure:YES];

  // Get the api ver path.
  NSString *verPath =
      [NSString stringWithFormat:@"api%@/", [self cloudAPIVersion]];

  // Remove api ver path from the device service base url.
  return [url substringToIndex:url.length - verPath.length];
}

+ (NSString *)composeUserUrlWithProtocolPath:(NSString *)protocolPath
                                     baseUrl:(NSString *)baseUrl
                                    settings:(AylaSystemSettings *)settings
                              apiVersionPath:(NSString *)apiVersionPath {
    AylaServiceLocation location = settings.serviceLocation;
    if (settings.serviceType == AylaServiceTypeDevelopment && location == AylaServiceLocationEU) {
        location = AylaServiceLocationUS;
    }
    return [self composeUrlWithProtocolPath:protocolPath baseUrl:baseUrl location:location apiVersionPath:apiVersionPath];
    
}

+ (NSString *)composeUrlWithProtocolPath:(NSString *)protocolPath
                                 baseUrl:(NSString *)baseUrl
                                location:(AylaServiceLocation)location
                          apiVersionPath:(NSString *)apiVersionPath {
  NSString *urlWithLocation = [self addLocation:location toBaseUrl:baseUrl];
    BOOL baseContainsProtocolPath = [baseUrl rangeOfString:https].location == 0 || [baseUrl rangeOfString:http].location == 0;
    return [NSString stringWithFormat:@"%@%@/%@", baseContainsProtocolPath ? @"" : protocolPath, urlWithLocation,
                                    apiVersionPath];
}

/**
 * A helpful method to add location info to the input *BASE URL*
 * @param location Location info which to be added into url.
 * @param url Url that is going to be modified
 */
+ (NSString *)addLocation:(AylaServiceLocation)location
                toBaseUrl:(NSString *)baseUrl {
  NSString *newUrl = baseUrl;
  switch (location) {
  case AylaServiceLocationCN: {
    newUrl = [baseUrl stringByReplacingOccurrencesOfString:serviceDomainUS
                                                withString:serviceDomainCN];
    break;
  }
  case AylaServiceLocationEU: {
    NSRange rangeOfDot = [newUrl rangeOfString:@"."];
    // Find first dot
    if (rangeOfDot.location != NSNotFound) {
      NSMutableString *mutableUrl = [newUrl mutableCopy];
      [mutableUrl insertString:serviceDomainEUSuffix
                       atIndex:rangeOfDot.location];
      newUrl = mutableUrl;
    }
    break;
  }
  default:
    break;
  }
  return newUrl;
}

+ (NSString *)deviceBaseUrlWithLanIp:(NSString *)lanIp isSecure:(BOOL)isSecure {
  return [NSString stringWithFormat:@"%@%@/", isSecure ? https : http, lanIp];
}

+ (NSString *)cloudAPIVersion {
  return @"v1";
}

+ (NSString *)getLanIp {
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  NSString *wifiAddress = nil;
  NSString *cellAddress = nil;

  // retrieve the current interfaces - returns 0 on success
  if (!getifaddrs(&interfaces)) {
    // Loop through linked list of interfaces
    temp_addr = interfaces;
    while (temp_addr != NULL) {
      sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
      if (sa_type == AF_INET || sa_type == AF_INET6) {
        NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
        NSString *addr = [NSString
            stringWithUTF8String:inet_ntoa(
                                     ((struct sockaddr_in *)temp_addr->ifa_addr)
                                         ->sin_addr)]; // pdp_ip0

        if (([name isEqualToString:@"en0"] || [name isEqualToString:@"en1"]) &&
            ![addr isEqualToString:@"0.0.0.0"]) {
          // Interface is the wifi connection on the iPhone
          wifiAddress = addr;
        } else if ([name isEqualToString:@"pdp_ip0"]) {
          // Interface is the cell connection on the iPhone
          cellAddress = addr;
        }
      }
      temp_addr = temp_addr->ifa_next;
    }
    // Free memory
    freeifaddrs(interfaces);
  }
  NSString *addr = wifiAddress ? wifiAddress : cellAddress;
  return addr ? addr : nil;
}

+ (NSDateFormatter *)defaultDateFormatter {
  static NSDateFormatter *dateFormatter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *zone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:locale];
    [dateFormatter setTimeZone:zone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  });
  return dateFormatter;
}

+ (void)initialize {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  documentsDirectory =
      [NSString stringWithFormat:@"%@/Ayla", [paths objectAtIndex:0]];

  NSFileManager *manager = [NSFileManager defaultManager];
  if (![manager fileExistsAtPath:documentsDirectory]) {
    NSError *error;
    [manager createDirectoryAtPath:documentsDirectory
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error];
    if (error) {
      //            saveToLog(@"%@, %@, %@:%@, %@", @"E", @"SystemUtils",
      //            @"Failed To Create Dir", error, @"doInitialize");
    }
  }
}

+ (NSString *)deviceArchivesPathForSession:(NSString *)sessionName {
  NSString *path =
      [documentsDirectory stringByAppendingPathComponent:sessionName];

  // Make sure it exists
  NSFileManager *manager = [NSFileManager defaultManager];
  if (![manager fileExistsAtPath:path]) {
    [manager createDirectoryAtPath:path
        withIntermediateDirectories:YES
                         attributes:nil
                              error:nil];
  }

  return path;
}

+ (NSString *)devicesArchiveFilePathForSession:(NSString *)sessionName {
  return [[AylaSystemUtils deviceArchivesPathForSession:sessionName]
      stringByAppendingPathComponent:@"AylaDevicesArchiver.arch"];
}

/**
 * Get HTTP(S) service base url constructed using given parameters.
 */
+ (NSString *)serviceBaseUrl:(NSString *)baseURL
             serviceLocation:(AylaServiceLocation)serviceLocation
                    isSecure:(BOOL)isSecure {
    NSString *serviceBaseUrl = baseURL;
    return [self composeUrlWithProtocolPath:isSecure ? https : http
                                    baseUrl:serviceBaseUrl
                                   location:serviceLocation
                             apiVersionPath:@""];
}

@end
