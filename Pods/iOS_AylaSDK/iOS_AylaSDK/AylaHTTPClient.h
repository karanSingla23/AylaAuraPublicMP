//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const AylaHTTPRequestMethodGET;     // HTTP request method `GET`
FOUNDATION_EXPORT NSString *const AylaHTTPRequestMethodPOST;    // HTTP request method `POST`
FOUNDATION_EXPORT NSString *const AylaHTTPRequestMethodPUT;     // HTTP request method `PUT`
FOUNDATION_EXPORT NSString *const AylaHTTPRequestMethodDELETE;  // HTTP request method `DELETE`;

FOUNDATION_EXPORT NSString *const AylaHTTPClientTag;  // Tag of HTTP client

@class AylaHTTPTask;
@class AylaSystemSettings;

/**
 * Ayla HTTP Client eatablish and maintain HTTP(S) session to a service which sepecified by its baseUrl.
 */
@interface AylaHTTPClient : NSObject

/** The given base url during initialization. */
@property (nonatomic, strong, readonly, nullable) NSURL *baseURL;

/**
 The dispatch queue for `successBlock`, `failureBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;

/** If current http client has been invalidated or not */
@property (nonatomic, assign, readonly) BOOL invalidated;

/**
 * Init method with base url as input.
 * @param baseUrl the base URL for all requests
 */
- (instancetype)initWithBaseUrl:(nullable NSURL *)baseUrl;

/**
 * Init method with base url and access token as input.
 * @param baseUrl the base URL for all requests
 * @param accessToken initializes the instance with an accessToken for authorization
 *
 * @note accessToken must be the token fetched from Cloud service
 */
- (instancetype)initWithBaseUrl:(nullable NSURL *)baseUrl accessToken:(nullable NSString *)accessToken;

/**
 * Init method with base url and default timeout as input.
 * @param baseUrl the base URL for all requests
 * @param defaultNetworkTimeout specifies the default timeout for network requests
 */
- (instancetype)initWithBaseUrl:(NSURL *)baseUrl defaultNetworkTimeout:(NSTimeInterval)defaultNetworkTimeout;

/**
 * Return current in-use headers
 */
- (NSDictionary *)currentRequestHeaders;

/**
 * Update authorization header with access token
 * @param accessToken new accessToken for authorization
 */
- (void)updateRequestHeaderWithAccessToken:(NSString *)accessToken;

/**
 * Update headers through a NSDictionary object.
 * @param headers Speifies the HTTP Headers the request should include
 */
- (void)updateRequestHeaders:(NSDictionary *)headers;


/**
 * Use this method to send a GET request to service. This request will be processed immediately.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */
- (AylaHTTPTask *)getPath:(NSString *)path
               parameters:(nullable NSDictionary *)parameters
                  success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                  failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to send a POST request to service. This request will be processed immediately.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure. 
 *
 * @return A started `AylaHTTPTask`
 */
- (AylaHTTPTask *)postPath:(NSString *)path
                parameters:(nullable NSDictionary *)parameters
                   success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                   failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to send a PUT request to service. This request will be processed immediately.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */
- (AylaHTTPTask *)putPath:(NSString *)path
               parameters:(nullable NSDictionary *)parameters
                  success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                  failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to send a DELETE request to service. This request will be processed immediately.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return A started `AylaHTTPTask`
 */
- (AylaHTTPTask *)deletePath:(NSString *)path
                  parameters:(nullable NSDictionary *)parameters
                     success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                     failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for the pass-in GET request.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithGET:(NSString *)path
                   parameters:(nullable NSDictionary *)parameters
                      success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                      failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for the pass-in POST request.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithPOST:(NSString *)path
                    parameters:(nullable NSDictionary *)parameters
                       success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                       failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for the pass-in PUT request.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithPUT:(NSString *)path
                   parameters:(nullable NSDictionary *)parameters
                      success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                      failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for the pass-in DELETE request.
 *
 * @param path         path to the wanted resource
 * @param parameters   call params to include in the request
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithDELETE:(NSString *)path
                      parameters:(nullable NSDictionary *)parameters
                         success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                         failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object with a NSURLRequest instance.
 *
 * @param request      The HTTP request for the request.
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithRequest:(NSURLRequest *)request
                          success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                          failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for an upload request.
 *
 * @param request      Upload request
 * @param bodyData     Data of the request body
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 * */
- (AylaHTTPTask *)taskWithUploadRequest:(NSURLRequest *)request
                               fromData:(NSData *)bodyData
                                success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                                failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for an upload request with progress block.
 *
 * @param request      Upload request
 * @param bodyData     Data to upload
 * @param uploadProgressBlock A block called with upload updates. Passed a NSProgress object for the update.
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithUploadRequest:(NSURLRequest *)request
                               fromData:(NSData *)bodyData
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for an upload request from a file with progress block.
 *
 * @param request      Upload request
 * @param fileURL      File to upload
 * @param uploadProgressBlock A block object to be executed when the download progress is updated. Note this block is called on the session queue, not the main queue.
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithUploadRequest:(NSURLRequest *)request
                               fromFile:(NSURL *)fileURL
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                success:(void (^)(AylaHTTPTask *task, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for a stream upload request.
 *
 * @param request      request to upload stream.
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithStreamedUploadRequest:(NSURLRequest *)request
                                        success:(void (^)(AylaHTTPTask *task, id _Nullable responseObject))successBlock
                                        failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for a download request.
 *
 * @param request      request to upload stream.
 * @param destination  A block object to be executed in order to determine the destination of the downloaded file. This block takes two arguments, the target path & the server response, and returns the desired file URL of the resulting download. The temporary file used during the download will be automatically deleted after being moved to the returned URL.
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithDownloadRequest:(NSURLRequest *)request
                              destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                  success:(void (^)(AylaHTTPTask *task, NSURL *filePath))successBlock
                                  failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;

/**
 * Use this method to create an AylaHTTPTask object for a download request with progress block.
 *
 * @param request      request to upload stream.
 * @param downloadProgressBlock A block object to be executed when the download progress is updated. Note this block is called on the session queue, not the main queue.
 * @param destination  A block object to be executed in order to determine the destination of the downloaded file. This block takes two arguments, the target path & the server response, and returns the desired file URL of the resulting download. The temporary file used during the download will be automatically deleted after being moved to the returned URL.
 * @param successBlock A block called when the request succeeds. Passed the completed AylaHTTPTask and a nullable responseObject.
 * @param failureBlock A block called when the request fails. Passed the AylaHTTPTask and an `NSError` describing the failure.
 *
 * @return An `AylaHTTPTask`
 */
- (AylaHTTPTask *)taskWithDownloadRequest:(NSURLRequest *)request
                                 progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                              destination:(NSURL *__nonnull (^)(NSURL *__nonnull, NSURLResponse *__nonnull))destination
                                  success:(void (^)(AylaHTTPTask *task, NSURL *filePath))successBlock
                                  failure:(void (^)(AylaHTTPTask *task, NSError *error))failureBlock;
/**
 * Create a mutable url request with input method, path and parameters
 *
 * @param method     HTTP Method of the request
 * @param path       The path to the resource
 * @param parameters Parameters passed in the request
 *
 * @return An `NSMutableURLRequest` initialized with the specified parameters
 * */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(nullable NSDictionary *)parameters;

/**
 * Use this method to invalidate http client
 *
 * @param cancelPendingTasks If pending tasks should be cancelled or allow them to be finished.
 *
 * @discussion Currently there is no recovery method for an invalidated HTTP client. Hence, this method should only be
 * called if this http client is no longer required.
 */
- (void)invalidateAndCancelTasks:(BOOL)cancelPendingTasks;

/**
 * A helpful method to create a HTTP client to device service
 * @param settings   The system settings to initialize the client
 * @param usingHTTPS Specifies wether or not the client should use HTTPS
 */
+ (instancetype)deviceServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS;

/**
 * A helpful method to create a HTTP client to user service
 * @param settings   The system settings to initialize the client
 * @param usingHTTPS Specifies wether or not the client should use HTTPS
 */
+ (instancetype)userServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS;

/**
 * A helpful method to create a HTTP client to log service
 * @param settings   The system settings to initialize the client
 * @param usingHTTPS Specifies wether or not the client should use HTTPS
 */
+ (instancetype)logServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS;

/**
 * A helpful method to create a HTTP client to stream service
 * @param settings   The system settings to initialize the client
 * @param usingHTTPS Specifies wether or not the client should use HTTPS
 */
+ (instancetype)streamServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS;

/**
 * A helpful method to create a HTTP client to stream subscription service
 * @param settings   The system settings to initialize the client
 * @param usingHTTPS Specifies wether or not the client should use HTTPS
 */
+ (instancetype)mdssSubscriptionServiceClientWithSettings:(AylaSystemSettings *)settings usingHTTPS:(BOOL)usingHTTPS;
/**
 * A helpful method to create a HTTP client to AP mode device
 * @param lanIp      LAN Ip of the device
 * @param usingHTTPS Specifies wether or not the client should use HTTPS
 */
+ (instancetype)apModeDeviceClientWithLanIp:(NSString *)lanIp usingHTTPS:(BOOL)usingHTTPS;

/**
 * A helpful method to create a Http client to a service pointed by endpoint baseURL
 * @param baseURL End-point base URL for service
 * @param AylaSystemSettings settings AylaSystemSettings object
 * @param usingHTTPS BOOL indicating if it is a secure endoint
 * @param timeout NSTimeInterval for request timeout
 *
 * @return AylaHTTPClient object
 */
+ (instancetype)serviceClientWithBaseUrl:(NSString *)baseURL
                       andSystemSettings:(AylaSystemSettings *)settings
                              usingHTTPS:(BOOL)usingHTTPS
                      withDefaultTimeout:(NSTimeInterval)timeout;

/**
 * A helpful method to create a Http client to a service pointed by endpoint url.
 * @param serviceUrl End-point URL for service
 * @param timeout NSTimeInterval for request timeout
 *
 * @return AylaHTTPClient object
 */
+ (instancetype)serviceClientWithUrl:(NSString *)serviceUrl
                  withDefaultTimeout:(NSTimeInterval)timeout;


/**
 Enables network profiler
 */
+ (void)enableNetworkProfiler;

/** Unavailable  */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
