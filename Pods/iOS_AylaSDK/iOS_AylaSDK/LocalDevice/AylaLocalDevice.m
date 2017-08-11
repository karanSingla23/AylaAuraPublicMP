//
//  AylaLocalDevice.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLocalDevice.h"
#import "AylaLocalProperty.h"
#import "AylaLocalDeviceManager.h"
#import "NSObject+Ayla.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceCommand.h"
#import "AylaObject+Internal.h"
#import "AylaLocalOTACommand.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const attrNameHardwareAddress = @"unique_hardware_id";
NSString const * OTATypeHostMCU = @"host_mcu";

@interface AylaLocalDevice ()

/**
 * Sets the status of a device command. This method should be called after a device command
 * (OTA update, for example) has completed. The command ID can be found in the processed
 * command, and the status should reflect an HTTP status (e.g. 200 for success).
 * @param commandId ID of the command that was processed
 * @param status HTTP status for the result of the command operation
 * @param success Listener called if the operation is successful
 * @param failure Listener called if the operation failed
 * @return the `AylaHTTPTask`, which may be used to cancel the operation
 */
- (nullable AylaHTTPTask *)ackCommandId:(NSInteger)commandId status:(NSInteger)status success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failure;

@property (strong, nonatomic) AylaHTTPTask *otaTask;
@end

@implementation AylaLocalDevice
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError * _Nullable __autoreleasing *)error {
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        _hardwareAddress = [dictionary[attrNameHardwareAddress] nilIfNull];
    }
    return self;
}

- (AylaGenericTask *)connectLocalWithSuccess:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return nil;
}

- (AylaGenericTask *)setValue:(id)value forProperty:(AylaLocalProperty *)property success:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return nil;
}

- (id)valueForProperty:(AylaLocalProperty *)property {
    return property.originalProperty.value;
}

- (AylaGenericTask *)disconnectLocalWithSuccess:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return nil;
}

- (BOOL)lanModePermitted {
    return NO;
}

- (NSString *)lanIp {
    return nil;
}

- (NSString *)ssid {
    return nil;
}

- (AylaRegistrationType)registrationType {
    return  AylaRegistrationTypeLocal;
}

- (AylaConnectTask *)fetchProperties:(NSArray<NSString *> *)propertyNames success:(void (^)(NSArray<AylaProperty *> * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [super fetchPropertiesCloud:propertyNames success:successBlock failure:failureBlock];
}

- (NSArray AYLA_GENERIC(AylaPropertyChange *) *)updateProperties: (NSArray *)properties {
    NSMutableArray <AylaLocalProperty *> *localProperties = [NSMutableArray array];
    for (AylaProperty *property in properties) {
        AylaLocalProperty *localProperty = [[AylaLocalProperty alloc]initWithDevice:self originalProperty:property name:property.name displayName:property.displayName readOnly:NO baseType:property.baseType];
        localProperty.datapoint = property.datapoint;
        [localProperty updateFrom:property dataSource:AylaDataSourceCloud];
        [localProperties addObject:localProperty];
        property.device = self;
    }
    return [super updateProperties:localProperties];
}

- (AylaConnectTask *)fetchPropertiesLAN:(NSArray<NSString *> *)propertyNames success:(void (^)(NSArray<AylaProperty *> * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self fetchProperties:propertyNames success:successBlock failure:failureBlock];
}

- (AylaConnectTask *)fetchPropertiesCloud:(NSArray *)propertyNames success:(void (^)(NSArray<AylaProperty *> * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self fetchProperties:propertyNames success:successBlock failure:failureBlock];
}

- (AylaConnectTask *)unregisterWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    if (self.isConnectedLocal) {
        [self disconnectLocalWithSuccess:^{ } failure:^(NSError * _Nonnull error) { }];
    }
    return [super unregisterWithSuccess:successBlock failure:failureBlock];
}
- (BOOL)requiresLocalConfiguration {
    return NO;
}

- (void)checkQueuedCommands {
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        AylaLogE([self logTag], 0, @"%@", @"Failed to get httpClient");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"dsns/%@/cmds.json", self.dsn];
    [httpClient getPath:path
             parameters:nil
                success:^(AylaHTTPTask *_Nonnull task, NSDictionary * _Nullable commandArray) {
                    AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                             NSStringFromSelector(_cmd));
                    NSMutableArray *commands = [NSMutableArray array];
                    for (NSDictionary *jsonCommand in commandArray) {
                        AylaDeviceCommand *command = [[AylaDeviceCommand alloc] initWithJSONDictionary:jsonCommand[@"cmd"] error:nil];
                        [commands addObject:command];
                    }
                    [self processCommands:commands];
                }
                failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                    AylaLogE([self logTag], 0, @"Error tryin to fech ommands:%@, %@", error,
                             NSStringFromSelector(_cmd));
                }];

}

- (void)processCommands:(NSArray <AylaDeviceCommand *> *)commands {
    AylaLogI([self logTag], 0, @"Processing commands");
    for (AylaDeviceCommand *command in commands) {
        AylaLogD([self logTag], 0, @"Command: %@: %@", command.type, command.data);
        if ([command.type compare:CMD_OTA] == NSOrderedSame) {
            AylaLocalOTACommand *otaCommand = [command getCommand];
            [self processOTA:otaCommand];
        }
    }
}

- (void)processOTA:(AylaLocalOTACommand *)command {
    if (self.otaTask != nil) {
        AylaLogE([self logTag], 0, @"processOTA called while OTA is in progress!");
        return;
    }
    
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        AylaLogE([self logTag], 0, @"%@", @"Failed to get httpClient");
        return;
    }
    
    AylaDeviceManager *deviceManager = self.deviceManager;
    if (deviceManager == nil) {
        AylaLogE([self logTag], 0, @"No device manager present for OTA fetch!");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *fileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-ota.bin",self.dsn]];
    
    NSURL *fileURL = [[NSURL alloc] initWithString:command.apiUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    request.HTTPMethod = AylaHTTPRequestMethodGET;
    request.allHTTPHeaderFields = httpClient.currentRequestHeaders;

    
    self.otaTask = [httpClient taskWithDownloadRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        AylaLogI([self logTag], 0, @"LAN OTA Image Download progress: %@", downloadProgress);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull url, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:fileName];
    } success:^(AylaHTTPTask * _Nonnull task, NSURL * _Nonnull filePath) {
        self.otaTask = nil;
        AylaLogI([self logTag], 0, @"Finished downloading OTA: %@", filePath);
        if ([self verifyChecksum:command.checksum filePath:filePath]) {
            AylaLogI([self logTag], 0, @"Checksum succceeded");
            [self otaReceived:command filePath:filePath];
        } else {
            AylaLogE([self logTag], 0, @"Checksum verification failed, bailing");
            NSError *error = nil;
            if ([[NSFileManager defaultManager]removeItemAtURL:filePath error:&error]) {
                AylaLogI([self logTag], 0, @"OTA Image deleted");
            } else {
                AylaLogE([self logTag], 0, @"Failed to remove file at path: %@", filePath);
            }
            
        }
    } failure:^(AylaHTTPTask * _Nonnull task, NSError * _Nonnull error) {
        self.otaTask = nil;
        
        AylaLogI([self logTag], 0, @"Failed downloading OTA: %@", error);
    }];
    [self.otaTask start];
}

- (BOOL)verifyChecksum:(NSString *)checksum filePath:(NSURL *)filePath {
    const NSInteger chunkSize = 128 *  1024;
    if (filePath == nil || checksum == nil) {
        return nil;
    }
    if (checksum.length != 32) {
        return false;
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath.path];
    if (handle == nil) {
        return false;
    }
    
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    
    BOOL done = NO;
    while (!done) {
        @autoreleasepool {
            NSData *data = [handle readDataOfLength:chunkSize];
            CC_MD5_Update(&md5, data.bytes, (CC_LONG)data.length);
            if (data.length == 0) {
                done = YES;
            }
        }
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x",digest[i]];
    }
    
    return [hash isEqualToString:checksum];
}

- (AylaHTTPTask *)setOTAStatus:(NSInteger)status commandId:(NSInteger)commandId success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    NSInteger httpStatus = 200;
    if (status != 0) {
        httpStatus = 400;
    }
    
    return [self updateOTAStatus:status type:OTATypeHostMCU success:^{
        
        AylaLogI([self logTag], 0, @"OTA status updated successfully");
        [self ackCommandId:commandId status:httpStatus success:^{
            AylaLogI([self logTag], 0, @"OTA ack sent successfully");
            successBlock();
        } failure:^(NSError * _Nonnull error) {
            
            AylaLogE([self logTag], 0, @"Error trying to update OTA Status: %@", error);
            failureBlock(error);
        }];
    } failure:^(NSError * _Nonnull error) {
        AylaLogE([self logTag], 0, @"Error trying to ack OTA command: \(String(describing:error))");
        failureBlock(error);
    }];
    
}

- (AylaHTTPTask *)ackCommandId:(NSInteger)commandId status:(NSInteger)status success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failure {
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        AylaLogE([self logTag], 0, @"%@", @"Failed to get httpClient");
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"dsns/%@/cmds/%ld/ack.json", self.dsn, commandId];
    NSDictionary *params = @{ @"status": @(status) };
    return [httpClient putPath:path parameters:params success:^(AylaHTTPTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock();
        });
    } failure:^(AylaHTTPTask * _Nonnull task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
    }];
}

- (AylaHTTPTask *)updateOTAStatus:(NSInteger)status type:(const NSString *)otaType success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failure {
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        AylaLogE([self logTag], 0, @"%@", @"Failed to get httpClient");
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"dsns/%@/ota_status.json", self.dsn];
    NSDictionary *params = @{
                             @"type": otaType,
                             @"status": @(status)
                             };
    return [httpClient putPath:path parameters:params success:^(AylaHTTPTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock();
        });
    } failure:^(AylaHTTPTask * _Nonnull task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
    }];
}

- (void)otaReceived:(AylaLocalOTACommand *)otaCommand filePath:(NSURL *)filePath {
    AylaLogE([self logTag], 0, @"This method must be overriden in subclass");
    NSAssert(NO, @"This method must be overriden in subclass");
}

- (NSString *)logTag {
    return [NSString stringWithFormat:@"LD: %@", self.dsn];
}
@end
