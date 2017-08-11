//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject+Internal.h"
#import "AylaWifiScanResults.h"
#import "NSObject+Ayla.h"

@implementation AylaWifiScanResult

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;

    _ssid = [dictionary[NSStringFromSelector(@selector(ssid))] nilIfNull];
    _type = [dictionary[NSStringFromSelector(@selector(type))] nilIfNull];
    _chan = [[dictionary[NSStringFromSelector(@selector(chan))] nilIfNull] intValue];
    _signal = [[dictionary[NSStringFromSelector(@selector(signal))] nilIfNull] intValue];
    _bars = [[dictionary[NSStringFromSelector(@selector(bars))] nilIfNull] intValue];
    _security = [dictionary[NSStringFromSelector(@selector(security))] nilIfNull];
    _bssid = dictionary[NSStringFromSelector(@selector(bssid))];

    return self;
}

@end

@implementation AylaWifiScanResults

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;

    _mtime = [[dictionary[NSStringFromSelector(@selector(mtime))] nilIfNull] unsignedIntegerValue];
    NSArray *resultsJSON = [dictionary[@"results"] nilIfNull];
    
    NSMutableArray *results = [NSMutableArray array];
    for (NSDictionary *resultInJson in resultsJSON) {
        AylaWifiScanResult *result = [[AylaWifiScanResult alloc] initWithJSONDictionary:resultInJson error:nil];
        [results addObject:result];
    }

    _results = results;

    return self;
}

@end
