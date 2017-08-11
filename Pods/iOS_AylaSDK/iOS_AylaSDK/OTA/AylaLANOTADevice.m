//
//  iOS_AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaLANOTADevice.h"
#import "AylaLANOTAHTTPServer.h"
#import "AylaNetworks+Internal.h"
#import "AylaNetworks.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemUtils.h"
#import "NSData+Base64.h"
#import "NSObject+Ayla.h"

static NSUInteger const kOTAServerPort   = 8888;
static NSUInteger const kHeaderSize      = 256;
static NSString *const kOTAFileSeparator = @"--";

@interface AylaLANOTADevice ()<AylaLANOTAHTTPServerDelegate>

@property (nonatomic, strong) AylaLANOTAHTTPServer *lanOTAServer;

@property (nonatomic, weak) AylaSessionManager *sessionManager;

@property (nonatomic, strong) NSString *otaDirectory;

@end

@implementation AylaLANOTADevice

- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager DSN:(NSString *)dsn lanIP:(NSString *)lanIP
{
    AYLAssert(sessionManager, @"Session manager should not be nil");
    AYLAssert(dsn, @"DSN should not be nil");
    AYLAssert(lanIP, @"LAN IP should not be nil");

    self = [super init];
    if (self) {
        _sessionManager = sessionManager;
        _dsn = dsn;
        _lanIP = lanIP;
    }

    return self;
}

- (BOOL)isOTAImageAvailable
{
    NSString *filePath = [self getOTAFilePathIfExist];
    if (filePath != nil) {
        return YES;
    }
    return NO;
}

- (void)deleteOTAFile
{
    NSString *filePath = [self getOTAFilePathIfExist];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (NSString *)otaDirectory
{
    if (_otaDirectory == nil) {
        NSString *otaDir = [NSString
            stringWithFormat:@"%@/ota", [AylaSystemUtils deviceArchivesPathForSession:_sessionManager.sessionName]];
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:otaDir]) {
            NSError *error;
            [manager createDirectoryAtPath:otaDir withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
            }
        }
        _otaDirectory = otaDir;
    }

    return _otaDirectory;
}

- (NSString *)generateFileNameWithImageInfo:(AylaOTAImageInfo *)info
{
    // ota--AC000W000101362--module--1.0--768943.img
    NSString *fileName = [NSString stringWithFormat:@"ota%@%@%@%@%@%@%@%@.img",
                                                    kOTAFileSeparator,
                                                    self.dsn,
                                                    kOTAFileSeparator,
                                                    info.type,
                                                    kOTAFileSeparator,
                                                    info.version,
                                                    kOTAFileSeparator,
                                                    info.size];
    return [NSString stringWithFormat:@"%@/%@", self.otaDirectory, fileName];
}

/**
 * Get saved ota image file path.
 *
 * @return ota image file path. Return nil if no image file exist.
 */
- (NSString *)getOTAFilePathIfExist
{
    NSString *filePath = nil;

    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.otaDirectory error:NULL];
    for (NSString *fileName in directoryContent) {
        if ([fileName containsString:self.dsn]) {  // we only save ONE ota image file
            filePath = [NSString stringWithFormat:@"%@/%@", self.otaDirectory, fileName];
            break;
        }
    }

    return filePath;
}

- (nullable AylaHTTPTask *)fetchOTAImageInfoWithSuccess:(void (^)(AylaOTAImageInfo *otaInfo))successBlock
                                                failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"%@/lan_ota.json", self.dsn];
    AylaLogD(self.logTag, 0, @"path: %@", path);
    return [httpClient getPath:path
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaLogD(self.logTag, 0, @"%@", responseObject);
            AylaOTAImageInfo *otaInfo = [[AylaOTAImageInfo alloc] initWithJSONDictionary:responseObject error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(otaInfo);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogD(self.logTag, 0, @"%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (nullable AylaHTTPTask *)fetchOTAImageFile:(AylaOTAImageInfo *)imageInfo
                                    progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                     success:(void (^)(void))successBlock
                                     failure:(void (^)(NSError *_Nonnull))failureBlock
{
    AYLAssert(imageInfo, @"OTAImageInfo cannot be nil or emtpy!");
    AYLAssert(imageInfo.url, @"Image url cannot be nil or emtpy!");

    NSURL *fileURL = [[NSURL alloc] initWithString:imageInfo.url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    request.HTTPMethod = AylaHTTPRequestMethodGET;

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    if ([imageInfo.location isEqualToString:@"local"]) {  // No token needed for "s3"
        NSString *authToken = self.sessionManager.authorization.accessToken;
        [request setValue:[NSString stringWithFormat:@"auth_token %@", authToken] forHTTPHeaderField:@"Authorization"];
    }

    AylaHTTPTask *task = [httpClient taskWithDownloadRequest:request
        progress:downloadProgressBlock
        destination:^NSURL *_Nonnull(NSURL *_Nonnull url, NSURLResponse *_Nonnull response) {
            NSString *filePath = [self generateFileNameWithImageInfo:imageInfo];
            // delete the former exist file
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            return [NSURL fileURLWithPath:filePath];
        }
        success:^(AylaHTTPTask *_Nonnull task, NSURL *_Nonnull filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
            [self notifyStatus:YES reason:@"success"];
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];

    [task start];

    return task;
}

- (nullable AylaHTTPTask *)notifyStatus:(BOOL)status reason:(NSString *)reason
{
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        AylaLogE([self logTag], 0, @"notifyStatus.error:%@", error);
        return nil;
    }

    NSDictionary *params = @{ @"dsn" : self.dsn, @"status" : @(status), @"reason" : reason };
    return [httpClient putPath:[NSString stringWithFormat:@"lan_ota/dsn/%@.json", self.dsn]
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaLogI([self logTag], 0, @"Notify LAN OTA image download status success!");
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogI([self logTag], 0, @"Notify LAN OTA image download status fail!:%@", error);
        }];
}

- (nullable AylaHTTPTask *)pushOTAImageToDeviceWithSuccess:(void (^)(void))successBlock
                                                   failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if ([self isOTAImageAvailable] == NO) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaLanErrorDomain
                       code:AylaRequestErrorCodeInvalidArguments
                   userInfo:@{
                       AylaLanErrorResponseJsonKey : @{@"Image file" : AylaErrorDescriptionCanNotBeFound}
                   }];
        failureBlock(error);
        return nil;
    }

    // attempt to start the server with the specified documentRootPath
    if (self.lanOTAServer.isRunning == NO) {
        NSError *error = nil;
        [self.lanOTAServer start:&error];
        if (error) {
            failureBlock(error);
            return nil;
        }
    }

    void(^failBlock)(NSError *_Nonnull error) = ^void(NSError *_Nonnull error) {
        [self sendInitialSignalVersion0WithSuccess:successBlock failure:failureBlock];
    };
    
    return [self sendInitialSignalVersion1WithSuccess:successBlock failure:failBlock];
}

/**
 * Internal method to push OTA Image. Most of the devices are of version 1 and we will pass the
 * 256 bytes of header data(base64 encoded) in the JSON body.
 *
 */
- (nullable AylaHTTPTask *)sendInitialSignalVersion1WithSuccess:(void (^)(void))successBlock
                                                        failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSString *filePath = [self getOTAFilePathIfExist];
    AYLAssert(filePath, @"LAN OTA download file does not exist.");

    // ota--AC000W000101362--module--1.0--768943.img
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSArray *components = [fileName componentsSeparatedByString:kOTAFileSeparator];

    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSData *header = [handle readDataOfLength:kHeaderSize];
    [handle closeFile];

    NSDictionary *otaDict = @{
        @"url" : [NSString stringWithFormat:@"http://%@/%@", [AylaSystemUtils getLanIp], [filePath lastPathComponent]],
        @"type" : components[2],
        @"ver" : components[3],
        @"size" : @([components[4] integerValue]),
        @"port" : @(self.lanOTAServer.port),
        @"head" : [header base64EncodedString]
    };

    AylaHTTPClient *httpClient = [AylaHTTPClient apModeDeviceClientWithLanIp:self.lanIP usingHTTPS:NO];
    AylaHTTPTask *task = [httpClient putPath:@"lanota.json"
        parameters:otaDict
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
                if (self.delegate) {
                    [self.delegate lanOTADevice:self didUpdateImagePushStatus:ImagePushStatusInitial];
                }
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            [self.lanOTAServer stop];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    return task;
}

/**
 * Internal method to push OTA Image. Very few devices will be Version 0. We call this only
 * if version 1 fails. In version 0 the header bytes are appended to the JSON Body.
 */
- (nullable AylaHTTPTask *)sendInitialSignalVersion0WithSuccess:(void (^)(void))successBlock
                                                        failure:(void (^)(NSError *_Nonnull))failureBlock
{
    NSString *filePath = [self getOTAFilePathIfExist];
    AYLAssert(filePath, @"LAN OTA download file does not exist.");

    // ota--AC000W000101362--module--1.0--768943.img
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSArray *components = [fileName componentsSeparatedByString:kOTAFileSeparator];

    NSDictionary *otaDict = @{
        @"url" : [NSString stringWithFormat:@"http://%@/%@", [AylaSystemUtils getLanIp], [filePath lastPathComponent]],
        @"type" : components[2],
        @"ver" : components[3],
        @"size" : @([components[4] integerValue]),
        @"port" : @(self.lanOTAServer.port)
    };
    NSError *error;
    NSData *otaData = [NSJSONSerialization dataWithJSONObject:@{ @"ota" : otaDict } options:0 error:&error];
    NSString *jsonHeader = [[NSString alloc] initWithData:otaData encoding:NSUTF8StringEncoding];
    AylaLogD([self logTag], 0, @"otaJSON:%@", jsonHeader);
    NSMutableData *body = [NSMutableData dataWithData:[jsonHeader dataUsingEncoding:NSUTF8StringEncoding]];

    unsigned char zeroByte = 0;
    [body appendBytes:&zeroByte length:1];

    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSData *header = [handle readDataOfLength:kHeaderSize];
    [handle closeFile];
    [body appendData:header];

    AylaHTTPClient *httpClient = [AylaHTTPClient apModeDeviceClientWithLanIp:self.lanIP usingHTTPS:NO];
    NSURL *url = [NSURL URLWithString:@"lanota.json" relativeToURL:httpClient.baseURL];
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [request setHTTPMethod:AylaHTTPRequestMethodPUT];
    [request setHTTPBody:body];
    AylaHTTPTask *task = [httpClient taskWithRequest:request
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
                if (self.delegate) {
                    [self.delegate lanOTADevice:self didUpdateImagePushStatus:ImagePushStatusInitial];
                }
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            [self.lanOTAServer stop];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
    [task start];
    return task;
}

- (void)didReceiveImagePushStatus:(NSInteger)status
{
    AylaLogD([self logTag], 0, @"didReceiveImagePushStatus:%@", @(status));
    if (status == ImagePushStatusDone) {
        [self deleteOTAFile];
        [self.lanOTAServer stop];
    }
    if (self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate lanOTADevice:self didUpdateImagePushStatus:status];
        });
    }
}

- (AylaLANOTAHTTPServer *)lanOTAServer
{
    if (_lanOTAServer == nil) {
        _lanOTAServer = [AylaLANOTAHTTPServer new];
        _lanOTAServer.port = kOTAServerPort;
        _lanOTAServer.documentRoot = [[self getOTAFilePathIfExist] stringByDeletingLastPathComponent];
        _lanOTAServer.delegate = self;
    }

    return _lanOTAServer;
}

- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaHTTPClient *client = [self.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];

    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                            code:AylaRequestErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }

    return client;
}

- (NSString *)logTag
{
    return @"LANOTADevice";
}

@end
