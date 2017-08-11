//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaPropertyTrigger.h"
NS_ASSUME_NONNULL_BEGIN
/**
 An internal header for SDK use only.
 */
@interface AylaPropertyTrigger (Internal)
/**
 The key assigned by the cloud.
 */
@property (strong, nonatomic) NSNumber *key;
/**
 Initializes the instance from the `NSDictionary` received from the cloud.

 @param dictionary The dictionary received from the cloud.
 @param property   The parent `AylaProperty`.
 @param error      A pointer to `NSError` that will be filled in case of error.

 @return An initialized `AylaPropertyTrigger`
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                              property:(AylaProperty *)property
                                 error:(NSError *__autoreleasing _Nullable *)error;
@end

FOUNDATION_EXPORT NSString *const attrNamePropertyTriggerTriggerType;
FOUNDATION_EXPORT NSString *const attrNamePropertyTriggerCompareType;
FOUNDATION_EXPORT NSString *const attrNamePropertyTriggerValue;
FOUNDATION_EXPORT NSString *const attrNamePropertyTriggerDeviceNickname;
FOUNDATION_EXPORT NSString *const attrNamePropertyTriggerPropertyNickname;
FOUNDATION_EXPORT NSString *const attrNamePropertyTriggerActive;
NS_ASSUME_NONNULL_END
