//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDeviceGateway;
/**
 *  A type of `AylaDevice` that must be registered and connected to the Ayla Service through an `AylaDeviceGateway`
 */
@interface AylaDeviceNode : AylaDevice
/** @name Node Properties */

/** The `AylaDeviceGateway` to which the node belongs */
@property (nonatomic, weak, readonly, getter=gateway, nullable) AylaDeviceGateway *gateway;

/** DSN of the `AylaDeviceGateway` to which the node belongs */
@property (nonatomic, readonly) NSString *gatewayDsn;

/** Type of node */
@property (nonatomic, readonly) NSString *nodeType;
@end

NS_ASSUME_NONNULL_END
