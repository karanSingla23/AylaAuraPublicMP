//
//  AylaLanConfig.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLanConfig.h"
#import "AylaObject+Internal.h"
#import "NSObject+Ayla.h"

static NSString *const attrNameKeepAlive = @"keep_alive";
static NSString *const attrNameLanipKey = @"lanip_key";
static NSString *const attrNameLanipKeyId = @"lanip_key_id";
static NSString *const attrNameStatus = @"status";

@implementation AylaLanConfig

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                 error:(NSError *__autoreleasing _Nullable *)
                                           error {
  self = [super initWithJSONDictionary:dictionary error:error];
  if (!self)
    return nil;

  _keepAlive = [dictionary[attrNameKeepAlive] nilIfNull];
  _lanipKey = [dictionary[attrNameLanipKey] nilIfNull];
  _lanipKeyId = [dictionary[attrNameLanipKeyId] nilIfNull];
  _status = [dictionary[attrNameStatus] nilIfNull];

  return self;
}

- (NSDictionary *)toJSONDictionary {
  NSMutableDictionary *dictionary =
      [NSMutableDictionary dictionaryWithDictionary:[super toJSONDictionary]];
  dictionary[attrNameKeepAlive] = _keepAlive;
  dictionary[attrNameLanipKey] = _lanipKey;
  dictionary[attrNameLanipKeyId] = _lanipKeyId;
  dictionary[attrNameStatus] = _status;

  return dictionary;
}

@end

@implementation AylaLanConfig (NSCoding)

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super init]) {
    _keepAlive = [aDecoder decodeObjectForKey:attrNameKeepAlive];
    _lanipKey = [aDecoder decodeObjectForKey:attrNameLanipKey];
    _lanipKeyId = [aDecoder decodeObjectForKey:attrNameLanipKeyId];
    _status = [aDecoder decodeObjectForKey:attrNameStatus];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_keepAlive forKey:attrNameKeepAlive];
  [aCoder encodeObject:_lanipKey forKey:attrNameLanipKey];
  [aCoder encodeObject:_lanipKeyId forKey:attrNameLanipKeyId];
  [aCoder encodeObject:_status forKey:attrNameStatus];
}

@end