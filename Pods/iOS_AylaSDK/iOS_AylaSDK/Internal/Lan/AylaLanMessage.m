//
//  AylaLanMessage.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/15/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLanMessage.h"
#import "AylaLogManager.h"
static NSString * const AttrNameData = @"data";
static NSString * const AttrUrlParamAckId = @"id";
static NSString * const AttrUrlParamAckStatus = @"ack_status";
static NSString * const AttrUrlParamCmdId = @"cmd_id";
static NSString * const AttrUrlParamStatus = @"status";

@interface AylaLanMessage ()

@property (nonatomic, readwrite) NSDictionary *urlParams;

@end

@implementation AylaLanMessage

- (instancetype)initWithType:(AylaLanMessageType)type
                         url:(NSString *)url
                        data:(NSData *)data
{
    self = [super init];
    if(!self) return nil;
    
    _type = type;
    _url = url;
    _urlParams = [self parseParamsWithUrlString:self.url];
    _data = data;

    if(data) {
        NSError *jerror;
        // if data is passed in, parse data and assign to json object
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jerror];
        // Only store `data` field
        if(jsonObject) {
            AylaLogV(@"LanMessage", 0, @"lan resp: %@", jsonObject);
            _jsonObject = jsonObject[AttrNameData];
        }
        _error = jerror;
    }
    
    return self;
}

- (NSDictionary *)parseParamsWithUrlString:(NSString *)urlString
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *components = [urlString componentsSeparatedByString:@"?"];
    if(components.count > 0) {
        [dictionary setObject:components.firstObject forKey:@"kBasicUrl"];
        
        if(components.count == 1) {
            return dictionary;
        }
        
        NSString *paramsString = components.lastObject;
        NSArray *paramsEquators = [paramsString componentsSeparatedByString:@"&"];
        [paramsEquators enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *kvPair = [(NSString *)obj componentsSeparatedByString:@"="];
            if(kvPair.count == 2) {
                [dictionary setObject:kvPair[1] forKey:kvPair[0]];
            }
        }];
    }
    return dictionary;
};

- (void)setUrl:(NSString *)url
{
    _url = url;
    self.urlParams = [self parseParamsWithUrlString:url];
}

- (NSUInteger)cmdId
{
    // Datapont ack doesn't use URL params, use "id" in json object, instead of "cmd_id"
    if (self.type == AylaLanMessageTypeDatapointAck) {
        return [self.jsonObject[AttrUrlParamAckId] integerValue];
    }

    return [(NSString *)self.urlParams[AttrUrlParamCmdId] integerValue];
}

- (NSInteger)status
{
    // Datapont ack doesn't use URL params, use "id" in json object, instead of "cmd_id"
    if (self.type == AylaLanMessageTypeDatapointAck) {
        return [self.jsonObject[AttrUrlParamAckStatus] integerValue];
    }
    return [self.urlParams[AttrUrlParamStatus] integerValue];
}

- (BOOL)isCallback
{
    return self.status != 0;
}

@end
