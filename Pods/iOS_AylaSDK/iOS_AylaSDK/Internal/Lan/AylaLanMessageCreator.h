//
//  AylaLanMessageCreator.h
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/15/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const AylaLanPathNodePrefix;

@class AylaEncryption;
@class AylaHTTPServerRequest;
@class AylaLanMessage;

/**
 * Lan message creator which composes lan messages
 */
@interface AylaLanMessageCreator : NSObject

/**
 * Get a default creator.
 */
+ (instancetype)defaultCreator;

/**
 * Compose a message from HTTP server request.
 *
 * @param request    HTTP server request
 * @param encryption The encryption which should be used to decrypt content in request.
 * @param error      An error wil be set if lan message can't be initialized successfully.
 *
 * @return Return composed lan message.
 * @attension This method will attempt to decrypt all messages except type AylaLanMessageTypeCommands or
 * AylaLanMessageTypeKeyExchange. Make sure to add message type to the skip flow if you have a new lan support which
 * doesn't need decrypt content.
 */
- (AylaLanMessage *)messageFromHTTPServerRequest:(AylaHTTPServerRequest *)request
                                      encryption:(AylaEncryption *)encryption
                                           error:(NSError *__autoreleasing *)error;

@end
