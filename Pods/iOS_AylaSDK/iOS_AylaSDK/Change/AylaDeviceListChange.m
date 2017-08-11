//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDeviceListChange.h"

@implementation AylaDeviceListChange
@dynamic addedItems;
@dynamic removedItemIdentifiers;

- (instancetype)initWithAddedDevices:(NSSet AYLA_GENERIC(AylaDevice *) *)addedDevices
                       removeDevices:(NSSet AYLA_GENERIC(AylaDevice *) *)removedDevices
{
    // Get identifiers from passed in removed device list
    NSSet *removedDsns = [removedDevices valueForKeyPath:@"@distinctUnionOfObjects.dsn"];
    return [super initWithAddedItems:addedDevices removeItems:removedDsns];
}

@end
