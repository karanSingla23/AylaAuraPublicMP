//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "AylaConnectTask+Internal.h"
#import "AylaDefines_Internal.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPError.h"
#import "AylaHTTPTask+Internal.h"
#import "AylaSystemSettings.h"
#import "AylaSystemUtils.h"
#import "AFHTTPSessionManagerProfiler.h"

NSString *const AylaHTTPRequestMethodGET = @"GET";
NSString *const AylaHTTPRequestMethodPOST = @"POST";
NSString *const AylaHTTPRequestMethodPUT = @"PUT";
NSString *const AylaHTTPRequestMethodDELETE = @"DELETE";

NSString *const AylaHTTPClientTag = @"HTTPClient";

static NSString* AFSessionManagerClass = @"AFHTTPSessionManager";

/**
 * Helpful method to get JSON objects from a NSError which contains response from cloud
 */
static id getJsonResponseFromNSError(NSError *error)
{
    NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (data) {
        NSError *jsonError;
        id object =
            [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (!jsonError) {
            return object;
        }
        else {
            AylaLogV(@"AylaApiClient", 0, @"Json parsing error %@, origError %@", jsonError, error);
        }
    }
    return nil;
}

/**
 * Helpful method to create HTTP error from URL response and NSError
 */
static NSError *generateHTTPError(NSURLResponse *urlResponse, NSError *error)
{
    NSHTTPURLResponse *taskResp = (NSHTTPURLResponse *)urlResponse;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

    id jsonObject = getJsonResponseFromNSError(error);
    if (error) userInfo[AylaHTTPErrorOrignialErrorKey] = error;
    if (jsonObject) userInfo[AylaHTTPErrorResponseJsonKey] = jsonObject;
    if (taskResp) userInfo[AylaHTTPErrorHTTPResponseKey] = taskResp;

    NSInteger code = taskResp ? AylaHTTPErrorCodeInvalidResponse : AylaHTTPErrorCodeLostConnectivity;
    if (error.code == NSURLErrorCancelled) code = AylaHTTPErrorCodeCancelled;

    NSError *httpError = [AylaErrorUtils errorWithDomain:AylaHTTPErrorDomain code:code userInfo:userInfo];
    return httpError;
}

@interface AylaHTTPClient ()

@property AFHTTPSessionManager *afSessionManager;
@property (nonatomic, readwrite) BOOL invalidated;

@end

@interface AFHTTPSessionManager (Ayla_DataTaskMethods)
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;
@end

@implementation AylaHTTPClient
+ (void)enableNetworkProfiler {
    AFSessionManagerClass = NSStringFromClass([AFHTTPSessionManagerProfiler class]);
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl defaultNetworkTimeout:(NSTimeInterval)defaultNetworkTimeout
{
    AylaHTTPClient *client = [self initWithBaseUrl:baseUrl accessToken:nil];
    _afSessionManager.requestSerializer.timeoutInterval = defaultNetworkTimeout;
    return client;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl
{
    return [self initWithBaseUrl:baseUrl accessToken:nil];
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl accessToken:(NSString *)accessToken
{
    self = [super init];
    if (!self) return nil;

    Class afHTTPSessionManagerClass = NSClassFromString(AFSessionManagerClass);
    _afSessionManager = [[afHTTPSessionManagerClass alloc] initWithBaseURL:baseUrl sessionConfiguration:nil];
    _afSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self updateRequestHeaderWithAccessToken:accessToken];

    return self;
}

- (NSURL *)baseURL
{
    return self.afSessionManager.baseURL;
}

- (void)updateRequestHeaderWithAccessToken:(NSString *)accessToken
{
    if (self.currentRequestHeaders[@"Authorization"] != nil && accessToken == nil) {
        NSLog(@"sd");
    }
    [self.afSessionManager.requestSerializer setValue:accessToken?[NSString stringWithFormat:@"auth_token %@", accessToken] : nil
                                   forHTTPHeaderField:@"Authorization"];
}

- (NSDictionary *)currentRequestHeaders
{
    return self.afSessionManager.requestSerializer.HTTPRequestHeaders;
}

- (void)updateRequestHeaders:(NSDictionary *)headers
{
    // Update headers iteratively.
    for (NSString *headerKey in headers.allKeys) {
        [self.afSessionManager.requestSerializer setValue:headers[headerKey] forHTTPHeaderField:headerKey];
    }
}

- (AylaHTTPTask *)getPath:(NSString *)path
               parameters:(NSDictionary *)parameters
                  success:(void (^)(AylaHTTPTask *, id))successBlock
                  failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    AylaHTTPTask *task = [self taskWithMethod:AylaHTTPRequestMethodGET
                                         path:path
                                   parameters:parameters
                                      success:successBlock
                                      failure:failureBlock];
    [task start];
    return task;
}

- (AylaHTTPTask *)postPath:(NSString *)path
                parameters:(NSDictionary *)parameters
                   success:(void (^)(AylaHTTPTask *, id))successBlock
                   failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    AylaHTTPTask *task = [self taskWithMethod:AylaHTTPRequestMethodPOST
                                         path:path
                                   parameters:parameters
                                      success:successBlock
                                      failure:failureBlock];
    [task start];
    return task;
}

- (AylaHTTPTask *)putPath:(NSString *)path
               parameters:(NSDictionary *)parameters
                  success:(void (^)(AylaHTTPTask *, id))successBlock
                  failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    AylaHTTPTask *task = [self taskWithMethod:AylaHTTPRequestMethodPUT
                                         path:path
                                   parameters:parameters
                                      success:successBlock
                                      failure:failureBlock];
    [task start];
    return task;
}

- (AylaHTTPTask *)deletePath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                     success:(void (^)(AylaHTTPTask *, id))successBlock
                     failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    AylaHTTPTask *task = [self taskWithMethod:AylaHTTPRequestMethodDELETE
                                         path:path
                                   parameters:parameters
                                      success:successBlock
                                      failure:failureBlock];
    [task start];
    return task;
}

- (AylaHTTPTask *)taskWithGET:(NSString *)path
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(AylaHTTPTask *, id))successBlock
                      failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    return [self taskWithMethod:AylaHTTPRequestMethodGET
                           path:path
                     parameters:parameters
                        success:successBlock
                        failure:failureBlock];
}

- (AylaHTTPTask *)taskWithPOST:(NSString *)path
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(AylaHTTPTask *, id))successBlock
                       failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    return [self taskWithMethod:AylaHTTPRequestMethodPOST
                           path:path
                     parameters:parameters
                        success:successBlock
                        failure:failureBlock];
}

- (AylaHTTPTask *)taskWithPUT:(NSString *)path
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(AylaHTTPTask *, id))successBlock
                      failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    return [self taskWithMethod:AylaHTTPRequestMethodPUT
                           path:path
                     parameters:parameters
                        success:successBlock
                        failure:failureBlock];
}

- (AylaHTTPTask *)taskWithDELETE:(NSString *)path
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AylaHTTPTask *, id))successBlock
                         failure:(void (^)(AylaHTTPTask *, NSError *))failureBlock
{
    return [self taskWithMethod:AylaHTTPRequestMethodDELETE
                           path:path
                     parameters:parameters
                        success:successBlock
                        failure:failureBlock];
}

/**
 * Use this method to create a HTTP task
 */
- (AylaHTTPTask *)taskWithMethod:(NSString *)method
                            path:(NSString *)path
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                         failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    __block AylaHTTPTask *httpTask = [[AylaHTTPTask alloc] init];
    NSURLSessionDataTask *task = [self.afSessionManager dataTaskWithHTTPMethod:method
        URLString:path
        parameters:parameters
        uploadProgress:nil
        downloadProgress:nil
        success:^(NSURLSessionDataTask *task, id responseObject) {
            httpTask.responseObject = responseObject;
            [self processResponseWithTask:httpTask
                                 response:task.response
                           responseObject:responseObject
                                    error:nil
                                  success:successBlock
                                  failure:failureBlock];
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            [self processResponseWithTask:httpTask
                                 response:task.response
                           responseObject:nil
                                    error:error
                                  success:successBlock
                                  failure:failureBlock];
        }];
    httpTask.task = task;
    return httpTask;
}

/**
 * Use this method to create an upload request
 */
- (AylaHTTPTask *)taskWithUploadRequest:(NSURLRequest *)request
                               fromData:(NSData *)bodyData
                               progress:(void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    __block AylaHTTPTask *httpTask = [[AylaHTTPTask alloc] init];
    NSURLSessionTask *task =
        [self.afSessionManager uploadTaskWithRequest:request
                                            fromData:bodyData
                                            progress:uploadProgressBlock
                                   completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                       [self processResponseWithTask:httpTask
                                                            response:response
                                                      responseObject:responseObject
                                                               error:error
                                                             success:successBlock
                                                             failure:failureBlock];
                                   }];
    httpTask.task = task;
    return httpTask;
}

/**
 * Use this method to create an upload request
 */
- (AylaHTTPTask *)taskWithUploadRequest:(NSURLRequest *)request
                               fromFile:(NSURL *)fileURL
                               progress:(void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    __block AylaHTTPTask *httpTask = [[AylaHTTPTask alloc] init];
    NSURLSessionTask *task =
        [self.afSessionManager uploadTaskWithRequest:request
                                            fromFile:fileURL
                                            progress:uploadProgressBlock
                                   completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                       [self processResponseWithTask:httpTask
                                                            response:response
                                                      responseObject:responseObject
                                                               error:error
                                                             success:successBlock
                                                             failure:failureBlock];
                                   }];
    httpTask.task = task;
    return httpTask;
}

/**
 * Use this method to create a streamed upload request
 */
- (AylaHTTPTask *)taskWithStreamedUploadRequest:(NSURLRequest *)request
                                       progress:(void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                        success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                        failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    __block AylaHTTPTask *httpTask = [[AylaHTTPTask alloc] init];
    NSURLSessionTask *task = [self.afSessionManager
        uploadTaskWithStreamedRequest:request
                             progress:uploadProgressBlock
                    completionHandler:^(
                        NSURLResponse *__nonnull response, id __nullable responseObject, NSError *__nullable error) {
                        [self processResponseWithTask:httpTask
                                             response:response
                                       responseObject:responseObject
                                                error:error
                                              success:successBlock
                                              failure:failureBlock];
                    }];
    httpTask.task = task;
    return httpTask;
}

/**
 * Use this method to create a download request
 */
- (AylaHTTPTask *)taskWithDownloadRequest:(NSURLRequest *)request
                                 progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                              destination:(NSURL *__nonnull (^)(NSURL *__nonnull, NSURLResponse *__nonnull))destination
                                  success:(void (^)(AylaHTTPTask *task, NSURL *filePath))successBlock
                                  failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    __block AylaHTTPTask *httpTask = [[AylaHTTPTask alloc] init];
    NSURLSessionTask *task = [self.afSessionManager
        downloadTaskWithRequest:request
                       progress:downloadProgressBlock
                    destination:destination
              completionHandler:^(
                  NSURLResponse *__nonnull response, NSURL *__nullable filePath, NSError *__nullable error) {
                  [self processResponseWithTask:httpTask
                                       response:response
                                 responseObject:filePath
                                          error:error
                                        success:successBlock
                                        failure:failureBlock];
              }];
    httpTask.task = task;
    return httpTask;
}

- (AylaHTTPTask *)taskWithUploadRequest:(NSURLRequest *)request
                               fromData:(NSData *)bodyData
                                success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    return
        [self taskWithUploadRequest:request fromData:bodyData progress:nil success:successBlock failure:failureBlock];
}

- (AylaHTTPTask *)taskWithStreamedUploadRequest:(NSURLRequest *)request
                                        success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                        failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    return [self taskWithStreamedUploadRequest:request progress:nil success:successBlock failure:failureBlock];
}

- (AylaHTTPTask *)taskWithDownloadRequest:(NSURLRequest *)request
                              destination:(NSURL *__nonnull (^)(NSURL *__nonnull targetPath,
                                                                NSURLResponse *response))destination
                                  success:(void (^)(AylaHTTPTask *task, NSURL *filePath))successBlock
                                  failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    return [self taskWithDownloadRequest:request
                                progress:nil
                             destination:destination
                                 success:successBlock
                                 failure:failureBlock];
}

- (AylaHTTPTask *)taskWithRequest:(NSURLRequest *)request
                          success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                          failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    __block AylaHTTPTask *httpTask = [[AylaHTTPTask alloc] init];
    NSURLSessionDataTask *task =
        [self.afSessionManager dataTaskWithRequest:request
                                 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                     [self processResponseWithTask:httpTask
                                                          response:response
                                                    responseObject:responseObject
                                                             error:error
                                                           success:successBlock
                                                           failure:failureBlock];
                                 }];
    httpTask.task = task;
    return httpTask;
}

/**
 * A helpful method to handle cloud response
 */
- (void)processResponseWithTask:(AylaHTTPTask *)httpTask
                       response:(NSURLResponse *)response
                 responseObject:(id)responseObject
                          error:(NSError *)error
                        success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                        failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock
{
    [httpTask setFinished:YES];
    if (!error) {
        httpTask.responseObject = responseObject;
        successBlock(httpTask, responseObject);
    }
    else {
        NSError *httpError = generateHTTPError(response, error);
        httpTask.responseObject = httpError.userInfo[AylaHTTPErrorResponseJsonKey];
        failureBlock(httpTask, httpError);
    }
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSError *error;

    NSMutableURLRequest *urlRequest = [self.afSessionManager.requestSerializer
        requestWithMethod:method
                URLString:[NSString
                              stringWithFormat:@"%@%@", self.afSessionManager.baseURL.absoluteString ?: @"", path, nil]
               parameters:parameters
                    error:&error];

    if (error) {
        AylaLogE([AylaHTTPClient logTag], 0, @"%@, %@", error, @"requestWithMethod");
    }

    return urlRequest;
}

- (void)invalidateAndCancelTasks:(BOOL)cancelPendingTasks
{
    self.invalidated = YES;
    [self.afSessionManager invalidateSessionCancelingTasks:cancelPendingTasks];
}

+ (instancetype)deviceServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils deviceServiceBaseUrl:settings isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:settings.defaultNetworkTimeout];
}

+ (instancetype)userServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils userServiceBaseUrl:settings isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:settings.defaultNetworkTimeout];
}

+ (instancetype)logServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils logServiceBaseUrl:settings isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:settings.defaultNetworkTimeout];
}

+ (instancetype)streamServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils streamServiceBaseUrl:settings isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:settings.defaultNetworkTimeout];
}

+ (instancetype)mdssSubscriptionServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils streamServiceBaseUrl:settings isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:settings.defaultNetworkTimeout];
}

+ (instancetype)apModeDeviceClientWithLanIp:(NSString *)lanIp usingHTTPS:(BOOL)usingHTTPS
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils deviceBaseUrlWithLanIp:lanIp isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url];
}

+ (instancetype)serviceClientWithBaseUrl:(NSString *)baseURL
                       andSystemSettings:(AylaSystemSettings *)settings
                              usingHTTPS:(BOOL)usingHTTPS
                      withDefaultTimeout:(NSTimeInterval)timeout
{
    NSURL *url = [[NSURL alloc] initWithString:[AylaSystemUtils serviceBaseUrl:baseURL serviceLocation:settings.serviceLocation isSecure:usingHTTPS]];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:timeout];
}

+ (instancetype)serviceClientWithUrl:(NSString *)serviceUrl
                  withDefaultTimeout:(NSTimeInterval)timeout
{
    NSURL *url = [[NSURL alloc] initWithString:serviceUrl];
    return [[self alloc] initWithBaseUrl:url defaultNetworkTimeout:timeout];
}

- (dispatch_queue_t)completionQueue
{
    return self.afSessionManager.completionQueue;
}

- (void)setCompletionQueue:(dispatch_queue_t)completionQueue
{
    self.afSessionManager.completionQueue = completionQueue;
}

- (void)dealloc
{
    // If this http client has never invalidated, call invalidate api once.
    if (!self.invalidated) {
        [self.afSessionManager invalidateSessionCancelingTasks:YES];
    }
}

+ (NSString *)logTag
{
    return AylaHTTPClientTag;
}

@end
