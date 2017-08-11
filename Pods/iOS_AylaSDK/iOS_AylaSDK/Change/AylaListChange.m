//
//  AylaListChange.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaListChange.h"

@implementation AylaListChange

- (instancetype)initWithAddedItems:(NSSet *)addedItems
                       removeItems:(NSSet *)removedItemIdentifiers
{
    self = [super init];
    if(!self) return nil;
    
    _addedItems = addedItems;
    _removedItemIdentifiers = removedItemIdentifiers;
    
    return self;
}

@end
