//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <CocoaHTTPServer/HTTPConnection.h>
#import <CocoaHTTPServer/HTTPDataResponse.h>
#import <CocoaHTTPServer/HTTPMessage.h>
#import <CocoaHTTPServer/HTTPServer.h>
#import "AylaHTTPClient.h"
#import "AylaHTTPServer.h"
#import "AylaLogManager.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface AylaHTTPServer ()
/**
 * The reponder set. Right now we only registers one responder to one lan ip.
 */
@property NSMutableDictionary AYLA_GENERIC(NSString *, id<AylaHTTPServerResponder>) * responders;

@end

/**
 * HTTP server connection
 */
@interface AylaHTTPServerConnection : HTTPConnection

/** Host ip of current connection */
@property (nonatomic) NSString *hostIp;

/** Http server which handles this http server connection */
@property (nonatomic, weak) AylaHTTPServer *httpServer;

@end

/**
 * HTTP server supported data response
 */
@interface AylaHTTPServerDataResponse : HTTPDataResponse

@property (nonatomic) NSInteger httpStatus;
@property (nonatomic) NSDictionary *headerFields;
@property (nonatomic) NSData *bodyData;

- (instancetype)initWithStatus:(NSInteger)httpStatus headerFields:(NSDictionary *)headerFields data:(NSData *)data;

+ (instancetype)defaultErrorResponse;

@end

@interface AylaHTTPServerResponse ()

- (AylaHTTPServerDataResponse *)toHttpServerDataResponse;

@end

@implementation AylaHTTPServer

- (instancetype)initWithPort:(UInt16)portNum
{
    self = [super init];
    if (self) {
        type = @"_http._tcp.";
        port = portNum;
        connectionClass = [AylaHTTPServerConnection class];

        _responders = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addResponder:(id<AylaHTTPServerResponder>)responder toLanIp:(NSString *)lanIp
{
    __block id<AylaHTTPServerResponder> origResponder;
    @synchronized(self) {
        
        origResponder = self.responders[lanIp];
 
        // If this is a duplicate add to current responder, skip it.
        if(origResponder == responder) {
            origResponder = nil;
            return;
        }
        
        // Right now, each lan ip will only hold one responder.
        self.responders[lanIp] = responder;
    }
    
    // Notify responder of this replacement.
    [origResponder httpServer:self isRemovedAsResponderToLanIp:lanIp];
}

- (void)removeResponder:(id<AylaHTTPServerResponder>)responder fromLanIp:(NSString *)lanIp
{
    @synchronized(self) {
        if(self.responders[lanIp] == responder) {
            // remove responder by cleaning set since each set only has one responder.
            self.responders[lanIp] = nil;
        }
    }
}

- (id<AylaHTTPServerResponder>)getResponderOfLanIp:(NSString *)lanIp
{
    @synchronized(self) {
        return self.responders[lanIp];
    }
}

@end

@implementation AylaHTTPServerConnection

- (id)initWithAsyncSocket:(GCDAsyncSocket *)socket configuration:(HTTPConfig *)aConfig
{
    self = [super initWithAsyncSocket:socket configuration:aConfig];
    self.hostIp = [socket connectedHost];

    HTTPServer *server = aConfig.server;
    if ([server isKindOfClass:[AylaHTTPServer class]]) {
        self.httpServer = (AylaHTTPServer *)server;
    }
    else {
        AylaLogW([self logTag], 0, @"No valid Ayla HTTP Server found for a server connection");
    }

    return self;
}

/**
 * Override to adjust supported methods
 *
 * @return If this method is supported for given path.
 */
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    // Add support for POST/PUT/DELETE
    if ([method isEqualToString:AylaHTTPRequestMethodPOST] || [method isEqualToString:AylaHTTPRequestMethodPUT] ||
        [method isEqualToString:AylaHTTPRequestMethodDELETE]) {
        return YES;
    }

    return [super supportsMethod:method atPath:path];
}

/**
 * Override to handle requests received by HTTP server.
 *
 * @param method HTTP request method of current request.
 * @param path   URI of current request.
 *
 * @return A response object which conforms HTTPResponse.
 */
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    // get lan ip from path
    NSString *lanIp = self.hostIp;

    AylaHTTPServer *httpServer = self.httpServer;
    id<AylaHTTPServerResponder> responder = httpServer.responders[lanIp];

    // Compose server request with known data.
    AylaHTTPServerRequest *req = [[AylaHTTPServerRequest alloc] initWithMethod:method
                                                                           URI:path
                                                                  headerFields:[request allHeaderFields]
                                                                      bodyData:[request body]];

    AylaHTTPServerResponse *response = [responder httpServer:httpServer didReceiveRequest:req];

    // If no response was found, user a default error response
    AylaHTTPServerDataResponse *dataResponse =
        [response toHttpServerDataResponse] ?: [AylaHTTPServerDataResponse defaultErrorResponse];
    return dataResponse;
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    // If we supported large uploads,
    // we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
    // Remember: In order to support LARGE POST uploads, the data is read in chunks.
    // This prevents a 50 MB upload from being stored in RAM.
    // The size of the chunks are limited by the POST_CHUNKSIZE definition.
    // Therefore, this method may be called multiple times for the same POST request.

    BOOL result = [request appendData:postDataChunk];
    if (!result) {
        AylaLogW(@"httpServer", 0, @"%@, %@", @"Couldn't append bytes", @"processBodyData");
    }
}

- (NSString *)logTag
{
    return @"ServerConnection";
}

@end


@implementation AylaHTTPServerRequest

- (instancetype)initWithMethod:(NSString *)method
                           URI:(NSString *)uri
                  headerFields:(NSDictionary *)headerFields
                      bodyData:(NSData *)bodyData
{
    self = [super init];
    if (!self) return nil;
    
    _method = method;
    _URI = uri;
    _bodyData = bodyData;
    
    return self;
}

@end


@implementation AylaHTTPServerResponse

- (instancetype)initWithHttpStatusCode:(NSInteger)httpStatusCode
                          headerFields:(NSDictionary *)headerFields
                              bodyData:(NSData *)bodyData
{
    self = [super init];
    if (!self) return nil;

    _httpStatusCode = httpStatusCode;
    _headerFields = headerFields;
    _bodyData = bodyData;

    return self;
}

- (AylaHTTPServerDataResponse *)toHttpServerDataResponse
{
    return [[AylaHTTPServerDataResponse alloc] initWithStatus:self.httpStatusCode
                                                 headerFields:self.headerFields
                                                         data:self.bodyData];
}

+ (NSDictionary *)JSONContentHeaderField
{
    return @{ @"Content-Type" : @"application/json" };
}

@end

@implementation AylaHTTPServerDataResponse : HTTPDataResponse

- (instancetype)initWithStatus:(NSInteger)httpStatus headerFields:(NSDictionary *)headerFields data:(NSData *)bodyData
{
    self = [super initWithData:bodyData];
    if (!self) return self;

    _headerFields = headerFields;
    _httpStatus = httpStatus;

    return self;
}

+ (instancetype)defaultErrorResponse
{
    return [[[self class] alloc] initWithStatus:400 headerFields:nil data:nil];
}

/**
 * Status code for response.
 * Allows for responses such as redirect (301), etc.
 **/
- (NSInteger)status
{
    return self.httpStatus;
}

/**
 * If you want to add any extra HTTP headers to the response,
 * simply return them in a dictionary in this method.
 **/
- (NSDictionary *)httpHeaders
{
    return self.headerFields;
};

/**
 * If you don't know the content-length in advance,
 * implement this method in your custom response class and return YES.
 *
 * Important: You should read the discussion at the bottom of this header.
 **/
//- (BOOL)isChunked;

/**
 * This method is called from the HTTPConnection class when the connection is closed,
 * or when the connection is finished with the response.
 * If your response is asynchronous, you should implement this method so you know not to
 * invoke any methods on the HTTPConnection after this method is called (as the connection may be deallocated).
 **/
//- (void)connectionDidClose;

@end
