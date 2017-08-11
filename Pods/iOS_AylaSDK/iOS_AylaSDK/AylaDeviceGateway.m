//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint.h"
#import "AylaDatapointParams.h"
#import "AylaDefines_Internal.h"
#import "AylaDevice+Internal.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceManager.h"
#import "AylaDeviceNode.h"
#import "AylaLanMessage.h"
#import "AylaLanMessageCreator.h"
#import "AylaObject+Internal.h"
#import "AylaProperty+Internal.h"
#import "AylaRegistration+Internal.h"
#import "AylaRegistrationCandidate.h"

static NSString *const attrNameConnectionStatus = @"connection_status";
static NSString *const deviceConnectionStatusOnline = @"Online";
static NSString *const deviceConnectionStatusOffline = @"Offline";

static NSString *const deviceTypeNode = @"Node";

@implementation AylaDeviceGateway

- (NSArray *)nodes
{
    // Returns nil if device list owned by device manager can't be found.
    NSArray *devices = self.deviceManager.devices.allValues;
    if (!devices) {
        return nil;
    }

    // Get all nodes belonging to current gateway
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"SELF.deviceType == %@ AND SELF.gatewayDsn == %@", deviceTypeNode, self.dsn];
    return [devices filteredArrayUsingPredicate:predicate];
}

- (AylaDeviceNode *)getNodeWithDsn:(NSString *)dsn
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.dsn == %@", dsn];
    NSArray *filtered = [self.nodes filteredArrayUsingPredicate:predicate];
    return filtered.count > 0 ? filtered[0] : nil;
}

- (AylaConnectTask *)openRegistrationJoinWindow:(NSUInteger)durationInSeconds
                                        success:(void (^)(void))successBlock
                                        failure:(void (^)(NSError *_Nonnull error))failureBlock
{
    AylaProperty *joinProperty = self.properties[[self getJoinEnablePropertyName]];
    if (!joinProperty) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodePreconditionFailure
                                   userInfo:@{ [self getJoinEnablePropertyName] : AylaErrorDescriptionCanNotBeFound }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"openRegistrationJoinWindow"];

        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    // Create a datapoint to join property with input durationInSeconds
    AylaDatapointParams *params = [[AylaDatapointParams alloc] init];
    params.value = @(durationInSeconds);
    return [joinProperty createDatapoint:params
                                 success:^(AylaDatapoint *_Nonnull createdDatapint) {
                                     successBlock();
                                 }
                                 failure:failureBlock];
}

- (AylaConnectTask *)closeRegistrationJoinWindow:(void (^)(void))successBlock
                                         failure:(void (^)(NSError *_Nonnull))failureBlock
{
    return [self openRegistrationJoinWindow:0 success:successBlock failure:failureBlock];
}

- (NSString *)getJoinEnablePropertyName
{
    return @"join_enable";
}

/**
 * Handle connection status update array.
 *
 * @param updates An array of connections status updates.
 */
- (void)handleConnStatusUpdates:(NSArray *)updates dataSource:(AylaDataSource)dataSource
{
    if (updates) {
        // Example: [{"dsn": "VR0005ZZZABCD","status": true}]
        for (NSDictionary *connStatus in updates) {
            NSString *dsn = connStatus[NSStringFromSelector(@selector(dsn))];
            AylaDeviceNode *node = [self getNodeWithDsn:dsn];
            if (node) {
                // Create temporary device to invoke the updateFrom: api of node.
                NSDictionary *deviceDictionary = @{
                    attrNameConnectionStatus : [connStatus[NSStringFromSelector(@selector(status))] boolValue]
                                                   ? deviceConnectionStatusOnline
                                                   : deviceConnectionStatusOffline
                };
                AylaDeviceNode *temp = [[AylaDeviceNode alloc] initWithJSONDictionary:deviceDictionary error:nil];
                [node updateFrom:temp dataSource:dataSource];
            }
        }
    }
}

/**
 * Override lan module call back to gurantee node messages are handled correctly
 */
- (void)lanModule:(AylaLanModule *)lanModuel didReceiveMessage:(AylaLanMessage *)message
{
    BOOL handled = NO;
    switch (message.type) {
        case AylaLanMessageTypeConnStatus:
            if ([message.url containsString:[@"/" stringByAppendingString:AylaLanPathNodePrefix]]) {
                [self handleConnStatusUpdates:message.jsonObject[@"connection"] dataSource:AylaDataSourceLAN];
                handled = YES;
            }
            break;
        case AylaLanMessageTypeUpdateDatapoint:
            // When receving a datapoint update, check if this update belongs to a known node.
            if ([message.url containsString:[@"/" stringByAppendingString:AylaLanPathNodePrefix]]) {
                AylaDeviceNode *node = [self getNodeWithDsn:message.jsonObject[NSStringFromSelector(@selector(dsn))]];
                if (node) {
                    [node lanModule:lanModuel didReceiveMessage:message];
                }
                else {
                    AylaLogI([self logTag], 0, @"%@, %@", @"node is not found", @"didReceiveMessage");
                }
                handled = YES;
            }
            break;
        default:
            break;
    }
    if (!handled) {
        [super lanModule:lanModuel didReceiveMessage:message];
    }
}

- (NSString *)logTag
{
    return @"DeviceGateway";
}

- (AylaHTTPTask *)fetchCandidatesWithSuccess:
                      (void (^)(NSArray AYLA_GENERIC(AylaRegistrationCandidate *) * candidates))successBlock
                                     failure:(void (^)(NSError *error))failureBlock
{
    AylaDeviceManager *deviceManager = self.deviceManager;
    if (!self.dsn) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodeInvalidArguments
                                   userInfo:@{
                                       NSStringFromSelector(@selector(dsn)) : AylaErrorDescriptionCanNotBeBlank
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"fetchCandidates"];

        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }
    else if (deviceManager == nil) {
        NSError *error =
            [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                       code:AylaRequestErrorCodePreconditionFailure
                                   userInfo:@{
                                       NSStringFromSelector(@selector(deviceManager)) : AylaErrorDescriptionIsInvalid
                                   }
                                  shouldLog:YES
                                     logTag:[self logTag]
                           addOnDescription:@"fetchCandidates"];

        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    return [deviceManager.registration fetchCandidatesWithDSN:self.dsn
                                             registrationType:AylaRegistrationTypeNode
                                                      success:successBlock
                                                      failure:failureBlock];
}

@end
