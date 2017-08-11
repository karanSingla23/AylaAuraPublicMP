//
//  AylaBLECandidate.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/23/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaLocalDeviceManager.h"
#import "AylaLocalRegistrationCandidate.h"
@import CoreBluetooth;
@class AylaBLEDeviceManager;
NS_ASSUME_NONNULL_BEGIN

/**
 Represents a BLE Registration Candidate
 */
@interface AylaBLECandidate : AylaLocalRegistrationCandidate

/**
 Initializes the candidate with a peripheral

 @param peripheral the BLE peripheral found
 @param advertisementData Advertisement data sent by peripheral
 @param rssi RSSI from peripheral
 @param bleDeviceManager BLE device manager of the session
 @return An initialized candidate
 */
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData rssi:(NSInteger)rssi bleDeviceManager:(AylaBLEDeviceManager *)bleDeviceManager;

/**
 BLE peripheral found during scan
 */
@property (nonatomic, strong) CBPeripheral *peripheral;

/**
 Advertisement data sent by peripheral
 */
@property (nonatomic, strong) NSDictionary<NSString *,id> *advertisementData;

/**
 RSSI from peripheral
 */
@property (nonatomic, readwrite) NSInteger rssi;

/**
 BLE device manager of the session
 */
@property (nonatomic, weak) AylaBLEDeviceManager *bleDeviceManager;
@end
NS_ASSUME_NONNULL_END
