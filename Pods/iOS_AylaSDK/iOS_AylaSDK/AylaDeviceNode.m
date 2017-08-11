//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceManager.h"
#import "AylaDeviceNode.h"
#import "AylaErrorUtils.h"
#import "AylaLanCommand.h"
#import "AylaLanModule.h"
#import "AylaLanTask.h"
#import "AylaDevice+Extensible.h"

static NSString *const attrNameGatewayDsn = @"gateway_dsn";
static NSString *const attrNodeType = @"node_type";

@implementation AylaDeviceNode

- (AylaDeviceGateway *)gateway
{
    return self.deviceManager.devices[self.gatewayDsn];
}

- (instancetype)initWithDeviceManager:(AylaDeviceManager *)deviceManager
                       JSONDictionary:(NSDictionary *)dictionary
                                error:(NSError *_Nullable __autoreleasing *)error
{
    self = [super initWithDeviceManager:deviceManager JSONDictionary:dictionary error:error];

    _gatewayDsn = dictionary[attrNameGatewayDsn];

    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError * _Nullable __autoreleasing *)error {
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        _nodeType = [dictionary[attrNodeType] nilIfNull];
    }
    return self;
}

/**
 * Override fetch properties LAN api
 */
- (AylaLanTask *)fetchPropertiesLAN:(NSArray *)propertyNames
                            success:(void (^)(NSArray AYLA_GENERIC(AylaProperty *) * _Nonnull))successBlock
                            failure:(void (^)(NSError *_Nonnull))failureBlock
{
    // If propertyNames is nil, fetch all properties
    if (propertyNames.count == 0) {
        NSError *error = [AylaErrorUtils
            errorWithDomain:AylaRequestErrorDomain
                       code:AylaRequestErrorCodeInvalidArguments
                   userInfo:@{
                       AylaRequestErrorResponseJsonKey : @{@"propertyNames" : AylaErrorDescriptionIsInvalid}
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
            [AylaLanCommand GETNodePropertyCommandWithNodeDsn:self.dsn propertyName:propertyName data:nil];
        [commands addObject:command];
    }

    AylaLanTask *task = [[AylaLanTask alloc] initWithPath:@"property.json"
        commands:commands
        success:^(id _Nonnull responseObject) {
            // Handle task callbacks.
            AylaLogI([self logTag], 0, @"%@, %@", @"finished", @"fetchPropertiesLAN");
            dispatch_async([AylaDevice deviceProcessingQueue], ^{

                NSMutableArray *properties = [NSMutableArray array];
                NSMutableDictionary *errorResponseInfo = [NSMutableDictionary dictionary];
                // Send an error back if we found any missing ones in the returned list
                for (NSDictionary *data in responseObject) {
                    AylaProperty *property = self.properties[data[@"name"]];
                    if (property) {
                        [properties addObject:property];
                    }
                    else {
                        errorResponseInfo[data[@"name"]] = AylaErrorDescriptionCanNotBeFound;
                    }
                }
                if (errorResponseInfo.count == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(properties);
                    });
                }
                else {
                    // If we have hit at least one error, call failureBlock with an error object.
                    NSError *error = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
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
        failure:^(NSError *_Nonnull error) {
            AylaLogI([self logTag], 0, @"err:%@, %@", error, @"fetchPropertiesLAN");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];

    // Try to deploy this lan task.
    NSError *error;
    if (![self deployLanTask:task error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return task;
}

/**
 * Override lan session api to avoid enabling lan session of a gateway.
 */
- (BOOL)enableLanSession
{
    return NO;
}

- (void)disableLanSession
{
    // Since node can't eastablish lan session. We skip this api here.
}

/**
 * Override to use gateway's lan module.
 */
- (AylaLanModule *)lanModule
{
    return self.gateway.lanModule;
}

- (BOOL)isLanModeActive
{
    return self.gateway.isLanModeActive;
}

- (BOOL)lanModePermitted
{
    return self.gateway.lanModePermitted;
}

/**
 * Override this method to check self.gateway first. If gateway can't be found, return an error.
 */
- (BOOL)deployLanTask:(AylaLanTask *)lanTask error:(NSError *__autoreleasing _Nullable *)error
{
    // If gateway of current node can't be found, return an error.
    AylaDeviceGateway *gateway = self.gateway;
    if (!gateway) {
        if (error) {
            *error =
                [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                           code:AylaRequestErrorCodePreconditionFailure
                                       userInfo:@{
                                           NSStringFromSelector(@selector(gateway)) : AylaErrorDescriptionCanNotBeFound
                                       }];
        }
        return NO;
    }

    return [super deployLanTask:lanTask error:error];
}

//-----------------------------------------------------------
#pragma mark - Property Delegate
//-----------------------------------------------------------
/**
 * Override this method to create a datapoint lan command for a node property.
 */
- (AylaLanCommand *)property:(AylaProperty *)property lanCommandToCreateDatapoint:(AylaDatapointParams *)datapointParams
{
    AYLAssert(self.dsn, @"Trying to create lan command with an invalid node object.");
    return [AylaLanCommand POSTNodeDatapointCommandWithNodeDsn:self.dsn
                                                  nodeProperty:property
                                               datapointParams:datapointParams];
}

//-----------------------------------------------------------
#pragma mark - Helpful Methods
//-----------------------------------------------------------

- (NSString *)logTag
{
    return @"DeviceNode";
}

@end
