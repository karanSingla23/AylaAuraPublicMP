//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaCache+Internal.h"
#import "AylaConnectTask.h"
#import "AylaDatapoint+Internal.h"
#import "AylaDatum+Internal.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceChange.h"
#import "AylaDeviceConnection.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceManager+Internal.h"
#import "AylaDeviceNode.h"
#import "AylaDeviceNotification+Internal.h"
#import "AylaDiscovery.h"
#import "AylaGrant.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPServer.h"
#import "AylaLanCommand.h"
#import "AylaLanMessage.h"
#import "AylaLanModule.h"
#import "AylaLanTask.h"
#import "AylaListenerArray.h"
#import "AylaNetworks+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"
#import "AylaPropertyChange.h"
#import "AylaSchedule+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemUtils.h"
#import "AylaTimeZone.h"
#import "AylaTimer.h"
#import "NSObject+Ayla.h"

static NSString *const attrNameConnectionStatus = @"connection_status";
static NSString *const attrNameConnectedAt = @"connected_at";
static NSString *const attrNameDeviceType = @"device_type";
static NSString *const attrNameDsn = @"dsn";
static NSString *const attrNameGrant = @"grant";
static NSString *const attrNameIp = @"ip";
static NSString *const attrNameKey = @"key";
static NSString *const attrNameLanIp = @"lan_ip";
static NSString *const attrNameLat = @"lat";
static NSString *const attrNameLng = @"lng";
static NSString *const attrNameMac = @"mac";
static NSString *const attrNameModel = @"model";
static NSString *const attrNameOemModel = @"oem_model";
static NSString *const attrNameProductClass = @"product_class";
static NSString *const attrNameProductName = @"product_name";
static NSString *const attrNameSWVersion = @"sw_version";
static NSString *const attrNameTemplateId = @"template_id";

static NSString *const AylaDeviceTypeGateway = @"Gateway";
static NSString *const AylaDeviceTypeNode = @"Node";
static NSString *const AylaNodeTypeLocal = @"Local";

static const NSUInteger DEFAULT_POLL_INTERVAL_MS = 5000;
static const NSUInteger DEFAULT_POLL_LEEWAY_MS = 1000;

static dispatch_queue_t device_processing_queue() {
  static dispatch_queue_t device_processing_queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    device_processing_queue = dispatch_queue_create(
        "com.aylanetworks.device.queue.processing", DISPATCH_QUEUE_SERIAL);
  });
  return device_processing_queue;
}

@interface AylaDevice () <AylaLanModuleInternalDelegate,
                          AylaPropertyInternalDelegate>
{
    BOOL _disableLANUntilNetworkChanges;
}

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

@property(nonatomic, readwrite, nullable) NSDictionary *properties;
@property(nonatomic, readwrite, nullable)
    NSMutableDictionary *mutableProperties;

@property(nonatomic, readwrite) BOOL tracking;

@property(nonatomic, readwrite) AylaListenerArray *listeners;
@property(nonatomic, readwrite) AylaTimer *timer;

@property(nonatomic, readwrite) AylaDataSource lastUpdateSource;

/** Lan Module of current device */
@property(nonatomic, readwrite) AylaLanModule *lanModule;

@property(nonatomic, strong, nullable) AylaGrant *grant;

@end

@implementation AylaDevice

- (instancetype)initWithDeviceManager:(AylaDeviceManager *)deviceManager
                       JSONDictionary:(NSDictionary *)dictionary
                                error:(NSError *__autoreleasing _Nullable *)
                                          error {
  self = [self initWithJSONDictionary:dictionary error:error];

  _deviceManager = deviceManager;

  // Set lan mode permitted as YES by default
  _lanModePermitted = YES;

  // Init lan module
  _lanModule = [[AylaLanModule alloc] initWithDevice:self];
  _lanModule.delegate = self;

  return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;
    
    NSDateFormatter *timeFormater = [AylaSystemUtils defaultDateFormatter];
    _key = [dictionary[attrNameKey] nilIfNull];
    _connectionStatus = [dictionary[attrNameConnectionStatus] nilIfNull];
    _connectedAt = [timeFormater dateFromString:[dictionary[attrNameConnectedAt] nilIfNull]];
    _deviceType = [dictionary[attrNameDeviceType] nilIfNull];
    _dsn = [dictionary[attrNameDsn] nilIfNull];
    _ip = [dictionary[attrNameIp] nilIfNull];
    _lanIp = [dictionary[attrNameLanIp] nilIfNull];
    _lat = [dictionary[attrNameLat] nilIfNull];
    _lng = [dictionary[attrNameLng] nilIfNull];
    _mac = [dictionary[attrNameMac] nilIfNull];
    _model = [dictionary[attrNameModel] nilIfNull];
    _oemModel = [dictionary[attrNameOemModel] nilIfNull];
    _productClass = [dictionary[attrNameProductClass] nilIfNull];
    _productName = [dictionary[attrNameProductName] nilIfNull];
    _swVersion = [dictionary[attrNameSWVersion] nilIfNull];
    _templateId = [dictionary[attrNameTemplateId] nilIfNull];
    _listeners = [[AylaListenerArray alloc] init];

    if (dictionary[attrNameGrant]) {
        _grant = [[AylaGrant alloc] initWithJSONDictionary:dictionary[attrNameGrant] error:nil];
    }

    return self;
}

- (NSDictionary *)toJSONDictionary {
    NSDateFormatter *timeFormater = [AylaSystemUtils defaultDateFormatter];
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionary];
    jsonDictionary[attrNameProductName] = self.productName;
    jsonDictionary[attrNameModel] = self.model;
    jsonDictionary[attrNameDsn] = self.dsn;
    jsonDictionary[attrNameOemModel] = self.oemModel;
    jsonDictionary[attrNameDeviceType] = self.deviceType;
    NSString *connectedAt = [timeFormater stringFromDate:self.connectedAt];
    if (connectedAt) {
        jsonDictionary[attrNameConnectedAt] = connectedAt;
    }
    jsonDictionary[attrNameMac] = self.mac;
    jsonDictionary[attrNameLanIp] = self.lanIp;
    jsonDictionary[attrNameIp] = self.ip;
    jsonDictionary[attrNameProductClass] = self.productClass;
    jsonDictionary[attrNameSWVersion] = self.swVersion;
    jsonDictionary[attrNameKey] = self.key;
    return jsonDictionary;
}

/**
 * Update device with other device object
 *
 * @note This method is must be called through processing queue
 */
- (void)updateFrom:(AylaDevice *)device dataSource:(AylaDataSource)dataSource
{
  NSMutableSet *set = [NSMutableSet set];

  // Dsn will not be updated in this method
  NSArray *names = @[
    @"connectionStatus",
    @"deviceType",
    @"ip",
    @"lat",
    @"lng",
    @"mac",
    @"model",
    @"oemModel",
    @"productClass",
    @"productName",
    @"swVersion",
    @"templateId"
  ];

  for (NSString *name in names) {
    id value = [device valueForKey:name];
    if (value) {
      if (![[self valueForKey:name] isEqual:value]) {
        [self setValue:value forKey:name];
        [set addObject:name];
      }
    }
  }

  // check if lanIp has changed, but consider if there's isn't an active lan session
  if (![device.lanIp isEqual:self.lanIp] && !self.isLanModeActive) {
    self.lanIp = device.lanIp;
  }

  self.lastUpdateSource = dataSource;
  AylaDeviceChange *change =
      set.count > 0
          ? [[AylaDeviceChange alloc] initWithDevice:self changedFields:set]
          : nil;

  if (change) {
    [self notifyChangesToListeners:@[ change ]];
  }
}

- (void)updateFromConnection:(AylaDeviceConnection *)deviceConnection dataSource:(AylaDataSource)dataSource {
    if ([self.connectionStatus isEqualToString:deviceConnection.status]) {
        return;
    }
    self.connectionStatus = deviceConnection.status;
    AylaDeviceChange *change = [[AylaDeviceChange alloc] initWithChangedFields:[NSSet setWithObject:NSStringFromSelector(@selector(connectionStatus))]];
    
    [self notifyChangesToListeners:@[ change ]];
}

/**
 * Override setter. Any changes to lanIp will cause lan module to do a refresh
 * attempt.
 */
- (void)setLanIp:(NSString *)lanIp {
  _lanIp = lanIp;
  [self refreshLanSessionIfNecessary];
}

/**
 * Override setter. Any changes to lanModePermitted will cause a call to
 * -adjustLanSessionBasedOnPermitAndStatus.
 */
- (void)setLanModePermitted:(BOOL)lanModePermitted {
  _lanModePermitted = lanModePermitted;
  [self adjustLanSessionBasedOnPermitAndStatus];
}

/**
 * Override setter: Any changes to lanModeUnavailable will cause a call to
 * -adjustLanSessionBasedOnPermitAndStatus.
 */
- (void)setDisableLANUntilNetworkChanges:(BOOL)disableLANUntilNetworkChanges {
  _disableLANUntilNetworkChanges = disableLANUntilNetworkChanges;
  [self adjustLanSessionBasedOnPermitAndStatus];
}

- (BOOL)disableLANUntilNetworkChanges {
    return _disableLANUntilNetworkChanges;
}

/**
 * override setter: Any changes to tracking will cause a call to
 * -adjustPollingBasedOnPermitAndStatus and
 * -adjustLanSessionBasedOnPermitAndStatus.
 */
- (void)setTracking:(BOOL)tracking {
  _tracking = tracking;
  [self adjustPollingBasedOnPermitAndStatus];
  [self adjustLanSessionBasedOnPermitAndStatus];
}

/**
 * This method checks value of lanModePermitted, validLanModeIp, isTracking to
 * determine if lan session should be
 * enabled/disabled.
 */
- (void)adjustLanSessionBasedOnPermitAndStatus {
  // Only enable lan session when preconditions are satisfied
  if (self.lanModePermitted && !self.disableLANUntilNetworkChanges && self.isTracking && !self.grant) {
    [self enableLanSession];
  } else if (self.lanModule.sessionState != AylaLanSessionStateDisabled) {
    // Otherwise, disable lan session of this device.
    [self disableLanSession];
  }
}

/**
 * Use this method to get a appropriate AylaDevice class from input json
 * dictionary
 *
 * @note Input json dictionary must contain contain attribute 'device_type'.
 * Otherwise AylaDevice class will
 * be returned by default.
 */
+ (Class)deviceClassFromJSONDictionary:(NSDictionary *)dictionary {
  NSString *deviceType = dictionary[attrNameDeviceType];
  NSString *model = [dictionary[attrNameModel] nilIfNull];
  NSString *oemModel = [dictionary[attrNameOemModel] nilIfNull];
  NSString *uniqueId = [dictionary[attrNameMac] nilIfNull];
    
  id<AylaDeviceClassPlugin> deviceClassPlugin = (id<AylaDeviceClassPlugin>)[[AylaNetworks shared] getPluginWithId:PLUGIN_ID_DEVICE_CLASS];
  if (deviceClassPlugin != nil) {
    Class pluginClass = [deviceClassPlugin deviceClassForModel:model oemModel:oemModel uniqueId:uniqueId];
      if (pluginClass != nil) {
          return pluginClass;
      }
  }
    
  if (!deviceType) {
    // If no device type is found in input dictionary, return AylaDevice class
    // by default.
    return [AylaDevice class];
  } else if ([deviceType isEqualToString:AylaDeviceTypeGateway]) {
    return [AylaDeviceGateway class];
  } else if ([deviceType isEqualToString:AylaDeviceTypeNode]) {
    return [AylaDeviceNode class];
  }
  return [AylaDevice class];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Device[%@]", self.dsn];
}

//-----------------------------------------------------------
#pragma mark - Update device
//-----------------------------------------------------------
- (AylaHTTPTask *)updateProductNameTo:(NSString *)newName
                              success:(void (^)())successBlock
                              failure:
                                  (void (^)(NSError *_Nonnull))failureBlock {
  if (newName.length == 0) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey :
                     @{@"newName" : AylaErrorDescriptionIsInvalid}
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSError *error;
  AylaHTTPClient *httpClient = [self getHttpClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSDictionary *params = @{ @"device" : @{@"product_name" : newName} };

  NSString *path = [NSString stringWithFormat:@"devices/%@.json", self.key];
  return [httpClient putPath:path
      parameters:params
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        AylaDevice *device = [[AylaDevice alloc] initWithJSONDictionary:@{
          attrNameProductName : newName
        }
                                                                  error:nil];
        dispatch_async(device_processing_queue(), ^{
          [self updateFrom:device dataSource:AylaDataSourceCloud];
          dispatch_async(dispatch_get_main_queue(), ^{
            successBlock();
          });
        });
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}
//-----------------------------------------------------------
#pragma mark - Properties
//-----------------------------------------------------------

- (void)readPropertiesFromCache {
  AylaCache *cache = self.deviceManager.sessionManager.aylaCache;
  if ([cache cachingEnabled:AylaCacheTypeProperty]) {
    NSDictionary *properties =
        [cache getData:AylaCacheTypeProperty uniqueId:self.dsn];
    for (AylaProperty *property in properties.allValues) {
      property.device = self;
    }
    self.properties = properties;
    [self updateProperties:properties.allValues];
  }
}

- (AylaConnectTask *)
fetchProperties:(NSArray *)propertyNames
        success:(void (^)(NSArray AYLA_GENERIC(AylaProperty *) *))successBlock
        failure:(void (^)(NSError *))failureBlock {
  // We only process request through LAN if
  // 1) Lan session is active
  // 2) Requested properties are all known by library
  BOOL allLanEnabledProperties = YES;
  for (NSString *propertyName in propertyNames) {
    AylaProperty *property = self.properties[propertyName];
    if (!property) {
      // If property is not known yet.
      allLanEnabledProperties = NO;
      break;
    }
  }

  // Check lan active status and property list to determine if request could be
  // sent through lan.
  if ([self.lanModule isActive] && propertyNames.count &&
      allLanEnabledProperties) {
    return [self fetchPropertiesLAN:propertyNames
                            success:successBlock
                            failure:failureBlock];
  } else {
    // Otherwise, redirect request to cloud
    return [self fetchPropertiesCloud:propertyNames
                              success:successBlock
                              failure:failureBlock];
  }
}

- (AylaHTTPTask *)fetchPropertiesCloud:(NSArray *)propertyNames
                               success:(void (^)(NSArray AYLA_GENERIC(
                                           AylaProperty *) *))successBlock
                               failure:(void (^)(NSError *))failureBlock {
  NSDictionary *params = nil;
  if (propertyNames.count > 0) {
    // Add parameter `names` when iput property names are not empty
    params = @{ @"names" : propertyNames };
  }

  NSError *error;
  AylaHTTPClient *httpClient = [self getHttpClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path = [NSString
      stringWithFormat:@"%@%@%@", @"dsns/", self.dsn, @"/properties.json"];

  return [httpClient getPath:path
      parameters:params
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        // Swith to device processing queue
        dispatch_async(device_processing_queue(), ^{
          NSMutableArray *properties = [NSMutableArray array];
          NSError *error;
          for (NSDictionary *propertyInJson in responseObject) {
            error = nil;
            AylaProperty *property = [[AylaProperty alloc]
                initWithJSONDictionary:propertyInJson[@"property"]
                                 error:&error];
            if (!error)
              [properties addObject:property];
          }

          // Update properties with fetched properties
          NSArray *propertyChanges = [self updateProperties:properties];

          // Compose property array from self.properties
          NSArray *rProperties;
          if (propertyNames.count > 0) {
            // If request declares the list property names, only return
            // properties inside that names list
            NSPredicate *predicate = [NSPredicate
                predicateWithFormat:@"SELF.name in %@", propertyNames];
            rProperties = [self.properties.allValues
                filteredArrayUsingPredicate:predicate];
          } else {
            // Otherwise return all properties
            rProperties = self.properties.allValues;
          }

          AylaLogI([self logTag], 0, @"%@, %@", @"finished",
                   @"fetchPropertiesCloud");

          AylaCache *cache = self.deviceManager.sessionManager.aylaCache;
          [cache save:AylaCacheTypeProperty
               uniqueId:self.dsn
              andObject:self.properties];

          dispatch_async(dispatch_get_main_queue(), ^{
            // Invoke success block with all properties.
            successBlock(rProperties);
          });

          if (propertyChanges.count > 0) {
            // Go through all observed changes and notify listeners.
            [self notifyChangesToListeners:propertyChanges];
          }
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        AylaLogI([self logTag], 0, @"err:%@, %@", error,
                 @"fetchPropertiesCloud");
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaLanTask *)fetchPropertiesLAN:(NSArray *)propertyNames
                            success:(void (^)(NSArray AYLA_GENERIC(
                                        AylaProperty *) *))successBlock
                            failure:(void (^)(NSError *))failureBlock {
  // If propertyNames is empty, return an error
  if (propertyNames.count == 0) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodeInvalidArguments
               userInfo:@{
                 AylaRequestErrorResponseJsonKey :
                     @{@"propertyNames" : AylaErrorDescriptionIsInvalid}
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  AylaLanModule *module = self.lanModule;
  if (!module) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                 AylaRequestErrorResponseJsonKey : @{
                                   NSStringFromSelector(@selector(lanModule)) :
                                       AylaErrorDescriptionIsInvalid
                                 }
                               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  // Compose list of lan commands
  NSMutableArray *commands = [NSMutableArray array];
  for (NSString *propertyName in propertyNames) {
    AylaLanCommand *command =
        [AylaLanCommand GETPropertyCommandWithPropertyName:propertyName
                                                      data:nil];
    [commands addObject:command];
  }

  AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"property.json"
      commands:commands
       timeout:MAX(DEFAULT_LAN_TASK_TIME_OUT * 1000., (1500 * propertyNames.count))
      success:^(id responseObject) {
        // Handle task call backs.
        AylaLogI([self logTag], 0, @"%@, %@", @"finished",
                 @"fetchPropertiesLAN");
        dispatch_async(dispatch_get_main_queue(), ^{

          NSMutableArray *properties = [NSMutableArray array];
          NSMutableDictionary *errorResponseInfo =
              [NSMutableDictionary dictionary];
          // Send an error back if we found any missing ones in the returned
          // list
          for (NSDictionary *data in responseObject) {
            AylaProperty *property = self.properties[data[@"name"]];
            if (property) {
              [properties addObject:property];
            } else {
              errorResponseInfo[data[@"name"]] =
                  AylaErrorDescriptionCanNotBeFound;
            }
          }
          if (errorResponseInfo.count == 0) {
            [self.deviceManager.sessionManager.aylaCache
                     save:AylaCacheTypeProperty
                 uniqueId:self.dsn
                andObject:self.properties];

            dispatch_async(dispatch_get_main_queue(), ^{
              successBlock(properties);
            });
          } else {
            // If we have hit at least one error, call failureBlock with an
            // error object.
            NSError *error = [AylaErrorUtils
                 errorWithDomain:AylaRequestErrorDomain
                            code:AylaRequestErrorCodeInvalidArguments
                        userInfo:@{
                          AylaRequestErrorResponseJsonKey : errorResponseInfo
                        }
                       shouldLog:YES
                          logTag:[self logTag]
                addOnDescription:@"fetchPropertiesLAN"];
            dispatch_async(dispatch_get_main_queue(), ^{
              failureBlock(error);
            });
          }
        });
      }
      failure:^(NSError *error) {
        AylaLogI([self logTag], 0, @"err:%@, %@", error, @"fetchPropertiesLAN");
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];

  // Set lan module for current task
  task.module = self.lanModule;
  [task start];

  return task;
}

/**
 * Use this method to update properties with pass-in property array.
 *
 * @note This method must be called through processing queue. Right now this
 * method will never remove any properties
 * from device object.
 *
 * @return A list of AylaPropertyChange
 */
- (NSArray AYLA_GENERIC(AylaPropertyChange *) *)updateProperties:
    (NSArray *)properties {
  NSMutableArray *changes = [NSMutableArray array];
  if (!self.mutableProperties) {
    self.mutableProperties = [NSMutableDictionary dictionary];
  }

  // A tag if property list has been changed because of this update.
  BOOL changedList = NO;
  for (AylaProperty *property in properties) {
    AylaProperty *bufferedCopy = self.mutableProperties[property.name];
    if (bufferedCopy) {
      AylaPropertyChange *propertyChange =
          [bufferedCopy updateFrom:property
                        dataSource:property.lastUpdateSource];
      if (propertyChange)
        [changes addObject:propertyChange];
    } else {
      changedList = YES;
      self.mutableProperties[property.name] = property;
      // Setup device and internal delegate of each property as its device
      property.device = self;
      property.delegate = self;

      // TODO: A newly added property will generate a property change object.
      // May  switch to a property list
      // change object.
      [changes
          addObject:[[AylaPropertyChange alloc] initWithProperty:property
                                                   changedFields:[NSSet set]]];
    }
  }

  // When property list has been updated, refresh the exposed property list
  self.properties = [self.mutableProperties copy];

  return changes;
}

- (void)property:(AylaProperty *)property
    didCreateDatapoint:(AylaDatapoint *)datapoint
        propertyChange:(AylaPropertyChange *)propertyChange {
  // When receving a `create datapoint` update from property.
  // Check if created datapoint has been triggered a property change,
  // if so, notify listeners regarding this update.
  if (propertyChange) {
    [self.listeners
        iterateListenersRespondingToSelector:@selector(device:didObserveChange:)
                                asyncOnQueue:dispatch_get_main_queue()
                                       block:^(id listener) {
                                         [listener device:self
                                             didObserveChange:propertyChange];
                                       }];
  }
}

- (AylaLanCommand *)property:(AylaProperty *)property
 lanCommandToCreateDatapoint:(AylaDatapointParams *)datapointParams {
  // Compose post datapoint command with given property and datapoint params.
  return [AylaLanCommand POSTDatapointCommandWithProperty:property
                                          datapointParams:datapointParams];
}

- (dispatch_queue_t)processingQueueForProperty:(AylaProperty *)property {
  return device_processing_queue();
}

- (void)shutDown {
  [self stopTracking];
  [self disableLanSession];
  self.lanModule = nil;
}

//-----------------------------------------------------------
#pragma mark - Device Notifications
//-----------------------------------------------------------
- (AylaHTTPTask *)
createNotification:(AylaDeviceNotification *)deviceNotification
           success:(void (^)(AylaDeviceNotification *_Nonnull))successBlock
           failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (!deviceNotification) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey : @{
                   NSStringFromClass([AylaDeviceNotification class]) :
                       AylaErrorDescriptionIsInvalid
                 }
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSError *error;
  AylaHTTPClient *httpClient = [self getHttpClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
  NSString *path =
      [NSString stringWithFormat:@"devices/%@/notifications.json", self.key];
  return [httpClient postPath:path
      parameters:[deviceNotification toJSONDictionary]
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

        NSError *error = nil;
        AylaDeviceNotification *applicationTrigger =
            [[AylaDeviceNotification alloc]
                initWithJSONDictionary:responseObject[@"notification"]
                                device:self
                                 error:&error];
        if (error) {
          AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                   NSStringFromSelector(_cmd));
          dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
          });
          return;
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(applicationTrigger);
        });
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)fetchNotifications:
                      (void (^)(NSArray<AylaDeviceNotification *> *_Nonnull))
                          successBlock
                             failure:(void (^)(NSError *_Nonnull))failureBlock {
  NSError *error;
  AylaHTTPClient *httpClient = [self getHttpClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
  NSString *path =
      [NSString stringWithFormat:@"devices/%@/notifications.json", self.key];
  return [httpClient getPath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

        NSError *error = nil;

        NSMutableArray *deviceNotifications = [NSMutableArray new];
        for (NSDictionary *notificationDictionary in responseObject) {
          AylaDeviceNotification *notification = [[AylaDeviceNotification alloc]
              initWithJSONDictionary:notificationDictionary[@"notification"]
                              device:self
                               error:&error];
          if (error) {
            AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                     NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
              failureBlock(error);
            });
            return;
          }
          [deviceNotifications addObject:notification];
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(deviceNotifications);
        });
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)
updateNotification:(AylaDeviceNotification *)deviceNotification
           success:(void (^)(AylaDeviceNotification *_Nonnull))successBlock
           failure:(void (^)(NSError *_Nonnull))failureBlock {
  NSError *error;
  AylaHTTPClient *httpClient = [self getHttpClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
  NSString *path = [NSString
      stringWithFormat:@"notifications/%@.json", deviceNotification.id];
  return [httpClient putPath:path
      parameters:[deviceNotification toJSONDictionary]
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSError *error = nil;
        AylaDeviceNotification *applicationTrigger =
            [[AylaDeviceNotification alloc]
                initWithJSONDictionary:responseObject[@"notification"]
                                device:self
                                 error:&error];
        if (error) {
          AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                   NSStringFromSelector(_cmd));
          dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
          });
          return;
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(applicationTrigger);
        });
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)deleteNotification:
                      (AylaDeviceNotification *)deviceNotification
                             success:(void (^)())successBlock
                             failure:(void (^)(NSError *_Nonnull))failureBlock {
  NSError *error;
  AylaHTTPClient *httpClient = [self getHttpClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
  NSString *path = [NSString
      stringWithFormat:@"notifications/%@.json", deviceNotification.id];
  return [httpClient deletePath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock();
        });
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}
//-----------------------------------------------------------
#pragma mark - Datum
//-----------------------------------------------------------

- (nullable AylaHTTPTask *)
createAylaDatumWithKey:(NSString *)key
                 value:(NSString *)value
               success:(void (^)(AylaDatum *createdDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock

{
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString stringWithFormat:@"dsns/%@/data.json", self.dsn];

  return [AylaDatum createDatumWithKey:key
                                 value:value
                            httpClient:httpClient
                                  path:path
                               success:successBlock
                               failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAylaDatumWithKey:(NSString *)key
              success:(void (^)(AylaDatum *datum))successBlock
              failure:(void (^)(NSError *error))failureBlock {
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"dsns/%@/data/%@.json", self.dsn, key];

  return [AylaDatum fetchDatumWithKey:key
                           httpClient:httpClient
                                 path:path
                              success:successBlock
                              failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAylaDatumsWithKeys:(nullable NSArray AYLA_GENERIC(NSString *) *)keys
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock {
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString stringWithFormat:@"dsns/%@/data.json", self.dsn];

  return [AylaDatum fetchDatumsWithKeys:keys
                             httpClient:httpClient
                                   path:path
                                success:successBlock
                                failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAylaDatumsMatching:(NSString *)wildcardedString
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock {
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString stringWithFormat:@"dsns/%@/data.json", self.dsn];

  return [AylaDatum fetchDatumsMatching:wildcardedString
                             httpClient:httpClient
                                   path:path
                                success:successBlock
                                failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAllAylaDatumsWithSuccess:
    (void (^)(NSArray AYLA_GENERIC(AylaDatum *) * datums))successBlock
                      failure:(void (^)(NSError *error))failureBlock {
  return [self fetchAylaDatumsWithKeys:nil
                               success:successBlock
                               failure:failureBlock];
}

- (nullable AylaHTTPTask *)
updateAylaDatumWithKey:(NSString *)key
               toValue:(NSString *)value
               success:(void (^)(AylaDatum *updatedDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock {
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"dsns/%@/data/%@.json", self.dsn, key];

  return [AylaDatum updateKey:key
                      toValue:value
                   httpClient:httpClient
                         path:path
                      success:successBlock
                      failure:failureBlock];
}

- (nullable AylaHTTPTask *)deleteAylaDatumWithKey:(NSString *)key
                                          success:(void (^)())successBlock
                                          failure:(void (^)(NSError *error))
                                                      failureBlock {
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"dsns/%@/data/%@.json", self.dsn, key];

  return [AylaDatum deleteKey:key
                   httpClient:httpClient
                         path:path
                      success:successBlock
                      failure:failureBlock];
}

//-----------------------------------------------------------
#pragma mark - AylaShare
//-----------------------------------------------------------

- (AylaShare *)aylaShareWithEmail:(NSString *)email
                         roleName:(NSString *)roleName
                        operation:(AylaShareOperation)operation
                          startAt:(NSDate *)startAt
                            endAt:(NSDate *)endAt {
  return [[AylaShare alloc] initWithEmail:email
                             resourceName:AylaShareResourceNameDevice
                               resourceId:self.dsn
                                 roleName:roleName
                                operation:operation
                                  startAt:startAt
                                    endAt:endAt];
}

- (AylaHTTPTask *)
fetchSharesWithExpired:(BOOL)expired
              accepted:(BOOL)accepted
               success:(void (^)(NSArray<AylaShare *> *_Nonnull))successBlock
               failure:(void (^)(NSError *_Nonnull))failureBlock {
  AylaSessionManager *sessionManager = self.deviceManager.sessionManager;
  if (sessionManager == nil) {
    NSError *error = [AylaErrorUtils
         errorWithDomain:AylaRequestErrorDomain
                    code:AylaRequestErrorCodePreconditionFailure
                userInfo:@{
                  NSStringFromSelector(@selector(sessionManager)) :
                      AylaErrorDescriptionIsInvalid
                }
               shouldLog:YES
                  logTag:[self logTag]
        addOnDescription:NSStringFromSelector(_cmd)];

    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
  return [sessionManager
      fetchOwnedSharesWithResourceName:AylaShareResourceNameDevice
                            resourceId:self.dsn
                               expired:expired
                              accepted:accepted
                               success:successBlock
                               failure:failureBlock];
}

//-----------------------------------------------------------
#pragma mark - Schedules
//-----------------------------------------------------------

- (nullable AylaHTTPTask *)
fetchAllSchedulesWithSuccess:
    (void (^)(NSArray AYLA_GENERIC(AylaSchedule *) * schedules))successBlock
                     failure:(void (^)(NSError *error))failureBlock {
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"devices/%@/schedules.json", self.key];

  return [httpClient getPath:path
      parameters:nil
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        NSMutableArray AYLA_GENERIC(AylaSchedule *) *schedules =
            [NSMutableArray new];

        for (NSDictionary *scheduleDict in responseObject) {
          AylaSchedule *schedule =
              [[AylaSchedule alloc] initWithJSONDictionary:scheduleDict
                                                    device:self
                                                     error:nil];
          [schedules addObject:schedule];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock([NSArray arrayWithArray:schedules]);
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (nullable AylaHTTPTask *)
fetchScheduleByName:(NSString *)scheduleName
            success:(void (^)(AylaSchedule *schedule))successBlock
            failure:(void (^)(NSError *error))failureBlock {
  AYLAssert([scheduleName length], @"scheduleName cannot be nil or emtpy!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString
      stringWithFormat:@"devices/%@/schedules/find_by_name.json", self.key];

  return [httpClient getPath:path
      parameters:@{
        @"name" : AYLNullIfNil(scheduleName)
      }
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaSchedule *schedule =
            [[AylaSchedule alloc] initWithJSONDictionary:responseObject
                                                  device:self
                                                   error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(schedule);
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (nullable AylaHTTPTask *)
updateSchedule:(AylaSchedule *)scheduleToUpdate
       success:(void (^)(AylaSchedule *updatedSchedule))successBlock
       failure:(void (^)(NSError *error))failureBlock {
  AYLAssert(scheduleToUpdate, @"scheduleToUpdate cannot be nil!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  NSError *error = nil;

  if (![scheduleToUpdate isValid:&error]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString stringWithFormat:@"devices/%@/schedules/%@.json",
                                              self.key, scheduleToUpdate.key];

  return [httpClient putPath:path
      parameters:[scheduleToUpdate toJSONDictionary]
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaSchedule *schedule =
            [[AylaSchedule alloc] initWithJSONDictionary:responseObject
                                                  device:self
                                                   error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(schedule);
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (nullable AylaHTTPTask *)
enableSchedule:(AylaSchedule *)scheduleToEnable
       success:(void (^)(AylaSchedule *enabledSchedule))successBlock
       failure:(void (^)(NSError *error))failureBlock {
  AYLAssert(scheduleToEnable, @"scheduleToEnable cannot be nil!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  AylaSchedule *schedule = [scheduleToEnable copy];
  schedule.active = YES;

  return
      [self updateSchedule:schedule success:successBlock failure:failureBlock];
}

- (nullable AylaHTTPTask *)
disableSchedule:(AylaSchedule *)scheduleToDisable
        success:(void (^)(AylaSchedule *disabledSchedule))successBlock
        failure:(void (^)(NSError *error))failureBlock {
  AYLAssert(scheduleToDisable, @"scheduleToDisable cannot be nil!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  AylaSchedule *schedule = [scheduleToDisable copy];
  schedule.active = NO;

  return
      [self updateSchedule:schedule success:successBlock failure:failureBlock];
}

- (nullable AylaHTTPTask *)
createSchedule:(AylaSchedule *)scheduleToCreate
       success:(void (^)(AylaSchedule *createdSchedule))successBlock
       failure:(void (^)(NSError *error))failureBlock {
  AYLAssert(scheduleToCreate, @"scheduleToCreate cannot be nil!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  NSError *error = nil;

  if (![scheduleToCreate isValid:&error]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"devices/%@/schedules.json", self.key];

  return [httpClient postPath:path
      parameters:[scheduleToCreate toJSONDictionary]
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaSchedule *schedule =
            [[AylaSchedule alloc] initWithJSONDictionary:responseObject
                                                  device:self
                                                   error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(schedule);
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (nullable AylaHTTPTask *)deleteSchedule:(AylaSchedule *)schedule
                                  success:(void (^)())successBlock
                                  failure:
                                      (void (^)(NSError *error))failureBlock {
  AYLAssert(schedule, @"schedule cannot be nil!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"successBlock cannot be NULL!");

  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"schedules/%@.json", schedule.key];

  return [httpClient deletePath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock();
        });
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

//-----------------------------------------------------------
#pragma mark - Time Zone
//-----------------------------------------------------------

- (nullable AylaHTTPTask *)
fetchTimeZoneWithSuccess:(void (^)(AylaTimeZone *timeZone))successBlock
                 failure:(void (^)(NSError *error))failureBlock {
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"failureBlock cannot be NULL!");

  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString
      stringWithFormat:@"%@%@%@", @"devices/", self.key, @"/time_zones.json"];

  return [httpClient getPath:path
      parameters:nil
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaTimeZone *timeZone =
            [[AylaTimeZone alloc] initWithJSONDictionary:responseObject
                                                   error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(timeZone);
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (nullable AylaHTTPTask *)
updateTimeZoneTo:(NSString *)tzID
         success:(void (^)(AylaTimeZone *timeZone))successBlock
         failure:(void (^)(NSError *error))failureBlock {
  AYLAssert([tzID length], @"tzID cannot be nil or emtpy!");
  AYLAssert(successBlock, @"successBlock cannot be NULL!");
  AYLAssert(failureBlock, @"failureBlock cannot be NULL!");

  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString
      stringWithFormat:@"%@%@%@", @"devices/", self.key, @"/time_zones.json"];

  NSDictionary *params = @{ @"tz_id" : AYLNullIfNil(tzID) };

  return [httpClient putPath:path
      parameters:params
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaTimeZone *updatedTimeZone =
            [[AylaTimeZone alloc] initWithJSONDictionary:responseObject
                                                   error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(updatedTimeZone);
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)factoryResetWithSuccess:(void (^)())successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    
    NSError *error = nil;
    
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    NSString *path = [NSString
                      stringWithFormat:@"%@%@%@", @"devices/", self.key, @"/cmds/factory_reset.json"];
    
    return [httpClient putPath:path
                    parameters:nil
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock();
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

//-----------------------------------------------------------
#pragma mark - Lan
//-----------------------------------------------------------
- (BOOL)enableLanSession {
  AylaHTTPServer *server = self.deviceManager.lanServer;
  if (!server) {
    // If server is not found, directly return a failure back.
    AylaLogW([self logTag], 0,
             @"Unable to enable lan session because http server is missing.");
    return NO;
  }

  // Update lan module with http client
  self.lanModule.httpClient = [self getHttpClient:nil];
  return [self.lanModule openSessionWithType:AylaLanSessionTypeNormal
                                onHTTPServer:server];
}

- (void)disableLanSession {
  [self.lanModule closeSession];
}

- (void)refreshLanSessionIfNecessary {
  [self.lanModule refreshSessionIfNecessary];
}

- (BOOL)isLanModeActive {
  return self.lanModule.isActive;
}

- (BOOL)deployLanTask:(AylaLanTask *)lanTask
                error:(NSError *__autoreleasing *)error {
  AylaLanModule *module = self.lanModule;
  if (!module) {
    if (error) {
      *error = [AylaErrorUtils
          errorWithDomain:AylaRequestErrorDomain
                     code:AylaRequestErrorCodePreconditionFailure
                 userInfo:@{
                   AylaRequestErrorResponseJsonKey : @{
                     NSStringFromSelector(@selector(lanModule)) :
                         AylaErrorDescriptionCanNotBeFound
                   }
                 }];
    }
    return NO;
  }

  if (![module isActive]) {
    if (error) {
      *error = [AylaErrorUtils
          errorWithDomain:AylaRequestErrorDomain
                     code:AylaRequestErrorCodePreconditionFailure
                 userInfo:@{
                   AylaRequestErrorResponseJsonKey : @{
                     NSStringFromSelector(@selector(lanModule)) :
                         AylaErrorDescriptionNotReady
                   }
                 }];
    }
    return NO;
  }

  lanTask.module = module;
  [lanTask start];
  return YES;
}

- (void)lanModule:(AylaLanModule *)lanModule
    didEastablishSessionOnLanIp:(NSString *)lanIp {
  [self dataSourceChanged:AylaDataSourceLAN];
}

- (void)lanModule:(AylaLanModule *)lanModuel
didReceiveMessage:(AylaLanMessage *)message {
  switch (message.type) {
  case AylaLanMessageTypeUpdateDatapoint: {
    NSDictionary *update = message.jsonObject;
    AylaProperty *property = self.mutableProperties[update[@"name"]];
    // Only update known properties.
    if (property) {
        NSMutableDictionary *updateDictionary = [@{
                                                  NSStringFromSelector(@selector(value)) : update[@"value"]
                                                  } mutableCopy];
        NSDictionary *metadata = update[@"metadata"];
        if (metadata) {
            updateDictionary[@"metadata"] = metadata;
        }
      NSError *error;
      AylaDatapoint *datapoint =
          [[AylaDatapoint alloc] initWithJSONDictionary:updateDictionary
                                             dataSource:AylaDataSourceLAN
                                                  error:&error];

      dispatch_async(device_processing_queue(), ^{
        AylaPropertyChange *propertyChange =
            [property updateFromDatapoint:datapoint];
        if (propertyChange) {
          [self notifyChangesToListeners:@[ propertyChange ]];
        }
      });
    }
  } break;
  default:
    break;
  }
}

- (void)lanModule:(AylaLanModule *)lanModule didFail:(NSError *)error {
  [self dataSourceChanged:AylaDataSourceLAN];
}

- (void)didDisableSessionOnModule:(AylaLanModule *)module {
  [self dataSourceChanged:AylaDataSourceLAN];
}

- (AylaSessionManager *)sessionManager {
  return self.deviceManager.sessionManager;
}

//-----------------------------------------------------------
#pragma mark - Tracking
//-----------------------------------------------------------

- (BOOL)startTracking {
  if (!self.timer) {
    __weak typeof(self) weakSelf = self;
    self.timer =
        [[AylaTimer alloc] initWithTimeInterval:DEFAULT_POLL_INTERVAL_MS
                                         leeway:DEFAULT_POLL_LEEWAY_MS
                                          queue:device_processing_queue()
                                    handleBlock:^(AylaTimer *timer) {
                                      [weakSelf processPolling];
                                    }];
  }

  // Set tracking as YES
  self.tracking = YES;

  return YES;
}

- (void)stopTracking {
  // Set tracking as NO
  self.tracking = NO;
}

- (void)adjustPollingBasedOnPermitAndStatus {
  // Only enable polling session when preconditions are satisfied
  if (!self.lanModule.isActive && self.isTracking && ![self isDSAvailable]) {
    AylaLogD([self logTag], 0, @"%@, Adjust polling(on) %d%d%d", self.dsn,
             self.lanModule.isActive, self.isTracking, [self isDSAvailable]);
    [self enablePolling];
  } else {
    // Otherwise, disable polling of this device.
    AylaLogD([self logTag], 0, @"%@, Adjust polling(off) %d%d%d,", self.dsn,
             self.lanModule.isActive, self.isTracking, [self isDSAvailable]);
    [self disablePolling];
  }
}

- (void)processPolling {
  [self fetchProperties:[self.deviceManager.deviceDetailProvider
                            monitoredPropertyNamesForDevice:self]
      success:^(NSArray AYLA_GENERIC(AylaProperty *) * properties) {
      }
      failure:^(NSError *error) {
        AylaLogE([self logTag], 0, @"poll failure %ld", (long)error.code);
        // Notify error to listeners
        [self.listeners
            iterateListenersRespondingToSelector:@selector(device:didFail:)
                                    asyncOnQueue:dispatch_get_main_queue()
                                           block:^(id listener) {
                                             [listener device:self
                                                      didFail:error];
                                           }];
      }];
}

- (BOOL)isTracking {
  return self.tracking;
}

/**
 * Use this method to start polling
 */
- (void)enablePolling {
  // Enable polling timer
  [self.timer startPollingWithDelay:NO];
}

/**
 * Use this method to stop polling
 */
- (void)disablePolling {
  [self.timer stopPolling];
}

/**
 * @discussion This method is used to trigger adjustments to POLLING based on
 * outside datasource status. Right now, it
 * only checks status of DS manager and lan module.
 */
- (void)dataSourceChanged:(AylaDataSource)dataSource {
  BOOL fetchProperties = NO;
  // If lan mode becomes active, fetch properties once.
  if (dataSource == AylaDataSourceLAN && self.lanModule.isActive) {
    fetchProperties = YES;
  }

  // Notify listener if this is a lan state update.
  if (dataSource == AylaDataSourceLAN) {
    [self.listeners
        iterateListenersRespondingToSelector:@selector(device:
                                                 didUpdateLanState:)
                                asyncOnQueue:dispatch_get_main_queue()
                                       block:^(id _Nonnull listener) {
                                         [(id<AylaDeviceListener>)listener
                                                        device:self
                                             didUpdateLanState:
                                                 [self isLanModeActive]];
                                       }];
  }

  // If DS becomes active and lan module is not active, fetch properties once.
  if (dataSource == AylaDataSourceDSS && [self isDSAvailable] &&
      !self.lanModule.isActive) {
    fetchProperties = YES;
  }

  if (fetchProperties) {
    // Make one time call to gurantee status
    NSArray *propertyNames;
    id<AylaDeviceDetailProvider> provider =
        self.deviceManager.deviceDetailProvider;
    if ([provider
            respondsToSelector:@selector(monitoredPropertyNamesForDevice:)]) {
      propertyNames = [provider monitoredPropertyNamesForDevice:self];
    }
    void (^successBlock)(NSArray *) = ^(NSArray *properties) {
    };
    void (^failureBlock)(NSError *) = ^(NSError *error) {
      AylaLogE([self logTag], 0, @"Failed to fetch properties(%ld), %@",
               (long)error.code, NSStringFromSelector(_cmd));
    };

    [self fetchProperties:propertyNames
                  success:successBlock
                  failure:failureBlock];
  }

  [self adjustPollingBasedOnPermitAndStatus];
}

//-----------------------------------------------------------
#pragma mark - Unregistration
//-----------------------------------------------------------
- (nullable AylaConnectTask *)unregisterWithSuccess:(void (^)(void))successBlock
                                            failure:(void (^)(NSError *error))
                                                     failureBlock {
  NSError *error = nil;

  AylaHTTPClient *httpClient = [self getHttpClient:&error];

  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });

    return nil;
  }

  NSString *path = [NSString stringWithFormat:@"devices/%@.json", self.key];

  return [httpClient deletePath:path
      parameters:nil
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaDeviceManager *deviceManager = self.deviceManager;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
          [deviceManager removeDevices:@[ self ]];
          dispatch_async(dispatch_get_main_queue(), ^{
            successBlock();
          });
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

//-----------------------------------------------------------
#pragma mark - DSS
//-----------------------------------------------------------
- (BOOL)isDSAvailable {
  return self.deviceManager.sessionManager.dssManager.state ==
         AylaDSStateConnected;
}

//-----------------------------------------------------------
#pragma mark - Listeners
//-----------------------------------------------------------

- (void)notifyChangesToListeners:(NSArray *)changes {
  if (changes.count > 0) {
    [self.listeners
        iterateListenersRespondingToSelector:@selector(device:didObserveChange:)
                                asyncOnQueue:dispatch_get_main_queue()
                                       block:^(id listener) {
                                         for (AylaChange *change in changes) {
                                           [listener device:self
                                               didObserveChange:change];
                                         }
                                       }];
  }
}

- (void)addListener:(id<AylaDeviceManagerListener>)listener {
  [self.listeners addListener:listener];
}

- (void)removeListener:(id<AylaDeviceManagerListener>)listener {
  [self.listeners removeListener:listener];
}

+ (dispatch_queue_t)deviceProcessingQueue {
  return device_processing_queue();
}

//-----------------------------------------------------------
#pragma mark - Http Client
//-----------------------------------------------------------
- (AylaHTTPClient *)getHttpClient:
    (NSError *_Nullable __autoreleasing *_Nullable)error {
  AylaHTTPClient *client = [self.deviceManager.sessionManager
      getHttpClientWithType:AylaHTTPClientTypeDeviceService];

  if (!client && error) {
    *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound
               }];
  }

  return client;
}

- (NSString *)logTag {
  return @"Device";
}

@end

@implementation AylaDevice (NSCoding)
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super init]) {
    _productName = [aDecoder
        decodeObjectForKey:NSStringFromSelector(@selector(productName))];
    _model =
        [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(model))];
    _dsn = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(dsn))];
    _oemModel =
        [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(oemModel))];
    _deviceType = [aDecoder
        decodeObjectForKey:NSStringFromSelector(@selector(deviceType))];
    _connectedAt = [aDecoder
        decodeObjectForKey:NSStringFromSelector(@selector(connectedAt))];
    _mac = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(mac))];
    _lanIp =
        [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(lanIp))];
    _key = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(key))];
    _ip = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ip))];
    _productClass = [aDecoder
        decodeObjectForKey:NSStringFromSelector(@selector(productClass))];
    _ssid = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ssid))];
    _swVersion = [aDecoder
        decodeObjectForKey:NSStringFromSelector(@selector(swVersion))];

    _listeners = [[AylaListenerArray alloc] init];

    AylaSessionManager *sessionManager = [[AylaNetworks shared]
        getSessionManagerWithName:
            [aDecoder decodeObjectForKey:NSStringFromSelector(
                                             @selector(sessionManager))]];

    _deviceManager = sessionManager.deviceManager;

    // Set lan mode permitted as YES by default
    _lanModePermitted = YES;
      
    _lastUpdateSource = AylaDataSourceCache;

    [AylaDiscovery getDeviceLanIpWithHostName:_dsn
                                      timeout:DEFAULT_LAN_TASK_TIME_OUT/3
                                  resultBlock:^(NSString *lanIp,
                                                NSString *deviceHostName) {
                                    if (lanIp != nil) {
                                      _lanIp = lanIp;
                                    }
                                    // Init lan module
                                    _lanModule = [[AylaLanModule alloc]
                                        initWithDevice:self];
                                    _lanModule.delegate = self;
                                    [self enableLanSession];
                                  }];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_productName
                forKey:NSStringFromSelector(@selector(productName))];
  [aCoder encodeObject:_model forKey:NSStringFromSelector(@selector(model))];
  [aCoder encodeObject:_dsn forKey:NSStringFromSelector(@selector(dsn))];
  [aCoder encodeObject:_oemModel
                forKey:NSStringFromSelector(@selector(oemModel))];
  [aCoder encodeObject:_deviceType
                forKey:NSStringFromSelector(@selector(deviceType))];
  [aCoder encodeObject:_connectedAt
                forKey:NSStringFromSelector(@selector(connectedAt))];
  [aCoder encodeObject:_mac forKey:NSStringFromSelector(@selector(mac))];
  [aCoder encodeObject:_lanIp forKey:NSStringFromSelector(@selector(lanIp))];
  [aCoder encodeObject:_ip forKey:NSStringFromSelector(@selector(ip))];
  [aCoder encodeObject:_productClass
                forKey:NSStringFromSelector(@selector(productClass))];
  [aCoder encodeObject:_ssid forKey:NSStringFromSelector(@selector(ssid))];
  [aCoder encodeObject:_swVersion
                forKey:NSStringFromSelector(@selector(swVersion))];
  [aCoder encodeObject:_key forKey:NSStringFromSelector(@selector(key))];

  [aCoder encodeObject:self.deviceManager.sessionManager.sessionName
                forKey:NSStringFromSelector(@selector(sessionManager))];
}
@end
