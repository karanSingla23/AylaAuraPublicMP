//
//  AylaBLEDeviceManager+Internal.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaBLEDeviceManager+Internal.h"
#import "AylaBLEDevice.h"
#import "AylaBLECandidate.h"

@implementation AylaBLEDeviceManager (Internal)
- (AylaGenericTask *)scanWithTimeout:(NSInteger)timeoutInMs success:(void (^)(NSArray<AylaRegistrationCandidate *> * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    if (self.scanTask) {
        return self.scanTask;
    }
    
    if (self.bleManager.state == CBManagerStatePoweredOff) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock != nil) {
                failureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                        code:AylaRequestErrorCodePreconditionFailure
                                                    userInfo:@{
                                                               NSLocalizedDescriptionKey :
                                                                   NSLocalizedString(AylaBLEDeviceManagerStatePoweredOff, nil)
                                                               }]);
            }
        });
        return nil;
    }
    
    self.scanResults = [NSMutableArray array];
    self.scanSuccessBlock = successBlock;
    self.scanFailureBlock = failureBlock;
    
    
    self.scanTask = [[AylaGenericTask alloc] initWithTask:^{
        [self.bleManager scanForPeripheralsWithServices:self.scanServices options:nil];
        return YES;
    } cancel:^(BOOL timedOut) {
        [self.bleManager stopScan];
        self.scanTask = nil;
        self.scanSuccessBlock = nil;
        self.scanFailureBlock = nil;
        if (timedOut) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(self.scanResults);
            });
        }
    } timeout:timeoutInMs];
    
    [self.scanTask start];
    
    return self.scanTask;
}

- (AylaGenericTask *)connectLocalDevice:(AylaBLEDevice *)device success:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    AylaGenericTask * (^connect)() = ^{
        AylaGenericTask *connectionTask = [[AylaGenericTask alloc] initWithTask:^BOOL{
            [self.bleManager connectPeripheral:device.peripheral options:nil];
            return YES;
        } cancel:^(BOOL timedOut) {
            [self.bleManager cancelPeripheralConnection:device.peripheral];
            if (timedOut && failureBlock) {
                failureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain code:kCFNetServiceErrorTimeout userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Connection timed out",nil) }]);
                return;
            }
        }];
        
        AylaBLEConnectionDescriptor *descriptor = [[AylaBLEConnectionDescriptor alloc] init];
        descriptor.connectionSuccessCallback = successBlock;
        descriptor.connectionFailureCallback = failureBlock;
        descriptor.connectionTask = connectionTask;
        [self addConnectionDescriptor:descriptor forPeripheral:device.peripheral];
        [connectionTask start];
        return connectionTask;
    };
    if (device.peripheral == nil) {
        NSUUID *uuid = device.bluetoothIdentifier;
        if (uuid != nil) {
            NSArray <CBPeripheral *> *knownPeripherals = [self.bleManager retrievePeripheralsWithIdentifiers:@[uuid]];
            if (knownPeripherals.count < 1) {
                NSArray *connectedPeripherals = [self.bleManager retrieveConnectedPeripheralsWithServices:device.servicesToDiscover];
                if (connectedPeripherals.count < 1) {
                    return [self scanWithTimeout:5000 success:^(NSArray<AylaBLECandidate *> * _Nonnull results) {
                        if (results.count < 1) {
                            failureBlock([AylaErrorUtils errorWithDomain:AylaBLEErrorDomain code:404 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"No candidates were found", nil)}]);
                            return;
                        }
                        device.peripheral = results.firstObject.peripheral;
                        connect();
                    } failure:failureBlock];
                } else {
                    device.peripheral = connectedPeripherals.firstObject;
                }
            } else {
                device.peripheral = knownPeripherals.firstObject;
            }
        } else {
            NSString *errorDescription = NSLocalizedString(@"BLE device requires local configuration", nil);
            failureBlock([AylaErrorUtils errorWithDomain:AylaRequestErrorDomain code:AylaRequestErrorCodePreconditionFailure userInfo:@{ NSLocalizedDescriptionKey : errorDescription } shouldLog:YES logTag:[self logTag] addOnDescription:errorDescription]);
            return nil;
        }
    }
    return connect();
}

- (AylaGenericTask *)disconnectLocalDevice:(AylaBLEDevice *)device success:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    if (device.peripheral == nil) {
        return nil;
    }
    AylaGenericTask *disconnectTask = [[AylaGenericTask alloc] initWithTask:^BOOL{
        [self.bleManager cancelPeripheralConnection:device.peripheral];
        return YES;
    } cancel:nil timeout:0];
    [disconnectTask start];
    return disconnectTask;
}

- (void)addConnectionDescriptor:(AylaBLEConnectionDescriptor *)descriptor forPeripheral:(CBPeripheral *)peripheral {
    self.connectionDescriptors[peripheral.identifier.UUIDString] = descriptor;
}

- (void)removeConnectionDescriptorForPeripheral:(CBPeripheral *)peripheral {
    [self.connectionDescriptors removeObjectForKey:peripheral.identifier.UUIDString];
}

- (AylaBLEConnectionDescriptor *)connectionDescriptorForPeripheral:(CBPeripheral *)peripheral {
    return self.connectionDescriptors[peripheral.identifier.UUIDString];
}
@end

@implementation AylaBLEConnectionDescriptor
@end
