//
//  AylaBLEDevice.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLocalDevice.h"
@import CoreBluetooth;

@class AylaBLEDeviceManager;

NS_ASSUME_NONNULL_BEGIN
/**
 Represents a local BLE Device, this class acts as perihperal delegate. If your device doesn't contain an Ayla GATT Service and you need to override the <CBPeripheralDelegate> methods mark your sublcasses as confirming the protocol and override them. Otherwise use the `didUpdateValueForVendorCharacteristic:error:` or, if necessary `didUpdateValueForAylaCharacteristic:error`
 */
@interface AylaBLEDevice : AylaLocalDevice <CBPeripheralDelegate>

/**
 Initializes the `AylaBLEDevice` with a peripheral
 
 @param peripheral the BLE peripheral
 @param advertisementData Advertisement data sent by peripheral
 @param rssi RSSI from peripheral
 @param bleDeviceManager BLE device manager of the session
 @return An initialized candidate
 */
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData rssi:(NSInteger)rssi bleDeviceManager:(AylaBLEDeviceManager *)bleDeviceManager;


/**
 Initializes the bluetooth connection
 */
- (void)initializeBluetooth;


/**
 Override to return the characteristics you want to fetch and receive notifications from.
 @param service The service that holds the characteristics.
 @return The characteristics to fetch from peripheral
 */
- (nullable NSArray<CBUUID *> *)vendorCharacteristicsToFetchForService:(CBService *)service;


/**
 Starts discovering the characteristics in service

 @param service The service to fetch its characteristics
 */
- (void)fetchCharacteristicsForService:(CBService *)service;

/**
 Override to return an array of CBUUID of the services to discover

 @return The Array of CBUUID of the services to discover
 */
- (NSArray <CBUUID *>*)vendorServicesToDiscover;


/**
 Maps the receiver to the identifier in the local device identifier map

 @param identifier The identifier of the device.
 */
- (void)mapToIdentifier:(nullable NSUUID *)identifier;


/**
 Invoked when a specified characteristic’s value has been read, or when the peripheral device notifies that the characteristic’s value has changed.
 Override to get notified when the SDK has found characteristics for the Vendor service.

 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occurred, the cause of the failure.
 */
- (void)didUpdateValueForVendorCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;


/**
 Invoked when a specified characteristic’s value has been read, or when the peripheral device notifies that the characteristic’s value has changed.
 Override just in case you want to do something with the Ayla Service Characteristics as they are read.

 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occurred, the cause of the failure.
 */
- (void)didUpdateValueForAylaCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;


/**
 @param uuid The `CBUUID` of the characteristic
 @return The characteristic from the Ayla BLE service with matching UUID
 */
- (nullable CBCharacteristic *)aylaCharacteristicForUUID:(CBUUID *)uuid;
/**
 @param uuid The `CBUUID` of the characteristic
 @return The characteristic from the Vendor BLE service with matching UUID
 */
- (nullable CBCharacteristic *)vendorCharacteristicForUUID:(CBUUID *)uuid;

/**
 Writes the data to the specified CBCharacteristic

 @param data The data to write
 @param characteristic Characteristic receiving the data
 @param type The type of write to be performed
 @param success Block called when the write succeeds
 @param failure Block called when the write fails
 @return An `AylaGenericTask` for the write operation
 */
- (nullable AylaGenericTask *)writeData:(NSData *)data toCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type success:(nullable void (^)())success failure:(nullable void (^)(NSError *error))failure;

/**
 BLE Peripheral of the device
 */
@property (nonatomic, readonly) CBPeripheral *peripheral;


/**
 Bluetooth identifier
 */
@property (nonatomic, readonly, nullable) NSUUID *bluetoothIdentifier;
@end
NS_ASSUME_NONNULL_END
