//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaSchedule.h"

#import "AylaDefines_Internal.h"
#import "AylaDevice.h"
#import "AylaDeviceManager.h"
#import "AylaHTTPClient.h"
#import "AylaObject+Internal.h"
#import "AylaScheduleAction+Internal.h"
#import "AylaSessionManager+Internal.h"

NSString *const AylaScheduleDirectionToDevice   = @"input";
NSString *const AylaScheduleDirectionFromDevice = @"output";

static NSString *const AylaScheduleAttrNameSchedule         = @"schedule";

static NSString *const AylaScheduleAttrNameScheduleName     = @"name";
static NSString *const AylaScheduleAttrNameDisplayName      = @"display_name";
static NSString *const AylaScheduleAttrNameDirection        = @"direction";
static NSString *const AylaScheduleAttrNameActive           = @"active";
static NSString *const AylaScheduleAttrNameUTC              = @"utc";
static NSString *const AylaScheduleAttrNameStartDate        = @"start_date";
static NSString *const AylaScheduleAttrNameEndDate          = @"end_date";
static NSString *const AylaScheduleAttrNameStartTimeEachDay = @"start_time_each_day";
static NSString *const AylaScheduleAttrNameEndTimeEachDay   = @"end_time_each_day";
static NSString *const AylaScheduleAttrNameTimeBeforeEnd    = @"time_before_end";
static NSString *const AylaScheduleAttrNameDaysOfWeek       = @"days_of_week";
static NSString *const AylaScheduleAttrNameDaysOfMonth      = @"days_of_month";
static NSString *const AylaScheduleAttrNameMonthsOfYear     = @"months_of_year";
static NSString *const AylaScheduleAttrNameDayOccurOfMonth  = @"day_occur_of_month";
static NSString *const AylaScheduleAttrNameDuration         = @"duration";
static NSString *const AylaScheduleAttrNameInterval         = @"interval";
static NSString *const AylaScheduleAttrNameFixedActions     = @"fixed_actions";
static NSString *const AylaScheduleAttrNameScheduleActions  = @"schedule_actions";
static NSString *const AylaScheduleAttrNameKey              = @"key";

@interface AylaSchedule ()

@property (nonatomic, strong, nullable) NSNumber *key;
@property (nonatomic, weak, nullable) AylaDevice *device;

@end

@implementation AylaSchedule

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _active = YES;
    }
    
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    
    if (self) {
        NSDictionary *scheduleDict = dictionary[AylaScheduleAttrNameSchedule];
        
        if (scheduleDict) {
            _key = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameKey]);
            
            _name = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameScheduleName]);
            _displayName = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameDisplayName]);
            _direction = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameDirection]);
            _active = [(NSNumber *)scheduleDict[AylaScheduleAttrNameActive] boolValue];
            _utc = [(NSNumber *)scheduleDict[AylaScheduleAttrNameUTC] boolValue];
            _startDate = AYLNilIfNullOrEmptyString(scheduleDict[AylaScheduleAttrNameStartDate]);
            _endDate = AYLNilIfNullOrEmptyString(scheduleDict[AylaScheduleAttrNameEndDate]);
            _startTimeEachDay = AYLNilIfNullOrEmptyString(scheduleDict[AylaScheduleAttrNameStartTimeEachDay]);
            _endTimeEachDay = AYLNilIfNullOrEmptyString(scheduleDict[AylaScheduleAttrNameEndTimeEachDay]);
            _timeBeforeEnd = AYLNilIfNullOrEmptyString(scheduleDict[AylaScheduleAttrNameTimeBeforeEnd]);
            _daysOfWeek = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameDaysOfWeek]);
            _daysOfMonth = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameDaysOfMonth]);
            _monthsOfYear = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameMonthsOfYear]);
            _dayOccurOfMonth = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameDayOccurOfMonth]);
            _duration = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameDuration]);
            _interval = AYLNilIfNull(scheduleDict[AylaScheduleAttrNameInterval]);
            _fixedActions = [(NSNumber *)scheduleDict[AylaScheduleAttrNameFixedActions] boolValue];
        }
    }
    
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary device:(AylaDevice *)device error:(NSError *__autoreleasing _Nullable *)error
{
    AYLAssert(device, @"device cannot be nil!");
    
    self = [self initWithJSONDictionary:dictionary error:error];
    
    if (self) {
        _device = device;
    }
    
    return self;
}

- (nullable AylaHTTPTask *)fetchAllScheduleActionsWithSuccess:(void (^)(NSArray AYLA_GENERIC(AylaScheduleAction *) *scheduleActions))successBlock
                                                      failure:(void (^)(NSError *error))failureBlock
{
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
    
    NSString *path = [NSString stringWithFormat:@"schedules/%@/schedule_actions.json", self.key];
    
    return [httpClient getPath:path
                    parameters:nil
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           NSMutableArray AYLA_GENERIC(AylaScheduleAction *) *scheduleActions = nil;
                           
                           if ([responseObject count]) {
                               scheduleActions = [NSMutableArray new];
                               
                               for (NSDictionary *scheduleActionDict in responseObject) {
                                   AylaScheduleAction *scheduleAction = [[AylaScheduleAction alloc] initWithJSONDictionary:scheduleActionDict schedule:self error:nil];
                                   [scheduleActions addObject:scheduleAction];
                               }
                           }
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock([NSArray arrayWithArray:scheduleActions]);
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

- (nullable AylaHTTPTask *)fetchScheduleActionsByName:(NSString *)name
                                              success:(void (^)(NSArray AYLA_GENERIC(AylaScheduleAction *) *scheduleActions))successBlock
                                              failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert([name length], @"name cannot be nil or emtpy!");
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
    
    NSString *path = [NSString stringWithFormat:@"schedules/%@/schedule_actions/find_by_name.json", self.key];
    
    return [httpClient getPath:path
                    parameters:@{ @"name" : AYLNullIfNil(name) }
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           NSMutableArray AYLA_GENERIC(AylaScheduleAction *) *scheduleActions = nil;

                           if ([responseObject count]) {
                               scheduleActions = [NSMutableArray new];
                               
                               for (NSDictionary *scheduleActionDict in responseObject) {
                                   AylaScheduleAction *scheduleAction = [[AylaScheduleAction alloc] initWithJSONDictionary:scheduleActionDict schedule:self error:nil];
                                   [scheduleActions addObject:scheduleAction];
                               }
                           }
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock([NSArray arrayWithArray:scheduleActions]);
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

- (void)updateScheduleActions:(NSArray AYLA_GENERIC(AylaScheduleAction *) *)scheduleActionsToUpdate
                      success:(void (^)(NSArray AYLA_GENERIC(AylaScheduleAction *) *updatedScheduleActions))successBlock
                      failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(scheduleActionsToUpdate, @"scheduleActionsToUpdate cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"failureBlock cannot be NULL!");
    
    dispatch_group_t updateActionsGroup = dispatch_group_create();
    __block NSMutableArray AYLA_GENERIC(AylaScheduleAction *) *updatedActions = [NSMutableArray new];
    __block NSMutableArray AYLA_GENERIC(NSError *) *updateErrors = [NSMutableArray new];
    
    // Dispatch an update request for each action
    for (AylaScheduleAction *scheduleAction in scheduleActionsToUpdate) {
        dispatch_group_enter(updateActionsGroup);
        
        [scheduleAction updateWithSuccess:^(AylaScheduleAction * _Nonnull updatedScheduleAction) {
            [updatedActions addObject:updatedScheduleAction];
            dispatch_group_leave(updateActionsGroup);
        } failure:^(NSError * _Nonnull error) {
            [updateErrors addObject:error];
            dispatch_group_leave(updateActionsGroup);
        }];
    }
        
    dispatch_group_notify(updateActionsGroup, dispatch_get_main_queue(), ^{
        // If we logged any errors, return an incomplete failure
        if ([updateErrors count]) {
                NSError *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                            code:AylaRequestErrorCodeIncomplete
                                                        userInfo:@{ AylaRequestErrorCompletedItemsKey : [NSArray arrayWithArray:updatedActions],
                                                                    AylaRequestErrorBatchErrorsKey : [NSArray arrayWithArray:updateErrors] }];
                
                failureBlock(error);
        } else {
            successBlock([NSArray arrayWithArray:updatedActions]);
        }
    });
}

- (nullable AylaHTTPTask *)createScheduleAction:(AylaScheduleAction *)scheduleActionToCreate
                                        success:(void (^)(AylaScheduleAction *createdScheduleAction))successBlock
                                        failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(scheduleActionToCreate, @"scheduleActionToCreate cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"failureBlock cannot be NULL!");
    
    NSError *error = nil;
    
    if (![scheduleActionToCreate isValid:&error])
    {
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
    
    NSString *path = [NSString stringWithFormat:@"schedules/%@/schedule_actions.json", self.key];
    
    return [httpClient postPath:path
                     parameters:[scheduleActionToCreate toJSONDictionary]
                        success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                            AylaScheduleAction *action = [[AylaScheduleAction alloc] initWithJSONDictionary:responseObject schedule:self error:nil];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                successBlock(action);
                            });
                        }
                        failure:^(AylaHTTPTask *task, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                failureBlock(error);
                            });
                        }];
}

- (nullable AylaHTTPTask *)deleteScheduleAction:(AylaScheduleAction *)scheduleAction
                                        success:(void (^)())successBlock
                                        failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(scheduleAction, @"scheduleAction cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"failureBlock cannot be NULL!");
    
    return [scheduleAction deleteWithSuccess:successBlock failure:failureBlock];
}

- (void)deleteAllScheduleActionsWithSuccess:(void (^)())successBlock
                                    failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"failureBlock cannot be NULL!");
    
    [self fetchAllScheduleActionsWithSuccess:^(NSArray<AylaScheduleAction *> *scheduleActions) {
        dispatch_group_t deleteActionsGroup = dispatch_group_create();
        __block NSMutableArray AYLA_GENERIC(AylaScheduleAction *) *deletedActions = [NSMutableArray new];
        __block NSMutableArray AYLA_GENERIC(NSError *) *deletionErrors = [NSMutableArray new];
        
        // Dispatch a delete request for each action
        for (AylaScheduleAction *scheduleAction in scheduleActions) {
            dispatch_group_enter(deleteActionsGroup);
            
            [self deleteScheduleAction:scheduleAction
                               success:^{
                                   [deletedActions addObject:scheduleAction];
                                   dispatch_group_leave(deleteActionsGroup);
                               }
                               failure:^(NSError * _Nonnull error) {
                                   [deletionErrors addObject:error];
                                   dispatch_group_leave(deleteActionsGroup);
                               }];
        }
        
        dispatch_group_notify(deleteActionsGroup, dispatch_get_main_queue(), ^{
            // If we logged any errors, return an incomplete failure
            if ([deletionErrors count]) {
                NSError *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                    code:AylaRequestErrorCodeIncomplete
                                                        userInfo:@{ AylaRequestErrorCompletedItemsKey : [NSArray arrayWithArray:deletedActions],
                                                                    AylaRequestErrorBatchErrorsKey : [NSArray arrayWithArray:deletionErrors] }];
                
                failureBlock(error);
            } else {
                successBlock();
            }
        });
    }
                                            failure:^(NSError * _Nonnull error) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    failureBlock(error);
                                                });
                                            }];
}

#pragma mark -
#pragma mark Internal APIs

- (BOOL)isValid:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    NSError *scheduleError = nil;
    
    NSMutableDictionary *errorResponseInfo = [NSMutableDictionary new];
    
    if (![self.name length]) {
        errorResponseInfo[AylaScheduleAttrNameScheduleName] = AylaErrorDescriptionCanNotBeBlank;
    }
    
    if (![self.direction length]) {
        errorResponseInfo[AylaScheduleAttrNameDirection] = AylaErrorDescriptionCanNotBeBlank;
    }
    
    if (![self.startTimeEachDay length]) {
        errorResponseInfo[AylaScheduleAttrNameStartTimeEachDay] = AylaErrorDescriptionCanNotBeBlank;
    }
    
    if ([errorResponseInfo count]) {
        scheduleError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                   code:AylaRequestErrorCodeInvalidArguments
                                               userInfo:@{
                                                          AylaRequestErrorResponseJsonKey : errorResponseInfo
                                                          }
                                              shouldLog:YES
                                                 logTag:[self logTag]
                                       addOnDescription:@"invalidSchedule"];
    }
    
    if (error) {
        *error = scheduleError;
    }
    
    return (scheduleError == nil);
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[AylaScheduleAttrNameScheduleName] = AYLNullIfNil(self.name);
    
    if (self.displayName) {
        dict[AylaScheduleAttrNameDisplayName] = self.displayName;
    }
    
    dict[AylaScheduleAttrNameDirection] = AYLNullIfNil(self.direction);
    
    dict[AylaScheduleAttrNameActive] = @(self.isActive);
    dict[AylaScheduleAttrNameUTC] = @(self.isUsingUTC);
    dict[AylaScheduleAttrNameFixedActions] = @(self.fixedActions);
    
    if (self.startDate) {
        dict[AylaScheduleAttrNameStartDate] = self.startDate;
    }

    if (self.endDate) {
        dict[AylaScheduleAttrNameEndDate] = self.endDate;
    }

    if (self.startTimeEachDay) {
        dict[AylaScheduleAttrNameStartTimeEachDay] = self.startTimeEachDay;
    }

    if (self.endTimeEachDay) {
        dict[AylaScheduleAttrNameEndTimeEachDay] = self.endTimeEachDay;
    }

    if (self.timeBeforeEnd) {
        dict[AylaScheduleAttrNameTimeBeforeEnd] = self.timeBeforeEnd;
    }

    if (self.daysOfWeek) {
        dict[AylaScheduleAttrNameDaysOfWeek] = self.daysOfWeek;
    }

    if (self.daysOfMonth) {
        dict[AylaScheduleAttrNameDaysOfMonth] = self.daysOfMonth;
    }
    
    if (self.monthsOfYear) {
        dict[AylaScheduleAttrNameMonthsOfYear] = self.monthsOfYear;
    }

    if (self.dayOccurOfMonth) {
        dict[AylaScheduleAttrNameDayOccurOfMonth] = self.dayOccurOfMonth;
    }

    if (self.duration) {
        dict[AylaScheduleAttrNameDuration] = self.duration;
    }

    if (self.interval) {
        dict[AylaScheduleAttrNameInterval] = self.interval;
    }

    if (self.key) {
        dict[AylaScheduleAttrNameKey] = self.key;
    }
    
    return [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithDictionary:dict] forKey:AylaScheduleAttrNameSchedule];
}

- (id)copyWithZone:(NSZone *)zone
{
    AylaSchedule *copy = [super copyWithZone:zone];
    
    copy.device = self.device;

    return copy;
}

#pragma mark -
#pragma mark Utilities

- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaHTTPClient *client = [self.device.deviceManager.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];
    
    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                            code:AylaRequestErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }
    
    return client;
}

- (NSString *)logTag
{
    return @"Schedule";
}

@end
