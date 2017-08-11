//
//  AylaDeviceClassPlugin.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaPlugin.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * The `AylaDeviceClassPlugin` interface allows implementers to specify the specific AylaDevice-derived
 * class that should be created within the AylaDeviceManager. When device objects are to be
 * created, the AylaDeviceManager will first check with the registered `AylaDeviceClassPlugin`, if
 * present, to determine what subtype to create.
 *
 * This allows application developers to create AylaDevice-derived classes to support
 * device-specific functionality, while having these objects created in place of `AylaDevice`
 * objects within `AylaDeviceManager`.
 */
@protocol AylaDeviceClassPlugin <AylaPlugin>
/**
 * Returns the AylaDevice-derived class for a given model, oemModel and unique identifier.
 * These fields are obtained from device JSON and passed to this method. The method should
 * return the appropriate class to create given the supplied parameters. These parameters may
 * be null if the fields did not exist in the original JSON.
 *
 * If no matching class can be found, this method should return null to indicate it does not
 * support devices with the given model, oemModel or unique ID.
 *
 * The AylaDeviceManager depends on this method returning the appropriate class type so that
 * local devices may be constructed properly.
 *
 * A plugin implementing this interface should be installed with the plugin ID of PLUGIN_ID_DEVICE_CLASS.
 *
 * @param model Model of the device
 * @param oemModel OEM model of the device
 * @param uniqueId Unique identifier for this device
 *
 * @return an AylaDevice-derived class object which will be used to construct this device object.
 */
- (nullable Class)deviceClassForModel:(NSString *)model oemModel:(NSString *)oemModel uniqueId:(NSString *)uniqueId;
@end
NS_ASSUME_NONNULL_END
