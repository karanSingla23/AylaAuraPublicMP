//
//  AylaDevice+Extensible.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 12/14/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"
#import "AylaProperty.h"
#import "AylaDatapoint.h"
#import "AylaSessionManager.h"
#import "AylaHTTPClient.h"
#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN
extern NSString *const AylaDeviceConnectionStatusOnline;
extern NSString *const AylaDeviceConnectionStatusOffline;
@interface AylaDevice (Extensible)

@property(nonatomic, readwrite, nullable) NSNumber *key;
@property(nonatomic, readwrite, nullable) NSString *productName;
@property(nonatomic, readwrite, nullable) NSString *model;
@property(nonatomic, readwrite, nullable) NSString *dsn;
@property(nonatomic, readwrite, nullable) NSString *oemModel;
@property(nonatomic, readwrite, nullable) NSString *deviceType;
@property(nonatomic, readwrite, nullable) NSDate *connectedAt;
@property(nonatomic, readwrite, nullable) NSString *mac;
@property(nonatomic, readwrite, nullable) NSString *lanIp;
@property(nonatomic, readwrite, nullable) NSString *swVersion;
@property(nonatomic, readwrite, nullable) NSString *ssid;
@property(nonatomic, readwrite, nullable) NSString *productClass;
@property(nonatomic, readwrite, nullable) NSString *ip;
@property(nonatomic, readwrite, nullable) NSNumber *lanEnabled;
@property(nonatomic, readwrite, nullable) NSString *connectionStatus;
@property(nonatomic, readwrite, nullable) NSNumber *templateId;
@property(nonatomic, readwrite, nullable) NSString *lat;
@property(nonatomic, readwrite, nullable) NSString *lng;
@property(nonatomic, readwrite, nullable) NSNumber *userId;
@property(nonatomic, readwrite, nullable) NSString *moduleUpdatedAt;

/** Indicates whether lan mode is unavailable */
@property(nonatomic, assign, readwrite) BOOL lanModeUnavailable;

/**
 Update device with another copy.

 @param device Device to use as update
 @param dataSource Source of the data
 */
- (void)updateFrom:(AylaDevice *)device dataSource:(AylaDataSource)dataSource;

/**
 Initializes an extensible device to be mutated by a plugin

 @return An initialized Extensible device
 */
- (instancetype)initExtensible;

/**
 Converts the device to its json representation

 @return The dictionary representing the instance
 */
- (NSDictionary *)toJSONDictionary;

/**
 Intializes the device with the specified dictionary

 @param dictionary The dictionary of JSON properties to initialize the device
 @param error Variable to write in case of error
 @return An initialized device
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error;


/**
 Intializes the device with the specified dictionary and deviceManager

 @param deviceManager The manager of the device
 @param dictionary The dictionary of JSON properties to initialize the device
 @param error Variable to write in case of error
 @return An initialized device
 */
- (instancetype)initWithDeviceManager:(AylaDeviceManager *)deviceManager
                       JSONDictionary:(NSDictionary *)dictionary
                                error:(NSError *__autoreleasing _Nullable *)error;
/**
 * Use this method to notify changes to all listeners.
 *
 * @param changes An array of changes.
 */
- (void)notifyChangesToListeners:(NSArray *)changes;


/**
 * Use this method to update properties with pass-in property array.
 *
 * @note This method must be called through processing queue. Right now this
 * method will never remove any properties
 * from device object.
 *
 * @param properties An array of `AylaLocalProperty` with the new values.
 *
 * @return A list of AylaPropertyChange
 */
- (NSArray AYLA_GENERIC(AylaPropertyChange *) *)updateProperties:(NSArray *)properties;
@end

@interface AylaProperty (Extensible)

/**
 * Use this method to update a property with a copy from cloud.
 *
 * @param property The copy current property updates from.
 *
 * @return A AylaPropertyChange object to indicate if changes have been observed in this property.
 */
- (nullable AylaPropertyChange *)updateFrom:(AylaProperty *)property dataSource:(AylaDataSource)dataSource;

/**
 * Use this method to update a property from a datapoint
 *
 * @param datapoint A datapoint current property updates from.
 *
 * @return A AylaPropertyChange object to indicate if changes have been observed in this property.
 */
- (nullable AylaPropertyChange *)updateFromDatapoint:(AylaDatapoint *)datapoint;



/** A reference to the device that owns the property */
@property (nonatomic, weak) AylaDevice *device;

/** Property Name */
@property (nonatomic, strong) NSString *name;

/** The property's base type (AylaPropertyBaseTypeString, etc) */
@property (nonatomic, strong) NSString *baseType;

/** Property Type */
@property (nonatomic, strong) NSString *type;

/** Direction. That is from device ("output") or to device ("input") */
@property (nonatomic, strong) NSString *direction;

/** The name for the property that will be displayed to app's user.*/
@property (nonatomic, strong) NSString *displayName;

/** Last updated data timestamp */
@property (nonatomic, strong, nullable) NSDate *dataUpdatedAt;

/** If Datapoint Ack has been enabled for current property  */
@property (nonatomic, assign) BOOL ackEnabled;

/** Timestamp indicating when datapoint ack was received. */
@property (nonatomic, strong, nullable) NSDate *ackedAt;

/** Datapoint ack status */
@property (nonatomic, assign) NSInteger ackStatus;

/** Datapoint ack message */
@property (nonatomic, assign) NSInteger ackMessage;

/** The AylaDataSource representing the service used to last update this property's status. */
@property (nonatomic, assign) AylaDataSource lastUpdateSource;

@property (nonatomic, readwrite) AylaDatapoint *datapoint;
@end

@interface AylaDatapoint (Extensible)

/** @name Datapoint Properties */

/** ID of datapoint */
@property (nonatomic, strong, nullable) NSString *id;

/** Value of datapoint */
@property (nonatomic, copy) id value;

/** Dictionary of metadata */
@property (nonatomic, strong, nullable) NSDictionary *metadata;

/** When datapoint is created. */
@property (nonatomic, strong, nullable) NSDate *createdAt;

/** Lastest updated time */
@property (nonatomic, strong, nullable) NSDate *updatedAt;

/** Timestamp indicating when datapoint ack is received. */
@property (nonatomic, strong, nullable) NSDate *ackedAt;

/** Datapoint ack status */
@property (nonatomic, assign) NSInteger ackStatus;

/** Datapoint ack message */
@property (nonatomic, assign) NSInteger ackMessage;

/** Created at time generated by device */
@property (nonatomic, strong, nullable) NSDate *createdAtFromDevice;

/** Data source of this datapoint */
@property (nonatomic, assign) AylaDataSource dataSource;
@end

@interface AylaSessionManager (Extensible)

/**
 * Get a http client.
 *
 * @param type The type of requested HTTP client.
 */
- (nullable AylaHTTPClient *)getHttpClientWithType:(AylaHTTPClientType)type;
@end
NS_ASSUME_NONNULL_END
