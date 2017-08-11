//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaProperty.h"
#import "AylaPropertyChange.h"

@implementation AylaPropertyChange

- (instancetype)initWithProperty:(AylaProperty *)property changedFields:(NSSet AYLA_GENERIC(NSString *) *)fields
{
    self = [super initWithChangedFields:fields];
    if (!self) return nil;

    _property = property;

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, propName: %@, fields: %@> ",
                                      NSStringFromClass([self class]),
                                      self,
                                      self.property.name,
                                      self.changedFields];
}

@end
