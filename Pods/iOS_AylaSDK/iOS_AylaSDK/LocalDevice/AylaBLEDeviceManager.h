//
//  AylaBLEDeviceManager.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/9/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLocalDeviceManager.h"
@import CoreBluetooth;
@class AylaBLECandidate;

NS_ASSUME_NONNULL_BEGIN
extern NSString * const AylaBLEErrorDomain;

/**
 Device Manager for BLE Devices
 */
@interface AylaBLEDeviceManager : NSObject  <AylaLocalDeviceManager, AylaDeviceListPlugin>

/**
 Initializes the manager with the specified services to scan

 @param scanServices The supported services
 @return an initialized BLE Device manager
 */
- (instancetype)initWithServices:(NSArray <CBUUID *>*)scanServices;

/**
 Creates a local candidate with the provided peripheral and advertisement data

 @param peripheral the BLE peripheral found
 @param advertisementData Advertisement data sent by peripheral
 @param rssi RSSI from peripheral
 @return An initialized candidate
 */
- (AylaBLECandidate *)createLocalCandidate:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData rssi:(NSInteger)rssi;
@end
NS_ASSUME_NONNULL_END
