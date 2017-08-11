//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <SocketRocket/SRWebSocket.h>

#import "AylaConnectivity.h"
#import "AylaDSHandler.h"
#import "AylaDSManager.h"
#import "AylaDSMessage.h"
#import "AylaDSSubscription.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceManager.h"

#import "AylaHTTPClient.h"
#import "AylaHTTPError.h"
#import "AylaListenerArray.h"
#import "AylaObject+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemSettings.h"
#import "AylaSystemUtils.h"

/** DSS Manager queue label */
static char *const AylaDSManagerQueueLabel = "com.aylanetworks.dsmgr.queue.processing";

/** Default retries for web socket eastalishment */
static const NSInteger DEFAULT_WEB_SOCKET_EASTABLISHMENT_RETIRES = 2;

/** Default retries for subscription creation/update */
static const NSInteger DEFAULT_SUBSCRIPTION_RETIRES = 1;

static NSString *const AylaDSHeartBeat = @"1|Z";

@interface AylaDSManager ()<SRWebSocketDelegate> {
    void *isOnQueueKey;
}

/** Array of listeners */
@property (nonatomic, strong, readwrite) AylaListenerArray *listeners;

@property (nonatomic, strong, readwrite) AylaHTTPClient *httpClient;
@property (nonatomic, strong, readwrite) AylaDSSubscription *subscription;
@property (nonatomic, strong, readwrite) SRWebSocket *webSocket;
@property (nonatomic, strong, readwrite) AylaSystemSettings *settings;
@property (nonatomic, assign, readwrite) AylaDSState state;
@property (nonatomic, strong, readwrite) dispatch_queue_t processingQueue;
@property (nonatomic, strong, readwrite) AylaDSHandler *handler;

@property (nonatomic, assign) int subscriptionRetries;
@property (nonatomic, assign) int wsConnectionRetries;
@property (nonatomic, assign) BOOL isPaused;
@end

@implementation AylaDSManager

- (BOOL)isConnected {
    return self.state == AylaDSStateConnected;
}

- (BOOL)isConnecting {
    return self.state == AylaDSStateConnecting;
}

- (instancetype)initWithSettings:(AylaSystemSettings *)settings
                   deviceManager:(AylaDeviceManager *)deviceManager
                      httpClient:(AylaHTTPClient *)httpClient
{
    self = [super init];
    if (!self) return self;
    
    _state = AylaDSStateUninitialized;

    // Linked device manager.
    _deviceManager = deviceManager;

    // In-use settings.
    _settings = settings;

    // Http client to stream service.
    _httpClient = httpClient;

    // Init listener array.
    _listeners = [[AylaListenerArray alloc] init];

    // Init queue in dss manager.
    _processingQueue = dispatch_queue_create(AylaDSManagerQueueLabel, DISPATCH_QUEUE_SERIAL);

    // Set an identifier to the created queue.
    void *aPointer = (__bridge void *)self;
    isOnQueueKey = &isOnQueueKey;
    dispatch_queue_set_specific(_processingQueue, isOnQueueKey, aPointer, NULL);

    // Init device manager.
    _handler = [[AylaDSHandler alloc] initWithDeviceManager:deviceManager];

    // Add self as network change observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:AylaConnectivityNetworkChangeNotification
                                               object:nil];

    return self;
}

- (void)subscribeWithDsns:(NSArray AYLA_GENERIC(NSString *) *)dsns
          completionBlock:
                         (void (^)(AylaDSSubscription *subscription, BOOL created, NSError *error))completionBlock
{
    [self setDSState:AylaDSStateInitialized object:nil error:nil];
    
    NSString *dsnsInString = nil;
    if (dsns.count > 0) {
        dsnsInString = [dsns componentsJoinedByString:AylaDSSubscriptionDefaultDelimiter];
    }


    void (^handleError)(NSError *) = ^(NSError *error) {
        NSHTTPURLResponse *response = error.userInfo[AylaHTTPErrorHTTPResponseKey];
        // If this update request is rejected by cloud, clean exsiting subscription
        if (response.statusCode) {
            self.subscription = nil;
        }
        if (self.subscriptionRetries-- > 0) {  // Have more retries
            [self subscribeWithDsns:dsns completionBlock:completionBlock];
        }
        else {
            completionBlock(nil, NO, error);
        }
    };

    // Otherwise, create a new subscription
    AylaDSSubscription *subscription = [[AylaDSSubscription alloc]
             initWithName:@"mobile dss"
                      dsn:dsnsInString
        subscriptionTypes:self.settings.dssSubscriptionType];

    AylaHTTPClient *httpClient = self.testSubscriptionClient == nil ? self.deviceManager.sessionManager.httpClients[@(AylaHTTPClientTypeMDSSService)] : self.testSubscriptionClient;
    [AylaDSSubscription createSubscription:subscription
        usingHttpClient:httpClient
        success:^(AylaDSSubscription *_Nonnull createdSubscription) {
            dispatch_async(self.processingQueue, ^{
                AylaLogD([self logTag], 0, @"created subscription, dsns:%@.", createdSubscription.dsn);
                self.subscription = createdSubscription;
                completionBlock(createdSubscription, YES, nil);
            });
        }
        failure:^(NSError *_Nonnull error) {
            dispatch_async(self.processingQueue, ^{
                AylaLogW([self logTag], 0, @"Failed to create subscription %ld", error.code);
                handleError(error);
            });
        }];
}

- (void)connectWebSocketWithSubscription:(AylaDSSubscription *)subscription
{
    if (!subscription) {
        [self setDSState:AylaDSStateDisconnected
                  object:nil
                   error:[AylaErrorUtils
                             errorWithDomain:AylaDSErrorDomain
                                        code:AylaDSErrorCodeInvalidSubscription
                                    userInfo:@{
                                        NSStringFromSelector(@selector(subscription)) : AylaErrorDescriptionIsInvalid
                                    }]];
        return;
    }

    // Clean existing connection.
    [self _cleanDSConnection];
    [self setDSState:AylaDSStateConnecting object:nil error:nil];

    // Compose url
    NSString *absoluteUrlString = [NSString
        stringWithFormat:@"%@stream?stream_key=%@", self.httpClient.baseURL.absoluteString, subscription.streamKey];
    NSURL *url = [NSURL URLWithString:absoluteUrlString];

    // init ws
    SRWebSocket *ws = [[SRWebSocket alloc] initWithURL:url];

    [ws setDelegateDispatchQueue:self.processingQueue];
    ws.delegate = self;
    [ws open];

    self.webSocket = ws;
}

- (void)resume
{
    self.isPaused = NO;
    dispatch_sync(self.processingQueue, ^{
        if (!self.isConnected && !self.isConnecting) {
            NSError *error;
            __block AylaDeviceManager *deviceManager = [self getDeviceManager:&error];
            if (error) {
                [self setDSState:AylaDSStateDisconnected object:nil error:error];
                return;
            }
            
            // Add self as listener of device manager.
            [deviceManager addListener:self];
            self.subscriptionRetries = DEFAULT_SUBSCRIPTION_RETIRES;
            [self subscribeWithDsns:nil
                    completionBlock:^(AylaDSSubscription *subscription, BOOL created, NSError *error) {
                        if (subscription && !error) {
                            // Reset retries
                            self.wsConnectionRetries = DEFAULT_WEB_SOCKET_EASTABLISHMENT_RETIRES;
                            
                            // Attempt to eastablish a new connection with refreshed subscription.
                            [self connectWebSocketWithSubscription:subscription];
                        }
                        else {
                            AylaLogW(
                                     [self logTag], 0, @"Failed to create subscription %ld", (long)error.code);
                            NSError *sdkErr = [AylaErrorUtils
                                               errorWithDomain:AylaDSErrorDomain
                                               code:AylaDSErrorCodeRefusedByCloud
                                               userInfo:@{AylaRequestErrorOrignialErrorKey : error}];
                            
                            [self setDSState:AylaDSStateDisconnected object:nil error:sdkErr];
                        }
                    }];
        }
    });
}

- (void)pause
{
    dispatch_sync(self.processingQueue, ^{
        self.isPaused = YES;
        [self.deviceManager removeListener:self];
        [self _cleanDSConnection];
        [self setDSState:AylaDSStateDisconnected object:nil error:nil];
    });
}

- (NSArray *)_getDsnsFromDeviceManager:(AylaDeviceManager *)deviceManager error:(NSError *__autoreleasing *)error
{
    void (^cleanBlock)(NSError *) = ^(NSError *anErr) {
        [self _cleanDSConnection];
        [self setDSState:AylaDSStateDisconnected object:nil error:anErr];
        if (error) {
            *error = anErr;
        }
    };

    if (deviceManager.state != AylaDeviceManagerStateReady) {
        NSError *dssErr = [AylaErrorUtils
            errorWithDomain:AylaDSErrorDomain
                       code:AylaDSErrorCodeDeviceManagerBadStatus
                   userInfo:@{
                       AylaDSErrorResponseJsonKey : @{NSStringFromSelector(@selector(deviceManager)) : @"Not ready."}
                   }];
        cleanBlock(dssErr);
        return nil;
    }

    // Compose dsns in string which is acceptable by stream service.
    NSArray *dsns = deviceManager.devices.allKeys;
    if (dsns.count == 0) {
        // If there is no devices listed in device manager, subscription is not allowed to be created,
        // reset state back to error.
        NSError *dssErr =
            [AylaErrorUtils errorWithDomain:AylaDSErrorDomain
                                       code:AylaDSErrorCodeDeviceManagerBadStatus
                                   userInfo:@{
                                       AylaDSErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(deviceManager)) : @"empty device list."}
                                   }];
        cleanBlock(dssErr);
        return nil;
    }

    return dsns;
}

- (void)_cleanDSConnection
{
    self.webSocket.delegate = nil;
    [self.webSocket close];
    self.webSocket = nil;
}

- (NSString *)nameOfState:(AylaDSState)state {
    switch (state) {
        case AylaDSStateConnected:
            return @"connected";
        case AylaDSStateConnecting:
            return @"connecting";
        case AylaDSStateDisconnected:
            return @"disconnected";
        case AylaDSStateInitialized:
            return @"initialized";
        case AylaDSStateUninitialized:
            return @"uninitialized";
            
        default:
            return nil;
    }
}

- (void)setDSState:(AylaDSState)state object:(id)object error:(NSError *)error
{
    AYLAssert(dispatch_get_specific(isOnQueueKey), @"State must be set on manager queue.");

    AylaDSState oldState = self.state;
    self.state = state;

    if (state != oldState) {
        switch (state) {
            case AylaDSStateConnecting: {
                
                [self.listeners iterateListenersRespondingToSelector:@selector(connectingDSManager:)
                                                        asyncOnQueue:dispatch_get_main_queue()
                                                               block:^(id _Nonnull listener) {
                                                                   [listener connectingDSManager:self];
                                                               }];
                
                break;
            }
            case AylaDSStateInitialized: {
                
                [self.listeners iterateListenersRespondingToSelector:@selector(didInitializeDSManager:)
                                                        asyncOnQueue:dispatch_get_main_queue()
                                                               block:^(id _Nonnull listener) {
                                                                   [listener didInitializeDSManager:self];
                                                               }];
                
                break;
            }
            case AylaDSStateConnected: {
                [self.listeners iterateListenersRespondingToSelector:@selector(didConnectDSManager:)
                                                        asyncOnQueue:dispatch_get_main_queue()
                                                               block:^(id _Nonnull listener) {
                                                                   [listener didConnectDSManager:self];
                                                               }];
                break;
            }
            case AylaDSStateDisconnected: {
                
                [self.listeners iterateListenersRespondingToSelector:@selector(dsManager:didDisconnectWithError:)
                                                        asyncOnQueue:dispatch_get_main_queue()
                                                               block:^(id _Nonnull listener) {
                                                                   [listener dsManager:self didDisconnectWithError:error];
                                                               }];
                break;
            }
            default:
                break;
        }
        AylaLogD([self logTag], 0, @"updatedState from(%@) to(%@)", [self nameOfState:oldState], [self nameOfState:state]);

        [self notifyDSStateChange];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _cleanDSConnection];
}

//-----------------------------------------------------------
#pragma mark - Device manager
//-----------------------------------------------------------

- (AylaDeviceManager *)getDeviceManager:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaDeviceManager *deviceManager = self.deviceManager;
    if (!deviceManager && error) {
        *error = [AylaErrorUtils
            errorWithDomain:AylaDSErrorDomain
                       code:AylaDSErrorCodeDeviceManagerNotFound
                   userInfo:@{
                       NSStringFromSelector(@selector(deviceManager)) : AylaErrorDescriptionCanNotBeFound
                   }];
    }
    return deviceManager;
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager
      didInitComplete:(NSDictionary<NSString *, NSError *> *)deviceFailures
{
    [self resume];
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager didInitFailure:(NSError *)error
{
    dispatch_async(self.processingQueue, ^{
        NSError *dssErr = [AylaErrorUtils errorWithDomain:AylaDSErrorDomain
                                                     code:AylaDSErrorCodeDeviceManagerBadStatus
                                                 userInfo:@{AylaDSErrorOrignialErrorKey : error}];
        [self setDSState:AylaDSStateDisconnected object:nil error:dssErr];
    });
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager didObserveDeviceListChange:(AylaDeviceListChange *)change
{
    // first device registerd to account
    if (self.state == AylaDSStateDisconnected && !self.isPaused) {
        [self resume];
    }
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager
    deviceManagerStateChanged:(AylaDeviceManagerState)oldState
                     newState:(AylaDeviceManagerState)newState
{
    // Do nothing, Android checks if the new state is paused to pause the DS Manager as well, but iOS already does this
    // in the sessionManager pause method itself.
}

//-----------------------------------------------------------
#pragma mark - Listeners
//-----------------------------------------------------------

- (void)addListener:(id<AylaDeviceManagerListener>)listener
{
    [self.listeners addListener:listener];
}

- (void)removeListener:(id<AylaDeviceManagerListener>)listener
{
    [self.listeners removeListener:listener];
}

//-----------------------------------------------------------
#pragma mark - Web socket delegate
//-----------------------------------------------------------

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [self setDSState:AylaDSStateConnected object:nil error:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)rawString
{
    if (rawString != nil) {
        if ([rawString isEqualToString:AylaDSHeartBeat]) {
            // respond with the same string
            [webSocket send:rawString];
        }
        else {
            AylaDSMessage *message = [self.handler messageFromRawString:rawString];
            if (message) {
                [self.handler handleMessage:message];
                [self.listeners iterateListenersRespondingToSelector:@selector(dsManager:didReceiveMessage:)
                                                        asyncOnQueue:dispatch_get_main_queue()
                                                               block:^(id _Nonnull listener) {
                                                                   [listener dsManager:self didReceiveMessage:message];
                                                               }];
            }
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    // If state has been set as Paused, skip this error.
    if (self.isPaused) {
        return;
    }

    NSError *dssError;
    NSNumber *serverResponseInNum = error.userInfo[SRHTTPResponseErrorKey];

    AylaLogD([self logTag], 0, @"ws err %@", error);

    // If request is rejected by server.
    if (serverResponseInNum) {
        dssError = [AylaErrorUtils errorWithDomain:AylaDSErrorDomain
                                              code:AylaDSErrorCodeRefusedByCloud
                                          userInfo:@{AylaDSErrorOrignialErrorKey : error}];
        // Clean subscription.
        self.subscription = nil;
        [self setDSState:AylaDSStateDisconnected object:nil error:dssError];
    }
    else {
        dssError = [AylaErrorUtils errorWithDomain:AylaDSErrorDomain
                                              code:AylaDSErrorCodeWebSocketError
                                          userInfo:@{AylaDSErrorOrignialErrorKey : error}];
        // Set as error first.
        [self setDSState:AylaDSStateDisconnected object:nil error:dssError];

        // If last web socket is disconnected due to web socket error, attempt to retry once.
        if (self.wsConnectionRetries-- > 0) {
            AylaLogD([self logTag], 0, @"connection err, retries left %d", self.wsConnectionRetries);
            [self connectWebSocketWithSubscription:self.subscription];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
    AylaLogD([self logTag], 0, @"ws closed: %ld (%@), %@", code, reason, wasClean?@"Clean":@"Not clean");
    [self _cleanDSConnection];
    [self setDSState:AylaDSStateDisconnected object:nil error:nil];
    self.subscription = nil;
}

//-----------------------------------------------------------
#pragma mark - Device manager
//-----------------------------------------------------------
- (void)notifyDSStateChange
{
    // Notify devices in device manager
    NSArray *devices = self.deviceManager.devices.allValues;
    if (devices.count) {
        // Switch to processing queue to call data source changed.
        dispatch_async([AylaDevice deviceProcessingQueue], ^{
            for (AylaDevice *device in devices) {
                [device dataSourceChanged:AylaDataSourceDSS];
            }
        });
    }
}

//-----------------------------------------------------------
#pragma mark - Notification
//-----------------------------------------------------------

- (void)networkChanged:(NSNotification *)notification
{
    NSNumber *changeInNum = notification.object;
    if ([changeInNum isEqual:@(AylaNetworkReachabilityStatusReachableViaWWAN)] ||
        [changeInNum isEqual:@(AylaNetworkReachabilityStatusReachableViaWiFi)]) {
        if (!self.isConnecting && !self.isConnected && !self.isPaused) {
            [self resume];
        }
    }
}

- (NSString *)logTag
{
    return @"DSManager";
}

@end
