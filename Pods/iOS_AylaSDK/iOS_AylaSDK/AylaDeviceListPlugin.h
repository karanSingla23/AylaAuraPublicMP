//
//  AylaDeviceListPlugin.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/7/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The DeviceListPlugin provides a means to modify the list of AylaDevice objects by
 * AylaDeviceManager before they are used to update the running device list.
 *
 * Implementers of this plugin class must return an array of AylaDevice-derived objects from the
 * `[AylaDeviceListPlugin updateDeviceDictionary:]` method. This list will be used by AylaDeviceManager.
 *
 * It is important to note that the `updateDeviceDictionary:` method will be called multiple times, and
 * should return the same set of objects each time. Returning a new set of objects will result in
 * problems with existing listener interfaces and live device objects owned by `AylaDeviceManager`.
 *
 * Changes to existing device objects should be handled via calls to
 * `[AylaDevice updateFrom:dataSource:]` to perform updates rather than creating new objects.
 */
@protocol  AylaDeviceListPlugin <AylaPlugin>

/**
 * Called by the `AylaDeviceManager` after merging the list of devices from the Ayla cloud
 * service. The provided map is the same map used by `AylaDeviceManager` for device management.
 * Implementers may update or modify the master device map in this method.
 *
 * @param devices Dictionary of DSN and device pairs from the device manager
 */
- (void)updateDeviceDictionary:(NSDictionary<NSString *,AylaDevice *>*)devices;
@end
NS_ASSUME_NONNULL_END
