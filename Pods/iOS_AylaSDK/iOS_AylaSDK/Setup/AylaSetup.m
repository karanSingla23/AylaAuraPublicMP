//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <SystemConfiguration/CaptiveNetwork.h>

#import "AylaConnectTask+Internal.h"
#import "AylaConnectivity.h"
#import "AylaDefines_Internal.h"
#import "AylaEncryption.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPServer.h"
#import "AylaHTTPTask.h"
#import "AylaKeyCrypto.h"
#import "AylaLanCommand.h"
#import "AylaLanConfig.h"
#import "AylaLanModule.h"
#import "AylaLanTask.h"
#import "AylaNetworks.h"
#import "AylaObject+Internal.h"
#import "AylaSetup.h"
#import "AylaSetupDevice+Internal.h"
#import "AylaSetupError.h"
#import "AylaTimer.h"
#import "AylaWifiScanResults.h"
#import "AylaWifiStatus.h"
#import "NSObject+Ayla.h"
#import "AylaListenerArray.h"
#import <QNNetDiag/QNNTraceRoute.h>

typedef void (^ConnectSuccessBlock)(AylaSetupDevice *setupDevice);
typedef void (^ConnectFailureBlock)(NSError *error);

/** Default public key tag for wifi setup crypto */
static NSString *const DEFAULT_KEY_CRYPTO_PUBLIC_KEY = @"com.aylanetworks.setup.crypto.publicKey";

/** Default private key tag for wifi setup crypto */
static NSString *const DEFAULT_KEY_CRYPTO_PRIVATE_KEY = @"com.aylanetworks.setup.crypto.privateKey";

/** Default interval of confirm poll */
static const NSTimeInterval DEFAULT_CONFIRM_POLL_TIME_INTERVAL = 1.;

/** Default timeout of confirm poll */
static const NSTimeInterval DEFAULT_CONFIRM_TIME_OUT = 60.;

/** Default timeout of disconnecting from device */
static const NSTimeInterval DEFAULT_DISCONNECT_TIME_OUT = 10.;

/** Default fetch new device timeout */
static const NSTimeInterval DEFAULT_FETCH_DEVICE_TIME_OUT = 5.;

/** Default length of setup token */
static const int DEFAULT_SETUP_TOKEN_LEN = 6;

static NSString * const UNKNOWN_STATE = @"unknown";

/**
 * A static method to help handle cancelled task.
 *
 * @param queue         The queue on which failureBlock should be deployed.
 * @param ^failureBlock The failureBlock which would be invoked.
 */
static void handleCancelledTask(dispatch_queue_t queue, void (^failureBlock)(NSError *error))
{
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain code:AylaRequestErrorCodeCancelled userInfo:nil];
    dispatch_async(queue, ^{
        failureBlock(error);
    });
}

@interface AylaSetup ()<AylaLanModuleInternalDelegate, AylaConnectivityListener, QNNOutputDelegate>

/** Array of WiFi Setup listeners */
@property(nonatomic, readwrite) AylaListenerArray *wiFiStateListeners;

@property (nonatomic, readwrite) AylaSetupStatus status;

/** HTTP client which is used to communicate with setup device */
@property (nonatomic) AylaHTTPClient *httpClient;

/** HTTP client which is used to communicate with cloud service */
@property (nonatomic) AylaHTTPClient *serviceHttpClient;

/** HTTP Server which is used to eatablish secure session */
@property (nonatomic, readwrite) AylaHTTPServer *httpServer;

/** Connectiviy object which help monitor network changes */
@property (nonatomic) AylaConnectivity *connectivity;

@property (nonatomic, readwrite, nullable) AylaSetupDevice *setupDevice;

// Note setup only retains one connect success block and one connect failure block
/** Retained connect success block */
@property (nonatomic, readwrite, copy) ConnectSuccessBlock connectSuccessBlock;

/** Retained connect failure block */
@property (nonatomic, readwrite, copy) ConnectFailureBlock connectFailureBlock;

@property (nonnull) AylaSystemSettings *settings;

/** Indicates whether the device will be performed securely */
@property (nonatomic, readwrite) BOOL isSecureSetup;
@end

@implementation AylaSetup
- (void)write:(NSString *)line {
    NSLog(@"Traceroute: %@", line);
}

- (instancetype)initWithSDKRoot:(AylaNetworks *)sdkRoot
{
    self = [super init];
    if (!self) return nil;
    
    _settings = sdkRoot.systemSettings;

    // Setup http client.
    _httpClient = [AylaHTTPClient apModeDeviceClientWithLanIp:_setupDeviceLanIp usingHTTPS:NO];

    // Setup service http client.
    _serviceHttpClient = [AylaHTTPClient deviceServiceClientWithSettings:sdkRoot.systemSettings usingHTTPS:YES];

    // Init setup status.
    _status = AylaSetupStatusIdle;

    // Setup HTTP Server, pass 0 to let system pick an available port.
    _httpServer = [[AylaHTTPServer alloc] initWithPort:0];

    // Init connectivity
    _connectivity = [[AylaConnectivity alloc] initWithSettings:sdkRoot.systemSettings];

    // Add self as connectivity listener
    [_connectivity addListener:self];

    // Let connectivity start monitor network changes
    [_connectivity startMonitoringNetworkChanges];
    
    _wiFiStateListeners = [[AylaListenerArray alloc] init];

    return self;
}

/**
 * Override setter of setupDeviceLanIp. Http client will be updated if the new input lan ip is different to current one.
 */
- (void)setSetupDeviceLanIp:(NSString *)setupDeviceLanIp
{
    // If setup device lan ip is adjusted, update http client to use this new lan ip.
    if (![_setupDeviceLanIp isEqualToString:setupDeviceLanIp]) {
        _setupDeviceLanIp = setupDeviceLanIp;
        _httpClient = [AylaHTTPClient apModeDeviceClientWithLanIp:_setupDeviceLanIp usingHTTPS:NO];
    }
}

- (void)determineSetupDeviceLanIp:(void (^)(NSString *lanIp))successBlock
                          failure:(void (^)(NSError *error))failureBlock {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [QNNTraceRoute start:[AylaSystemUtils deviceServiceBaseUrl:self.settings isSecure:YES] output:self complete:^(QNNTraceRouteResult *result) {
        if (!result.ip) {
            
            NSError *setupError = [AylaErrorUtils
                                   errorWithDomain:AylaSetupErrorDomain
                                   code:AylaSetupErrorCodeNoDeviceFound
                                   userInfo:@{
                                              AylaSetupErrorResponseJsonKey :
                                                  @{NSStringFromSelector(@selector(lanIp)) : AylaErrorDescriptionCanNotBeFound},
                                              }];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(setupError);
            });
            return;
        }
        successBlock(result.ip);
    }];
    });
}

- (void)connectToNewDevice:(void (^)(AylaSetupDevice *setupDevice))successBlock
                                failure:(void (^)(NSError *error))failureBlock
{
    self.status = AylaSetupStatusDeterminingLanIp;
    void (^connectToDevice)(NSString *) = ^(NSString *lanIp){
        self.setupDeviceLanIp = lanIp;
        // This is a compoune method.
        // Attempt to fetch new device for known lan ip.
        self.status = AylaSetupStatusConnectingToDevice;
        
        __block AylaConnectTask *task = [self fetchNewDevice:^(AylaSetupDevice *setupDevice) {
            
            // Update connected fallback status of setup device as connected; used only if captive network API is not available
            setupDevice.connectedStausFallback = YES;
            
            // A successful connect response will cause a replacement to current connected device.
            self.setupDevice = setupDevice;
            
            if (task.cancelled) {
                // If task has been cancelled, call failure block with a cancelled error
                self.status = AylaSetupStatusIdle;
                handleCancelledTask(dispatch_get_main_queue(), failureBlock);
                return;
            }
            // Setup device time with current system time
            task.chainedTask = [self updateNewDeviceTime:[NSDate date]
                                                 success:^{
                                                     if (task.cancelled) {
                                                         // If task has been cancelled, call failure block with a cancelled error
                                                         self.status = AylaSetupStatusIdle;
                                                         handleCancelledTask(dispatch_get_main_queue(), failureBlock);
                                                         return;
                                                     }
                                                     
                                                     // after we have found setup device, start enabling lan session.
                                                     [self _eastablishLanConnectionToDevice:setupDevice
                                                                                    success:^(AylaSetupDevice *setupDevice) {
                                                                                        successBlock(setupDevice);
                                                                                    }
                                                                                    failure:^(NSError *error) {
                                                                                        self.status = AylaSetupStatusError;
                                                                                        failureBlock(error);
                                                                                    }];
                                                 }
                                                 failure:^(NSError *error) {
                                                     self.status = AylaSetupStatusError;
                                                     failureBlock(error);
                                                 }];
            
        }
                                                     failure:^(NSError *error) {
                                                         NSError *originalError = error.userInfo[AylaHTTPErrorOrignialErrorKey];
                                                         NSHTTPURLResponse *response = originalError.userInfo[AylaHTTPErrorHTTPResponseKey];
                                                         if (response.statusCode == 404) {
                                                             if (task.cancelled) {
                                                                 // If task has been cancelled, call failure block with a cancelled error
                                                                 self.status = AylaSetupStatusIdle;
                                                                 handleCancelledTask(dispatch_get_main_queue(), failureBlock);
                                                                 return;
                                                             }
                                                             // Device doesn't work with clear text API, initiate secure setup
                                                             self.setupDevice = [[AylaSetupDevice alloc] initWithLANIP:self.setupDeviceLanIp];
                                                             self.setupDevice.deviceSSIDRegex = self.settings.deviceSSIDRegex;
                                                             
                                                             [self _eastablishLanConnectionToDevice:self.setupDevice
                                                                                            success:^(AylaSetupDevice *setupDevice) {
                                                                                                self.isSecureSetup = YES;
                                                                                                [setupDevice fetchDeviceDetailsLANWithSuccess:^{
                                                                                                    successBlock(setupDevice);
                                                                                                } failure:failureBlock];
                                                                                            }
                                                                                            failure:failureBlock];
                                                             
                                                             NSNumber *time = [NSNumber numberWithUnsignedInteger:[[NSDate date] timeIntervalSince1970]];
                                                             task.chainedTask = [self.setupDevice updateNewDeviceTime:time success:^{
                                                                 AylaLogI([self logTag], 0, @"Updated time in device");
                                                             } failure:^(NSError * _Nonnull error) {
                                                                 AylaLogI([self logTag], 0, @"Failed to update time in device, setup will continue regardless");
                                                             }];
                                                         } else {
                                                             self.status = AylaSetupStatusIdle;
                                                             failureBlock(error);
                                                         }
                                                     }];
    };
    [self determineSetupDeviceLanIp:connectToDevice failure:^(NSError *error) {
        if (self.settings.fallbackDeviceLANIP != nil) {
            connectToDevice(self.settings.fallbackDeviceLANIP);
        } else {
            failureBlock(error);
        }
    }];
}

- (void)_eastablishLanConnectionToDevice:(AylaSetupDevice *)device
                                 success:(void (^)(AylaSetupDevice *setupDevice))successBlock
                                 failure:(void (^)(NSError *error))failureBlock
{
    // If http server is still not running, start it
    if (self.httpServer.listeningPort == 0) {
        NSError *error;
        if (![self.httpServer start:&error]) {
            failureBlock(error);
            return;
        }
    }

    // Setup only keeps one copy of pending connection success/failure blocks.
    // Clean any existing pending blocks before settings new ones.
    @synchronized(self)
    {
        if (self.connectFailureBlock) {
            NSError *error = [AylaErrorUtils
                errorWithDomain:AylaRequestErrorDomain
                           code:AylaRequestErrorCodeCancelled
                       userInfo:@{
                           NSStringFromSelector(@selector(request)) : @"Cancelled because of duplicated request."
                       }];
            ConnectFailureBlock failureBlock = self.connectFailureBlock;
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }
        // Assign new success/failure block
        self.connectSuccessBlock = successBlock;
        self.connectFailureBlock = failureBlock;
    }

    // Enable lan connection to http server.
    // Set self as delegate of lan module
    device.lanModule.delegate = self;

    // Create a lan config
    AylaLanConfig *config = [[AylaLanConfig alloc] initWithJSONDictionary:@{} error:nil];

    // Set tags of keys in key pair.
    config.keyPairPublicKeyTag = DEFAULT_KEY_CRYPTO_PUBLIC_KEY;
    config.keyPairPrivateKeyTag = DEFAULT_KEY_CRYPTO_PRIVATE_KEY;

    [device startLanSessionOnHttpServer:self.httpServer usingLanConfig:config];

    // We use delegate callbacks from modules to send update to applications. Hence, no timer is required here.
}

- (AylaConnectTask *)fetchNewDevice:(void (^)(AylaSetupDevice *setupDevice))successBlock
                            failure:(void (^)(NSError *error))failureBlock
{
    // Set a shorter timeout for fetchNewDevice api.
    NSMutableURLRequest *request =
        [self.httpClient requestWithMethod:AylaHTTPRequestMethodGET path:@"status.json" parameters:nil];
    [request setTimeoutInterval:DEFAULT_FETCH_DEVICE_TIME_OUT];

    AylaHTTPTask *task = [self.httpClient taskWithRequest:request
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            // append lan ip to responseObject
            NSMutableDictionary *responseInJson = [NSMutableDictionary dictionaryWithDictionary:responseObject];
            responseInJson[@"lan_ip"] = self.setupDeviceLanIp;

            NSError *error;
            AylaSetupDevice *setupDevice = [[AylaSetupDevice alloc] initWithJSONDictionary:responseInJson error:&error];
            setupDevice.deviceSSIDRegex = self.settings.deviceSSIDRegex;
            
            if (!error) {
                self.setupDevice = setupDevice;
                AylaLogI([self logTag], 0, @"connected to device");
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(setupDevice);
                });
            }
            else {
                NSError *setupError = [AylaErrorUtils
                    errorWithDomain:AylaSetupErrorDomain
                               code:AylaSetupErrorCodeNoDeviceFound
                           userInfo:@{
                               AylaSetupErrorResponseJsonKey :
                                   @{NSStringFromSelector(@selector(setupDevice)) : AylaErrorDescriptionIsInvalid},
                               AylaSetupErrorOrignialErrorKey : error
                           }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(setupError);
                });
            }
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            NSError *setupError = [AylaErrorUtils
                errorWithDomain:AylaSetupErrorDomain
                           code:AylaSetupErrorCodeNoDeviceFound
                       userInfo:@{
                           AylaSetupErrorResponseJsonKey :
                               @{NSStringFromSelector(@selector(setupDevice)) : AylaErrorDescriptionCanNotBeFound},
                           AylaSetupErrorOrignialErrorKey : error
                       }];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(setupError);
            });
        }];

    [task start];
    return task;
}

- (AylaConnectTask *)updateNewDeviceTime:(NSDate *)date
                                 success:(void (^)(void))successBlock
                                 failure:(void (^)(NSError *error))failureBlock
{
    NSNumber *time = [NSNumber numberWithUnsignedInteger:[date timeIntervalSince1970]];
    
    if (self.isSecureSetup) {
        return [self.setupDevice updateNewDeviceTime:time success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        } failure:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    }
    return [self.httpClient putPath:@"time.json"
        parameters:@{
            @"time" : time
        }
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaConnectTask *)startDeviceScanForAccessPoints:(void (^)(void))successBlock
                                            failure:(void (^)(NSError *error))failureBlock
{
    if (self.isSecureSetup) {
        return [self.setupDevice startDeviceScanForAccessPoints:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        } failure:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    }
    return [self.httpClient postPath:@"wifi_scan.json"
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaConnectTask *)fetchDeviceAccessPoints:(void (^)(AylaWifiScanResults *))successBlock
                                     failure:(void (^)(NSError *error))failureBlock
{
    if (self.isSecureSetup) {
        return [self.setupDevice fetchDeviceAccessPoints:^(AylaWifiScanResults * _Nonnull scanResults) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(scanResults);
            });
        } failure:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    }
    return [self.httpClient getPath:@"wifi_scan_results.json"
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaWifiScanResults *scanResults =
                [[AylaWifiScanResults alloc] initWithJSONDictionary:responseObject[@"wifi_scan"] error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(scanResults);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaConnectTask *)connectDeviceToServiceWithSSID:(NSString *)SSID
                                           password:(nullable NSString *)password
                                         setupToken:(NSString *)setupToken
                                           latitude:(double)latitude
                                          longitude:(double)longitude
                                            success:(void (^)(AylaWifiStatus *status))successBlock
                                            failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(SSID, @"SSID must not be null.");

    // Connection request will only be sent through secured session.
    setupToken = setupToken ?: [AylaEncryption randomToken:DEFAULT_SETUP_TOKEN_LEN];
    AylaLanCommand *command = [AylaLanCommand ConnectCommandWithSSID:SSID
                                                            password:password
                                                          setupToken:setupToken
                                                            latitude:latitude
                                                           longitude:longitude];

    __weak __block AylaLanTask *weakTask;
    __block AylaLanTask *task;
    weakTask = task = [[AylaLanTask alloc] initWithPath:@"wifi_connect.json"
        commands:@[ command ]
        success:^(id _Nonnull responseObject) {
            // Get a succeeded response from module

            // Set a delay to confirm connection
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DEFAULT_CONFIRM_POLL_TIME_INTERVAL * NSEC_PER_SEC)),
                dispatch_get_main_queue(),
                ^{
                    // Start the polling mechanism
                    weakTask.chainedTask = [self confirmConnectToAccessPoint:^(AylaWifiStatus *status) {
                        AylaLogI([self logTag], 0, @"Confirmed device connected to %@", status.connectedSsid);
                        successBlock(status);
                    }
                        failure:^(NSError *error) {
                            AylaLogE([self logTag], 0, @"Failed to confirm device connected to AP");
                            failureBlock(error);
                        }];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DEFAULT_CONFIRM_TIME_OUT * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakTask unretainSelf];
                        
                        if (!weakTask.cancelled) {
                            [weakTask cancel];
                        }
                    });

                });
        }
        failure:^(NSError *_Nonnull error) {
            [weakTask unretainSelf];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];

    task.module = self.setupDevice.lanModule;
    if (![task start]) {
        NSError *setupError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                         code:AylaRequestErrorCodePreconditionFailure
                                                     userInfo:@{
                                                         NSStringFromSelector(@selector(task)) : @"Can't be started"
                                                     }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(setupError);
        });
        return nil;
    }

    // Let task retain itself.
    [task retainSelf];
    return task;
}

- (AylaConnectTask *)confirmConnectToAccessPoint:(void (^)(AylaWifiStatus *status))successBlock
                                         failure:(void (^)(NSError *error))failureBlock
{
    // Fetch device wifi status to check connect history
    __block AylaConnectTask *task = [self fetchDeviceWifiStatus:^(AylaWifiStatus *_Nonnull wifiStatus) {
        
        if (task.cancelled) {
            // If task has already been cancelled.
            NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain code:AylaRequestErrorCodeCancelled userInfo:nil];
            failureBlock(error);
        }
        else if (wifiStatus.connectHistory.count > 0) {
            // Check the first connection history entry
            AylaWifiConnectionHistory *history = wifiStatus.connectHistory[0];
            if (history.error == AylaWifiConnectionErrorInProgress) {
                // If attempt is still in progress, we will continue and won't decrease the retries
                // Dispatch another attempt after the polling interval
                dispatch_after(
                               dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DEFAULT_CONFIRM_POLL_TIME_INTERVAL * NSEC_PER_SEC)),
                               dispatch_get_main_queue(),
                               ^{
                                   task.chainedTask = [self confirmConnectToAccessPoint:successBlock failure:failureBlock];
                               });
            }
            else if (history.error == AylaWifiConnectionErrorNoError) {
                // NoError state indicates completion.
                if (wifiStatus.connectedSsid && ![wifiStatus.connectedSsid isEqualToString:@""]) {
                    
                    // This step is optional as the device is ultimately responsible for starting and stopping it's AP Mode
                    AylaLogI([self logTag], 0, @"Device connected to %@. Attempting to shutdown AP mode on the device immediatley", wifiStatus.connectedSsid);
                    [self disconnectFromDevice:^{
                        
                        AylaLogI([self logTag], 0, @"Disconnected from the device");
                        // If module has connected to one AP, return status back
                        successBlock(wifiStatus);
                    } failure:^(NSError *error) {
                        
                        AylaLogI([self logTag], 0, @"Failed to force kill AP mode on the device. The device should kill AP mode soon after setup is complete.");
                        successBlock(wifiStatus);
                    }];
                }
                else {
                    // In case of completion (NoError) but no reported ssid, an unknown error has occurred on the module.
                    NSError *error =
                    [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain code:AylaRequestErrorCodeUnknown userInfo:nil];
                    failureBlock(error);
                }
            }
            else {
                // Return any other error reported
                NSError *error =
                [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                           code:AylaRequestErrorCodeInvalidArguments
                                       userInfo:@{
                                                  AylaRequestErrorResponseJsonKey : @{
                                                          NSStringFromSelector(@selector(error)) : @(history.error),
                                                          NSStringFromSelector(@selector(msg)) : history.msg ?: @""
                                                          }
                                                  }];
                failureBlock(error);
            }
        }
        else {
            // Reply on module status, we will keep polling here.
            dispatch_after(
                           dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DEFAULT_CONFIRM_POLL_TIME_INTERVAL * NSEC_PER_SEC)),
                           dispatch_get_main_queue(),
                           ^{
                               task.chainedTask = [self confirmConnectToAccessPoint:successBlock failure:failureBlock];
                           });
        }
    }
        failure:^(NSError *_Nonnull error) {
            if (error.code == AylaHTTPErrorCodeCancelled || error.code == AylaRequestErrorCodeCancelled) {
                // If request has been cancelled
                failureBlock(error);
            }
            else {
                dispatch_after(
                               dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DEFAULT_CONFIRM_POLL_TIME_INTERVAL * NSEC_PER_SEC)),
                               dispatch_get_main_queue(),
                               ^{
                                   task.chainedTask = [self confirmConnectToAccessPoint:successBlock failure:failureBlock];
                               });
            }
        }];
    
    return task;
}

- (AylaConnectTask *)confirmDeviceConnectedWithTimeout:(NSTimeInterval)timeoutInSeconds
                                                   dsn:(NSString *)dsn
                                            setupToken:(NSString *)setupToken
                                               success:(void (^)(AylaSetupDevice *setupDevice))successBlock
                                               failure:(void (^)(NSError *error))failureBlock
{
    __block AylaConnectTask *task;

    void (^processsPollingBlock)(AylaConnectTask *) = ^(AylaConnectTask *task) {
        if (task.cancelled) {
            handleCancelledTask(dispatch_get_main_queue(), failureBlock);
            return;
        }

        task.chainedTask = [self pollDeviceConnectStatusOnCloudWithTimeout:timeoutInSeconds
                                                                       dsn:dsn
                                                                setupToken:setupToken
                                                                   success:successBlock
                                                                   failure:failureBlock];
    };

    if (self.setupDevice.connected) {
        // If we still connect to device, call disconnect first.

        task = [self disconnectFromDevice:^{
            processsPollingBlock(task);
        }
            failure:^(NSError *error) {
                // We will skip this error and continue polling.
                processsPollingBlock(task);
            }];
    }
    else {
        task = [self pollDeviceConnectStatusOnCloudWithTimeout:timeoutInSeconds
                                                           dsn:dsn
                                                    setupToken:setupToken
                                                       success:successBlock
                                                       failure:failureBlock];
    }

    return task;
}

- (AylaConnectTask *)pollDeviceConnectStatusOnCloudWithTimeout:(NSTimeInterval)timeoutInSeconds
                                                           dsn:(NSString *)dsn
                                                    setupToken:(NSString *)setupToken
                                                       success:(void (^)(AylaSetupDevice *setupDevice))successBlock
                                                       failure:(void (^)(NSError *error))failureBlock
{
    NSDictionary *errDescription;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    if (dsn) {
        params[NSStringFromSelector(@selector(dsn))] = dsn;
    }
    else {
        errDescription = @{ NSStringFromSelector(@selector(dsn)) : AylaErrorDescriptionCanNotBeFound };
    }

    if (setupToken) {
        params[@"setup_token"] = setupToken;
    }
    else {
        errDescription = @{ @"setupToken" : AylaErrorDescriptionCanNotBeFound };
    }

    if (errDescription) {
        NSError *error = [NSError errorWithDomain:AylaRequestErrorDomain
                                             code:AylaRequestErrorCodeInvalidArguments
                                         userInfo:@{AylaRequestErrorResponseJsonKey : errDescription}];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    __block AylaHTTPTask *task;

    NSString *path = [[NSString alloc] initWithFormat:@"devices/connected.json"];

    // Set a timer to determine timeout
    __block AylaTimer *timer = [[AylaTimer alloc] initWithTimeInterval:timeoutInSeconds * NSEC_PER_USEC
                                                                leeway:100.
                                                                 queue:dispatch_get_main_queue()
                                                           handleBlock:^(AylaTimer *timer) {
                                                               [timer stopPolling];
                                                               if (!task.cancelled) {
                                                                   [task cancel];
                                                               }
                                                           }];

    AylaHTTPTask * (^processBlock)(void (^)(AylaHTTPTask *, NSError *)) =
        ^AylaHTTPTask *(void (^aFailureBlock)(AylaHTTPTask *, NSError *))
    {
        if (task.cancelled) {
            handleCancelledTask(dispatch_get_main_queue(), failureBlock);
            return nil;
        }

        AylaLogD([self logTag], 0, @"Confirming to cloud with DSN:%@, token:%@", dsn, setupToken);
        return [self.serviceHttpClient
               getPath:path
            parameters:params
               success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                   AylaLogD([self logTag], 0, @"Confirmed to cloud connection");
                   [timer stopPolling];
                   NSMutableDictionary *deviceDictionary = [responseObject[@"device"] mutableCopy];

                   if (dsn) {
                       deviceDictionary[@"dsn"] = dsn;
                   }

                   AylaSetupDevice *setupDevice = self.setupDevice;
                   if (setupDevice == nil) {
                       setupDevice = [[AylaSetupDevice alloc] initWithJSONDictionary:deviceDictionary error:nil];
                   }
                   else {
                       [setupDevice
                           updateFrom:[[AylaSetupDevice alloc] initWithJSONDictionary:deviceDictionary error:nil]];
                   }
                   setupDevice.deviceSSIDRegex = self.settings.deviceSSIDRegex;
                   dispatch_async(dispatch_get_main_queue(), ^{
                       successBlock(setupDevice);
                   });
               }
               failure:aFailureBlock];
    };

    void (^__block __weak __failureBlock)(AylaHTTPTask *, NSError *);
    void (^__block _failureBlock)(AylaHTTPTask *, NSError *);

    __failureBlock = _failureBlock = ^(AylaHTTPTask *httpTask, NSError *error) {

        AylaLogD([self logTag], 0, @"Failed to confirm, continue after %f, error: %@", DEFAULT_CONFIRM_POLL_TIME_INTERVAL, error);

        __strong typeof(__failureBlock) strongFailureblock = __failureBlock;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DEFAULT_CONFIRM_POLL_TIME_INTERVAL * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       ^{
                           if (task.cancelled) {
                               handleCancelledTask(dispatch_get_main_queue(), failureBlock);
                               return;
                           }
                           task.chainedTask = processBlock(strongFailureblock);
                           AylaLogD([self logTag], 0, @"New confirm conneciton to cloud task: %@", task.chainedTask);
                       });
    };

    task = processBlock(_failureBlock);
    [timer startPollingWithDelay:YES];
    return task;
}

/**
 * Use this method to send a disconnect request to setup device.
 */
- (AylaConnectTask *)disconnectFromDevice:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock
{
    if (self.isSecureSetup) {
        return [self.setupDevice stopAPMode:^{
            self.status = AylaSetupStatusDisconnectedFromDevice;
            AylaLogI([self logTag], 0, @"Disconnected from device.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        } failure:^(NSError * _Nonnull error) {
            AylaLogE([self logTag], 0, @"err: %@, %@", error, @"disconnectFromDevice");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    }
    NSMutableURLRequest *request =
        [self.httpClient requestWithMethod:AylaHTTPRequestMethodPUT path:@"wifi_stop_ap.json" parameters:nil];
    [request setTimeoutInterval:DEFAULT_DISCONNECT_TIME_OUT];

    AylaHTTPTask *task = [self.httpClient taskWithRequest:request
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            self.status = AylaSetupStatusDisconnectedFromDevice;
            AylaLogI([self logTag], 0, @"Disconnected from device.");

            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err: %@, %@", error, @"disconnectFromDevice");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];

    [task start];
    return task;
}

- (AylaConnectTask *)fetchDeviceWifiStatus:(void (^)(AylaWifiStatus *wifiStatus))successBlock
                                   failure:(void (^)(NSError *error))failureBlock
{
    AylaLogI([self logTag], 0, @"Fetching WiFi status");
    
    if (self.isSecureSetup) {
        return [self.setupDevice fetchWiFiStatus:^(AylaWifiStatus * _Nonnull wifiStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(wifiStatus);
                [self notifyWiFiSetupListenerWithState:wifiStatus.state];
            });
        } failure:^(NSError * _Nonnull error) {
            AylaLogE([self logTag], 0, @"err: %@, %@", error, @"disconnectFromDevice");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    }
    return [self.httpClient getPath:@"wifi_status.json"
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            
            AylaWifiStatus *wifiStatus =
                [[AylaWifiStatus alloc] initWithJSONDictionary:responseObject[@"wifi_status"] error:nil];
            
            AylaLogI([self logTag], 0, @"Got status back from device: %@", wifiStatus);
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(wifiStatus);
                [self notifyWiFiSetupListenerWithState:wifiStatus.state];
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            
            AylaLogE([self logTag], 0, @"Failed to fetch WiFi status: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

/**
 * Use this method to notify status of last connection attempt.
 * @note This method will check retrained connectSuccessBlock and connectFailureBlock and call corresponding one to
 * return status. Once invoked, this method wil clean both blocks to guarantee status will only be updated once to a
 * pending request.
 *
 * @param error An error object which tells last connection status.
 */
- (void)notifyConnectiionStatus:(NSError *)error
{
    @synchronized(self)
    {
        if (!error) {
            self.status = AylaSetupStatusConnectedToDevice;
            ConnectSuccessBlock successBlock = self.connectSuccessBlock;
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(self.setupDevice);
                });
            }
        }
        else {
            self.status = AylaSetupStatusError;
            ConnectFailureBlock failureBlcok = self.connectFailureBlock;
            if (failureBlcok) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlcok(error);
                });
            }
        }

        self.connectSuccessBlock = nil;
        self.connectFailureBlock = nil;
    }
}

- (void)exit
{
    return [self exitWithDisconnecting:YES];
}

/**
 * Use this method to exit setup
 *
 * @param needsDiconnect If diconnection call should be made to module.
 */
- (void)exitWithDisconnecting:(BOOL)needsDiconnect
{
    if (needsDiconnect) {
        // Send a disconnect request to device
        [self disconnectFromDevice:^{
        }
            failure:^(NSError *error){
            }];
    }

    // Disable lan mode of setup device
    [self.setupDevice.lanModule closeSession];
    
    // Update connected fallback status of setup device as connected; used only if captive network API is not available
    self.setupDevice.connectedStausFallback = NO;

    // Update setup status.
    self.status = self.setupDevice ? AylaSetupStatusDisconnectedFromDevice : AylaSetupStatusIdle;

    // Stop monitoring network changes.
    [self.connectivity stopMonitoringNetworkChanges];
}

- (void)dealloc
{
    // Stop http server
    [self.httpServer stop];

    // Don't call disconnect if setup is going to be deallocated.
    [self exitWithDisconnecting:NO];
}

- (NSString *)logTag
{
    return @"Setup";
}

//-----------------------------------------------------------
#pragma mark - Lan Connection
//-----------------------------------------------------------
- (void)lanModule:(AylaLanModule *)lanModule didEastablishSessionOnLanIp:(NSString *)lanIp
{
    ConnectSuccessBlock block = self.connectSuccessBlock;
    if (block && lanModule.device == self.setupDevice) {
        [self notifyConnectiionStatus:nil];
    }
}

- (void)lanModule:(AylaLanModule *)lanModule didFail:(NSError *)error
{
    ConnectFailureBlock block = self.connectFailureBlock;
    if (block && lanModule.device == self.setupDevice) {
        [self notifyConnectiionStatus:error];
    }
}

- (void)didDisableSessionOnModule:(AylaLanModule *)module
{
    // We will skip disable callbacks here.
}

- (void)lanModule:(AylaLanModule *)lanModuel didReceiveMessage:(AylaLanMessage *)message
{
    // Setup is not caring about from-device message.
}

//-----------------------------------------------------------
#pragma mark - Connectivity
//-----------------------------------------------------------
- (void)connectivity:(AylaConnectivity *)connectivity
    didObserveNetworkChange:(AylaNetworkReachabilityStatus)reachabilityStatus
{
    AylaLogI([self logTag], 0, @"Network changed %ld", (long)reachabilityStatus);
    
    // Update connected fallback status of setup device as connected; used only if captive network API is not available
    self.setupDevice.connectedStausFallback = NO;

    // Stop lan session of device.
    [self.setupDevice stopLanSession];
}

- (void)addWiFiStateListener:(id<AylaDeviceWifiStateChangeListener>)listener {
    [self.wiFiStateListeners addListener:listener];
}

- (void)notifyWiFiSetupListenerWithState:(NSString *)state {
    [self.wiFiStateListeners iterateListenersRespondingToSelector:@selector(wifiStateDidChange:) block:^(id<AylaDeviceWifiStateChangeListener>  _Nonnull listener) {
        [listener wifiStateDidChange:state ?: UNKNOWN_STATE];
    }];
}

- (void)removeWiFiStateListener:(id<AylaDeviceWifiStateChangeListener>)listener {
    [self.wiFiStateListeners removeListener:listener];
}
@end
