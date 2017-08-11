//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * RSA key size options
 */
typedef NS_ENUM(uint32_t, AylaKeyCryptoRSAKeySize) {
    /**
     * RSA key size 1024
     */
    AylaKeyCryptoRSAKeySize1024 = 1024,
    /**
     * RSA key size 1056
     */
    AylaKeyCryptoRSAKeySize1056 = 1056,
    /**
     * RSA key size 2048
     */
    AylaKeyCryptoRSAKeySize2048 = 2048
};

/**
 * Key Crypto helps get and manage a key pair fetched from system key chain.
 *
 * All key tags and key refs will be set as null for a newly initialized instance of this class. To prepare a valid key
 * pair, you must call -getKeyPairFromKeyChainWithPubKeyTag:privKeyTag to query for a key pair in key chain. If you
 * want to update the key pair with the key tags, you could invoke -updateRSAKeyPairInKeyChain: to generate a new key 
 * pair using same key tags.
 *
 * @note Synchronous api -updateRSAKeyPairInKeyChain: will potentialy take a while to generate a new key pair. Calling
 * it from main thread will cause an assertion.
 */
@interface AylaKeyCrypto : NSObject

/** Tag of public key in key chain */
@property (nonatomic, nullable) NSString *pubKeyTag;

/** Tag of private key in key chain */
@property (nonatomic, nullable) NSString *privKeyTag;

/** Ref to a copy of public key in key chain */
@property (nonatomic, readonly, nullable) SecKeyRef pubKeyRef;

/** Ref to a copy of private key in key chain */
@property (nonatomic, readonly, nullable) SecKeyRef privKeyRef;

/**
 * Use this method to get bytes of public key.
 *
 * @return The data instance which contains bytes of public key.
 */
- (nullable NSData *)publicKeyInData;

/**
 * Use this method to get key pair with tags from key chain.
 *
 * @param pubKeyTag  The tag of public key in the key chain. In nil is passed in, default public key tag will be used.
 * @param privKeyTag The tag of private key in the key chain. In nil is passed in, default private key tag will be used.
 *
 * @return YES if a key pair has been found and current crypto has been updated with this key pair.
 */
- (BOOL)getKeyPairFromKeyChainWithPubKeyTag:(nullable NSString *)pubKeyTag privKeyTag:(nullable NSString *)privKeyTag;

/**
 * Use this method to update key pair inside the key chain with a key size.
 *
 * @param keySize The key size of updated key pair.
 *
 * @return YES if key pair has been updated and current crypto has been updated with this key pair.
 *
 * @note An assertion would be fired if this method was called on main thread.
 */
- (BOOL)updateRSAKeyPairInKeyChain:(AylaKeyCryptoRSAKeySize)keySize;

/**
 * Use key pair to decypt the input data as lan key.
 *
 * @param data The data which needs to be decypted.
 *
 * @return Decrypted data. Nil would be returned if error was hit during decryption.
 *
 * @note The lengh of decrypted lan key can not be greater than 1024.
 */
- (nullable NSData *)decryptAsLanKey:(NSData *)data;

@end

NS_ASSUME_NONNULL_END