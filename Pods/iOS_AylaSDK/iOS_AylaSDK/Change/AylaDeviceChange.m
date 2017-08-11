//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"
#import "AylaDeviceChange.h"

@implementation AylaDeviceChange

- (instancetype)initWithDevice:(AylaDevice *)device changedFields:(nonnull NSSet *)changedFields
{
    self = [super initWithChangedFields:changedFields];
    if (!self) return nil;

    _device = device;

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, devDsn: %@, fields: %@> ",
                                      NSStringFromClass([self class]),
                                      self,
                                      self.device.dsn,
                                      self.changedFields];
}

@end
