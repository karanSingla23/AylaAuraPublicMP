//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaAlertHistory.h"
#import "AylaObject+Internal.h"

@interface AylaAlertFilter ()
@property (nonatomic, strong) NSMutableDictionary *filterDictionary;
@end

@implementation AylaAlertFilter
- (instancetype)init {
    if (self = [super init]) {
        _filterDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}
+ (NSString *)filterToString:(AlertHistoryFilter)filter {
    switch (filter) {
        case AlertHistoryFilterPropertyName:
            return @"property_name";
        case AlertHistoryFilterPropertyDescription:
            return @"property_description";
        case AlertHistoryFilterPropertyValue:
            return @"property_value";
        case AlertHistoryFilterTriggerTriggeredAt:
            return @"trigger_triggered_at";
        case AlertHistoryFilterTriggerDescription:
            return @"trigger_description";
        case AlertHistoryFilterTriggerAppDescription:
            return @"trigger_app_description";
        case AlertHistoryFilterAlertType:
            return @"alert_type";
        case AlertHistoryFilterAlertContent:
            return @"alert_content";
        case AlertHistoryFilterContentDescription:
            return @"content_description";
        default:
            return nil;
    }
    
}

+ (NSString *)operatorToString:(AylaFilterOperator)operator {
    switch (operator) {
        case AylaFilterOperatorNot:
            return @"_not"; // Exact match exclusion
        case AylaFilterOperatorLike:
            return @"_like"; // Partial match
        case AylaFilterOperatorNotLike:
            return @"_notlike"; //Partial match exclusion
        case AylaFilterOperatorGreaterThan:
            return @"_gt"; //Greater than
        case AylaFilterOperatorGreaterThanOrEqualTo:
            return @"_gte"; // Greater than or equals
        case AylaFilterOperatorLessThan:
            return @"_lt"; // Less than
        case AylaFilterOperatorLessThanOrEqualTo:
            return @"_lte"; //Less than or equals
        case AylaFilterOperatorIn:
            return @"_in"; // Values are in a comma separated list
        case AylaFilterOperatorNotIn:
            return @"_notin"; // Values are in a comma separated list
        case AylaFilterOperatorEqualTo: 
            return @"_eq"; // Exact match
            
        default:
            return nil;
    }
}

- (void)addFilter:(AlertHistoryFilter)filter operator:(AylaFilterOperator)fOperator operand:(NSString *)operand {
    NSString *filterKey = [NSString stringWithFormat:@"%@%@",[AylaAlertFilter filterToString:filter],[AylaAlertFilter operatorToString:fOperator]];
    self.filterDictionary[filterKey] = operand;
}

- (NSDictionary *)build {
    return self.filterDictionary;
}
@end

@implementation AylaAlertHistory
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing  _Nullable *)error {
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        _oem = dictionary[@"oem"];
        _sentAt = dictionary[@"sent_at"];
        _propertyId = dictionary[@"property_id"];
        _propertyName = dictionary[@"property_name"];
        _propertyValue = dictionary[@"property_value"];
        _propertyDataUpdatedAt = dictionary[@"property_data_updated_at"];
        _propertyDataUpdatedAtDeviceTz = dictionary[@"property_data_updated_at_device_tz"];
        _triggerId = dictionary[@"trigger_id"];
        _triggerTriggeredAt = dictionary[@"trigger_triggered_at"];
        _alertType = dictionary[@"alert_type"];
        _alertContent = dictionary[@"alert_content"];
    }
    return self;
}
@end
