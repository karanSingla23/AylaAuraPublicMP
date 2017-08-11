//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint+Internal.h"
#import "AylaDatapointBlob.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"

static NSString *const attrNameLocation = @"location";
static NSString *const attrNameFile = @"file";
static NSString *const attrNameClosed = @"closed";
static NSString *const attrNameValue = @"value";
static NSString *const attrNameDatapoint = @"datapoint";

@interface AylaDatapointBlob ()

@property (nonatomic, assign) BOOL closed;
@end

@implementation AylaDatapointBlob
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                            dataSource:(AylaDataSource)dataSource
                                 error:(NSError *__autoreleasing _Nullable *_Nullable)error
{
    if (self = [super initWithJSONDictionary:dictionary dataSource:dataSource error:error]) {
        _fileURL = [NSURL URLWithString:dictionary[attrNameFile]];
        _closed = [dictionary[attrNameClosed] boolValue];
        // check if dictionary returned by cloud contains blob location in attrNameLocation key, when a new blob is
        // created it can be present in attrNameValue instead.
        NSString *location = dictionary[attrNameLocation] ?: dictionary[attrNameValue];
        _location = [NSURL URLWithString:location];
    }
    return self;
}

- (AylaHTTPTask *)uploadBlobWithProgress:(void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                 success:(void (^)())successBlock
                                 failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!self.fileURL) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(fileURL)) : AylaErrorDescriptionIsInvalid}
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"init"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSNumber *fileSize = nil;
    NSInputStream *inputStream = nil;

    AylaHTTPClient *httpClient = [[AylaHTTPClient alloc] initWithBaseUrl:self.fileURL.baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.fileURL];
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

    void (^sharedSuccessBlock)(AylaHTTPTask *_Nonnull task, id _Nonnull responseObject) =
        ^(AylaHTTPTask *_Nonnull task, id _Nonnull responseObject) {
            [self markAsCompleteWithSuccess:^{
                dispatch_async(dispatch_get_main_queue(), successBlock);
            }
                failureBlock:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failureBlock(error);
                    });
                }];
        };

    void (^sharedFailureBlock)(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) =
        ^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        };

    if (self.blobData) {
        AylaHTTPTask *task = [httpClient taskWithUploadRequest:request
                                                      fromData:self.blobData
                                                      progress:uploadProgressBlock
                                                       success:sharedSuccessBlock
                                                       failure:sharedFailureBlock];
        [task start];
        return task;
    }
    else if (self.localFileURL) {
        NSError *fileError;
        [self.localFileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&fileError];

        inputStream = [NSInputStream inputStreamWithURL:self.localFileURL];
        if (fileError || !inputStream) {
            NSError *error = [AylaErrorUtils
                 errorWithDomain:AylaRequestErrorDomain
                            code:AylaRequestErrorCodeInvalidArguments
                        userInfo:@{
                            AylaRequestErrorResponseJsonKey :
                                @{NSStringFromSelector(@selector(localFileURL)) : AylaErrorDescriptionIsInvalid}
                        }
                       shouldLog:YES
                          logTag:[self logTag]
                addOnDescription:@"init"];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return nil;
        }

        // Setup header fields
        [request setValue:fileSize.stringValue forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBodyStream:inputStream];

        AylaHTTPTask *task = [httpClient taskWithUploadRequest:request
                                                      fromFile:self.localFileURL
                                                      progress:uploadProgressBlock
                                                       success:sharedSuccessBlock
                                                       failure:sharedFailureBlock];
        [task start];
        return task;
    }

    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodeInvalidArguments
                               userInfo:@{
                                   AylaRequestErrorResponseJsonKey :
                                       @{NSStringFromSelector(@selector(localFileURL)) : AylaErrorDescriptionIsInvalid}
                               }
                              shouldLog:YES
                                 logTag:[self logTag]
                       addOnDescription:@"init"];
    dispatch_async(dispatch_get_main_queue(), ^{
        failureBlock(error);
    });
    return nil;
}

- (AylaHTTPTask *)markAsCompleteWithSuccess:(void (^)())successBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    AylaProperty *property = self.property;
    if (!property) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(property)) : AylaErrorDescriptionIsInvalid}
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"init"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSError *error = nil;
    AylaHTTPClient *client = [property getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *apiPath = self.location.path;
    NSMutableArray *pathComponents = [[apiPath pathComponents] mutableCopy];
    if (pathComponents.count > 2) {
        [pathComponents removeObjectsInRange:NSMakeRange(0, 2)];
    }
    apiPath = [NSString pathWithComponents:pathComponents];

    return [client putPath:apiPath
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            self.closed = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)fetchLocationWithSuccess:(void (^)(AylaDatapointBlob *datapoint))successBlock
                                   failure:(void (^)(NSError *_Nonnull))failureBlock
{
    AylaProperty *property = self.property;
    if (!property) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(property)) : AylaErrorDescriptionIsInvalid}
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"init"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    NSError *error = nil;
    AylaHTTPClient *client = [property getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    if (!self.location) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(fileURL)) : AylaErrorDescriptionIsInvalid}
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"init"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *apiPath = self.location.path;
    NSMutableArray *pathComponents = [[apiPath pathComponents] mutableCopy];
    if (pathComponents.count > 2) {
        [pathComponents removeObjectsInRange:NSMakeRange(0, 2)];
    }
    apiPath = [NSString pathWithComponents:pathComponents];

    return [client getPath:apiPath
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSDictionary *datapointDictionary = responseObject[attrNameDatapoint];
            AylaDatapointBlob *blob = [[AylaDatapointBlob alloc] initWithJSONDictionary:datapointDictionary
                                                                             dataSource:AylaDataSourceCloud
                                                                                  error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(blob);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)downloadToFile:(NSURL *)filePath
                        progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         success:(void (^)(NSURL *filePath))successBlock
                         failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!self.fileURL) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey :
                                           @{NSStringFromSelector(@selector(fileURL)) : AylaErrorDescriptionIsInvalid}
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"init"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [self fetchLocationWithSuccess:^(AylaDatapointBlob *datapoint) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:datapoint.fileURL];
        request.HTTPMethod = @"GET";

        AylaHTTPClient *httpClient = [[AylaHTTPClient alloc] initWithBaseUrl:datapoint.fileURL.baseURL];
        AylaHTTPTask *task = [httpClient taskWithDownloadRequest:request
            progress:downloadProgressBlock
            destination:^NSURL *_Nonnull(NSURL *_Nonnull url, NSURLResponse *_Nonnull response) {
                return filePath;
            }
            success:^(AylaHTTPTask *_Nonnull task, NSURL *_Nonnull filePath) {
                [self markAsFetchedWithFilePath:filePath success:successBlock failure:failureBlock];
            }
            failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
            }];

        [task start];
    }
                                  failure:failureBlock];
}


/**
 After the Blob download is successful mark a stream data point operation as fetched on the device service
 */
- (AylaHTTPTask *)markAsFetchedWithFilePath:(NSURL *)filePath
                                    success:(void (^)(NSURL *filePath))successBlock
                                    failure:(void (^)(NSError *error))failureBlock
{
    AylaProperty *property = self.property;
    if (!property) {
        NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodeInvalidArguments
                               userInfo:@{
                                          AylaRequestErrorResponseJsonKey :
                                              @{NSStringFromSelector(@selector(property)) : AylaErrorDescriptionIsInvalid}
                                          }
                              shouldLog:YES
                                 logTag:[self logTag]
                       addOnDescription:@"init"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    NSError *error = nil;
    AylaHTTPClient *client = [property getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    NSString *apiPath = self.location.path;
    NSMutableArray *pathComponents = [[apiPath pathComponents] mutableCopy];
    if (pathComponents.count > 2) {
        [pathComponents removeObjectsInRange:NSMakeRange(0, 2)];
    }
    apiPath = [NSString pathWithComponents:pathComponents];
    if (!apiPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    
    NSDictionary *fetchedDict = @{@"fetched": @"true"};
    return [client putPath:apiPath
        parameters:@{@"datapoint" : fetchedDict}
        success:^(AylaHTTPTask * _Nonnull task, id  _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(filePath);
            });
        }
        failure:^(AylaHTTPTask * _Nonnull task, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
    }];
}

- (NSString *)logTag
{
    return NSStringFromClass([AylaDatapoint class]);
}
@end
