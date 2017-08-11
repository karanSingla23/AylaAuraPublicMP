//
//  iOS_SDK
//
//  Copyright © 2016 AylaNetworks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaDevice.h"
#import "AylaDeviceManager.h"
#import "AylaLANOTAHTTPServer.h"
#import "AylaSystemUtils.h"
#import "GCDAsyncSocket.h"
#import "HTTPConnection.h"
#import "HTTPFileResponse.h"

NSInteger const AylaLANOTAHTTPDefaultServerPort = 8888;

@interface AylaLANOTAPUTResponse : NSObject<HTTPResponse>
@property (nonatomic, readwrite) NSInteger status;
@end

@implementation AylaLANOTAPUTResponse
- (UInt64)contentLength
{
    return 0;
}
- (UInt64)offset
{
    return 0;
}
- (void)setOffset:(UInt64)offset
{
    ;
}
- (NSData *)readDataOfLength:(NSUInteger)length
{
    return nil;
}
- (BOOL)isDone
{
    return YES;
}
@end

@interface AylaLANOTAGETResponse : HTTPFileResponse
@end

@implementation AylaLANOTAGETResponse

- (UInt64)offset
{
    return self->fileOffset + 256;
}

- (UInt64)contentLength
{
    return self->fileLength - 256;
}

@end

@interface AylaLANOTAHTTPServerConnection : HTTPConnection
@property (strong, nonatomic) NSString *hostIp;
@property (weak, nonatomic) AylaLANOTAHTTPServer *lanOTAServer;
@end

@interface AylaLANOTAHTTPServer ()

@property (strong, nonatomic) NSNumber *imagePushStatus;
@end

@implementation AylaLANOTAHTTPServer
static AylaLANOTAHTTPServer *_sharedInstance = nil;

- (instancetype)initWithPort:(int)portNum
{
    self = [super init];
    if (self) {
        [self setPort:portNum];
    }
    return self;
}

- (BOOL)start:(NSError *__autoreleasing *)errPtr
{
    [self setType:@"_http._tcp."];
    [self setConnectionClass:[AylaLANOTAHTTPServerConnection class]];
    return [super start:errPtr];
}

- (void)setImagePushStatus:(NSNumber *)imagePushStatus
{
    _imagePushStatus = imagePushStatus;
    [self.delegate didReceiveImagePushStatus:imagePushStatus.integerValue];
}

@end

@implementation AylaLANOTAHTTPServerConnection

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    self.hostIp = [newSocket connectedHost];
    self.lanOTAServer = (AylaLANOTAHTTPServer *)aConfig.server;
    return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    if ([method isEqualToString:@"GET"]) {
        return YES;
    }
    if ([method isEqualToString:@"PUT"]) {
        return YES;
    }

    return NO;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    // Print out url for each incoming request - DEBUG level only
    AylaLogD(@"httpLANOTAServer", 0, @"%@, %@:%@", method, @"url", path);
    if ([method isEqualToString:@"PUT"]) {
        NSURL *url = [NSURL URLWithString:path];
        NSArray *query = [[url query] componentsSeparatedByString:@"&"];

        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[query count]];
        for (NSString *parameter in query) {
            NSArray *pair = [parameter componentsSeparatedByString:@"="];
            [parameters setObject:[pair count] > 1 ? [pair objectAtIndex:1] : [NSNull null]
                           forKey:[pair objectAtIndex:0]];
        }

        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        self.lanOTAServer.imagePushStatus = [formatter numberFromString:[parameters objectForKey:@"status"]];

        NSInteger statusCode = 200;
        AylaLANOTAPUTResponse *response = [[AylaLANOTAPUTResponse alloc] init];
        response.status = statusCode;
        return response;
    }
    else if ([method isEqualToString:@"GET"] && [path containsString:@"ota"]) {
        NSString *filePath = [self filePathForURI:path allowDirectory:NO];

        BOOL isDir = NO;

        if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
            AylaLANOTAGETResponse *response = [[AylaLANOTAGETResponse alloc] initWithFilePath:filePath forConnection:self];
            [response setOffset:256];  // stripping the first 256 bytes
            return response;
        }
    }

    return [super httpResponseForMethod:method URI:path];
}
@end