//
//  AylaBLEDevice+Internal.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBLEDevice.h"
#import "AylaBLEDeviceManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN
extern NSString * const SERVICE_AYLA_BLE;

@interface AylaBLEDevice()
@property (nonatomic, strong) CBPeripheral *peripheral;

/**
 BLE Manager of the device
 */
@property (nonatomic, weak) AylaBLEDeviceManager *bleDeviceManager;

/**
 Data received during device discovery
 */
@property (nonatomic, strong) NSDictionary<NSString *,id> *advertisedData;

/**
 Serial Communication Queue
 */
@property (nonatomic, readwrite) dispatch_queue_t serialQueue;

/**
 @return an array with the CBUUID of the Ayla services in the BLE device to discover
 */
- (NSArray <CBUUID *>*)aylaServicesToDiscover;

/**
 @return an array with the CBUUID of the vendor services in the BLE device to discover
 */
- (NSArray <CBUUID *>*)servicesToDiscover;
@end

@interface AylaBLEDevice (Internal)

@end
NS_ASSUME_NONNULL_END
