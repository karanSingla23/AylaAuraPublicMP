//
//  AylaDatum.m
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatum.h"

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaSystemUtils.h"
#import "NSObject+Ayla.h"

static NSString *const kAylaDatumAttrNameDatum = @"datum";

static NSString *const kAylaDatumAttrNameKey = @"key";
static NSString *const kAylaDatumAttrNameValue = @"value";
static NSString *const kAylaDatumAttrNameCreatedAt = @"created_at";
static NSString *const kAylaDatumAttrNameUpdatedAt = @"updated_at";

@implementation AylaDatum

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];

    if (self) {
        NSDictionary *datumDict = dictionary[kAylaDatumAttrNameDatum];

        if (datumDict) {
            _key = AYLNilIfNull(datumDict[kAylaDatumAttrNameKey]);
            _value = AYLNilIfNull(datumDict[kAylaDatumAttrNameValue]);

            NSDateFormatter *timeFormater = [AylaSystemUtils defaultDateFormatter];
            _createdAt = [timeFormater dateFromString:AYLNilIfNull(datumDict[kAylaDatumAttrNameCreatedAt])];
            _updatedAt = [timeFormater dateFromString:AYLNilIfNull(datumDict[kAylaDatumAttrNameUpdatedAt])];
        }
    }

    return self;
}

@end
