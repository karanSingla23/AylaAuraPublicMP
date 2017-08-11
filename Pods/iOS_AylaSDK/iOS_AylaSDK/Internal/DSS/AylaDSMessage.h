//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint32_t, AylaDSMessageEventType) {
    AylaDSMessageEventTypeUnknown,
    AylaDSMessageEventTypeDatapoint,
    AylaDSMessageEventTypeDatapointAck,
    AylaDSMessageEventTypeConnectivity,
};

@class AylaDatapoint;
@class AylaDeviceConnection;
@class AylaDSMetadata;
@class AylaProperty;

@interface AylaDSMessage : AylaObject

@property (nonatomic, strong, readonly) NSString *seq;
@property (nonatomic, strong, readonly) AylaDSMetadata *metadata;

@property (nonatomic, strong, readonly, nullable) AylaDatapoint *datapoint;
@property (nonatomic, strong, readonly, nullable) AylaDeviceConnection *connection;
@end

@interface AylaDSMetadata : AylaObject

/** Device OEM id */
@property (nonatomic, readonly, nullable) NSString *oemId;

/** Device serial number */
@property (nonatomic, readonly, nullable) NSString *dsn;

/** Device OEM model */
@property (nonatomic, readonly, nullable) NSString *oemModel;

/** Event type */
@property (nonatomic, readonly) AylaDSMessageEventType eventType;

/** Base type */
@property (nonatomic, readonly) NSString *baseType;

/** Property name */
@property (nonatomic, readonly, nullable) NSString *propertyName;

/** Display name */
@property (nonatomic, readonly, nullable) NSString *displayName;

@end

NS_ASSUME_NONNULL_END
