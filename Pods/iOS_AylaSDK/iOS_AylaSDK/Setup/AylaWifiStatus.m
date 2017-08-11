//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject+Internal.h"
#import "AylaWifiStatus.h"
#import "NSObject+Ayla.h"

@implementation AylaWifiConnectionHistory

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing  _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if(!self) return nil;
    
    _ssidInfo= [dictionary[@"ssid_info"] nilIfNull];
    _bssid = [dictionary[@"bssid"] nilIfNull];
    _error = [[dictionary[@"error"] nilIfNull] intValue];
    _msg = [dictionary[@"msg"] nilIfNull];
    _mtime = [[dictionary[@"mtime"] nilIfNull] intValue];
    _ipAddress = [dictionary[@"ip_addr"] nilIfNull];
    _netmask = [dictionary[@"netmask"] nilIfNull];;
    _defaultRoute = [dictionary[@"default_route"] nilIfNull];
    _dnsServers = [dictionary[@"dns_servers"] nilIfNull];
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BSSID: %@, msg: %@, error:%d", self.bssid, self.msg, self.error];
}

@end

@implementation AylaWifiStatus


- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing  _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if(!self) return nil;

    _ant = [[dictionary[@"ant"] nilIfNull] intValue];
    _bars = [[dictionary[@"bars"] nilIfNull] intValue];
    _connectedSsid = [dictionary[@"connected_ssid"] nilIfNull];
    _deviceService = [dictionary[@"device_service"] nilIfNull];
    _dsn= [dictionary[@"dsn"] nilIfNull];
    _hostSymname = [dictionary[@"host_symname"] nilIfNull];
    _logService = [dictionary[@"log_service"] nilIfNull];
    _mac = [dictionary[@"mac"] nilIfNull];
    _mtime = [[dictionary[@"mtime"] nilIfNull] unsignedIntegerValue];;
    _rssi = [[dictionary[@"rssi"] nilIfNull] intValue];
    _wps = [dictionary[@"wps"] nilIfNull];
    _state = [dictionary[@"state"] nilIfNull];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if( dictionary[@"connect_history"] != [NSNull null]){
        NSArray* historyArray = dictionary[@"connect_history"];
        for(NSDictionary *historyInJson in historyArray){
            AylaWifiConnectionHistory *history = [[AylaWifiConnectionHistory alloc] initWithJSONDictionary:historyInJson error:nil];
            [array addObject:history];
        }
    }
    
    _connectHistory = [array copy];
    
    return self;
}

- (NSString *)description
{
    return [NSString
        stringWithFormat:@"WiFiStatus: state:%@ connected_ssid=%@ history[%@]", self.state, self.connectedSsid, self.connectHistory];
}

@end
