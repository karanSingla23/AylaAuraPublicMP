//
//  AylaDatapointParams.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatapointParams.h"

@implementation AylaDatapointParams

- (NSDictionary *)toCloudJSONDictionary
{
    return @{
             NSStringFromSelector(@selector(value)) : self.value?:[NSNull null],
             NSStringFromSelector(@selector(metadata)) : self.metadata?:[NSNull null]
             };
}

- (instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        _data = data;
    }
    return self;
}

- (instancetype)initWithFilePath:(NSURL *)filePath {
    if (self = [super init]) {
        _filePath = filePath;
    }
    return self;
}
@end
