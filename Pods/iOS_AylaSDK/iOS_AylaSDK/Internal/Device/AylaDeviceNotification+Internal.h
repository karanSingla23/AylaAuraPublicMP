//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDeviceNotification.h"
NS_ASSUME_NONNULL_BEGIN
/**
 For internal SDK purposes, do not use in app layer.
 */
@interface AylaDeviceNotification (Internal)

/** Associated device */
@property (nonatomic, weak, readwrite) AylaDevice *device;

/** ID of the AylaDeviceNotification */
@property (strong, nonatomic) NSNumber *id;

/**
 Initializes the instance from the specified dictionary.

 @param dictionary The dictionary fetched from the cloud.
 @param device     The parent `AylaDevice`
 @param error      A pointer to an `NSError` that will be filled in case of error.

 @return An initalized instance.
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                device:(AylaDevice *)device
                                 error:(NSError *__autoreleasing _Nullable *)error;
@end
NS_ASSUME_NONNULL_END