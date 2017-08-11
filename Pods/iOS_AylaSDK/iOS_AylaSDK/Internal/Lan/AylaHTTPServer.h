//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <CocoaHTTPServer/HTTPServer.h>
#import <Foundation/Foundation.h>
#import "AylaDefines.h"
NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPServer;
@class AylaHTTPServerRequest;
@class AylaHTTPServerResponse;

/**
 * Protocol all AylaHTTPServerResponder should follow
 */
@protocol AylaHTTPServerResponder<NSObject>

/**
 * Inform responder a request has been received.
 *
 * @param server  HTTP server who received this request
 * @param request The request instance
 *
 * @return The response of given request. If a nil is returned, HTTP server will return an empty response with a http
 * status code 400.
 */
- (nullable AylaHTTPServerResponse *)httpServer:(AylaHTTPServer *)server
                              didReceiveRequest:(AylaHTTPServerRequest *)request;

/**
 * Inform responder it has been removed as listener to given lanIp.
 *
 * @param lanIp Lan ip which responder listened to before being removed.
 *
 * @note This callback will only be triggered when the method -addResponder:toLanIp: causes a replacement of responder
 * for a lan ip. Method -removeResponder:fromLanIp will not invoke this callback.
 */
- (void)httpServer:(AylaHTTPServer *)server isRemovedAsResponderToLanIp:(NSString *)lanIp;

@end

@interface AylaHTTPServer : HTTPServer

/**
 * Init method
 *
 * @param portNum The port number which will be used as default port number to listen to. Note there is no guarantee
 * this port num will be the final port num listened by HTTP Server. Check the -listeningPort to get the current
 * listeneed port number.
 */
- (instancetype)initWithPort:(UInt16)portNum;

/**
 * Add responder to given lan ip
 *
 * @param responder The responder which conforms AylaHTTPServerResponder.
 * @param lanIp     Lan ip this responder listens to.
 */
- (void)addResponder:(id<AylaHTTPServerResponder>)responder toLanIp:(NSString *)lanIp;

/**
 * Remove responder from given lan ip
 *
 * @param responder The responder which conforms AylaHTTPServerResponder.
 * @param lanIp     Lan ip this responder is listening to.
 */
- (void)removeResponder:(id<AylaHTTPServerResponder>)responder fromLanIp:(NSString *)lanIp;

/**
 * Get responder of passed in lan ip
 */
- (nullable id<AylaHTTPServerResponder>)getResponderOfLanIp:(NSString *)lanIp;

@end

/**
 * Each AylaHTTPServerRequest represents a request received by http server
 */
@interface AylaHTTPServerRequest : NSObject

/** HTTP method */
@property (nonatomic, readonly) NSString *method;

/** Request URI */
@property (nonatomic, readonly) NSString *URI;

/** Header fields */
@property (nonatomic, readonly) NSDictionary *headerFields;

/** Body data */
@property (nonatomic, readonly) NSData *bodyData;

/**
 * Init method
 */
- (instancetype)initWithMethod:(NSString *)method
                           URI:(NSString *)uri
                  headerFields:(NSDictionary *)headerFields
                      bodyData:(NSData *)bodyData;

@end

/**
 * Each AylaHTTPServerRequest represents a response to a http server request.
 */
@interface AylaHTTPServerResponse : NSObject

/** HTTP status code */
@property (nonatomic, readonly) NSInteger httpStatusCode;

/** Header fields */
@property (nonatomic, readonly) NSDictionary *headerFields;

/** Body data */
@property (nonatomic, readonly) NSData *bodyData;

/**
 * Init method
 */
- (instancetype)initWithHttpStatusCode:(NSInteger)httpStatusCode
                          headerFields:(NSDictionary *)headerFields
                              bodyData:(nullable NSData *)bodyData;

/**
 * A helpful method to get default header field for json content-type.
 */
+ (NSDictionary *)JSONContentHeaderField;

@end

NS_ASSUME_NONNULL_END