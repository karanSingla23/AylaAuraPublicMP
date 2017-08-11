//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint16_t, AylaLanCommandType) {
    AylaLanCommandTypeUnknown,
    AylaLanCommandTypeCommand,
    AylaLanCommandTypeProperty,
    AylaLanCommandTypeNodeProperty
};

@class AylaDatapointParams;
@class AylaLanCommand;
@class AylaLanMessage;
@class AylaProperty;

typedef void (^ProcessingBlock)(AylaLanCommand *command, BOOL isSent);
typedef void (^CallbackBlock)(AylaLanCommand *command, id _Nullable responseObject, NSError *_Nullable error);

/**
 * AylaLanCommand
 */
@interface AylaLanCommand : NSObject

/** Current supported lan command type */
@property (nonatomic, readonly) AylaLanCommandType type;

/** Assigned command id */
@property (nonatomic, readonly) NSUInteger cmdId;

/** Json command */
@property (nonatomic, nullable) id commandInJson;

/** If current command has been cancelled */
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

/** Process block will be invoked when command is in progress */
@property (nonatomic, copy, nullable) ProcessingBlock processingBlock;

/** Callblock block of current command */
@property (nonatomic, copy, nullable) CallbackBlock callbackBlock;

/** If YES, callback block will be called after a response of command has been recevied */
@property (nonatomic) BOOL needsWaitResponse;

/** Response object returned from lan module */
@property (nonatomic, nullable) id responseObject;

/** Response error */
@property (nonatomic, nullable) NSError *error;

/** Command identifier */
@property (nonatomic, nullable) NSString *identifier;

/**
 * Init method
 */
- (instancetype)initWithType:(AylaLanCommandType)type commandInJson:(nullable id)jsonObject;

/**
 * Encapsulated command with self.commandInJson
 */
- (NSDictionary *)encapulatedCommandInJson;

#pragma mark - Secure Setup

/**
 * Helpful method to create a GET device details command during secure WiFi Setup.
 *
 * @return The LAN Command to perform the action.
 */
+ (instancetype)GETDeviceDetailsCommand;

/**
 * Helpful method to create a PUT device time command during secure WiFi Setup.
 *
 * @param time New time
 * @return The LAN Command to perform the action.
 */
+ (instancetype)PUTNewDeviceTimeCommand:(NSNumber *)time;

/**
 * Helpful method to create a POST start scanning APs during secure WiFi Setup.
 *
 * @return The LAN Command to perform the action.
 */
+ (instancetype)POSTStartScanCommand;

/**
 * Helpful method to create a GET a list of found APs command during secure WiFi Setup.
 *
 * @return The LAN Command to perform the action.
 */
+ (instancetype)GETWiFiScanResults;

/**
 * Helpful method to create a PUT command to stop AP during secure WiFi Setup.
 *
 * @return The LAN Command to perform the action.
 */
+ (instancetype)PUTStopAPCommand;

/**
 * Helpful method to create a GET WiFi status command during secure WiFi Setup.
 *
 * @return The LAN Command to perform the action.
 */
+ (instancetype)GETWiFiStatusCommand;

#pragma mark - LAN Mode
/**
 * Helpful method to create a GET property command with property name and data.
 *
 * @param propertyName The property name of requested property.
 * @param data         Data which puts inside command.
 */
+ (instancetype)GETPropertyCommandWithPropertyName:(NSString *)propertyName data:(nullable id)data;

/**
 * Helpful method to create a GET node property command with dsn, property name and data.
 *
 * @param dsn          Dsn of the node.
 * @param propertyName The property name of requested property.
 * @param data         Data which puts inside command.
 */
+ (instancetype)GETNodePropertyCommandWithNodeDsn:(NSString *)dsn
                                     propertyName:(NSString *)propertyName
                                             data:(nullable id)data;

/**
 * Helpful method to create a POST datapoint command with property and datapoint params.
 *
 * @param property The requested property
 * @param params   Datapoint params of the new datapoint.
 */
+ (instancetype)POSTDatapointCommandWithProperty:(AylaProperty *)property datapointParams:(AylaDatapointParams *)params;

/**
 * Helpful method to create a POST node datapoint command with node dsn, node property and datapoint params.
 *
 * @param dsn      Dsn of the node.
 * @param property The requested node property
 * @param params   Datapoint params of the new datapoint.
 */
+ (instancetype)POSTNodeDatapointCommandWithNodeDsn:(NSString *)dsn
                                       nodeProperty:(AylaProperty *)property
                                    datapointParams:(AylaDatapointParams *)params;

/**
 * Use this method to create a connect command.
 *
 * @param SSID       SSID of the access point.
 * @param password   Password of that SSID. Pass nil if no password is required for input SSID.
 * @param setupToken Setup token which will be sent to module.
 * @param latitude   Latitude location of device
 * @param longitude  Longitude location of device
 *
 * @return A lan command instance.
 */
+ (instancetype)ConnectCommandWithSSID:(NSString *)SSID
                              password:(nullable NSString *)password
                            setupToken:(NSString *)setupToken
                              latitude:(double)latitude
                            longitude:(double)longitude;

/**
 * Use this method to cancel current command.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
