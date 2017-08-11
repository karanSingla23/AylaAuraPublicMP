//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "AylaDefines_Internal.h"
#import "AylaDiscovery.h"

typedef void (^discoveryCompletionBlock)(NSString *, NSString *);
typedef void (^discoveryExecutionBlock)(void);

@class AylaDiscoveryOperation;
@protocol AylaDiscoveryOperationDelegate<NSObject>

- (void)AylaDiscoveryOperation:(AylaDiscoveryOperation *)operation willExecute:(BOOL)isExecutionBlockAvailable;
- (void)AylaDiscoveryOperation:(AylaDiscoveryOperation *)operation didTimeout:(BOOL)isCompletionBlockAvailable;

@end

@interface AylaDiscoveryOperation : NSOperation

@property (assign, nonatomic) NSInteger operationTimeout;
@property (weak, nonatomic) id<AylaDiscoveryOperationDelegate> delegate;
@property (strong, nonatomic) NSString *hostName;
@property (assign, nonatomic) BOOL isHostReachable;
@property (assign, nonatomic) BOOL isCompletionBlockExecuted;
@property (assign, nonatomic) BOOL isTimeout;

@property (copy, nonatomic) discoveryExecutionBlock discoveryExecutionBlock;
@property (copy, nonatomic) discoveryCompletionBlock discoveryCompletionBlock;

@end

@implementation AylaDiscoveryOperation

+ (instancetype)operationWithDelegate:(id<AylaDiscoveryOperationDelegate>)delegate
                             hostName:(NSString *)hostName
                      completionBlock:(discoveryCompletionBlock)completionBlock
                              timeout:(NSTimeInterval)timeout
{
    AylaDiscoveryOperation *operation = [[AylaDiscoveryOperation alloc] init];
    operation.delegate = delegate;
    operation.hostName = hostName;
    operation.discoveryCompletionBlock = completionBlock;
    operation.operationTimeout = timeout;
    return operation;
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }

    if (self.discoveryExecutionBlock) {
        [_delegate AylaDiscoveryOperation:self willExecute:YES];
        self.discoveryExecutionBlock();

        int64_t timeout = (int64_t)(self.operationTimeout * NSEC_PER_SEC);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), dispatch_get_main_queue(), ^{
            [self timeout];
        });
    }
}

- (BOOL)isConcurrent
{
    return NO;
}

- (void)timeout
{
    if (self.isCancelled || self.isCompletionBlockExecuted) {
        return;
    }
    [_delegate AylaDiscoveryOperation:self didTimeout:YES];
}

@end

@interface AylaDiscovery ()<AylaDiscoveryOperationDelegate, GCDAsyncUdpSocketDelegate> {
    GCDAsyncUdpSocket *udpSocket;
    dispatch_queue_t udpSocketOperationQueue;
    dispatch_semaphore_t discoverySemaphore;

    NSOperationQueue *requestOperationQueue;
    NSMutableArray *pendingOperations;
}

@property (assign, nonatomic) BOOL isAvailable;
@end

@implementation AylaDiscovery

static int const devDNSPort = 10276;
static int const devDNSPort2 = 5353;

static NSString *const mDNSHost = @"224.0.0.251";
static NSString *const domain = @"local";

static NSObject *synchronizedObj = nil;
static NSLock *connectionsLock = nil;

+ (void)getDeviceLanIpWithHostName:(NSString *)deviceHostName
                           timeout:(NSTimeInterval)timeout
                       resultBlock:(void (^)(NSString *lanIp, NSString *deviceHostName))resultBlock
{
    [[AylaDiscovery sharedDiscovery] getDeviceLanIpWithHostName:deviceHostName timeout:timeout resultBlock:resultBlock];
}

static AylaDiscovery *discovery;
+ (instancetype)sharedDiscovery
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        synchronizedObj = [NSObject new];
        connectionsLock = [[NSLock alloc] init];
    });

    [connectionsLock lock];
    if (discovery && discovery.isAvailable) {
    }
    else {
        discovery = [[AylaDiscovery alloc] init];
        discovery.isAvailable = [discovery socketSetup] ? YES : NO;
    }
    [connectionsLock unlock];
    return discovery;
}

+ (void)cancelDiscovery
{
    [connectionsLock lock];
    [discovery close];
    discovery = nil;
    [connectionsLock unlock];
}

- (instancetype)init
{
    self = [super init];
    if (!self) return self;

    requestOperationQueue = [[NSOperationQueue alloc] init];
    requestOperationQueue.maxConcurrentOperationCount = 1;
    pendingOperations = [NSMutableArray new];
    udpSocketOperationQueue =
        dispatch_queue_create("com.aylanetworks.AylaDiscovery.udpSocketQueue", DISPATCH_QUEUE_CONCURRENT);
    discoverySemaphore = dispatch_semaphore_create(1);

    return self;
}

- (BOOL)socketSetup
{
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:udpSocketOperationQueue];
    NSError *error = nil;
    if (![udpSocket bindToPort:0 error:&error]) {
        AylaLogE(@"Discovery", 0, @"bind err %@, %@", error, @"socketSetup");
        return NO;
    }
    if (![udpSocket beginReceiving:&error]) {
        AylaLogE(@"Discovery", 0, @"begin err %@, %@", error, @"socketSetup");
        return NO;
    }
    return YES;
}

- (void)getDeviceLanIpWithHostName:(NSString *)deviceHostName
                           timeout:(NSTimeInterval)timeout
                       resultBlock:(void (^)(NSString *, NSString *))_resultBlock
{
    NSData *sendPacket = [self packetWithDeviceHostName:deviceHostName];

    AylaDiscoveryOperation *operation =
        [AylaDiscoveryOperation operationWithDelegate:self hostName:deviceHostName completionBlock:_resultBlock timeout:timeout];

    [operation setDiscoveryExecutionBlock:^(void) {
        [udpSocket sendData:sendPacket toHost:mDNSHost port:devDNSPort withTimeout:-1 tag:0];
        [udpSocket sendData:sendPacket toHost:mDNSHost port:devDNSPort2 withTimeout:-1 tag:0];
        usleep(100000);
        [udpSocket sendData:sendPacket toHost:mDNSHost port:devDNSPort withTimeout:-1 tag:0];
        [udpSocket sendData:sendPacket toHost:mDNSHost port:devDNSPort2 withTimeout:-1 tag:0];
    }];

    [requestOperationQueue addOperation:operation];
}

- (NSData *)packetWithDeviceHostName:(NSString *)deviceHostName
{
    // Build packet
    long devHostNameLength = [deviceHostName length];
    long domainLength = [domain length];
    long packetDataLength = devHostNameLength + domainLength + 12 + 5 + 2;
    Byte *bytes = malloc(packetDataLength);
    bzero(bytes, packetDataLength);
    bytes[5] = 0x01;

    Byte *data = bytes + 12;
    *data = (Byte)devHostNameLength;
    data++;
    NSData *nameData = [deviceHostName dataUsingEncoding:NSUTF8StringEncoding];
    memcpy(data, [nameData bytes], devHostNameLength);
    data += devHostNameLength;
    *data = domainLength;
    NSData *domainData = [domain dataUsingEncoding:NSUTF8StringEncoding];
    data++;
    memcpy(data, [domainData bytes], domainLength);
    data += domainLength;
    data[2] = 0x01;
    data[4] = 0x01;

    NSData *sendData = [[NSData alloc] initWithBytes:bytes length:packetDataLength];
    free(bytes);

    return sendData;
}

- (void)doResponseWithHostName:(NSString *)hostName lanIp:(NSString *)lanIp
{
    // Check pending operations to return response
    if (hostName) {
        dispatch_semaphore_wait(discoverySemaphore, DISPATCH_TIME_FOREVER);
        NSArray *currentPendingOperations = pendingOperations;
        NSMutableArray *updatedPendingOperations = [NSMutableArray new];

        AylaLogI(@"Discovery", 0, @"ip:%@, %@", lanIp, @"doResponse");

        [currentPendingOperations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

            AylaDiscoveryOperation *operation = obj;
            if ([operation.hostName isEqualToString:hostName] && !operation.isTimeout) {
                operation.isHostReachable = lanIp ? YES : NO;
                operation.isCompletionBlockExecuted = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    operation.discoveryCompletionBlock(lanIp, hostName);
                });
            }
            else {
                [updatedPendingOperations addObject:operation];
            }
        }];

        pendingOperations = updatedPendingOperations;
        dispatch_semaphore_signal(discoverySemaphore);
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *hostAddress = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&hostAddress port:&port fromAddress:address];
    if (port != devDNSPort && port != devDNSPort2) return;

    const void *ptr = data.bytes;
    Byte lenByte = ((Byte *)ptr)[12];
    int len = lenByte;
    NSData *hostNameData = [data subdataWithRange:NSMakeRange(13, len)];
    NSString *hostName = [[NSString alloc] initWithData:hostNameData encoding:NSUTF8StringEncoding];

    if (hostName) {
        [self doResponseWithHostName:hostName lanIp:hostAddress];
    }
}

- (void)close
{
    [udpSocket close];
    udpSocket = nil;
}

- (void)dealloc
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#else
    dispatch_release(discoverySemaphore);
#endif
}

#pragma mark - discovery delegate
- (void)AylaDiscoveryOperation:(AylaDiscoveryOperation *)operation willExecute:(BOOL)isExecutionBlockAvailable
{
    // move operation to pending queue
    [pendingOperations addObject:operation];
}

- (void)AylaDiscoveryOperation:(AylaDiscoveryOperation *)operation didTimeout:(BOOL)isCompletionBlockAvailable
{
    // suspend operations to update list
    [requestOperationQueue setSuspended:YES];
    BOOL implementCompletionBlock = NO;
    dispatch_semaphore_wait(discoverySemaphore, DISPATCH_TIME_FOREVER);

    operation.isTimeout = YES;
    // Skip if completion operation has been implemented
    if (!operation.isCompletionBlockExecuted) {
        implementCompletionBlock = YES;
    }
    
    // remove operation from pending operation list
    [pendingOperations removeObject:operation];

    dispatch_semaphore_signal(discoverySemaphore);
    [requestOperationQueue setSuspended:NO];

    if (implementCompletionBlock && isCompletionBlockAvailable) {
        AylaLogI(@"Discovery", 0, @"timeout:%@, %@", operation.hostName, @"endDiscovery");
        dispatch_async(dispatch_get_main_queue(), ^{
            operation.discoveryCompletionBlock(nil, operation.hostName);
        });
    }
}

@end
