//
//  AylaBLEDevice.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBLEDevice+Internal.h"
@import CoreBluetooth;
NSString * const SERVICE_AYLA_BLE = @"FE28";

static NSString * const CHARACTERISTIC_ID_UNIQUE_ID = @"00000001-FE28-435B-991A-F1B21BB9BCD0";
static NSString * const CHARACTERISTIC_ID_OEM = @"00000002-FE28-435B-991A-F1B21BB9BCD0";
static NSString * const CHARACTERISTIC_ID_OEM_MODEL = @"00000003-FE28-435B-991A-F1B21BB9BCD0";
static NSString * const CHARACTERISTIC_ID_TEMPLATE_VERSION = @"00000004-FE28-435B-991A-F1B21BB9BCD0";
static NSString * const CHARACTERISTIC_ID_IDENTIFY = @"00000005-FE28-435B-991A-F1B21BB9BCD0";
static NSString * const CHARACTERISTIC_ID_NAME = @"00000006-FE28-435B-991A-F1B21BB9BCD0";

static NSString *const PREFS_IDENTIFIER_PREFIX = @"HWAddr-";
static NSString *const PREFS_IDENTIFIERS_MAPPING = @"BLEAddrMap";

@interface AylaBLEWriteCommandDescriptor: NSObject
@property (nonatomic, strong) void (^success)();
@property (nonatomic, strong) void (^failure)(NSError *);
@end
@implementation AylaBLEWriteCommandDescriptor

- (instancetype)initWithSuccess:(void(^)())success failure:(void (^)(NSError *))failure {
    if (self = [super init]) {
        _success = success;
        _failure = failure;
    }
    return self;
}

@end

@interface AylaBLEDevice () <CBPeripheralDelegate>
@property (nonatomic, strong) NSMutableDictionary <CBUUID *, CBCharacteristic*>*aylaCharacteristics;
@property (nonatomic, strong) NSMutableDictionary <CBUUID *, CBCharacteristic*>*vendorCharacteristics;
@property (nonatomic, strong) NSMutableArray<AylaBLEWriteCommandDescriptor *> *writeCharacteristicDescriptors;
@end

@implementation AylaBLEDevice
- (void)setPeripheral:(CBPeripheral *)peripheral {
    _peripheral = peripheral;
    _peripheral.delegate = self;
}

- (void)initializeBluetooth {
    AylaBLEDeviceManager *deviceManager = (AylaBLEDeviceManager *)[[AylaNetworks shared] getPluginWithId:PLUGIN_ID_LOCAL_DEVICE];
    if (deviceManager != nil && (self.peripheral == nil || self.peripheral.state == CBPeripheralStateDisconnected) && self.hardwareAddress != nil) {
        AylaLogI([self logTag], 0, @"Initializing BLE connection with %@", self.hardwareAddress);
        [self connectLocalWithSuccess:^{
        } failure:^(NSError * _Nonnull error) {
        }];
    } else {
        AylaLogI([self logTag], 0, @"BLE device is already connected");
    }
}

- (BOOL)isConnectedLocal {
    return self.peripheral.state == CBPeripheralStateConnected;
}

- (instancetype)initWithDeviceManager:(AylaDeviceManager *)deviceManager JSONDictionary:(NSDictionary *)dictionary error:(NSError * _Nullable __autoreleasing *)error {
    if (self = [super initWithDeviceManager:deviceManager JSONDictionary:dictionary error:error]) {
        _serialQueue = dispatch_queue_create("com.aylanetworks.bleDeviceQueue", DISPATCH_QUEUE_SERIAL);
        _aylaCharacteristics = [NSMutableDictionary dictionary];
        _vendorCharacteristics = [NSMutableDictionary dictionary];
        _writeCharacteristicDescriptors = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData rssi:(NSInteger)rssi bleDeviceManager:(AylaBLEDeviceManager *)bleDeviceManager {
    if (self = [super initExtensible]) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _bleDeviceManager = bleDeviceManager;
        _serialQueue = dispatch_queue_create("com.aylanetworks.bleDeviceQueue", DISPATCH_QUEUE_SERIAL);
        _aylaCharacteristics = [NSMutableDictionary dictionary];
        _vendorCharacteristics = [NSMutableDictionary dictionary];
        _writeCharacteristicDescriptors = [NSMutableArray array];
    }
    
    AylaLogD([self logTag], 0, @"Creating AylaBLEDevice from advertised device: %@", advertisementData);
    return self;
}

- (AylaGenericTask *)connectLocalWithSuccess:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self.bleDeviceManager connectLocalDevice:self success:successBlock failure:failureBlock];
}

- (AylaGenericTask *)disconnectLocalWithSuccess:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self.bleDeviceManager disconnectLocalDevice:self success:successBlock failure:failureBlock];
}

- (NSString *)logTag {
    return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([AylaBLEDevice class]), self.hardwareAddress];
}

- (AylaGenericTask *)writeValue:(NSData *)value toCharacteristic:(CBCharacteristic *)characteristic {
    AylaGenericTask *writeTask = [[AylaGenericTask alloc] initWithTask:^BOOL{
        [self.peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        return YES;
    } cancel:nil];
    [writeTask start];
    return writeTask;
}

- (NSArray<CBUUID *> *)characteristicsToFetch {
    NSMutableArray<CBUUID *> *characteristicsToFetch = [NSMutableArray array];
    if (self.hardwareAddress ==  nil) {
        [characteristicsToFetch addObject:[CBUUID UUIDWithString:CHARACTERISTIC_ID_UNIQUE_ID]];
    }
    
    if (self.oemModel == nil) {
        [characteristicsToFetch addObject:[CBUUID UUIDWithString:CHARACTERISTIC_ID_OEM_MODEL]];
    }
    
    if (self.productName == nil) {
        [characteristicsToFetch addObject:[CBUUID UUIDWithString:CHARACTERISTIC_ID_NAME]];
    }
    
    if (self.swVersion == nil) {
        [characteristicsToFetch addObject:[CBUUID UUIDWithString:CHARACTERISTIC_ID_TEMPLATE_VERSION]];
    }
    
    return characteristicsToFetch;
}

- (NSArray <CBUUID *>*)aylaServicesToDiscover {
    return @[[CBUUID UUIDWithString:SERVICE_AYLA_BLE]];
}

- (NSArray <CBUUID *>*)servicesToDiscover {
    NSArray *servicesToDiscover = [self aylaServicesToDiscover];
    NSArray *vendorServices = [self vendorServicesToDiscover];
    if (vendorServices.count) {
        servicesToDiscover = [servicesToDiscover arrayByAddingObjectsFromArray:vendorServices];
    }
    return servicesToDiscover;
}

- (NSArray <CBUUID *>*)vendorServicesToDiscover {
    return nil;
}

- (NSArray <CBUUID *> *)vendorCharacteristicsToFetchForService:(CBService *)service {
    return nil;
}

- (void)didUpdateValueForVendorCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {    
}

- (void)fetchCharacteristicsForService:(CBService *)service {
    if ([service.UUID.UUIDString isEqualToString:SERVICE_AYLA_BLE]) {
        [self.peripheral discoverCharacteristics:[self characteristicsToFetch] forService:service];
    } else {
        [self.peripheral discoverCharacteristics:[self vendorCharacteristicsToFetchForService:service] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        AylaLogE([self logTag], 0, @"%@", error);
        return;
    }
    AylaLogD([self logTag], 0, @"Discovered %ld services:", peripheral.services.count);
    for (CBService *service in peripheral.services) {
        if ([[self servicesToDiscover]containsObject:service.UUID]) {
            AylaLogI([self logTag], 0, @"Found managed BLE Service %@, discovering characteristics...", service.UUID);
            [self fetchCharacteristicsForService:service];
        } else {
            AylaLogD([self logTag], 0, @"Ignoring non managed service: %@",service.UUID);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        AylaLogE([self logTag], 0, @"%@", error);
        return;
    }
    AylaLogD([self logTag], 0,  @"Discovered %ld characteristics:", service.characteristics.count);
    for (CBCharacteristic *characteristic in service.characteristics) {
        AylaLogD([self logTag], 0,  @"Characteristic: %@", characteristic);
        if ([service.UUID.UUIDString isEqualToString:SERVICE_AYLA_BLE]) {
            NSArray *characteristicsToFetch = [self characteristicsToFetch];
            BOOL shouldReadCharacteristic = characteristicsToFetch == nil || [characteristicsToFetch containsObject:characteristic.UUID];
            if (shouldReadCharacteristic) {
                AylaLogI([self logTag], 0, @"Characteristic in Ayla BLE service, reading...");
                [peripheral readValueForCharacteristic:characteristic];
                self.aylaCharacteristics[characteristic.UUID] = characteristic;
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        } else {
            NSArray *characteristicsToFetch = [self vendorCharacteristicsToFetchForService:service];
            BOOL shouldReadCharacteristic = characteristicsToFetch == nil || [characteristicsToFetch containsObject:characteristic.UUID];
            if (shouldReadCharacteristic) {
                AylaLogI([self logTag], 0, @"Characteristic in Vendor list to fetch, reading...");
                [peripheral readValueForCharacteristic:characteristic];
                self.vendorCharacteristics[characteristic.UUID] = characteristic;
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
    [self checkQueuedCommands];
}

- (CBCharacteristic *)vendorCharacteristicForUUID:(CBUUID *)uuid {
    return self.vendorCharacteristics[uuid];
}

- (CBCharacteristic *)aylaCharacteristicForUUID:(CBUUID *)uuid {
    return self.aylaCharacteristics[uuid];
}

- (AylaGenericTask *)writeData:(NSData *)data toCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type success:(void (^)())success failure:(void (^)(NSError * _Nonnull))failure {
    [self.writeCharacteristicDescriptors addObject:[[AylaBLEWriteCommandDescriptor alloc]initWithSuccess:success failure:failure]];
    
    AylaGenericTask *task = [[AylaGenericTask alloc] initWithTask:^BOOL{
        [self.peripheral writeValue:data forCharacteristic:characteristic type:type];
        return YES;
    } cancel:nil];
    
    dispatch_async(self.serialQueue, ^{
        [task start];
    });
    return task;
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    AylaBLEWriteCommandDescriptor *writeCharacteristicDescriptor = self.writeCharacteristicDescriptors.firstObject;
    
    [self.writeCharacteristicDescriptors removeObjectAtIndex:0];
    if (writeCharacteristicDescriptor == nil) {
        return;
    }
    
    if (error != nil) {
        if (writeCharacteristicDescriptor.failure != nil) {
            writeCharacteristicDescriptor.failure(error);
        }
        return;
    }
    if (writeCharacteristicDescriptor.success != nil) {
        writeCharacteristicDescriptor.success();
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        AylaLogE([self logTag], 0, @"%@", error);
        return;
    }
    if ([characteristic.service.UUID.UUIDString isEqualToString:SERVICE_AYLA_BLE]) {
        
        AylaLogD([self logTag], 0, @"Read value for Ayla characteristic: %@",characteristic);
        [self didUpdateValueForAylaCharacteristic:characteristic error:error];
    } else {
        AylaLogD([self logTag], 0, @"Read value for Vendor characteristic: %@",characteristic);
        [self didUpdateValueForVendorCharacteristic:characteristic error:error];
    }
}

- (void)didUpdateValueForAylaCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *updatedCharecteristic = nil;
    if ([characteristic.UUID.UUIDString isEqual:CHARACTERISTIC_ID_UNIQUE_ID]) {
        self.hardwareAddress = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        updatedCharecteristic = @"hardware address";
    } else if ([characteristic.UUID.UUIDString isEqual:CHARACTERISTIC_ID_NAME]) {
        self.productName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        updatedCharecteristic = @"product name";
    } else if ([characteristic.UUID.UUIDString isEqual:CHARACTERISTIC_ID_OEM_MODEL]) {
        self.oemModel = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        updatedCharecteristic = @"OEM Model";
    } else if ([characteristic.UUID.UUIDString isEqualToString:CHARACTERISTIC_ID_TEMPLATE_VERSION]) {
        self.swVersion = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    }
    if (updatedCharecteristic != nil) {
        AylaLogD([self logTag], 0, @"Updated %@ to: %@", updatedCharecteristic, characteristic.value);
    } else {
        AylaLogE([self logTag], 0, @"Found unknown characteristic: %@", characteristic.UUID);
    }
}

- (void)mapToIdentifier:(NSUUID *)identifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *identifiersMap = [[defaults objectForKey:PREFS_IDENTIFIERS_MAPPING] mutableCopy];
    if (identifiersMap == nil) {
        identifiersMap = [NSMutableDictionary dictionary];
    }
    NSString *mapKey = [NSString stringWithFormat:@"%@%@", PREFS_IDENTIFIER_PREFIX, self.hardwareAddress];
    if (identifier == nil) {
        [identifiersMap removeObjectForKey:mapKey];
    } else {
        identifiersMap[mapKey] = identifier.UUIDString;
    }
    [defaults setObject:identifiersMap forKey:PREFS_IDENTIFIERS_MAPPING];
}

- (NSUUID *)bluetoothIdentifier {
    if (self.hardwareAddress == nil) {
        return nil;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *identifiersMap = [defaults objectForKey:PREFS_IDENTIFIERS_MAPPING];
    NSString *identifier = identifiersMap[[NSString stringWithFormat:@"%@%@", PREFS_IDENTIFIER_PREFIX, self.hardwareAddress]];
    
    return identifier == nil ? nil : [[NSUUID alloc] initWithUUIDString:identifier];
    
}

- (BOOL)requiresLocalConfiguration {
    return self.bluetoothIdentifier == nil;
}
@end
