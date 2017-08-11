//
//  AylaLocalOTACommand.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaLocalOTACommand.h"
#import "AylaObject+Internal.h"

@implementation AylaLocalOTACommand
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing  _Nullable *)error {
    if (self = [super initWithJSONDictionary:dictionary error:nil]) {
        _url = dictionary[@"url"];
        _type = dictionary[@"type"];
        _ver = dictionary[@"ver"];
        _size = [dictionary[@"size"] integerValue];
        _checksum = dictionary[@"checksum"];
        _source = dictionary[@"source"];
        _apiUrl = dictionary[@"api_url"];
    }
    return self;
}
@end
