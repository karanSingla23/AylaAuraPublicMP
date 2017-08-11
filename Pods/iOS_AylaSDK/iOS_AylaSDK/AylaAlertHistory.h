//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"


/** Enum with Filters that can be applied to the alert history */
typedef NS_ENUM(NSInteger, AlertHistoryFilter) {
    /** Property name */
    AlertHistoryFilterPropertyName = 0,
    /** Property Description */
    AlertHistoryFilterPropertyDescription,
    /** Value */
    AlertHistoryFilterPropertyValue,
    /** Date the alert was triggered at */
    AlertHistoryFilterTriggerTriggeredAt,
    /** Trigger description */
    AlertHistoryFilterTriggerDescription,
    /** Trigger App Description */
    AlertHistoryFilterTriggerAppDescription,
    /** Can be "email", "sms", "push_ios", "push_android", "push_baidu" */
    AlertHistoryFilterAlertType,
    /** Content of the alert */
    AlertHistoryFilterAlertContent,
    /** Filer Content Description */
    AlertHistoryFilterContentDescription,
};

/** Operators for the alert history filters */
typedef NS_ENUM (NSInteger, AylaFilterOperator) {
    /** Exact match exclusion */
    AylaFilterOperatorNot = 0,
    /** Partial match */
    AylaFilterOperatorLike,
    /** Partial match exclusion */
    AylaFilterOperatorNotLike,
    /** reater than */
    AylaFilterOperatorGreaterThan,
    /** Greater than or equals */
    AylaFilterOperatorGreaterThanOrEqualTo,
    /** Less than */
    AylaFilterOperatorLessThan,
    /** Less than or equals */
    AylaFilterOperatorLessThanOrEqualTo,
    /** Values are in a comma separated list */
    AylaFilterOperatorIn,
    /** Values are in a comma separated list */
    AylaFilterOperatorNotIn,
    /** Exact match */
    AylaFilterOperatorEqualTo
};


/** Provides a way to filter alert histories */
@interface AylaAlertFilter : NSObject

/**
 * Create a filter for alert history requests. If this method is called with the same
 * filter and operator combination, the previous entry will be replaced.
 * @param filter Field to filter. `AlertHistoryFilter`
 * @param fOperator Valid operator for the filter `AylaFilterOperator`.
 * @param operand A single value or a set of comma separated values to be passed as a single
 *                string. eg: "Blue_LED,Blue_button"
 *
 * For example,
 *                To exclude all alerts with property name Blue_LED, use
 *                add(PropertyName, Not,"Blue_LED")
 *
 *                To exclude results with property names Blue_LED and Blue_button, use
 *                add(PropertyName, Notin, "Blue_LED,Blue_button");
 *
 */
- (void)addFilter:(AlertHistoryFilter)filter operator:(AylaFilterOperator)fOperator operand:(NSString *)operand;

/**
 * Constructs the filter parameters for the fetch API.
 *
 * @return An NSDictionary that can be passed to the fetch API to filter histories.
 */
- (NSDictionary *)build;
@end


/** This class represents the content in the alert. */
@interface AylaAlertContent : NSObject

/** Message sent in the alert */
@property (nonatomic, strong) NSString *message;
@end


/** Class representing a sent alert */
@interface AylaAlertHistory : AylaObject

/** ID of the OEM */
@property (nonatomic, strong)NSString *oem;

/** Date the alert was triggered at */
@property (nonatomic, strong)NSString *sentAt;

/** ID of the `AylaProperty` */
@property (nonatomic, strong)NSString *propertyId;

/** Description of alert property */
@property (nonatomic, strong)NSString *propertyDescription;

/** Name of the property that triggered the alert */
@property (nonatomic, strong)NSString *propertyName;

/** Value of the property when alert was triggered */
@property (nonatomic, strong)NSString *propertyValue;

/** Date the data was updated at */
@property (nonatomic, strong)NSString *propertyDataUpdatedAt;

/** Date the alert was triggered at Timezone of the device */
@property (nonatomic, strong)NSString *propertyDataUpdatedAtDeviceTz;

/** ID of the `AylaPropertyTrigger` that fired the alert */
@property (nonatomic, strong)NSString *triggerId;

/** Trigger description */
@property (nonatomic, strong)NSString *triggerDescription;

/** Date the alert was triggered at */
@property (nonatomic, strong)NSString *triggerTriggeredAt;

/** Trigger App Description */
@property (nonatomic, strong)NSString *triggerAppDescription;

/** Can be "email", "sms", "push_ios", "push_android", "push_baidu" */
@property (nonatomic, strong)NSString *alertType;

/** Content sent with the alert */
@property (nonatomic, strong)AylaAlertContent *alertContent;

/** Filer Content Description */
@property (nonatomic, strong)NSString *contentDescription;

@end
