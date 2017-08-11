//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "AylaConnectivity.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPError.h"
#import "AylaHTTPTask.h"
#import "AylaListenerArray.h"
#import "AylaSystemSettings.h"
#import "AylaSystemUtils.h"

NSString *const AylaConnectivityNetworkChangeNotification = @"com.aylanetworks.connectivity.networkChange";

static const NSTimeInterval DEFAULT_SERVICE_REACHABILITY_TIMEOUT = 10.;

@interface AylaConnectivity ()

@property (nonatomic) AylaSystemSettings *settings;
@property (nonatomic) NSString *servicePath;
@property (nonatomic) AylaHTTPClient *httpClient;
@property (nonatomic) AFNetworkReachabilityManager *afReachabilityManager;
@property (nonatomic) AylaListenerArray *listeners;

@end

@implementation AylaConnectivity

- (instancetype)initWithSettings:(AylaSystemSettings *)settings
{
    self = [super init];
    if (!self) return nil;

    _settings = settings;
    _servicePath = [AylaSystemUtils reachabilityBaseUrlWithSettings:settings];
    _httpClient = [[AylaHTTPClient alloc] initWithBaseUrl:[NSURL URLWithString:_servicePath]];
    _afReachabilityManager = [AFNetworkReachabilityManager manager];
    _listeners = [[AylaListenerArray alloc] init];

    return self;
}

- (void)addListener:(id<AylaConnectivityListener>)listener
{
    [self.listeners addListener:listener];
}

- (void)removeListener:(id<AylaConnectivityListener>)listener
{
    [self.listeners removeListener:listener];
}

- (void)startMonitoringNetworkChanges
{
    __weak typeof(self) weakSelf = self;
    [self.afReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AylaNetworkReachabilityStatus reachabilityStatus =
            [strongSelf reachabilityStatusFromAFReachabilityStatus:status];

        [strongSelf.listeners iterateListenersRespondingToSelector:@selector(connectivity:didObserveNetworkChange:)
                                                      asyncOnQueue:dispatch_get_main_queue()
                                                             block:^(id _Nonnull listener) {
                                                                 [listener connectivity:strongSelf
                                                                     didObserveNetworkChange:reachabilityStatus];
                                                             }];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:AylaConnectivityNetworkChangeNotification
                                                                object:@(reachabilityStatus)];
        });
    }];

    [self.afReachabilityManager startMonitoring];
}

- (void)stopMonitoringNetworkChanges
{
    [self.afReachabilityManager stopMonitoring];
}

- (AylaConnectTask *)determineServiceReachability:(void (^)(BOOL isReachable, BOOL cancelled))responseBlock
{
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"GET" path:@"ping.json" parameters:nil];
    // We are using a shorter timeout to determine service reachability.
    [request setTimeoutInterval:DEFAULT_SERVICE_REACHABILITY_TIMEOUT];

    AylaHTTPTask *task = [self.httpClient taskWithRequest:request
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                responseBlock(YES, NO);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error.code == AylaHTTPErrorCodeCancelled) {
                    responseBlock(NO, YES);
                }
                else if (error.code == AylaHTTPErrorCodeLostConnectivity) {
                    // Only returns unreachable if request can't be sent to service.
                    responseBlock(NO, NO);
                }
                else {
                    responseBlock(YES, NO);
                }
            });
        }];

    [task start];
    return task;
}

- (AylaNetworkReachabilityStatus)reachabilityStatusFromAFReachabilityStatus:(AFNetworkReachabilityStatus)status
{
    switch (status) {
        case AFNetworkReachabilityStatusNotReachable:
            return AylaNetworkReachabilityStatusNotReachable;
        case AFNetworkReachabilityStatusReachableViaWiFi:
            return AylaNetworkReachabilityStatusReachableViaWiFi;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return AylaNetworkReachabilityStatusReachableViaWWAN;
        case AFNetworkReachabilityStatusUnknown:
            return AylaNetworkReachabilityStatusUnknown;
        default:
            break;
    }
    return AylaNetworkReachabilityStatusUnknown;
}

- (void)dealloc
{
    [self stopMonitoringNetworkChanges];
}

@end
