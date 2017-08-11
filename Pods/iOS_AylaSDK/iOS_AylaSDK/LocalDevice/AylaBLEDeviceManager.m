//
//  AylaBLEDeviceManager.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/9/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBLEDeviceManager+Internal.h"
#import "AylaLogManager.h"
#import "AylaRegistrationCandidate.h"
#import "AylaBLECandidate.h"

NSString * const DEFAULT_MODEL = @"AY001BT01";
NSString * const DEFAULT_OEM_MODEL = @"OEM-AYLABT";
NSString * const AylaBLEErrorDomain = @"com.aylanetworks.error.ble";

@interface AylaBLEDeviceManager (CBCentralManagerDelegate)<CBCentralManagerDelegate>
@end
@interface AylaBLEDeviceManager (AylaDeviceManagerListener)<AylaDeviceManagerListener>
@end
@interface AylaBLEDeviceManager ()
@property (nonatomic, weak) AylaSessionManager *sessionManager;
@end

NSString * const AylaBLEDeviceManagerStatePoweredOff = @"Bluetooth is currently powered off";

@implementation AylaBLEDeviceManager
- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error sessionManager:(AylaSessionManager *)sessionManager
{
    AylaHTTPClient *client = [sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];
    
    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRegistrationErrorDomain
                                            code:AylaRegistrationErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }
    
    return client;
}

- (instancetype)initWithServices:(NSArray<CBUUID *> *)scanServices {
    if (self = [super init]) {
        _scanServices = scanServices;
    }
    return self;
}
+ (NSString*)randomToken:(int)len
{
    static NSString *list = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    int list_len =62;
    NSMutableString *s = [NSMutableString stringWithCapacity:len];
    for (NSUInteger i = 0U; i < len; i++) {
        u_int32_t r = arc4random() % list_len;
        unichar c = [list characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

- (NSString *)pluginName {
    return @"Ayla BLE Device Manager";
}
- (void)initializePlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager {
    if ([pluginId isEqualToString:PLUGIN_ID_DEVICE_LIST]) {
        self.bleManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.connectionDescriptors = [NSMutableDictionary dictionary];
        [self reconnectDevices:sessionManager];
        [sessionManager.deviceManager addListener:self];
        self.sessionManager = sessionManager;
    }
}

- (void)updateDeviceDictionary:(NSDictionary<NSString *,AylaDevice *> *)devices {
    for (AylaDevice *device in devices.allValues) {
        if ([device isKindOfClass:[AylaBLEDevice class]]) {
            [(AylaBLEDevice *)device initializeBluetooth];
        }
    }
}

- (NSMutableArray <AylaRegistrationCandidate *>*)filteredScanResults {
    NSMutableArray *wholeResults = [NSMutableArray array];
    for (AylaRegistrationCandidate *candidate in self.scanResults) {
        //check all keys required for registration are not nil
        NSArray <NSString *>*keysToCheck = @[ NSStringFromSelector(@selector(hardwareAddress)),
                                   NSStringFromSelector(@selector(oemModel)),
                                   NSStringFromSelector(@selector(model)),
                                   NSStringFromSelector(@selector(swVersion)),
                                   NSStringFromSelector(@selector(deviceType))];
        BOOL pass = YES;
        for (NSString *key in keysToCheck) {
            if ([candidate valueForKey:key] == nil) {
                pass = NO;
                break;
            }
        }
        if (pass) {
            [wholeResults addObject:candidate];
        }
        
    }
    return wholeResults;
}

- (AylaGenericTask *)findLocalDevicesWithHint:(nullable id)hint timeout:(NSInteger)timeoutInMs success:(void (^)(NSArray<AylaRegistrationCandidate *> * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self scanWithTimeout:timeoutInMs success:successBlock failure:failureBlock];
}

- (void)reconnectDevices:(AylaSessionManager *)sessionManager {
    // reconnect devices
    AylaDeviceManager *deviceManager = sessionManager.deviceManager;
    if (deviceManager == nil) {
        AylaLogE([self logTag], 0, @"No device manager found");
        return;
    }
    for (AylaDevice *device in deviceManager.devices.allValues) {
        if ([device isKindOfClass:[AylaBLEDevice class]]) {
            AylaBLEDevice *bleDevice = (AylaBLEDevice *)device;
            bleDevice.bleDeviceManager = self;
            [bleDevice connectLocalWithSuccess:^{ } failure:^(NSError * _Nonnull errors) { }];
        }
    }
}

- (AylaConnectTask *)registerLocalDevice:(AylaBLECandidate *)bleCandidate sessionManager:(AylaSessionManager *)sessionManager success:(void (^)(AylaLocalDevice * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    if (sessionManager == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                    code:AylaRequestErrorCodePreconditionFailure
                                                userInfo:@{
                                                           NSStringFromSelector(@selector(sessionManager)) :
                                                               AylaErrorDescriptionIsInvalid
                                                           }]);
        });
        return nil;
    }
    
    AylaDeviceManager *deviceManager = sessionManager.deviceManager;
    if (deviceManager == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                    code:AylaRequestErrorCodePreconditionFailure
                                                userInfo:@{
                                                           NSStringFromSelector(@selector(deviceManager)) :
                                                               AylaErrorDescriptionIsInvalid
                                                           }]);
        });
        return nil;
    }
    if (![bleCandidate isKindOfClass:[AylaBLECandidate class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                    code:AylaRequestErrorCodePreconditionFailure
                                                userInfo:@{
                                                           NSLocalizedDescriptionKey : NSLocalizedString(@"Invalid candidate type", nil)
                                                           }]);
        });
        return nil;
    }
    NSError *error = nil;
    AylaHTTPClient *httpClient = [self getHttpClient:&error sessionManager:sessionManager];
    if (error != nil) {
        failureBlock(error);
        return nil;
    }
    NSDictionary *jsonCandidate = [bleCandidate toJSONDictionary];
    AylaLogD([self logTag], 0, @"Registering candidate: %@", jsonCandidate);
    return [httpClient postPath:@"devices/discover.json" parameters:jsonCandidate success:^(AylaHTTPTask * _Nonnull task, id  _Nullable responseObject) {
        if (task.cancelled) {
            AylaLogI([self logTag], 0, @"request canceled: %@", NSStringFromSelector(_cmd));
            return ;
        }
        
        AylaLogI([self logTag], 0, @"Response to discover.json: %@", responseObject);
        AylaRegistration *registration = [[AylaRegistration alloc] initWithSessionManager:sessionManager];
        AylaRegistrationCandidate *candidate = [[AylaRegistrationCandidate alloc] initWithDictionary:responseObject];
        candidate.registrationType = AylaRegistrationTypeDsn;
        [registration registerCandidate:candidate success:^(AylaDevice * _Nonnull device) {
            if ([device isKindOfClass:[AylaBLEDevice class]]) {
                AylaBLEDevice *bleDevice = (AylaBLEDevice *)device;
                CBPeripheral *peripheral = bleCandidate.peripheral;
                bleDevice.peripheral = peripheral;
                bleDevice.bleDeviceManager = bleCandidate.bleDeviceManager;
                [self connectLocalDevice:bleDevice success:^{
                    [bleDevice mapToIdentifier:peripheral.identifier];
                } failure:^(NSError * _Nonnull error) {}];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock((AylaLocalDevice *)device);
            });
        } failure:^(NSError * _Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    } failure:^(AylaHTTPTask * _Nonnull task, NSError * _Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
    }];
}

- (AylaConnectTask *)unregisterLocalDevice:(AylaBLEDevice *)device sessionManager:(AylaSessionManager *)sessionManager success:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    [device disconnectLocalWithSuccess:nil failure:nil];
    
    return [device unregisterWithSuccess:successBlock failure:failureBlock];
}

- (Class)deviceClassForModel:(NSString *)model oemModel:(NSString *)oemModel uniqueId:(NSString *)uniqueId {
    if ([model isEqualToString:DEFAULT_MODEL] && [oemModel isEqualToString:DEFAULT_OEM_MODEL]) {
        return [AylaBLEDevice class];
    }
    return nil;
}

- (AylaBLECandidate *)createLocalCandidate:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData rssi:(NSInteger)rssi  {
    return [[AylaBLECandidate alloc] initWithPeripheral:peripheral advertisementData:advertisementData rssi:rssi bleDeviceManager:self];
}

- (void)pausePlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager {
    if ([pluginId isEqualToString:PLUGIN_ID_LOCAL_DEVICE]) {
        // Disconnect devices
        AylaDeviceManager *deviceManager = sessionManager.deviceManager;
        if (deviceManager == nil) {
            AylaLogE([self logTag], 0, @"No device manager found");
            return;
        }
        for (AylaDevice *device in deviceManager.devices.allValues) {
            if ([device isKindOfClass:[AylaBLEDevice class]]) {
                AylaBLEDevice *bleDevice = (AylaBLEDevice *)device;
                [bleDevice disconnectLocalWithSuccess:nil failure:nil];
            }
        }
        
    }
}

- (void)resumePlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager {
    
    if ([pluginId isEqualToString:PLUGIN_ID_LOCAL_DEVICE]) {
        [self reconnectDevices:sessionManager];
    }
}

- (void)shutDownPlugin:(NSString *)pluginId sessionManager:(AylaSessionManager *)sessionManager {
    [self pausePlugin:pluginId sessionManager:sessionManager];
}

- (NSString *)logTag {
    return NSStringFromClass([AylaBLEDeviceManager class]);
}
@end

@implementation AylaBLEDeviceManager (CBCentralManagerDelegate)
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSArray <CBUUID *>*serviceUUIDs = advertisementData[@"kCBAdvDataServiceUUIDs"];
    for (CBUUID *service in serviceUUIDs) {
        if ([self.scanServices containsObject:service]) {
            AylaBLECandidate *device = [self createLocalCandidate:peripheral advertisementData:advertisementData rssi:RSSI.integerValue];
            [self.scanResults addObject:device];
            [self.bleManager connectPeripheral:peripheral options:nil];
        }
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOff:
            if (self.scanFailureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.scanFailureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                                     code:AylaRequestErrorCodePreconditionFailure
                                                                 userInfo:@{
                                                                            NSLocalizedDescriptionKey :
                                                                                NSLocalizedString(AylaBLEDeviceManagerStatePoweredOff, nil)
                                                                            }]);
                });
                self.scanTask = nil;
                self.scanSuccessBlock = nil;
                self.scanFailureBlock = nil;
            }
            return;
        case CBManagerStatePoweredOn:
        default:
            break;
    }
}

- (AylaBLEDevice *)deviceForPeripheral:(CBPeripheral *)peripheral {
    for (AylaBLEDevice *device in self.sessionManager.deviceManager.devices.allValues) {
        if ([device isKindOfClass:[AylaBLEDevice class]]) {
            if ([device.peripheral.identifier isEqual:peripheral.identifier]) {
                return device;
            }
        }
    }
    return nil;
}

- (void)updateDeviceForPeripheral:(CBPeripheral *)peripheral fromDevice:(AylaBLEDevice *)updateDevice {
    AylaBLEDevice *bleDevice = [self deviceForPeripheral:peripheral];
    bleDevice.peripheral = peripheral;
    [bleDevice updateFrom:updateDevice dataSource:AylaDataSourceCloud];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    AylaBLEDevice *updateDevice = [[AylaBLEDevice alloc] initExtensible];
    updateDevice.connectedAt = [NSDate date];
    updateDevice.connectionStatus = AylaDeviceConnectionStatusOnline;
    [self updateDeviceForPeripheral:peripheral fromDevice:updateDevice];
    [peripheral discoverServices:nil];
    
    AylaBLEConnectionDescriptor *connectionDescriptor = [self connectionDescriptorForPeripheral:peripheral];
    if (connectionDescriptor.connectionSuccessCallback) {
        
        AylaLogI([self logTag], 0, @"Connected to BLE Device");
        connectionDescriptor.connectionSuccessCallback();
    }
    [self removeConnectionDescriptorForPeripheral:peripheral];
    AylaBLEDevice *bleDevice = [self deviceForPeripheral:peripheral];
    [bleDevice stopTracking];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    AylaBLEConnectionDescriptor *connectionDescriptor = [self connectionDescriptorForPeripheral:peripheral];
    if (connectionDescriptor.connectionFailureCallback) {
        
        AylaLogE([self logTag], 0, @"Failed to connect to BLE Device: %@", error);
        connectionDescriptor.connectionFailureCallback(error);
    }
    [self removeConnectionDescriptorForPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    AylaBLEDevice *updateDevice = [[AylaBLEDevice alloc] initExtensible];
    updateDevice.connectionStatus = AylaDeviceConnectionStatusOffline;
    [self updateDeviceForPeripheral:peripheral fromDevice:updateDevice];
    AylaBLEDevice *bleDevice = [self deviceForPeripheral:peripheral];
    [bleDevice startTracking];
    AylaLogI([self logTag], 0, @"Disconnected from BLE peripheral: %@", bleDevice.hardwareAddress);
}
@end

@implementation AylaBLEDeviceManager (AylaDeviceManagerListener)

- (void)deviceManager:(AylaDeviceManager *)deviceManager didInitComplete:(NSDictionary<NSString *,NSError *> *)deviceFailures {
    [self reconnectDevices:deviceManager.sessionManager];
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager didInitFailure:(NSError *)error {
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager didObserveDeviceListChange:(AylaDeviceListChange *)change {
}

- (void)deviceManager:(AylaDeviceManager *)deviceManager deviceManagerStateChanged:(AylaDeviceManagerState)oldState newState:(AylaDeviceManagerState)newState {
}
@end
