//
//  AylaBLECandidate.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/23/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBLECandidate.h"
#import "AylaBLEDevice.h"

@interface AylaBLECandidate ()
@property (nonatomic, strong) AylaBLEDevice *listener;
@end

@implementation AylaBLECandidate

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData rssi:(NSInteger)rssi bleDeviceManager:(AylaBLEDeviceManager *)bleDeviceManager {
    if (self = [super init]) {
        _peripheral = peripheral;
        _listener = [[AylaBLEDevice alloc] initWithPeripheral:peripheral advertisementData:advertisementData rssi:rssi bleDeviceManager:bleDeviceManager];
        _advertisementData = advertisementData;
        _rssi = rssi;
        _bleDeviceManager = bleDeviceManager;
    }
    return self;
}

- (AylaRegistrationType)registrationType {
    return AylaRegistrationTypeLocal;
}

- (NSString *)productName {
    return self.listener.productName;
}

- (NSString *)model {
    return self.listener.model;
}

- (NSString *)oemModel {
    NSString *oemModel = self.listener.oemModel;
    return oemModel == nil ? @"Ayla BLE Peripheral" : oemModel;
}

- (NSString *)hardwareAddress {
    return self.listener.hardwareAddress;
}

- (NSString *)dsn {
    return self.hardwareAddress;
}

- (NSString *)swVersion {
    return @"0.1";
}

@end
