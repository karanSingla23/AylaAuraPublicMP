//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint+Internal.h"
#import "AylaDatapointBlob.h"
#import "AylaDefines_Internal.h"
#import "AylaDevice+Internal.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaLanCommand.h"
#import "AylaLanTask.h"
#import "AylaNetworks+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaPoll.h"
#import "AylaProperty+Internal.h"
#import "AylaProperty.h"
#import "AylaPropertyChange.h"
#import "AylaPropertyTrigger+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemUtils.h"
#import "NSObject+Ayla.h"
#import "AylaLanTaskProfiler.h"

static NSString *const attrNameBaseType = @"base_type";
static NSString *const attrNameDatapoint = @"datapoint";
static NSString *const attrNameDataUpdatedAt = @"data_updated_at";
static NSString *const attrNameDirection = @"direction";
static NSString *const attrNameDisplayName = @"display_name";
static NSString *const attrNameKey = @"key";
static NSString *const attrNameName = @"name";
static NSString *const attrNameTrigger = @"trigger";
static NSString *const attrNameType = @"type";
static NSString *const attrNameUpdatedAt = @"updated_at";
static NSString *const attrNameValue = @"value";

static NSString *const attrNameFile = @"file";

static NSString *const attrNameAckEnabled = @"ack_enabled";
static NSString *const attrNameAckAt = @"acked_at";
static NSString *const attrNameAckStatus = @"ack_status";
static NSString *const attrNameAckMessage = @"ack_message";

NSString *const AylaPropertyBaseTypeInteger = @"integer";
NSString *const AylaPropertyBaseTypeString = @"string";
NSString *const AylaPropertyBaseTypeBoolean = @"boolean";
NSString *const AylaPropertyBaseTypeDecimal = @"decimal";
NSString *const AylaPropertyBaseTypeFloat = @"float";
NSString *const AylaPropertyBaseTypeFile = @"file";

static const NSTimeInterval DEFAULT_DATAPOINT_ACK_DELAY = 2.;
static const NSTimeInterval DEFAULT_DATAPOINT_ACK_TIMEOUT = 10.;
static const NSInteger MAX_DATAPOINT_COUNT = 100;

static NSString* AylaLanTaskClass = @"AylaLanTask";

@interface AylaProperty ()

@property (nonatomic, weak, readwrite) AylaDevice *device;
@property (nonatomic, readwrite) NSNumber *key;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *baseType;
@property (nonatomic, readwrite) NSString *type;
@property (nonatomic, readwrite) NSString *direction;
@property (nonatomic, readwrite) NSString *displayName;
@property (nonatomic, readwrite) AylaDatapoint *datapoint;
@property (nonatomic, readwrite) AylaDataSource lastUpdateSource;
@property (nonatomic, readwrite) NSDate *ackedAt;
@property (nonatomic, assign) NSInteger ackStatus;
@property (nonatomic, assign) NSInteger ackMessage;

@property (nonatomic, readwrite) dispatch_queue_t processingQueue;
@property (nonatomic, weak, readwrite) id<AylaPropertyInternalDelegate> delegate;

@end

@implementation AylaProperty

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    return [self initWithJSONDictionary:dictionary device:nil delegate:nil error:error];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                device:(AylaDevice *)device
                              delegate:(id<AylaPropertyInternalDelegate>)delegate
                                 error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;

    _baseType = [dictionary[attrNameBaseType] nilIfNull];
    _direction = [dictionary[attrNameDirection] nilIfNull];
    _displayName = [dictionary[attrNameDisplayName] nilIfNull];
    _name = [dictionary[attrNameName] nilIfNull];
    _type = [dictionary[attrNameType] nilIfNull];
    NSString *dataUpdatedAt = [dictionary[attrNameDataUpdatedAt] nilIfNull];
    _dataUpdatedAt = [[AylaSystemUtils defaultDateFormatter] dateFromString:dataUpdatedAt];
    _key = [dictionary[attrNameKey] nilIfNull];

    _ackEnabled = [[dictionary[attrNameAckEnabled] nilIfNull] boolValue];
    NSString *ackedAtString = [dictionary[attrNameAckAt] nilIfNull];
    _ackedAt = [[AylaSystemUtils defaultDateFormatter] dateFromString:ackedAtString];
    _ackStatus = [[dictionary[attrNameAckStatus] nilIfNull] integerValue];
    _ackMessage = [[dictionary[attrNameAckMessage] nilIfNull] integerValue];
     _lastUpdateSource = AylaDataSourceCloud;

    // TODO: Before datapoint is returned from cloud with each property, check `value` & `dataUpdatedAt` field to
    // determine if a datapoint is available in dictionary
    if ([dictionary[attrNameValue] nilIfNull] && _dataUpdatedAt) {
        // If value is found in pass-in dictionary. Assign a datapoint to this property
        // TODO: Before datapoint is returned from cloud with each property, use property dictionary
        // to init datapoint
        NSMutableDictionary *datapointDictionary = [@{
            attrNameValue : dictionary[attrNameValue],
            // Use property's `data_updated_at` to compose datapoint `updated_at`
            attrNameUpdatedAt : dictionary[attrNameDataUpdatedAt]
        } mutableCopy];
        
        if ([_baseType isEqualToString:@"file"]) {
            datapointDictionary[attrNameFile] = dictionary[attrNameValue];
        }

        if (AYLNilIfNull(dictionary[attrNameAckAt])) {
            datapointDictionary[attrNameAckAt] = dictionary[attrNameAckAt];
            datapointDictionary[attrNameAckStatus] = dictionary[attrNameAckStatus];
            datapointDictionary[attrNameAckMessage] = dictionary[attrNameAckMessage];
        }

        // use the proper class, according to the info in the datapoint dictionary
        Class datapointClass = [AylaDatapoint class];
        if (datapointDictionary[attrNameFile]) {
            datapointClass = [AylaDatapointBlob class];
        }

        _datapoint = [[datapointClass alloc] initWithJSONDictionary:datapointDictionary
                                                         dataSource:AylaDataSourceCloud
                                                              error:error];
        _datapoint.property = self;
    }

    _device = device;
    _delegate = delegate;

    // Get processing queue from delegate. if there queue is not given from deleage, use main thread by default.
    _processingQueue = [delegate processingQueueForProperty:self] ?: dispatch_get_main_queue();

    return self;
}

- (void)setDelegate:(id<AylaPropertyInternalDelegate>)delegate
{
    _delegate = delegate;
    _processingQueue = [delegate processingQueueForProperty:self] ?: dispatch_get_main_queue();
}

- (AylaPropertyChange *)updateFrom:(AylaProperty *)property dataSource:(AylaDataSource)dataSource
{
    NSMutableSet *set = [NSMutableSet set];

    // Property name will not be updated in this method
    NSArray *names =
        @[ @"baseType", @"direction", @"displayName", @"key", @"type", @"ackedAt", @"ackStatus", @"ackMessage" ];

    for (NSString *name in names) {
        id value = [property valueForKey:name];
        if (value) {
            if (![[self valueForKey:name] isEqual:value]) {
                [self setValue:value forKey:name];
                [set addObject:name];
            }
        }
    }

    // Update datapoint with input property
    if ([self updateFromDatapoint:property.datapoint]) {
        [set addObject:NSStringFromSelector(@selector(datapoint))];
    }

    AylaPropertyChange *propertyChange =
        set.count > 0 ? [[AylaPropertyChange alloc] initWithProperty:self changedFields:set] : nil;
    return propertyChange;
}

//-----------------------------------------------------------
#pragma mark - Datapoint
//-----------------------------------------------------------

- (id)value
{
    return self.datapoint.value;
}

- (NSDictionary*)metadata {
    return self.datapoint.metadata;
}

- (void)setDatapoint:(AylaDatapoint *)datapoint {
    _datapoint = datapoint;
    _datapoint.property = self;
}

- (AylaConnectTask *)createDatapoint:(AylaDatapointParams *)datapointParams
                             success:(void (^)(AylaDatapoint *createdDatapoint))successBlock
                             failure:(void (^)(NSError *error))failureBlock
{
    AylaConnectTask *task;
    // if baseType is file, then don't use LAN creation
    if (!self.device.isLanModeActive || [self.baseType isEqualToString:AylaPropertyBaseTypeFile]) {
        task = [self createDatapointCloud:datapointParams success:successBlock failure:failureBlock];
    }
    else {
        task = [self createDatapointLAN:datapointParams success:successBlock failure:failureBlock];
    }
    return task;
}

- (AylaConnectTask *)createDatapointCloud:(AylaDatapointParams *)datapointParams
                                  success:(void (^)(AylaDatapoint *createdDatapoint))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    NSError *error;
    if (![self validateValue:datapointParams lanMode:NO error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSDictionary *params = nil;

    // if any of the blob fields is in use then pass params = nil, to create an empty datapoint blob
    if (!datapointParams.filePath && !datapointParams.data) {
        params = @{attrNameDatapoint : [datapointParams toCloudJSONDictionary]};
    }
    NSString *path = [NSString stringWithFormat:@"properties/%@/datapoints.json", self.key];

    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [httpClient postPath:path
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSError *error;

            AylaDatapoint *createdDatapoint = nil;

            // use the proper class accoring to the data contained in the dictionary (regular vs blob datapoint)
            Class datapointClass = [AylaDatapoint class];
            if (datapointParams.filePath || datapointParams.data) {
                datapointClass = [AylaDatapointBlob class];
            }
            createdDatapoint = [[datapointClass alloc] initWithJSONDictionary:responseObject[attrNameDatapoint]
                                                                   dataSource:AylaDataSourceCloud
                                                                        error:&error];

            // required to use the http client inside the blob class instace
            createdDatapoint.property = self;

            // pass the local information
            if ([createdDatapoint isKindOfClass:[AylaDatapointBlob class]]) {
                ((AylaDatapointBlob *)createdDatapoint).localFileURL = datapointParams.filePath;
                ((AylaDatapointBlob *)createdDatapoint).blobData = datapointParams.data;
            }

            if (error) {
                AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, @"createDatapointCloud");
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }
            void (^notifyCreation)(AylaDatapoint *datapoint) = ^(AylaDatapoint *datapoint) {
                AylaLogI([self logTag], 0, @"%@, %@", @"complete", @"createDatapointCloud");
                dispatch_async(self.processingQueue, ^{
                    [self.delegate property:self
                         didCreateDatapoint:datapoint
                             propertyChange:[self updateFromDatapoint:datapoint]];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(datapoint);
                    });
                });

            };

            if (self.ackEnabled && createdDatapoint.ackedAt == nil) {
                AylaPoll *poll = [[AylaPoll alloc]
                    initWithPollBlock:^(ContinueBlock _Nonnull continueBlock, BOOL *stop, NSInteger repetitionNumber) {
                        [self fetchDatapointWithId:createdDatapoint.id
                            success:^(AylaDatapoint *fetchedDatapoint) {
                                if (fetchedDatapoint.ackedAt != nil) {
                                    *stop = YES;
                                    notifyCreation(fetchedDatapoint);
                                }
                                else {
                                    continueBlock();
                                }
                            }
                            failure:^(NSError *error) {
                                continueBlock();
                            }];
                    }
                    delay:DEFAULT_DATAPOINT_ACK_DELAY
                    timeout:DEFAULT_DATAPOINT_ACK_TIMEOUT
                    timeoutBlock:^{
                        NSError *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                                    code:AylaRequestErrorCodeTimedOut
                                                                userInfo:nil];
                        failureBlock(error);
                    }];
                [poll start];
            }
            else {
                notifyCreation(createdDatapoint);
            }
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, @"createDatapointCloud");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaConnectTask *)createDatapointLAN:(AylaDatapointParams *)datapointParams
                                success:(void (^)(AylaDatapoint *createdDatapint))successBlock
                                failure:(void (^)(NSError *error))failureBlock
{
    NSError *error;
    if (![self validateValue:datapointParams lanMode:YES error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    AylaDevice *device = self.device;
    if (!device) {
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                   AylaRequestErrorResponseJsonKey :
                                       @{NSStringFromSelector(@selector(device)) : AylaErrorDescriptionCanNotBeFound}
                               }
                              shouldLog:YES
                                 logTag:[self logTag]
                       addOnDescription:@"createDatapointLAN"];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    id<AylaPropertyInternalDelegate> delegate = self.delegate;
    AylaLanCommand *command = nil;
    // If delegate is found for property, let delegate return a lan command.
    // Otherwise create a default datapoint lan command.
    if (delegate) {
        command = [delegate property:self lanCommandToCreateDatapoint:datapointParams];
    }
    else {
        AylaLogI([self logTag], 0, @"%@, %@", @"No delegate found, use default command", @"createDatapointLAN");
        command = [AylaLanCommand POSTDatapointCommandWithProperty:self datapointParams:datapointParams];
    }

    AylaLanTask *task = [[NSClassFromString(AylaLanTaskClass) alloc] initWithPath:@"datapoint.json"
        commands:@[ command ]
        success:^(id _Nullable responseObject) {
            NSMutableDictionary *datapointDictionary = [datapointParams.toCloudJSONDictionary mutableCopy];

            // Check if response object is an NSArray to be able to use firstObject
            if ([responseObject isKindOfClass:[NSArray class]]) {
                id ackDatapointDicitonary = ((NSArray *)responseObject).firstObject;

                // when creating a non-ACK-enabled datapoint the responseObject will contain an NSNull instance,
                // therefore is necessary to  check if the ackDatapointDicitonary is actually of NSDictionary kind.
                if ([ackDatapointDicitonary isKindOfClass:[NSDictionary class]]) {
                    // ackDatapointDicitonary returned by the module will contain the ack information only,
                    // add the entries in ackDatapointDicitonary to the dictionary used to create the datapoint to
                    // instantiate it
                    [datapointDictionary addEntriesFromDictionary:(NSDictionary *)ackDatapointDicitonary];

                    // the ack information returned by the module doesn't contain the attrNameAckAt attribute, then is
                    // necessary to initialise it with the local timestamp
                    if (!datapointDictionary[attrNameAckAt]) {
                        datapointDictionary[attrNameAckAt] =
                            [[AylaSystemUtils defaultDateFormatter] stringFromDate:[NSDate date]];
                    }
                }
            }

            NSError *error;
            AylaDatapoint *datapoint = [[AylaDatapoint alloc] initWithJSONDictionary:datapointDictionary
                                                                          dataSource:AylaDataSourceLAN
                                                                               error:&error];
            datapoint.property = self;

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", @"createDatapointLAN");
            [self updateAndNotifyDelegateFromDatapoint:datapoint
                                          successBlock:^{
                                              successBlock(datapoint);
                                          }];
        }
        failure:^(NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, @"createDatapointLAN");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];

    [device deployLanTask:task error:&error];
    if (error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error, @"createDatapointLAN");
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    return task;
}

- (AylaHTTPTask *)fetchDatapointWithId:(NSString *)datapointId
                               success:(void (^)(AylaDatapoint *fetchedDatapoint))successBlock
                               failure:(void (^)(NSError *error))failureBlock
{
    if (!datapointId) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodeInvalidArguments
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey : @{@"datapointId" : AylaErrorDescriptionIsInvalid}
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

    NSString *path = [NSString
        stringWithFormat:@"devices/%@/properties/%@/datapoints/%@.json", self.device.key, self.name, datapointId];

    return [httpClient getPath:path
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, NSDictionary *_Nullable responseObject) {
            NSError *error;

            NSDictionary *datapointDictionary = responseObject[attrNameDatapoint];

            Class datapointClass = [AylaDatapoint class];
            if (datapointDictionary[attrNameFile]) {
                datapointClass = [AylaDatapointBlob class];
            }

            AylaDatapoint *datapoint = [[datapointClass alloc] initWithJSONDictionary:datapointDictionary error:&error];
            datapoint.property = self;
            if (error) {
                AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, @"createDatapointCloud");
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));

            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(datapoint);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));

            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}
- (AylaHTTPTask *)fetchDatapointsWithCount:(NSInteger)count
                                      from:(NSDate *)from
                                        to:(NSDate *)to
                                   success:(void (^)(NSArray<AylaDatapoint *>*fetchedDatapoint))successBlock
                                   failure:(void (^)(NSError *error))failureBlock
    {
        
        NSError *error;
        AylaHTTPClient *httpClient = [self getHttpClient:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return nil;
        }
        
        if (count <= 0 || count > MAX_DATAPOINT_COUNT) {
            count = MAX_DATAPOINT_COUNT;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@(count) forKey:@"limit"];
        if (from != nil) {
            NSString *fromString = [[AylaSystemUtils defaultDateFormatter] stringFromDate:from];
            params[@"filter[created_at_since_date]"] = fromString;
        }
        
        if (to != nil) {
            NSString *fromString = [[AylaSystemUtils defaultDateFormatter] stringFromDate:to];
            params[@"filter[created_at_end_date]"] = fromString;
        }
        
        NSString *path = [NSString
                          stringWithFormat:@"properties/%@/datapoints.json", self.key];
        
        return [httpClient getPath:path
                        parameters:params
                           success:^(AylaHTTPTask *_Nonnull task, NSDictionary *_Nullable responseObject) {
                               NSMutableArray *datapoints = [NSMutableArray array];
                               
                               for (NSDictionary *datapointJSON in responseObject) {
                                   NSError *error;
                                   NSDictionary *datapointDictionary = datapointJSON[attrNameDatapoint];
                                   
                                   Class datapointClass = [AylaDatapoint class];
                                   if (datapointDictionary[attrNameFile]) {
                                       datapointClass = [AylaDatapointBlob class];
                                   }
                                   AylaDatapoint *datapoint = [[datapointClass alloc] initWithJSONDictionary:datapointDictionary error:&error];
                                   datapoint.property = self;
                                   if (error) {
                                       AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, @"createDatapointCloud");
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           failureBlock(error);
                                       });
                                       return;
                                   }
                                   [datapoints addObject:datapoint];
                               }
                               
                               AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
                               
                               if (successBlock != nil) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                           successBlock(datapoints);
                                   });
                               }
                           }
                           failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
                               AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
                               
                               if (failureBlock != nil) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       failureBlock(error);
                                   });
                               }
                           }];
    }

- (void)updateAndNotifyDelegateFromDatapoint:(AylaDatapoint *)datapoint successBlock:(nonnull void (^)())successBlock
{
    dispatch_async(self.processingQueue, ^{
        [self.delegate property:self didCreateDatapoint:datapoint propertyChange:[self updateFromDatapoint:datapoint]];
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock();
        });
    });
}
/**
 *  Update datapoint of current property with pass-in copy.
 *  Make sure this datapoint copy will not be
 */
- (AylaPropertyChange *)updateFromDatapoint:(AylaDatapoint *)datapoint
{
    NSMutableSet *changes = [NSMutableSet set];
    AylaDatapoint *curDatapoint = self.datapoint;
    if (curDatapoint == datapoint) return nil;

    // Add change notifications for value property
    if (![curDatapoint.value isEqual:datapoint.value]) {
        // no need to assign, since value property is a passthrough to the datapoint value
        [changes addObject:NSStringFromSelector(@selector(value))];
    }
    
    // Add change notifications for metadata
    if (![curDatapoint.metadata isEqual:datapoint.metadata]) {
        // no need to assign, since metadata is a passthrough to the datapoint metadata
        [changes addObject:NSStringFromSelector(@selector(metadata))];
    }

    if (![datapoint.updatedAt isEqualToDate:self.dataUpdatedAt]) {
        _dataUpdatedAt = datapoint.updatedAt;
        [changes addObject:NSStringFromSelector(@selector(dataUpdatedAt))];
    }

    // add ack changes
    if (datapoint.ackedAt != nil && datapoint.ackedAt != nil && ![datapoint.ackedAt isEqualToDate:datapoint.ackedAt]) {
        [changes addObjectsFromArray:@[
            NSStringFromSelector(@selector(ackedAt)),
            NSStringFromSelector(@selector(ackStatus)),
            NSStringFromSelector(@selector(ackMessage))
        ]];
    }
    self.ackedAt = datapoint.ackedAt;
    self.ackStatus = datapoint.ackStatus;
    self.ackMessage = datapoint.ackMessage;
    self.lastUpdateSource = datapoint.dataSource;

    AylaPropertyChange *change = nil;
    if (changes.count > 0) {
        self.datapoint = datapoint;
        [changes addObject:NSStringFromSelector(@selector(datapoint))];
        change = [[AylaPropertyChange alloc] initWithProperty:self changedFields:changes];
    }
    return change;
}

- (BOOL)validateValue:(AylaDatapointParams *)params lanMode:(BOOL)lanMode error:(NSError *__autoreleasing *)error
{
    NSString *baseType = self.baseType;
    NSDictionary *errorInfo;
    id value = params.value;

    if (![baseType nilIfNull]) {
        errorInfo = @{ NSStringFromSelector(@selector(baseType)) : AylaErrorDescriptionCanNotBeBlank };
    }
    else if (!value && ![baseType isEqualToString:AylaPropertyBaseTypeFile]) {
        errorInfo = @{ NSStringFromSelector(@selector(value)) : AylaErrorDescriptionCanNotBeBlank };
    }
    else if ([baseType isEqualToString:AylaPropertyBaseTypeInteger]) {
        if (strcmp([value objCType], @encode(long)) != 0 && strcmp([value objCType], @encode(int)) != 0 && strcmp([value objCType], @encode(long long)) != 0) {
            errorInfo = @{ NSStringFromSelector(@selector(value)) : AylaErrorDescriptionIsInvalid };
        }
    }
    else if ([baseType isEqualToString:AylaPropertyBaseTypeString]) {
        if (![value isKindOfClass:[NSString class]]) {
            errorInfo = @{ NSStringFromSelector(@selector(value)) : AylaErrorDescriptionIsInvalid };
        }
    }
    else if ([baseType isEqualToString:AylaPropertyBaseTypeBoolean]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            errorInfo = @{ NSStringFromSelector(@selector(value)) : AylaErrorDescriptionIsInvalid };
        }
        else {
            value = @([(NSNumber *)value boolValue]);
        }
    }
    else if ([baseType isEqualToString:AylaPropertyBaseTypeDecimal] ||
             [baseType isEqualToString:AylaPropertyBaseTypeFloat]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            errorInfo = @{ NSStringFromSelector(@selector(value)) : AylaErrorDescriptionIsInvalid };
        }
    }
    else if ([baseType isEqualToString:AylaPropertyBaseTypeFile]) {
        // Discussion:
        // Basetype of file/stream has to be handled differently.
        // If input datapoint is an instance of AylaDatapointBlob. Use 'url' attribute to complete validation.
        //
        // If input datapoint is an instance of AylaDatapoint. Since uploading files to 'file'/'stream' properties will
        // always create a empty datapoint first, library will skip validation here and always return null to indicate
        // an empty value.
        if (lanMode) {
            errorInfo = @{ @"lanMode" : @"Not supported with Blobs" };
        }
        else if (params.filePath == nil && params.data == nil) {
            errorInfo = @{ NSStringFromClass([AylaDatapointBlob class]) : @"Requires filePath or data to be non-nil" };
        }
        else {
            value = nil;
        }
    }
    else {
        errorInfo = @{ NSStringFromSelector(@selector(baseType)) : AylaErrorDescriptionIsInvalid };
    }

    if (errorInfo) {
        NSError *foundError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                         code:AylaRequestErrorCodeInvalidArguments
                                                     userInfo:errorInfo
                                                    shouldLog:YES
                                                       logTag:[self logTag]
                                             addOnDescription:@"validatedValueFromDatapoint"];
        if (error != NULL) {
            *error = foundError;
        }
        return NO;
    }

    return YES;
}

//-----------------------------------------------------------
#pragma mark - PropertyTriggers
//-----------------------------------------------------------

- (AylaHTTPTask *)createTrigger:(AylaPropertyTrigger *)trigger
                        success:(void (^)(AylaPropertyTrigger *_Nonnull))successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!trigger) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey : @{@"trigger" : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSDictionary *parameters = @{attrNameTrigger : [trigger toJSONDictionary]};

    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", self.key, @"/triggers.json"];

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [httpClient postPath:path
        parameters:parameters
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSError *error = nil;
            AylaPropertyTrigger *applicationTrigger =
                [[AylaPropertyTrigger alloc] initWithJSONDictionary:responseObject property:self error:&error];
            if (error) {
                AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, NSStringFromSelector(_cmd));
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(applicationTrigger);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)fetchTriggersWithSuccess:(void (^)(NSArray AYLA_GENERIC(AylaPropertyTrigger *) *))successBlock
                                   failure:(void (^)(NSError *))failureBlock
{
    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", self.key, @"/triggers.json"];
    return [httpClient getPath:path
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, NSArray AYLA_GENERIC(NSDictionary *) * _Nullable propertyTriggersDict) {
            int count = 0;
            NSMutableArray AYLA_GENERIC(AylaPropertyTrigger *) *propertyTriggers = [NSMutableArray array];
            for (NSDictionary *propertyTriggerDictionary in propertyTriggersDict) {
                NSError *error = nil;
                AylaPropertyTrigger *propertyTrigger =
                    [[AylaPropertyTrigger alloc] initWithJSONDictionary:propertyTriggerDictionary
                                                               property:self
                                                                  error:&error];
                [propertyTriggers addObject:propertyTrigger];
                count++;
            }
            AylaLogI([self logTag], 0, @"%@, found %d triggers, %@", @"", count, NSStringFromSelector(_cmd));

            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(propertyTriggers);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));

            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)deleteTrigger:(AylaPropertyTrigger *)trigger
                        success:(void (^)())successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!trigger) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey : @{@"trigger" : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"triggers/", trigger.key, @".json"];

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [httpClient deletePath:path
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock();
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {

            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (AylaHTTPTask *)updateTrigger:(AylaPropertyTrigger *)trigger
                        success:(void (^)(AylaPropertyTrigger *_Nonnull))successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock
{
    if (!trigger) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       AylaRequestErrorResponseJsonKey : @{@"trigger" : AylaErrorDescriptionIsInvalid}
                                   }];
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"triggers/", trigger.key, @".json"];

    NSDictionary *parameters = @{attrNameTrigger : [trigger toJSONDictionary]};

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [httpClient putPath:path
        parameters:parameters
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSError *error = nil;
            AylaPropertyTrigger *applicationTrigger =
                [[AylaPropertyTrigger alloc] initWithJSONDictionary:responseObject property:self error:&error];
            if (error) {
                AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject, NSStringFromSelector(_cmd));
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }

            AylaLogI([self logTag], 0, @"%@, %@", @"complete", NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(applicationTrigger);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {

            AylaLogE([self logTag], 0, @"err:%@, %@", error, NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (NSString *)logTag
{
    return @"Property";
}

//-----------------------------------------------------------
#pragma mark - Http Client
//-----------------------------------------------------------
- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaSessionManager *manager = (AylaSessionManager *)[self valueForKeyPath:@"device.deviceManager.sessionManager"];
    AylaHTTPClient *client = [manager getHttpClientWithType:AylaHTTPClientTypeDeviceService];
    
    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                            code:AylaRequestErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }
    
    return client;
}

+ (void)enableNetworkProfiler {
    AylaLanTaskClass = NSStringFromClass([AylaLanTaskProfiler class]);
}

@end

@implementation AylaProperty (NSCoding)

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _baseType = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(baseType))];
        _name = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(name))];
        _type = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(type))];
        _direction = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(direction))];
        _key = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(key))];
        _datapoint = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(datapoint))];
        _dataUpdatedAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(dataUpdatedAt))];
        _displayName = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(displayName))];

        _ackEnabled = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackEnabled))] boolValue];
        _ackedAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackedAt))];
        _ackStatus = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackStatus))] integerValue];
        _ackMessage = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(ackMessage))] integerValue];

        // Get processing queue from delegate. if there queue is not given from deleage, use main thread by default.
        _processingQueue = dispatch_get_main_queue();
        _lastUpdateSource = AylaDataSourceCache;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_baseType forKey:NSStringFromSelector(@selector(baseType))];
    [aCoder encodeObject:_name forKey:NSStringFromSelector(@selector(name))];
    [aCoder encodeObject:_type forKey:NSStringFromSelector(@selector(type))];
    [aCoder encodeObject:_direction forKey:NSStringFromSelector(@selector(direction))];
    [aCoder encodeObject:_key forKey:NSStringFromSelector(@selector(key))];
    [aCoder encodeObject:_datapoint forKey:NSStringFromSelector(@selector(datapoint))];
    [aCoder encodeObject:_dataUpdatedAt forKey:NSStringFromSelector(@selector(dataUpdatedAt))];
    [aCoder encodeObject:_displayName forKey:NSStringFromSelector(@selector(displayName))];

    [aCoder encodeObject:@(_ackEnabled) forKey:NSStringFromSelector(@selector(ackEnabled))];
    [aCoder encodeObject:_ackedAt forKey:NSStringFromSelector(@selector(ackedAt))];
    [aCoder encodeObject:@(_ackStatus) forKey:NSStringFromSelector(@selector(ackStatus))];
    [aCoder encodeObject:@(_ackMessage) forKey:NSStringFromSelector(@selector(ackMessage))];
}

@end
