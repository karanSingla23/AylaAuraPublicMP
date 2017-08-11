//
//  AylaNetworks.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 12/10/15.
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaConnectivity+Internal.h"
#import "AylaNetworks.h"
#import "AylaDefines_Internal.h"
#import "AylaHTTPClient.h"
#import "AylaLoginManager+Internal.h"
#import "AylaSessionManager.h"
#import "AylaSystemSettings.h"

NSString * const PLUGIN_ID_DEVICE_CLASS = @"com.aylanetworks.aylasdk.deviceclass";
NSString * const PLUGIN_ID_DEVICE_LIST = @"com.aylanetworks.aylasdk.devicelist";

@interface AylaNetworks ()

@property (nonatomic, readwrite) AylaSystemSettings *systemSettings;
@property (nonatomic, readwrite) NSMutableDictionary *sessionManagers;
@property (nonatomic, readwrite) AylaConnectivity *connectivity;
@property (nonatomic, readwrite) NSMutableDictionary *plugins;
@end

@implementation AylaNetworks

// static shared manager instance
static AylaNetworks *__shared;

- (instancetype)initWithSettings:(AylaSystemSettings *)settings;
{
    self = [super init];
    if (!self) return nil;

    _systemSettings = settings;

    // Init login manager
    _loginManager = [[AylaLoginManager alloc] initWithSDKRoot:self];

    // Init session manager dictionary
    _sessionManagers = [NSMutableDictionary dictionary];

    // Init connectvity listener
    _connectivity = [[AylaConnectivity alloc] initWithSettings:settings];

    // Start connectivity monitoring immidiately.
    [_connectivity startMonitoringNetworkChanges];
    
    _plugins = [NSMutableDictionary dictionary];
    
    return self;
}

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @synchronized(self)
        {
            if (!__shared)
                __shared = [[AylaNetworks alloc] initWithSettings:[AylaSystemSettings defaultSystemSettings]];
        }
    });
    return __shared;
}

+ (instancetype)initializeWithSettings:(AylaSystemSettings *)settings
{
    AylaNetworks *manager = nil;
    @synchronized(self)
    {
        manager = __shared = [[AylaNetworks alloc] initWithSettings:settings];
    }

    AylaLogI(@"SDKRoot", 0, @"Initialized new manager.");
    return manager;
}

- (id<AylaPlugin>)getPluginWithId:(NSString *)pluginId
{
    @synchronized (self) {
        return self.plugins[pluginId];
    }
}

- (void)installPlugin:(id<AylaPlugin>)plugin id:(NSString *)pluginId
{
    @synchronized (self) {
        self.plugins[pluginId] = plugin;
    }
}

- (void)pause
{
    @synchronized (self) {
        for (AylaSessionManager *sessionManager in self.sessionManagers.allValues) {
            [sessionManager pause];
            
            [self.plugins enumerateKeysAndObjectsUsingBlock:^(NSString  * _Nonnull pluginId, id<AylaPlugin> plugin, BOOL * _Nonnull stop) {
                [plugin pausePlugin:pluginId sessionManager:sessionManager];
            }];
        }
    }
}

- (void)resume
{
    @synchronized (self) {
        for (AylaSessionManager *sessionManager in self.sessionManagers.allValues) {
            [sessionManager resume];
            
            [self.plugins enumerateKeysAndObjectsUsingBlock:^(NSString  * _Nonnull pluginId, id<AylaPlugin> plugin, BOOL * _Nonnull stop) {
                [plugin resumePlugin:pluginId sessionManager:sessionManager];
            }];
        }
    }
}

- (nullable AylaSessionManager *)getSessionManagerWithName:(NSString *)sessionName
{
    __block AylaSessionManager *sessionManager;
    @synchronized (self) {
        sessionManager = self.sessionManagers[sessionName];
    }
    return sessionManager;
}

+ (NSString *)getVersion
{
    return AYLA_SDK_VERSION;
}

+ (NSString *)getSupportEmailAddress
{
    return @"mobile-libraries@aylanetworks.com";
}

@end

@implementation AylaNetworks (Internal)

- (void)addSessionManager:(AylaSessionManager *)sessionManager
{
    @synchronized (self) {
        AYLAssert(sessionManager.sessionName, @"Session name must not be nil.");
        self.sessionManagers[sessionManager.sessionName] = sessionManager;
        
        [self.plugins enumerateKeysAndObjectsUsingBlock:^(NSString  * _Nonnull pluginId, id<AylaPlugin> plugin, BOOL * _Nonnull stop) {
            [plugin initializePlugin:pluginId sessionManager:sessionManager];
        }];
    }
}

- (void)removeSessionManager:(AylaSessionManager *)sessionManager
{
    @synchronized (self) {
        AYLAssert(sessionManager.sessionName, @"Session name must not be nil.");
        self.sessionManagers[sessionManager.sessionName] = nil;
        
        [self.plugins enumerateKeysAndObjectsUsingBlock:^(NSString  * _Nonnull pluginId, id<AylaPlugin> plugin, BOOL * _Nonnull stop) {
            [plugin shutDownPlugin:pluginId sessionManager:sessionManager];
        }];
    }
}

@end
