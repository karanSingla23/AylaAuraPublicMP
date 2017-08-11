//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaFieldChange.h"

@implementation AylaFieldChange

- (instancetype)initWithChangedFields:(NSSet *)changedFields
{
    self = [super init];
    if (!self) return nil;

    _changedFields = changedFields;

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"FieldChange: [%@]", self.changedFields];
}

@end
