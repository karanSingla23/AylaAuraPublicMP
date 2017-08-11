//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AylaDeviceManager;
@class AylaDSMessage;

@interface AylaDSHandler : NSObject

/** Weak reference to linked device manager. */
@property (nonatomic, weak, readonly, nullable) AylaDeviceManager *deviceManager;

/**
 * Init method.
 *
 * @param deviceManager device manager which would be queried from.
 */
- (instancetype)initWithDeviceManager:(nullable AylaDeviceManager *)deviceManager NS_DESIGNATED_INITIALIZER;

/**
 * Use this method to let DS handler invoke corresponding receivers for each message.
 *
 * @param message To-be-processed datastream message .
 */
- (void)handleMessage:(AylaDSMessage *)message;

/**
 * A helpful method to get a DS message from raw string.
 *
 * @param string String to be parsed from.
 *
 * @return Created DSMessage object. Return nil if input string is invalid.
 */
- (nullable AylaDSMessage *)messageFromRawString:(NSString *)string;

// Unavailable methods
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END