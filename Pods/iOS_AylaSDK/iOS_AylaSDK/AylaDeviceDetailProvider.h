//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AylaDevice;
@class AylaProperty;
/**
 * Describes an object that can curate a subset of property names for a device
 */
@protocol AylaDeviceDetailProvider<NSObject>

/**
 * @param device The `AylaDevice` ofr which the monitored property list is requested.
 * @return An `NSArray` of property names that the current `AylaDeviceManager` should keep up-to-date for passed in device. 
 * If this method returns nil for a given device, all properties will be fetched for that device.
 */
- (nullable NSArray *)monitoredPropertyNamesForDevice:(AylaDevice *)device;

@end

NS_ASSUME_NONNULL_END
