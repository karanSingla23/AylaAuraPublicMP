//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaOTAImageInfo.h"

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaSystemUtils.h"
#import "NSObject+Ayla.h"

static NSString *const kAylaOTAAttrNameLANOTA = @"lanota";

static NSString *const kAylaOTAAttrNameUrl       = @"url";
static NSString *const kAylaOTAAttrNameVersion   = @"version";
static NSString *const kAylaOTAAttrNameLocation  = @"location";
static NSString *const kAylaOTAAttrNameType      = @"type";
static NSString *const kAylaOTAAttrNameSize      = @"size";

@implementation AylaOTAImageInfo

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    
    if (self) {
        NSDictionary *otaDict = dictionary[kAylaOTAAttrNameLANOTA];
        
        if (otaDict) {
            _url = AYLNilIfNull(otaDict[kAylaOTAAttrNameUrl]);
            _version = AYLNilIfNull(otaDict[kAylaOTAAttrNameVersion]);
            _location = AYLNilIfNull(otaDict[kAylaOTAAttrNameLocation]);
            _type = AYLNilIfNull(otaDict[kAylaOTAAttrNameType]);
            _size = AYLNilIfNull(otaDict[kAylaOTAAttrNameSize]);
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{url:%@, version:%@, location:%@, type:%@, size:%@}", self.url, self.version, self.location, self.type, self.size];
}
@end
