//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaErrorUtils.h"
#import "AylaLanModule.h"
#import "AylaObject+Internal.h"
#import "AylaRegistration+Internal.h"
#import "AylaSetupDevice+Internal.h"
#import "NSObject+Ayla.h"
#import "AylaLanCommand.h"
#import "AylaLanTask.h"
#import "AylaNetworks+Internal.h"
#import "AylaWifiScanResults.h"
#import "AylaWifiStatus.h"
#import "AylaNetworkInformation.h"

static NSString *const attrNameApiVersion = @"api_version";
static NSString *const attrNameBuild = @"build";
static NSString *const attrNameDsn = @"dsn";
static NSString *const attrNameDeviceService = @"device_service";
static NSString *const attrNameFeatures = @"features";
static NSString *const attrNameLanIp = @"lan_ip";
static NSString *const attrNameLastConnectMtime = @"last_connect_mtime";
static NSString *const attrNameLastConnectTime = @"last_connect_time";
static NSString *const attrNameMac = @"mac";
static NSString *const attrNameModel = @"model";
static NSString *const attrNameMtime = @"mtime";
static NSString *const attrNameKey = @"key";
static NSString *const attrNameVersion = @"version";
static NSString *const attrNameDeviceType = @"device_type";
static NSString *const attrNameRegistrationType = @"registration_type";

@interface AylaSetupDevice ()

@property (nonatomic, readwrite) AylaLanModule *lanModule;
@property (nonatomic, readwrite) BOOL connectedStausFallback;

@end

@implementation AylaSetupDevice
@dynamic disableLANUntilNetworkChanges;
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;
    
    [self setPropertiesFromDictionary:dictionary];

    NSString *registrationType = [dictionary[attrNameRegistrationType] nilIfNull];
    if (registrationType) {
        _registrationType = [AylaRegistration registrationTypeFromName:registrationType];
    }

    // Setup lan module
    _lanModule = [[AylaLanModule alloc] initWithDevice:self];

    if (!_dsn) {
        NSError *foundError =
            [AylaErrorUtils errorWithDomain:AylaJsonErrorDomain
                                       code:AylaJsonErrorCodeInvalidJson
                                   userInfo:@{
                                       NSStringFromSelector(@selector(dsn)) : AylaErrorDescriptionCanNotBeFound
                                   }];
        if (error) {
            *error = foundError;
        }
    }

    return self;
}

- (void)setPropertiesFromDictionary:(NSDictionary *)dictionary {
    _key = [dictionary[attrNameKey] nilIfNull];
    _apiVersion = [dictionary[attrNameApiVersion] nilIfNull];
    _build = [dictionary[attrNameBuild] nilIfNull];
    _dsn = [dictionary[attrNameDsn] nilIfNull];
    _deviceService = [dictionary[attrNameDeviceService] nilIfNull];
    _features = [dictionary[attrNameFeatures] nilIfNull];
    _lanIp = [dictionary[attrNameLanIp] nilIfNull];
    _lastConnectMtime = [dictionary[attrNameLastConnectMtime] nilIfNull];
    _lastConnectTime = [dictionary[attrNameLastConnectTime] nilIfNull];
    _mac = [dictionary[attrNameMac] nilIfNull];
    _model = [dictionary[attrNameModel] nilIfNull];
    _mtime = [dictionary[attrNameMtime] nilIfNull];
    _version = [dictionary[attrNameVersion] nilIfNull];
    _deviceType = [dictionary[attrNameDeviceType] nilIfNull];
}

- (instancetype)initWithLANIP:(NSString *)lanIP {
    if (self = [super init]) {
        _lanIp = lanIP;
        
        // Setup lan module
        _lanModule = [[AylaLanModule alloc] initWithDevice:self];
    }
    
    return self;
}

- (void)updateFrom:(AylaSetupDevice *)device
{
    NSMutableSet *set = [NSMutableSet set];

    NSArray *names = @[
        NSStringFromSelector(@selector(dsn)),
        NSStringFromSelector(@selector(lanIp)),
        NSStringFromSelector(@selector(mac)),
        NSStringFromSelector(@selector(model)),
        NSStringFromSelector(@selector(key)),
        NSStringFromSelector(@selector(deviceService)),
        NSStringFromSelector(@selector(features)),
        NSStringFromSelector(@selector(lastConnectMtime)),
        NSStringFromSelector(@selector(lastConnectTime)),
        NSStringFromSelector(@selector(mtime)),
        NSStringFromSelector(@selector(version)),
        NSStringFromSelector(@selector(apiVersion)),
        NSStringFromSelector(@selector(build)),
        NSStringFromSelector(@selector(registrationType)),
        NSStringFromSelector(@selector(deviceType))
    ];

    for (NSString *name in names) {
        id value = [device valueForKey:name];
        if (value) {
            if (![[self valueForKey:name] isEqual:value]) {
                [self setValue:value forKey:name];
                [set addObject:name];
            }
        }
    }
}

- (BOOL)connected {
    
    NSString *ssid = [AylaNetworkInformation ssid];
    // if captive portal info is unavailable resort to fallback:
    if (ssid == nil) {
        return self.connectedStausFallback;
    }
    
    // otherwise use the regex to look for matching SSID
    return [AylaNetworkInformation connectedToAPWithRegEx:self.deviceSSIDRegex];
}

- (void)startLanSessionOnHttpServer:(AylaHTTPServer *)httpServer usingLanConfig:(AylaLanConfig *)lanConfig
{
    self.lanModule.config = lanConfig;
    [self.lanModule openSessionWithType:AylaLanSessionTypeSetup onHTTPServer:httpServer];
}

- (void)stopLanSession
{
    [self.lanModule closeSession];
}

- (AylaSessionManager *)sessionManager
{
    // Setup does not cache, and does not require a session manager, so we can
    // just return nil here
    return nil;
}

- (void)dealloc
{
    [self stopLanSession];
}

- (AylaLanTask *)fetchDeviceDetailsLANWithSuccess:(void (^)())successBlock
                                          failure:(void (^)(NSError *))failureBlock {
    
    AylaLanModule *module = self.lanModule;
    if (!module) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey : @{
                                                  NSStringFromSelector(@selector(lanModule)) :
                                                      AylaErrorDescriptionIsInvalid
                                                  }
                                          }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"status.json"
                                                 commands:@[ [AylaLanCommand GETDeviceDetailsCommand] ]
                                                  success:^(NSArray *responseObject) {
                                                      // Handle task call backs.
                                                      AylaLogI([self logTag], 0, @"%@, %@", @"finished",
                                                               NSStringFromSelector(_cmd));
                                                      [self setPropertiesFromDictionary:responseObject.firstObject];
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          successBlock();
                                                      });
                                                  }
                                                  failure:^(NSError *error) {
                                                      AylaLogI([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failureBlock(error);
                                                      });
                                                  }];
    
    // Set lan module for current task
    task.module = self.lanModule;
    [task start];
    
    return task;
}

- (AylaLanTask *)updateNewDeviceTime:(NSNumber *)time success:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaLanModule *module = self.lanModule;
    if (!module) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey : @{
                                                  NSStringFromSelector(@selector(lanModule)) :
                                                      AylaErrorDescriptionIsInvalid
                                                  }
                                          }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"time.json"
                                                 commands:@[ [AylaLanCommand PUTNewDeviceTimeCommand:time] ]
                                                  success:^(NSArray *responseObject) {
                                                      // Handle task call backs.
                                                      AylaLogI([self logTag], 0, @"%@, %@", @"finished",
                                                               NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          successBlock();
                                                      });
                                                  }
                                                  failure:^(NSError *error) {
                                                      AylaLogI([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failureBlock(error);
                                                      });
                                                  }];
    
    // Set lan module for current task
    task.module = self.lanModule;
    [task start];
    
    return task;
}

- (AylaLanTask *)startDeviceScanForAccessPoints:(void (^)())successBlock
                                        failure:(void (^)(NSError *))failureBlock {
    AylaLanModule *module = self.lanModule;
    if (!module) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey : @{
                                                  NSStringFromSelector(@selector(lanModule)) :
                                                      AylaErrorDescriptionIsInvalid
                                                  }
                                          }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"status.json"
                                                 commands:@[ [AylaLanCommand GETDeviceDetailsCommand] ]
                                                  success:^(NSArray *responseObject) {
                                                      // Handle task call backs.
                                                      AylaLogI([self logTag], 0, @"%@, %@", @"finished",
                                                               NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          successBlock();
                                                      });
                                                  }
                                                  failure:^(NSError *error) {
                                                      AylaLogI([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failureBlock(error);
                                                      });
                                                  }];
    
    // Set lan module for current task
    task.module = self.lanModule;
    [task start];
    
    return task;
}

- (AylaLanTask *)fetchDeviceAccessPoints:(void (^)(AylaWifiScanResults *))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaLanModule *module = self.lanModule;
    if (!module) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey : @{
                                                  NSStringFromSelector(@selector(lanModule)) :
                                                      AylaErrorDescriptionIsInvalid
                                                  }
                                          }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"wifi_scan_results.json"
                                                 commands:@[ [AylaLanCommand GETWiFiScanResults] ]
                                                  success:^(NSArray *responseObject) {
                                                      // Handle task call backs.
                                                      NSDictionary *scanResultsDictionary = responseObject.firstObject;
                                                      AylaWifiScanResults *scanResults =
                                                      [[AylaWifiScanResults alloc] initWithJSONDictionary:scanResultsDictionary[@"wifi_scan"] error:nil];
                                                      AylaLogI([self logTag], 0, @"%@, %@", @"finished",
                                                               NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          successBlock(scanResults);
                                                      });
                                                  }
                                                  failure:^(NSError *error) {
                                                      AylaLogI([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failureBlock(error);
                                                      });
                                                  }];
    
    // Set lan module for current task
    task.module = self.lanModule;
    [task start];
    
    return task;
}

- (AylaLanTask *)stopAPMode:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaLanModule *module = self.lanModule;
    if (!module) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey : @{
                                                  NSStringFromSelector(@selector(lanModule)) :
                                                      AylaErrorDescriptionIsInvalid
                                                  }
                                          }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"wifi_stop_ap.json"
                                                 commands:@[ [AylaLanCommand PUTStopAPCommand] ]
                                                  success:^(NSDictionary *responseObject) {
                                                      AylaLogI([self logTag], 0, @"Sent stop AP command");
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          successBlock();
                                                      });
                                                  }
                                                  failure:^(NSError *error) {
                                                      AylaLogI([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failureBlock(error);
                                                      });
                                                  }];
    
    // Set lan module for current task
    task.module = self.lanModule;
    [task start];
    
    return task;

    
}

- (AylaLanTask *)fetchWiFiStatus:(void (^)(AylaWifiStatus * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaLanModule *module = self.lanModule;
    if (!module) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey : @{
                                                  NSStringFromSelector(@selector(lanModule)) :
                                                      AylaErrorDescriptionIsInvalid
                                                  }
                                          }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"wifi_status.json"
                                                 commands:@[ [AylaLanCommand GETWiFiStatusCommand] ]
                                                  success:^(NSArray *responseObject) {
                                                      
                                                      NSDictionary *statusResultsDictionary = responseObject.firstObject;
                                                      AylaWifiStatus *wifiStatus =
                                                      [[AylaWifiStatus alloc] initWithJSONDictionary:statusResultsDictionary[@"wifi_status"] error:nil];
                                                      
                                                      AylaLogI([self logTag], 0, @"Got status back from device: %@", wifiStatus);
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          successBlock(wifiStatus);
                                                      });
                                                  }
                                                  failure:^(NSError *error) {
                                                      AylaLogI([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          failureBlock(error);
                                                      });
                                                  }];
    
    // Set lan module for current task
    task.module = self.lanModule;
    [task start];
    
    return task;
}

- (NSString *)logTag {
    return NSStringFromClass([self  class]);
}

@end
