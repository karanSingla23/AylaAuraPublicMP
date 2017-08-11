//
//  AylaBLEDeviceManager+Internal.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBLEDeviceManager.h"
#import "AylaBLEDevice+Internal.h"

@import CoreBluetooth;

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a task and its callbacks when connecting to a BLE Device
 */
@interface AylaBLEConnectionDescriptor : NSObject

/**
 Connection Task
 */
@property (nonatomic, strong) AylaGenericTask *connectionTask;

/**
 Connection success callback
 */
@property (nonatomic, strong, nullable) void (^connectionSuccessCallback)();

/**
 Connection failure callback
 */
@property (nonatomic, strong, nullable) void (^connectionFailureCallback)(NSError * _Nonnull);
@end

@interface AylaBLEDeviceManager ()

/**
 @return Tag for logs
 */
- (NSString *)logTag;

/** BLE manager */
@property (nonatomic, strong) CBCentralManager *bleManager;
/** Services to scan */
@property (nonatomic, strong) NSArray<CBUUID *> *scanServices;
/** Block called when scan succeeds */
@property (nonatomic, strong, nullable) void (^scanSuccessBlock)(NSArray<AylaLocalDevice *> * _Nonnull);
/** Block called when scan fails */
@property (nonatomic, strong, nullable) void (^scanFailureBlock)(NSError * _Nonnull);


/** BLE Device scan task */
@property (nonatomic, strong, nullable) AylaGenericTask *scanTask;
/** Holds the results of the scan */
@property (nonatomic, strong) NSMutableArray <AylaRegistrationCandidate *> *scanResults;
/** Helps identifying the connection tasks in the operation queue */
@property (nonatomic, strong) NSMutableDictionary *connectionDescriptors;
@end


extern NSString * const AylaBLEDeviceManagerStatePoweredOff;
@interface  AylaBLEDeviceManager (Internal)

/**
 Adds a connection descriptor

 @param descriptor Connection Descriptor
 @param peripheral Peripheral to connect
 */
- (void)addConnectionDescriptor:(AylaBLEConnectionDescriptor *)descriptor forPeripheral:(CBPeripheral *)peripheral;

/**
 Remove connection descriptor

 @param peripheral Peripheral for the descriptor to remove.
 */
- (void)removeConnectionDescriptorForPeripheral:(CBPeripheral *)peripheral;


/**
 Returns the connection descriptor for the perihperal

 @param peripheral The BLE peripheral
 @return The connection descriptor
 */
- (AylaBLEConnectionDescriptor *)connectionDescriptorForPeripheral:(CBPeripheral *)peripheral;

/**
 Connects to the specified BLE Device

 @param device the device to connect
 @param successBlock block called when the device has been connected
 @param failureBlock A block called when the connection fails
 @return A generic task representing the request
 */
- (nullable AylaGenericTask *)connectLocalDevice:(AylaBLEDevice *)device success:(nullable void (^)())successBlock failure:(nullable void (^)(NSError * _Nonnull))failureBlock;

/**
 Disconnects the specified BLE local device

 @param device The device to disconnect
 @param successBlock block called when the device has been disconnected
 @param failureBlock A block called when the disconnection fails
 @return A generic task representing the request
 */
- (nullable AylaGenericTask *)disconnectLocalDevice:(AylaBLEDevice *)device success:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock;


/**
 Starts the scan for local devices with the specified timeout and returns the results in the success block

 @param timeoutInMs timeout for scan for devices
 @param successBlock block called when the device scan is complete, takes an array with the results
 @param failureBlock A block called when the scan fails.
 @return A generic task representing the request
 */
- (nullable AylaGenericTask *)scanWithTimeout:(NSInteger)timeoutInMs success:(void (^)(NSArray<AylaRegistrationCandidate *> * _Nonnull results))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock;
@end
NS_ASSUME_NONNULL_END
