//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint.h"
#import "AylaDatapointBatchRequest.h"
#import "AylaDefines_Internal.h"
#import "AylaDevice.h"
#import "AylaObject+Internal.h"
#import "AylaProperty.h"

@implementation AylaDatapointBatchRequest
- (instancetype)initWithDatapoint:(AylaDatapointParams *)datapointParams property:(AylaProperty *)property
{
    AYLAssert(datapointParams.value != nil, @"Datapoint value should not be nil");
    AYLAssert(property.name != nil, @"Property name should not be nil");
    AYLAssert(property.baseType != nil, @"Property baseType should not be nil");
    AYLAssert(property.device.dsn != nil, @"Owner Device dsn should not be nil");

    if (self = [super init]) {
        _datapoint = datapointParams;
        _property = property;
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    return @{
        @"datapoint" : [self.datapoint toCloudJSONDictionary],
        @"name" : self.property.name,
        @"dsn" : AYLNullIfNil(self.property.device.dsn)
    };
}
@end
