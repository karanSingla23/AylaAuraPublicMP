//
//  AylaLanMessageCreator.m
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/15/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaEncryption.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPServer.h"
#import "AylaLanMessage.h"
#import "AylaLanMessageCreator.h"

NSString *const AylaLanPathCommands = @"/commands.json";
NSString *const AylaLanPathConnStatus = @"/conn_status.json";
NSString *const AylaLanPathDatapoint = @"property/datapoint.json";
NSString *const AylaLanPathDatapointAck = @"property/datapoint/ack.json";
NSString *const AylaLanPathKeyExchange = @"key_exchange.json";

NSString *const AylaLanPathNodePrefix = @"node/";
NSString *const AylaLanPathLocalLanPrefix = @"local_lan/";

@implementation AylaLanMessageCreator

+ (instancetype)defaultCreator
{
    return [[self alloc] init];
}

- (AylaLanMessage *)messageFromHTTPServerRequest:(AylaHTTPServerRequest *)request
                                      encryption:(AylaEncryption *)encryption
                                           error:(NSError *__autoreleasing *)error
{
    AylaLanMessageType type = [self getTypeWithMethod:request.method path:request.URI];
    NSData *data = request.bodyData;
    // We will skip decryption for messages with type AylaLanMessageTypeCommands or AylaLanMessageTypeKeyExchange
    switch (type) {
        case AylaLanMessageTypeCommands:
        case AylaLanMessageTypeKeyExchange:
            break;
        default:
            data = [self decryptedConntent:request.bodyData encryption:encryption error:error];
            break;
    }

    AylaLanMessage *message = [[AylaLanMessage alloc] initWithType:type url:request.URI data:data];
    return message;
}

- (NSData *)decryptedConntent:(NSData *)data
                   encryption:(AylaEncryption *)encryption
                        error:(NSError *__autoreleasing *)error
{
    NSError *jerr;
    id responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jerr];
    if (!responseJSON) {
        AylaLogE([self logTag], 0, @"%@:%ld, %@", @"jerr", (long)jerr.code, @"decryptedContent");
        if (error) {
            *error = jerr;
        }
        return nil;
    }

    NSDictionary *jsonDict = responseJSON;
    NSString *sign = [jsonDict valueForKeyPath:@"sign"];
    NSString *enc = [jsonDict valueForKeyPath:@"enc"];

    NSData *decodedSign = [AylaEncryption base64Decode:sign];
    NSData *decodedEnc = [AylaEncryption base64Decode:enc];

    NSData *decryptedEnc = [encryption lanModeDecryptInStream:decodedEnc];
    if (!decryptedEnc) {
        NSError *err = [AylaErrorUtils errorWithDomain:AylaLanErrorDomain
                                                  code:AylaLanErrorCodeEncryptionFailure
                                              userInfo:@{
                                                  AylaLanErrorResponseJsonKey : @{@"failure" : @"encryption failed."}
                                              }];
        AylaLogE([self logTag], 0, @"%@:%@, %@", @"decryp", @"failed", @"decryptedContent");
        if (error) {
            *error = err;
        }
        return nil;
    }

    NSData *calcSign = [AylaEncryption hmacForKey:[encryption devSignKey] data:decryptedEnc];
    if (![decodedSign isEqualToData:calcSign]) {
        NSError *err =
            [AylaErrorUtils errorWithDomain:AylaLanErrorDomain
                                       code:AylaLanErrorCodeEncryptionFailure
                                   userInfo:@{
                                       AylaLanErrorResponseJsonKey : @{@"sign" : AylaErrorDescriptionIsInvalid}
                                   }];
        AylaLogE([self logTag], 0, @"%@:%@, %@", @"signature", @"is invalid", @"decryptedContent");
        if (error) {
            *error = err;
        }
        return nil;
    }

    return decryptedEnc;
}

/**
 * Adjust this method when a new lan message type needs to be supported.
 *
 * @param method HTTP request method
 * @param path   Request path.
 *
 * @return Correpsonding message type from method and path.
 */
- (AylaLanMessageType)getTypeWithMethod:(NSString *)method path:(NSString *)path
{
    AylaLanMessageType type = AylaLanMessageTypeUnknown;
    if ([method isEqualToString:AylaHTTPRequestMethodPOST]) {
        if ([path containsString:AylaLanPathDatapoint]) {
            type = AylaLanMessageTypeUpdateDatapoint;
        }
        else if ([path containsString:AylaLanPathKeyExchange]) {
            type = AylaLanMessageTypeKeyExchange;
        }
        else if ([path containsString:AylaLanPathConnStatus]) {
            type = AylaLanMessageTypeConnStatus;
        }
        else if ([path containsString:AylaLanPathDatapointAck]) {
            type = AylaLanMessageTypeDatapointAck;
        }
    }
    else if ([method isEqualToString:AylaHTTPRequestMethodGET]) {
        if ([path containsString:AylaLanPathCommands]) {
            type = AylaLanMessageTypeCommands;
        }
    }
    return type;
}

- (NSString *)logTag
{
    return @"LanMessageCreator";
}

@end
