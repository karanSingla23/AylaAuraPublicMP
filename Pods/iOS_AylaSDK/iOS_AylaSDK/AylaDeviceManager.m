//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaCache+Internal.h"
#import "AylaDatapointBatchRequest.h"
#import "AylaDatapointBatchResponse.h"
#import "AylaDefines_Internal.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceListChange.h"
#import "AylaDeviceManager.h"
#import "AylaDeviceNode.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPServer.h"
#import "AylaListenerArray.h"
#import "AylaNetworks+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"
#import "AylaRegistration+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemSettings.h"
#import "AylaTimer.h"
#import "AylaAlertHistory.h"

static dispatch_queue_t device_manager_processing_queue()
{
    static dispatch_queue_t device_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device_manager_processing_queue =
            dispatch_queue_create("com.aylanetworks.deviceManager.queue.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    return device_manager_processing_queue;
}

/** Default poll time interval of 15 seconds */
static const NSInteger DEFAULT_POLL_INTERVAL_MS = 15000;

/** Default poll time leeway of 1 seconds */
static const NSInteger DEFAULT_POLL_LEEEWAY_MS = 1000;

/** Default Lan server port number */
static const NSInteger DEFAULT_LAN_SERVER_PORT = 10275;

@interface AylaDeviceManager () <AylaConnectivityListener>

/** Mutable Device List */
@property (nonatomic, strong, readwrite) NSMutableDictionary *mutableDevices;

/** Array of listeners */
@property (nonatomic, strong, readwrite) AylaListenerArray *listeners;

@property (nonatomic, readwrite) AylaDeviceManagerState state;

@property (nonatomic, readwrite) BOOL cachedDeviceList;

@property (nonatomic, readwrite) id<AylaDeviceDetailProvider> deviceDetailProvider;

/** Lock of device list */
@property (nonatomic) NSRecursiveLock *lock;

/** Poll timer */
@property (nonatomic) AylaTimer *pollTimer;

/** Time between calls to the server to fetch the current device list */
@property (nonatomic) NSUInteger pollIntervalMs;

/** Time leeway of the call to fetch the current device list */
@property (nonatomic) NSUInteger pollLeewayMs;

/** Lan HTTP server */
@property (nonatomic, readwrite) AylaHTTPServer *lanServer;

/** Device client which will be used to send http request to device at lan */
@property (nonatomic, readwrite) AylaHTTPClient *lanHttpClient;

@property (strong, nonatomic) AylaRegistration *registration;
@end

@implementation AylaDeviceManager

- (void)setState:(AylaDeviceManagerState)state
{
    if (_state == state) {
        return;
    }

    if (state == AylaDeviceManagerStateReady) {
        _hasInitialized = YES;
    }
    // Save old state for notification
    AylaDeviceManagerState oldState = _state;
    // set the new state in the ivar
    _state = state;
    // notifty listeners
    [self.listeners iterateListenersRespondingToSelector:@selector(deviceManager:deviceManagerStateChanged:newState:)
                                                   block:^(id _Nonnull listener) {
                                                       [listener deviceManager:self
                                                           deviceManagerStateChanged:oldState
                                                                            newState:state];
                                                   }];
}

- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager
{
    self = [super init];
    if (!self) return nil;

    _sessionManager = sessionManager;

    // Init listener array
    _listeners = [[AylaListenerArray alloc] init];

    // Setup notification queue, use main queue be default
    _notificationQueue = dispatch_get_main_queue();

    // Initialize status
    _state = AylaDeviceManagerStateUninitialized;

    // Init lock
    _lock = [[NSRecursiveLock alloc] init];

    // Init poll variable and timer
    _pollIntervalMs = DEFAULT_POLL_INTERVAL_MS;
    _pollLeewayMs = DEFAULT_POLL_LEEEWAY_MS;
    _pollTimer = [[AylaTimer alloc] initWithTimeInterval:_pollIntervalMs
                                                  leeway:DEFAULT_POLL_LEEEWAY_MS
                                                   queue:device_manager_processing_queue()
                                             handleBlock:^(AylaTimer *timer) {
                                                 [self processPolling];
                                             }];

    // Init device detail provider
    _deviceDetailProvider = sessionManager.sdkRoot.systemSettings.deviceDetailProvider;

    _lanServer = [[AylaHTTPServer alloc] initWithPort:DEFAULT_LAN_SERVER_PORT];
    [self setupLanServer];

    // Init lan http client
    _lanHttpClient = [[AylaHTTPClient alloc] initWithBaseUrl:nil];

    // Initialize all devices
    [self initDevices];

    [[AylaNetworks shared].connectivity addListener:self];
    return self;
}

- (NSDictionary *)devices
{
    return [self.mutableDevices copy];
}

- (AylaDevice *)_deviceWithDsn:(NSString *)dsn
{
    return self.mutableDevices[dsn];
}

/**
 * Processes and initializes the devices on init or after going online after
 * being in offline mode
 *
 * @param devices The list of devices to init
 */
- (void)processDeviceList:(NSArray AYLA_GENERIC(AylaDevice *) * _Nonnull)devices
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        AylaLogI([self logTag], 0, @"setup devices(%ld) properties", (unsigned long)devices.count);

        dispatch_group_t group = dispatch_group_create();
        NSMutableDictionary *failureDictionary = [NSMutableDictionary dictionary];

        // Set state to AylaDeviceManagerStateFetchingDeviceProperties
        self.state = AylaDeviceManagerStateFetchingDeviceProperties;

        // Iterate all devices to fetch properties of each device
        for (AylaDevice *device in devices) {
            dispatch_group_enter(group);
            [self setupDevice:device
                completionBlock:^(NSError *error) {
                    dispatch_group_leave(group);

                    if (error) {
                        AylaLogE([self logTag], 0, @"setup device properties %@", error);
                        failureDictionary[device.dsn] = error;
                    }
                }];
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        // Once all fetch request have been completed, set state to
        // AylaDeviceManagerStateReady
        self.state = AylaDeviceManagerStateReady;

        // Enable polling timer
        [self startPollTimer];

        dispatch_async(self.notificationQueue, ^{
            [self.listeners
                iterateListenersRespondingToSelector:@selector(deviceManager:didInitComplete:)
                                               block:^(id _Nonnull listener) {
                                                   [listener deviceManager:self didInitComplete:failureDictionary];
                                               }];
        });
    });
}

/**
 * This method will 1) fetch all device 2) fetch properties of all devices.
 * Once all implementation have been processed, Init status will be sent to all
 * listeners of current device manager.
 */
- (void)initDevices
{
    // Fetch all devices from cloud
    // Set state to AylaDeviceManagerStateFetchingDeviceList
    self.state = AylaDeviceManagerStateFetchingDeviceList;

    if (!self.mutableDevices) {
        self.mutableDevices = [NSMutableDictionary dictionary];
    }

    AylaLogI([self logTag], 0, @"setup devices");

    [self fetchDevices:^(NSArray<AylaDevice *> *_Nonnull devices) {
        [self processDeviceList:devices];
    }
        failure:^(NSError *_Nonnull error) {
            if ([self.sessionManager.aylaCache cachingEnabled:AylaCacheTypeDevice]) {
                [self initFromCache];
                return;
            }

            // Set state to AylaDeviceManagerStateError if device list cannot be
            // fetched from cloud
            self.state = AylaDeviceManagerStateError;

            AylaLogE([self logTag], 0, @"setup devices failure %@", error);

            dispatch_async(self.notificationQueue, ^{
                [self.listeners iterateListenersRespondingToSelector:@selector(deviceManager:didInitFailure:)
                                                               block:^(id _Nonnull listener) {
                                                                   [listener deviceManager:self didInitFailure:error];
                                                               }];
            });
        }];
}

- (void)initFromCache
{
    NSArray *array = [self.sessionManager.aylaCache getData:AylaCacheTypeDevicePrefix];
    [self mergeDevices:array completeList:YES];

    NSArray *devices = self.devices.allValues;
    for (AylaDevice *device in devices) {
        [device readPropertiesFromCache];
    }

    // Once all devices and properties have been loaded from cache, set state to
    // AylaDeviceManagerStateReady
    self.state = AylaDeviceManagerStateReady;
    self.cachedDeviceList = YES;

    // Enable polling timer
    [self startPollTimer];

    dispatch_async(self.notificationQueue, ^{
        [self.listeners iterateListenersRespondingToSelector:@selector(deviceManager:didInitComplete:)
                                                       block:^(id _Nonnull listener) {
                                                           [listener deviceManager:self didInitComplete:@{}];
                                                       }];
    });
}

/**
 * Use this method to merge devices which are fetched from cloud.
 * @param compeleteList Pass YES if the input device list is the complete device
 * list of current user.
 *                      Pass No if the input device list is a sublist of user's
 * devices.
 */
- (void)mergeDevices:(NSArray AYLA_GENERIC(AylaDevice *) *)devices completeList:(BOOL)completeList
{
    [self.lock lock];

    NSMutableArray *deleted = [self.mutableDevices.allValues mutableCopy];
    NSMutableArray *added = [NSMutableArray arrayWithCapacity:devices.count];

    for (AylaDevice *device in devices) {
        // If device is not a node, directly update device list maintained in
        // manager.
        AylaDevice *found = [self _deviceWithDsn:device.dsn];
        if (found) {
            [found updateFrom:device dataSource:AylaDataSourceCloud];
            [deleted removeObject:found];
        }
        else {
            [self.mutableDevices setObject:device forKey:device.dsn];
            [added addObject:device];
        }
    }

    if (completeList) {
        // If input device array is tagged as a complete device list from cloud.
        // Remove any devices that are appeared in device array.
        for (AylaDevice *device in deleted) {
            [self.mutableDevices removeObjectForKey:device.dsn];
        }
    }
    else {
        // If input device array in not a complete list
        // Clean the 'deleted' array.
        deleted = [NSMutableArray array];
    }

    [self processDeviceListChangesWithAddedDevices:added removedDevices:deleted];

    // Do an update to lan ip status of each device.
    [self validateLanIpForDevices];

    [self.lock unlock];
}

/**
 * Use this method to validate lan ips for devices. For any devices having the
 * same lan ip, this method will call
 * -confirmDeviceOfLanIp:timeout:completionBlock: to confirm the device of that
 * lan ip.
 *
 * @note The method may be optimized to use mDNS query.
 */
- (void)validateLanIpForDevices
{
    NSMutableDictionary *lanIpTable = [NSMutableDictionary dictionary];

    for (AylaDevice *device in self.mutableDevices.allValues) {
        if (device.lanIp) {
            if (lanIpTable[device.lanIp]) {
                [lanIpTable[device.lanIp] addObject:device];
            }
            else {
                lanIpTable[device.lanIp] = [NSMutableArray arrayWithObject:device];
            }
        }
        else {
            // For any devices without lan ip, set lan mode as unavailable
            // immidiately.
            device.disableLANUntilNetworkChanges = YES;
        }
    }

    for (NSString *lanIp in lanIpTable.allKeys) {
        NSArray *devices = lanIpTable[lanIp];
        if ([lanIpTable[lanIp] count] == 1) {
            AylaDevice *device = [devices firstObject];
            // For any lan ips which having no conflicts, set lan mode as available
            // for corresponding device.
            device.disableLANUntilNetworkChanges = NO;
        }
        else {
            AylaLogD([self logTag], 0, @"found duplicate lanIp:%@, %@", lanIp, @"validateLanIpForDevices");
            // For duplicated lan IPs
            for (AylaDevice *device in devices) {
                if (!device.disableLANUntilNetworkChanges) {
                    [device adjustLanSessionBasedOnPermitAndStatus];
                }
            }
        }
    }
}

- (void)connectivity:(AylaConnectivity *)connectivity didObserveNetworkChange:(AylaNetworkReachabilityStatus)reachabilityStatus {
    AylaLogD([self logTag], 0, @"Connectivity changed: %ld, resetting disableLANUntilNetworkChanges", (long)reachabilityStatus);
    [self.lock lock];
    for (AylaDevice *device in self.mutableDevices.allValues) {
        device.disableLANUntilNetworkChanges = NO;
    }
    [self.lock unlock];
}

/**
 * Use this method to complete extra steps for added or removed devices.
 * This method will also trigger device list change notifications.
 */
- (void)processDeviceListChangesWithAddedDevices:(NSArray *)added removedDevices:(NSArray *)removed
{
    if (added.count > 0) {
        // This method will only setup added devices when manager state has moved to
        // AylaDeviceManagerStateReady.
        // If not, device manager must explicitly call setupDevice:completionBlock:.
        if (self.state == AylaDeviceManagerStateReady) {
            for (AylaDevice *device in added) {
                [self setupDevice:device completionBlock:nil];
            }
        }
    }
    if (removed.count > 0) {
        for (AylaDevice *device in removed) {
            [device shutDown];
        }
    }

    // When there are any changes need to be notified to appilcation, go through
    // all registered
    // listeners and invoke any of them which conforms
    // @selector(deviceManager:didObserveDeviceListChange:)
    if (added.count > 0 || removed.count > 0) {
        NSSet *addedSet = [[NSSet alloc] initWithArray:added];
        NSSet *removedSet = [[NSSet alloc] initWithArray:removed];

        AylaDeviceListChange *change =
            [[AylaDeviceListChange alloc] initWithAddedDevices:addedSet removeDevices:removedSet];
        dispatch_async(self.notificationQueue, ^{
            [self.listeners
                iterateListenersRespondingToSelector:@selector(deviceManager:didObserveDeviceListChange:)
                                               block:^(id _Nonnull listener) {
                                                   [listener deviceManager:self didObserveDeviceListChange:change];
                                               }];
        });
    }
}

/**
 * Use this api to shut down functionalities of current device manager.
 */
- (void)shutDown
{
    [self.lock lock];

    [self stopPollTImer];

    [self.lanServer stop];

    for (AylaDevice *device in self.mutableDevices.allValues) {
        [device shutDown];
    }

    // Clean device list
    self.mutableDevices = nil;

    self.state = AylaDeviceManagerStateShutDown;

    [self.lock unlock];
}

- (AylaRegistration *)registration
{
    if (_registration == nil) {
        _registration = [[AylaRegistration alloc] initWithSessionManager:self.sessionManager];
    }
    return _registration;
}

- (void)addDevices:(NSArray *)devices
{
    [self mergeDevices:devices completeList:NO];
}

- (void)removeDevices:(NSArray *)devices
{
    NSMutableArray *remainingDevices = [self.mutableDevices.allValues mutableCopy];

    for (AylaDevice *device in devices) {
        [remainingDevices removeObject:device];
    }

    [self mergeDevices:remainingDevices completeList:YES];
}

//-----------------------------------------------------------
#pragma mark - Setup/Clean Device
//-----------------------------------------------------------

/**
 * When a new device is added into device manager, use this method to init
 * device object by fetching all required data
 * from cloud.
 *
 * Currenly only property list of each device will be fetched during device
 * initialization.
 */
- (void)setupDevice:(AylaDevice *)device completionBlock:(void (^)(NSError *error))completionBlock
{
    // Call method to fetch all managed properties for this device
    [device fetchProperties:[self.deviceDetailProvider monitoredPropertyNamesForDevice:device]
        success:^(NSArray AYLA_GENERIC(AylaProperty *) * _Nonnull properties) {

            // Enable tracking for a newly added device
            [device startTracking];

            if (completionBlock) completionBlock(nil);
        }
        failure:^(NSError *_Nonnull error) {
            
            // Enable tracking for a newly added device regardless of the first fetch properties failure
            // This will allow the DM to recover from an early failure
            [device startTracking];
            if (completionBlock) completionBlock(error);
        }];
}

//-----------------------------------------------------------
#pragma mark - Fetch Methods
//-----------------------------------------------------------

- (AylaHTTPTask *)fetchDevices:(void (^)(NSArray AYLA_GENERIC(AylaDevice *) * _Nonnull))successBlock
                       failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];

    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [httpClient getPath:@"devices.json"
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            __block NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[(NSArray *)responseObject count]];
            for (NSDictionary *deviceInJson in responseObject) {
                NSDictionary *attrsInJson = deviceInJson[@"device"];
                Class deviceClass = [AylaDevice deviceClassFromJSONDictionary:attrsInJson];
                [array addObject:[[deviceClass alloc] initWithDeviceManager:self JSONDictionary:attrsInJson error:nil]];
            }

            // Merge new devices in device manager
            dispatch_async(device_manager_processing_queue(), ^{
                if ([self.sessionManager.aylaCache cachingEnabled:AylaCacheTypeDevice]) {
                    [self.sessionManager.aylaCache save:AylaCacheTypeDevicePrefix object:array];
                }
                
                [self mergeDevices:array completeList:YES];
                
                id<AylaDeviceListPlugin> deviceListPlugin = (id<AylaDeviceListPlugin>)[[AylaNetworks shared] getPluginWithId:PLUGIN_ID_DEVICE_LIST];
                if (deviceListPlugin != nil) {
                    @synchronized (_mutableDevices) {
                        [deviceListPlugin updateDeviceDictionary:self.devices];
                    }
                }


                NSArray *devices = self.devices.allValues;
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(devices);
                });

            });
            if (self.sessionManager.cachedSession) {
                self.sessionManager.cachedSession = NO;
            }
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

//-----------------------------------------------------------
#pragma mark - Pause/Resume
//-----------------------------------------------------------
- (void)pause
{
    [self.lock lock];

    [self stopPollTImer];

    [self.lanServer stop];

    for (AylaDevice *device in self.devices.allValues) {
        [device stopTracking];
    }
    
    [[AylaNetworks shared].connectivity removeListener:self];

    self.state = AylaDeviceManagerStatePaused;

    [self.lock unlock];
}

- (void)resume
{
    [self.lock lock];
    
    // resume polling for devices to reverse the pause logic, regardless
    // of initDevices outcome below, otherwise fetchDevices might fail
    // and the poll timer will never be started
    [self startPollTimer];
    
    [self setupLanServer];
    [self initDevices];
    
    [[AylaNetworks shared].connectivity addListener:self];

    [self.lock unlock];
}

//-----------------------------------------------------------
#pragma mark - Datapoint Batches
//-----------------------------------------------------------
- (AylaHTTPTask *)createDatapointBatch:(NSArray AYLA_GENERIC(AylaDatapointBatchRequest *) *)datapointBatch
                               success:(void (^)(NSArray<AylaDatapointBatchResponse *> *_Nonnull))successBlock
                               failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];

    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSMutableArray *jsonBatch = [NSMutableArray array];
    for (AylaDatapointBatchRequest *datapointRequest in datapointBatch) {
        [jsonBatch addObject:[datapointRequest toJSONDictionary]];
    }

    NSDictionary *params = @{ @"batch_datapoints" : jsonBatch };

    return [httpClient postPath:@"/apiv1/batch_datapoints.json"
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSMutableArray *batchResponseArray = [NSMutableArray array];
            dispatch_group_t updatePropertiesGroup = dispatch_group_create();
            for (NSDictionary *jsonDictionary in responseObject) {
                AylaDatapointBatchResponse *batchResp =
                    [[AylaDatapointBatchResponse alloc] initWithJSONDictionary:jsonDictionary error:nil];
                if (batchResp) {
                    [batchResponseArray addObject:batchResp];
                    AylaDevice *device = [self.devices objectForKey:batchResp.deviceDsn];
                    AylaProperty *property = [device.properties objectForKey:batchResp.propertyName];

                    AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
                    dispatch_group_enter(updatePropertiesGroup);
                    [property updateAndNotifyDelegateFromDatapoint:batchResp.datapoint
                                                      successBlock:^{
                                                          dispatch_group_leave(updatePropertiesGroup);
                                                      }];
                }
            }
            dispatch_group_notify(updatePropertiesGroup, dispatch_get_main_queue(), ^{
                successBlock(batchResponseArray);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {

            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

//-----------------------------------------------------------
#pragma mark - Poll
//-----------------------------------------------------------
- (void)setPollIntervalMs:(NSUInteger)pollIntervalMs
{
    if (self.isPolling) {
        [self stopPollTImer];
        [self startPollTimer];
    }
    _pollIntervalMs = pollIntervalMs;
}

- (void)startPollTimer
{
    [self.pollTimer startPollingWithDelay:NO];
}

- (void)stopPollTImer
{
    [self.pollTimer stopPolling];
}

- (void)processPolling
{
    AylaLogI([self logTag], 0, @"%@", @"poll triggerred");
    [self fetchDevices:^(NSArray AYLA_GENERIC(AylaDevice *) * _Nonnull devices) {
        if (self.isCachedDeviceList) {  // if DM received a fresh list of devices
                                        // means we have connectivity again, exit
                                        // Offline mode then.
            AylaLogD([self logTag], 0, @"%@", @"Fresh device list fetched. Currently using cached list.");
            [self processDeviceList:devices];
            self.cachedDeviceList = NO;
        } else if (self.state == AylaDeviceManagerStateError) {
            AylaLogD([self logTag], 0, @"%@", @"Fresh device list fetched in Error State: process device list");
            [self processDeviceList:devices];
        }
    }
        failure:^(NSError *_Nonnull error) {
            if (!self.isCachedDeviceList) {
                AylaLogE([self logTag], 0, @"poll failure %ld", (long)error.code);
            }
        }];
}

- (BOOL)isPolling
{
    return self.pollTimer.isPolling;
}

- (void)startPolling
{
    [self.lock lock];
    
    for (AylaDevice *device in self.devices.allValues) {
        [device startTracking];
    }
    [self startPollTimer];
    
    [self.lock unlock];
}

- (void)stopPolling
{
    [self.lock lock];
    
    [self stopPollTImer];
    for (AylaDevice *device in self.devices.allValues) {
        [device stopTracking];
    }
    
    [self.lock unlock];
}

//-----------------------------------------------------------
#pragma mark - Lan
//-----------------------------------------------------------

- (NSError *)setupLanServer
{
    // Setup Lan server if it's not running.
    NSError *error;
    if (self.lanServer.listeningPort == 0) {
        [_lanServer start:&error];

        if (error) {
            error = nil;
            // If server can not be created with default port, let server pick an
            // available one
            _lanServer.port = 0;
            [_lanServer start:&error];
            if (error) {
                AylaLogE([self logTag], 0, @"Lan server cannot be started %@", error);
            }
        }
    }
    return error;
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

- (void)setNotificationQueue:(dispatch_queue_t)notificationQueue
{
    self.notificationQueue = notificationQueue != NULL ? notificationQueue : dispatch_get_main_queue();
}

//-----------------------------------------------------------
#pragma mark - Http Client
//-----------------------------------------------------------

- (AylaHTTPClient *)getLanHttpClient
{
    return self.lanHttpClient;
}

- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaHTTPClient *client = [self.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];

    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                            code:AylaRequestErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }

    return client;
}

//-----------------------------------------------------------
#pragma mark - Helpful Methods
//-----------------------------------------------------------

- (void)dealloc
{
    [self.pollTimer stopPolling];
    [self.lanServer stop];
}

- (NSString *)logTag
{
    return @"DeviceManager";
}

@end
@implementation AylaDeviceManager (AlertHistory)
- (AylaHTTPTask *)fetchAlertHistoryWithDSN:(NSString *)dsn paginated:(BOOL)paginated number:(NSInteger)perPage page:(NSInteger)pageNumber alertFilter:(AylaAlertFilter *)filter success:(void (^)(NSArray<AylaAlertHistory *> * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self fetchAlertHistoryWithDSN:dsn paginated:paginated number:perPage page:pageNumber alertFilter:filter sortParams:nil success:successBlock failure:failureBlock];
}

- (AylaHTTPTask *)fetchAlertHistoryWithDSN:(NSString *)dsn paginated:(BOOL)paginated number:(NSInteger)perPage page:(NSInteger)pageNumber alertFilter:(nullable AylaAlertFilter *)filter sortParams:(NSDictionary *)sortParams success:(void (^)(NSArray AYLA_GENERIC(AylaAlertHistory *) * alertHistory))successBlock
                                   failure:(void (^)(NSError *error))failureBlock {
    // if dsn is nil call failure with error and return
    if (dsn == nil) {
        NSError *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                    code:AylaRequestErrorCodeInvalidArguments
                                                userInfo:@{
                                                           AylaRequestErrorResponseJsonKey :
                                                               @{NSStringFromSelector(@selector(dsn)) : AylaErrorDescriptionCanNotBeBlank}
                                                           }
                                               shouldLog:YES
                                                  logTag:[self logTag]
                                        addOnDescription:@"invalidDSN"];
        failureBlock(error);
        return nil;
    }
    
    // else perform request
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"dsns/%@/devices/alert_history.json", dsn];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (paginated) {
        params[@"paginated"] = @"true";
        params[@"page"] = @(pageNumber);
        params[@"per_page"] = @(perPage);
    }
    if (filter) {
        [params addEntriesFromDictionary:[filter build]];
    }
    if (sortParams) {
        [params addEntriesFromDictionary:sortParams];
    }
    
    return [httpClient getPath:path
                    parameters:params.count > 0 ? params : nil
                       success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
                           NSArray *historyDictionaries = responseObject[@"alert_histories"];
                           NSMutableArray *histories = [NSMutableArray array];
                           for (NSDictionary *historyDictionary in historyDictionaries) {
                               [histories addObject:[[AylaAlertHistory alloc] initWithJSONDictionary:historyDictionary[@"alert_history"] error:nil]];
                           }
                           successBlock(histories);
                           AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
                       } failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                           
                           AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                       }];

}
@end
