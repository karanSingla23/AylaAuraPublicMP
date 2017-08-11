//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const AylaEncryptionTypeLAN;
FOUNDATION_EXPORT NSString *const AylaEncryptionTypeWifiSetup;

/**
 * Encryption config which will be used to initialize AylaEncryption instance.
 *
 * When type is set as AylaEncryptionTypeLAN: lanipKey must be set with the key fetched from cloud.
 * When type is set as AylaEncryptionTypeWifiSetup: data must be set with decrypted key data.
 */
@interface AylaEncryptionConfig : NSObject

/** Current supported types: AylaEncryptionTypeLAN, AylaEncryptionTypeWifiSetup */
@property (nonatomic) NSString *type;
@property (nonatomic) NSData *data;
@property (nonatomic) NSString *lanipKey;

@end

/**
 * AylaEncryption
 *
 * An cryption class which handles lan encryption flows.
 */
@interface AylaEncryption : NSObject

@property (nonatomic) NSNumber *version;
@property (nonatomic) NSNumber *proto1;
@property (nonatomic) NSNumber *keyId1;
@property (nonatomic) NSInteger sessionId;

@property (nonatomic) NSString *sRnd1;
@property (nonatomic) NSString *sRnd2;
@property (nonatomic) NSNumber *nTime1;
@property (nonatomic) NSNumber *nTime2;

@property (nonatomic, readonly) NSData *appSignKey;
@property (nonatomic, readonly) NSData *devSignKey;

- (NSError *)generateSessionkeys:(AylaEncryptionConfig *)config
                           sRnd1:(NSString *)sRnd1
                          nTime1:(NSNumber *)nTime1
                           sRnd2:(NSString *)sRnd2
                          nTime2:(NSNumber *)nTime2;

+ (NSData *)hmacForKey:(NSData *)key data:(NSData *)data;

- (NSData *)lanModeEncryptInStream:(NSString *)plainText;
- (NSData *)lanModeDecryptInStream:(NSData *)cipherData;

+ (NSData *)base64Decode:(NSString *)string;

+ (NSData *)dataFromHexString:(NSString *)hexString;
+ (NSString *)dataToHexString:(NSData *)data;

- (NSString *)encryptEncapsulateSignWithPlaintext:(NSString *)plaintext sign:(NSData *)sign;

- (void)cleanEncrypSession;

//-----------TokenGeneration-----------------------------
+ (NSString *)randomToken:(int)len;

@end
