//
//  AylaLanMessage.h
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/15/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * List of message types.
 */
typedef NS_ENUM(NSInteger, AylaLanMessageType) {
    /**
     * Unknow message
     */
    AylaLanMessageTypeUnknown,
    /**
     * Commands
     */
    AylaLanMessageTypeCommands,
    /**
     * Update datapoint
     */
    AylaLanMessageTypeUpdateDatapoint,
    /**
     * Key exchange
     */
    AylaLanMessageTypeKeyExchange,
    /**
     * Connection status
     */
    AylaLanMessageTypeConnStatus,
    /**
     * Datapoint ack
     */
    AylaLanMessageTypeDatapointAck
};

/**
 * AylaLanMessage
 *
 * Each instance of AylaLanMessage represents a message from device.
 */
@interface AylaLanMessage : NSObject

/** Message type */
@property (nonatomic, readonly) AylaLanMessageType type;

/** Message URL */
@property (nonatomic, setter=setUrl:) NSString *url;

/** Params from message URL */
@property (nonatomic, readonly) NSDictionary *urlParams;

/** Orignial data from device */
@property (nonatomic) NSData *data;

/** Command id parsed from urlParams. Return 0 if no cmdId is found. */
@property (nonatomic, getter=cmdId, readonly) NSUInteger cmdId;

/** Status parsed from urlParams. Return 0 if no statue is found. */
@property (nonatomic, getter=status, readonly) NSInteger status;

/** If message is a callback of a request. */
@property (nonatomic, getter=isCallback, readonly) BOOL isCallback;

/** Serialized `data` field from original data */
@property (nonatomic, readonly) id jsonObject;

/** Encountered error when serialzing message content */
@property (nonatomic, readonly) NSError *error;

/**
 * Init method
 */
- (instancetype)initWithType:(AylaLanMessageType)type
                         url:(NSString *)url
                        data:(NSData *)data;

@end
