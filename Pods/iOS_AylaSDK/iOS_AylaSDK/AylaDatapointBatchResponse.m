//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint+Internal.h"
#import "AylaDatapointBatchResponse.h"
#import "AylaDefines.h"
#import "AylaObject+Internal.h"
#import "NSObject+Ayla.h"

@implementation AylaDatapointBatchResponse
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        _statusCode = [dictionary[@"status"] nilIfNull];
        _deviceDsn = dictionary[@"dsn"];
        _propertyName = dictionary[@"name"];
        _datapoint = [[AylaDatapoint alloc] initWithJSONDictionary:dictionary[@"datapoint"] dataSource:AylaDataSourceCloud error:nil];
    }
    return self;
}
@end
