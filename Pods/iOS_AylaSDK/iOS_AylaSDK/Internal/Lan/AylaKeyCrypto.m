//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines_Internal.h"
#import "AylaKeyCrypto.h"
#import "AylaLogManager.h"
#import "NSData+Base64.h"

/** Default RSA public key tag */
static NSString *const defaultKeyExchangeIdentifierRSAPublic = @"com.aylanetworks.keyCrypto.rsaPublicKey";

/** Default RSA private key tag */
static NSString *const defaultKeyExchangeIdentifierRSAPrivate = @"com.aylanetworks.keyCrypto.rsaPrivateKey";

@interface AylaKeyCrypto ()

@property (nonatomic, readwrite) SecKeyRef pubKeyRef;
@property (nonatomic, readwrite) SecKeyRef privKeyRef;
@property (nonatomic, readwrite) NSRecursiveLock *lock;

@end

@implementation AylaKeyCrypto

- (instancetype)init
{
    self = [super init];
    
    if(self) {
        _lock = [[NSRecursiveLock alloc] init];
    }
    
    return self;
}

/**
 * Get public key in data
 *
 * @return Return key as NSData object.
 */
- (NSData *)publicKeyInData
{
    if (self.pubKeyTag) {
        return [self getKeyInBitsFromKeyChainWithTag:self.pubKeyTag];
    }
    return nil;
}

- (BOOL)getKeyPairFromKeyChainWithPubKeyTag:(nullable NSString *)pubKeyTag privKeyTag:(nullable NSString *)privKeyTag
{
    [self.lock lock];
    
    // Use default key tags if tags are not set correctly.
    if(!pubKeyTag || !privKeyTag) {
        pubKeyTag = defaultKeyExchangeIdentifierRSAPublic;
        privKeyTag = defaultKeyExchangeIdentifierRSAPrivate;
    }
    
    self.pubKeyRef = [self getKeyRefFromKeyChainWithTag:pubKeyTag];
    self.privKeyRef = [self getKeyRefFromKeyChainWithTag:privKeyTag];
    BOOL re = YES;
    if (self.pubKeyRef && self.privKeyRef) {
        self.pubKeyTag = pubKeyTag;
        self.privKeyTag = privKeyTag;;
    }
    else {
        re = NO;
    }
    
    [self.lock unlock];
    return re;
}

- (BOOL)updateRSAKeyPairInKeyChain:(AylaKeyCryptoRSAKeySize)keySize
{
    // This method will return NO immidilately if either pubKeyTag or privKeyTag are not set.
    if (!self.pubKeyTag || !self.privKeyTag) {
        return NO;
    }
    return [self generateRSAKeyPair:keySize
                          pubKeyTag:self.pubKeyTag ?: defaultKeyExchangeIdentifierRSAPublic
                         privKeyTag:self.privKeyTag ?: defaultKeyExchangeIdentifierRSAPrivate];
}

- (BOOL)generateRSAKeyPair:(AylaKeyCryptoRSAKeySize)keySize
                 pubKeyTag:(NSString *)pubKeyTag
                privKeyTag:(NSString *)privKeyTag
{
    AYLAssert(![NSThread isMainThread], @"Key pair generation must be off main thread.");

    [self.lock lock];
    
    SecKeyRef publicKey = NULL;
    SecKeyRef privateKey = NULL;

    NSData *publicTag = [pubKeyTag dataUsingEncoding:NSUTF8StringEncoding];
    NSData *privateTag = [privKeyTag dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];

    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithUnsignedInteger:keySize] forKey:(__bridge id)kSecAttrKeySizeInBits];

    [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];

    [keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];

    OSStatus sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
    if (sanityCheck == noErr) {
        if (self.pubKeyRef) {
            CFRelease(self.pubKeyRef);
        }
        self.pubKeyRef = publicKey;

        if (self.privKeyRef) {
            CFRelease(self.privKeyRef);
        }
        self.privKeyRef = privateKey;
    }
    else {
        AylaLogE([self logTag], 0, @"%@:%d, %@", @"failed", (int)sanityCheck, @"generateRSAKeyPair");
    }

    [self.lock unlock];
    
    return sanityCheck == noErr;
}

- (nullable NSData *)decryptAsLanKey:(NSData *)data
{
    [self.lock lock];
    
    SecKeyRef keyRef = self.privKeyRef;
    if(keyRef == NULL) {
        [self.lock unlock];
        return nil;
    }
    unsigned char decrypBuf[1024];
    size_t decryptedLength = 1024;
    OSStatus status =
        SecKeyDecrypt((SecKeyRef)keyRef, kSecPaddingNone, data.bytes, [data length], decrypBuf, &decryptedLength);
    if (status != noErr) {
        AylaLogE([self logTag], 0, @"failed:%d, %@", (int)status, @"decryptData");
        [self.lock unlock];
        return nil;
    }
    
    long dataLength = SecKeyGetBlockSize(keyRef) - 1;
    if (decryptedLength != dataLength || decrypBuf[0] != 0x02) {
        AylaLogE([self logTag], 0, @"invalid len:%zd, %@", decryptedLength, @"decryptData");
        [self.lock unlock];
        return nil;
    }

    // One more step before padding
    unsigned char tmpDecrypBuf[1024];
    tmpDecrypBuf[0] = 0x00;
    memcpy(tmpDecrypBuf + 1, decrypBuf, decryptedLength);

    NSData *unpaddedDecypData = [AylaKeyCrypto pkcsUnpadWithBuffer:tmpDecrypBuf length:decryptedLength + 1];
    if (!unpaddedDecypData) {
        AylaLogE([self logTag], 0, @"can't unpad, %@", @"decryptData");
        [self.lock unlock];
        return nil;
    }

    [self.lock unlock];
    return unpaddedDecypData;
}

/**
 * PKCS padding
 */
+ (NSData *)pkcsUnpadWithBuffer:(unsigned char *)dataPtr length:(NSUInteger)len
{
    unsigned char *p = dataPtr;
    if (*p++ != 0 || *p != 2) {
        return nil;
    }
    for (p = p + 1; p < dataPtr + len; p++) {
        if (*p == 0) break;
    }
    if (p >= dataPtr + len) {
        return nil;
    }
    if (p - dataPtr < 8) return nil;
    p++;
    NSData *unpaddedData = [NSData dataWithBytes:p length:len - (p - dataPtr)];
    return unpaddedData;
}

/**
 * Use this method to get key in bits from key chain with key tag.
 *
 * @param keyTag The key tag which helps to find the key.
 *
 * @return The key in bits.
 */
- (NSData *)getKeyInBitsFromKeyChainWithTag:(NSString *)keyTag
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    NSData *dataOfKeyTag = [keyTag dataUsingEncoding:NSUTF8StringEncoding];

    [query setObject:dataOfKeyTag forKey:(__bridge id)kSecAttrApplicationTag];
    [query setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query setObject:@YES forKey:(__bridge id)kSecReturnData];
    [query setObject:@NO forKey:(__bridge id)kSecReturnRef];

    CFTypeRef result = NULL;
    OSStatus sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    if (sanityCheck == noErr) {
        NSData *data = CFBridgingRelease(result);
        return data;
    }

    return nil;
}

/**
 * Use this method to get key ref from key chain with key tag.
 *
 * @param keyTag The key tag which helps to find the key.
 *
 * @return The key in bits.
 */
- (SecKeyRef)getKeyRefFromKeyChainWithTag:(NSString *)keyTag
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    NSData *dataOfKeyTag = [keyTag dataUsingEncoding:NSUTF8StringEncoding];
    [query setObject:dataOfKeyTag forKey:(__bridge id)kSecAttrApplicationTag];
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [query setObject:@YES forKey:(__bridge id)kSecReturnRef];
    [query setObject:@NO forKey:(__bridge id)kSecReturnData];

    CFTypeRef result = NULL;
    __unused OSStatus sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    return (SecKeyRef)result;
}

- (void)dealloc
{
    if (self.pubKeyRef != NULL) {
        CFRelease(self.pubKeyRef);
    }
    if (self.privKeyRef != NULL) {
        CFRelease(self.privKeyRef);
    }
}

- (NSString *)logTag
{
    return @"KeyCrypto";
}

@end
