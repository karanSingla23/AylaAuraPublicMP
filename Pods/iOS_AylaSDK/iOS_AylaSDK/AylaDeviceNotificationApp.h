//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AylaServiceApp.h"
NS_ASSUME_NONNULL_BEGIN
/**
 `AylaDeviceNotificationApp` objects are applications that are triggered when an `AylaDeviceNotification` condition is triggered.
 */
@interface AylaDeviceNotificationApp : AylaServiceApp

/** @name Notification App Properties */

/** ID assigned by the cloud */
@property (nonatomic, strong, readonly) NSNumber *id;

@end
NS_ASSUME_NONNULL_END
