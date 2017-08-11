//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaEncryption.h"
#import "AylaErrorUtils.h"
#import "AylaLanConfig.h"
#import "AylaLogManager.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

NSString *const AylaEncryptionTypeLAN = @"lan";
NSString *const AylaEncryptionTypeWifiSetup = @"wifi_setup";

@implementation AylaEncryptionConfig

@end

@interface AylaEncryption () {
    CCCryptorRef eCipher;
    CCCryptorRef dCipher;
}

@property (strong, nonatomic) NSData *bLanKey;
@property (strong, nonatomic) NSString *sLanKey;

@property (strong, nonatomic) NSData *appSignKey;
@property (strong, nonatomic) NSData *appCryptoKey;
@property (strong, nonatomic) NSData *appIvSeed;

@property (strong, readwrite, nonatomic) NSData *devSignKey;
@property (strong, nonatomic) NSData *devCryptoKey;
@property (strong, nonatomic) NSData *devIvSeed;

@end

@implementation AylaEncryption

- (void) updateParamsWithVersion:(NSNumber *)version proto1:(NSNumber *)proto1 keyId1:(NSNumber *)keyId1
{
    self.version = version;
    self.proto1 = proto1;
    self.keyId1 = keyId1;
}


- (NSError *)generateSessionkeys:(AylaEncryptionConfig *)config
                           sRnd1:(NSString *)sRnd1
                          nTime1:(NSNumber *)nTime1
                           sRnd2:(NSString *)sRnd2
                          nTime2:(NSNumber *)nTime2
{
    AylaLogI([self logTag], 0, @"%@, %@", @"entry", @"generateSessionKeys");
    
    //get time and random number from server
    self.sRnd1 = sRnd1;
    self.nTime1 = nTime1;
    
    //get ios time and random number
    self.sRnd2 = sRnd2;
    self.nTime2 = nTime2;
    
    NSData *bRnd1 = [sRnd1 dataUsingEncoding:NSUTF8StringEncoding];
    NSData *bRnd2 = [sRnd2 dataUsingEncoding:NSUTF8StringEncoding];
    
    AYLAssert(config, @"Config must not be null.");
    
    NSDictionary *errDescrip = nil;
    if([config.type isEqualToString:AylaEncryptionTypeWifiSetup]) {
        if(config.data) {
            self.bLanKey = config.data;
        }
        else {
            errDescrip = @{ NSStringFromSelector(@selector(data)) : AylaErrorDescriptionCanNotBeFound };
        }
    }
    else if ([config.type isEqualToString:AylaEncryptionTypeLAN]) {
        if(config.lanipKey) {
            self.sLanKey = [config lanipKey];
            self.bLanKey = [self.sLanKey dataUsingEncoding:NSUTF8StringEncoding];
        }
        else {
            errDescrip = @{ NSStringFromSelector(@selector(lanipKey)) : AylaErrorDescriptionCanNotBeFound };
        }
    }
    else {
        errDescrip = @{ NSStringFromSelector(@selector(type)): AylaErrorDescriptionIsInvalid };
    }
    
    if(errDescrip) {
        // If we found an error in config, return this error and stop generation.
        return [AylaErrorUtils errorWithDomain:AylaLanErrorDomain
                                          code:AylaLanErrorCodeKeyGenerationFailure
                                      userInfo:@{
                                                 AylaLanErrorResponseJsonKey:errDescrip
                                                 }
                                     shouldLog:YES
                                        logTag:[self logTag]
                              addOnDescription:@"generate"];
    }
    
    NSString *sTime1 = [NSString stringWithFormat:@"%@", nTime1];
    NSString *sTime2 = [NSString stringWithFormat:@"%@", nTime2];
    
    NSData *bTime1 = [sTime1 dataUsingEncoding:NSUTF8StringEncoding];
    NSData *bTime2 = [sTime2 dataUsingEncoding:NSUTF8StringEncoding];
    
    
    // App Signing key:    <random_1> + <random_2> + <time_1> + <time_2> + 0
    // App Encrypting key: <random_1> + <random_2> + <time_1> + <time_2> + 1
    // App IV CBC seed:    <random_1> + <random_2> + <time_1> + <time_2> + 2
    
    Byte lastByte = 48;
    
    NSMutableData *bTempSeed = [[NSMutableData alloc] init];
    
    [bTempSeed appendBytes:bRnd1.bytes length:[bRnd1 length]];
    [bTempSeed appendBytes:bRnd2.bytes length:[bRnd2 length]];
    [bTempSeed appendBytes:bTime1.bytes length:[bTime1 length]];
    [bTempSeed appendBytes:bTime2.bytes length:[bTime2 length]];
    [bTempSeed appendBytes:&lastByte length:1];
    
    size_t seedLen = [bTempSeed length];
    
    NSData *level1 = [AylaEncryption hmacForKey:self.bLanKey  data:bTempSeed];
    NSMutableData *tmpSeed = [[NSMutableData alloc] initWithData:level1];
    [tmpSeed appendData:bTempSeed];
    self.appSignKey = [AylaEncryption hmacForKey:self.bLanKey data:tmpSeed];
    
    
    //App Encrypting Key
    lastByte++;
    [bTempSeed replaceBytesInRange:NSMakeRange(seedLen-1, 1) withBytes:&lastByte];
    level1 = [AylaEncryption hmacForKey:self.bLanKey data:bTempSeed];
    [tmpSeed setLength:0]; [tmpSeed appendData:level1]; [tmpSeed appendData:bTempSeed];
    self.appCryptoKey = [AylaEncryption hmacForKey:self.bLanKey data:tmpSeed];
    
    //App IV CBC seed
    lastByte++;
    [bTempSeed replaceBytesInRange:NSMakeRange(seedLen-1, 1) withBytes:&lastByte];
    level1 = [AylaEncryption hmacForKey:self.bLanKey data:bTempSeed];
    [tmpSeed setLength:0]; [tmpSeed appendData:level1]; [tmpSeed appendData:bTempSeed];
    self.appIvSeed = [AylaEncryption hmacForKey:self.bLanKey data:tmpSeed];
    self.appIvSeed = [self.appIvSeed subdataWithRange:NSMakeRange(0, 16)];
    
    // NSLog(@"appSignKey: %@\n", [appSignKey description]);
    // NSLog(@"appCryptoKey: %@\n", [appCryptoKey description]);
    // NSLog(@"appIvSeed: %@\n", [appIvSeed description]);
    
    
    // Device Signing key:    <random_2> + <random_1> + <time_2> + <time_1> + 0
    // Device Encrypting key: <random_2> + <random_1> + <time_2> + <time_1> + 1
    // Device IV CBC seed:    <random_2> + <random_1> + <time_2> + <time_1> + 2
    
    lastByte = 48;
    
    [bTempSeed setLength:0];
    [bTempSeed appendBytes:bRnd2.bytes length:[bRnd2 length]];
    [bTempSeed appendBytes:bRnd1.bytes length:[bRnd1 length]];
    [bTempSeed appendBytes:bTime2.bytes length:[bTime2 length]];
    [bTempSeed appendBytes:bTime1.bytes length:[bTime1 length]];
    [bTempSeed appendBytes:&lastByte length:1];
    
    seedLen = [bTempSeed length];
    level1 = [AylaEncryption hmacForKey:self.bLanKey data:bTempSeed];
    [tmpSeed setLength:0]; [tmpSeed appendData:level1]; [tmpSeed appendData:bTempSeed];
    self.devSignKey = [AylaEncryption hmacForKey:self.bLanKey data:tmpSeed];
    
    //App Encrypting Key
    lastByte++;
    [bTempSeed replaceBytesInRange:NSMakeRange(seedLen-1, 1) withBytes:&lastByte];
    level1 = [AylaEncryption hmacForKey:_bLanKey data:bTempSeed];
    [tmpSeed setLength:0]; [tmpSeed appendData:level1]; [tmpSeed appendData:bTempSeed];
    _devCryptoKey = [AylaEncryption hmacForKey:_bLanKey data:tmpSeed];
    
    //App IV CBC seed
    lastByte++;
    [bTempSeed replaceBytesInRange:NSMakeRange(seedLen-1, 1) withBytes:&lastByte];
    level1 = [AylaEncryption hmacForKey:_bLanKey data:bTempSeed];
    [tmpSeed setLength:0]; [tmpSeed appendData:level1]; [tmpSeed appendData:bTempSeed];
    _devIvSeed = [AylaEncryption hmacForKey:_bLanKey data:tmpSeed];
    _devIvSeed = [_devIvSeed subdataWithRange:NSMakeRange(0, 16)];
    
    // NSLog(@"devSignKey: %@\n", [devSignKey description]);
    // NSLog(@"devCryptoKey: %@\n", [devCryptoKey description]);
    // NSLog(@"devIvSeed: %@\n", [devIvSeed description]);
    
    _sessionId ++;
    [self cipherClean:&eCipher];
    [self cipherClean:&dCipher];
    [self cipherInit:&eCipher operation:kCCEncrypt key:_appCryptoKey iv:_appIvSeed];
    [self cipherInit:&dCipher operation:kCCDecrypt key:_devCryptoKey iv:_devIvSeed];
    
    return nil;
}



- (NSString *)encryptEncapsulateSignWithPlaintext:(NSString *)plaintext sign:(NSData *)sign
{
    //  saveToLog(@"%@, %@, %@: %@, %@", @"I", @"AylaEncryption", @"enc", jsonEnc, @"encryptEncapsulateSign");
    NSData *signData = [AylaEncryption hmacForKey:sign data:[plaintext dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedSign = [signData base64EncodedString];
    
    NSData *encryptedData  = [self cipherEncrypt:&eCipher plainText:plaintext];
    NSString *encodedEnc = [encryptedData base64EncodedString];
    
    NSString *send = [NSString stringWithFormat:@"{\"enc\":\"%@\",\"sign\":\"%@\"}", encodedEnc, encodedSign];
    
    //  saveToLog(@"%@, %@, %@: %@, %@", @"I", @"AylaEncryption", @"sendString", send, @"encryptEncapsulateSign");
    return send;
}




- (BOOL)cipherInit:(CCCryptorRef *)cryptorRef operation:(CCOperation)op key:(NSData *)key iv:(NSData *)iv
{
    CCCryptorStatus status = CCCryptorCreate(
                                             op, kCCAlgorithmAES128, 0x0000,
                                             key.bytes, kCCKeySizeAES256,
                                             iv.bytes, // initialisation vector
                                             cryptorRef
                                             );
    if (status == kCCSuccess) {
        //saveToLog(@"%@, %@, %@: %@, %@", @"I", @"AylaEncryption", @"start encrypt context", @"success", @"cipherInit");
        return true;
    }
    else{
        AylaLogE([self logTag], 0, @"crypo error %d, %@", status, @"cipherInit");
        return false;
    }
}


- (NSData*)cipherEncrypt:(CCCryptorRef *)ref plainText:(NSString *)plainText
{
    plainText = [NSString stringWithFormat:@"%@\0",plainText];
    
    //Do padding
    long len = [plainText length];
    long pad = len % 16;
    pad = (pad>0)? 16-pad : pad;
    NSMutableData *padBuf = [NSMutableData dataWithLength:pad];
    NSMutableData *paddedData = [[NSMutableData alloc] initWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
    [paddedData appendData:padBuf];
    
    NSUInteger dataLength = [paddedData length];
    size_t dataSize = dataLength + kCCBlockSizeAES128;
    NSMutableData *cipherData = [NSMutableData dataWithLength:dataSize];
    
    size_t encryptedDataSize = 0;
    CCCryptorStatus cryptStatus = CCCryptorUpdate(*ref, paddedData.bytes, paddedData.length, cipherData.mutableBytes,  dataSize,  &encryptedDataSize);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        NSData *_cipherData = [cipherData subdataWithRange:NSMakeRange(0, encryptedDataSize)];
        return _cipherData;
    }
    return nil;
}

- (NSData*)cipherDecrypt:(CCCryptorRef *)ref cipherData:(NSData *)cipherData
{
    NSUInteger dataLength = [cipherData length];
    size_t dataSize = dataLength + kCCBlockSizeAES128;
    NSMutableData *clearData = [NSMutableData dataWithLength:dataSize];
    
    size_t decryptedDataSize = 0;
    CCCryptorStatus cryptStatus = CCCryptorUpdate(*ref, cipherData.bytes, cipherData.length, clearData.mutableBytes,  dataSize,  &decryptedDataSize);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        
        NSData *_clearData = [clearData subdataWithRange:NSMakeRange(0, decryptedDataSize)];
        NSString *str = [[NSString alloc] initWithData:_clearData encoding:NSUTF8StringEncoding];
        return [[str stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSData*)lanModeEncryptInStream:(NSString *)plainText
{
    return [self cipherEncrypt:&eCipher plainText:plainText];
}

- (NSData*)lanModeDecryptInStream:(NSData *)cipherData
{
    return [self cipherDecrypt:&dCipher cipherData:cipherData ];
}

- (void)clean
{
    [self cipherClean:&eCipher];
    [self cipherClean:&dCipher];
}

- (void)cipherClean:(CCCryptorRef *)ref
{
    CCCryptorReset(*ref, "");
    //if (*ref != nil) {
    //size_t dataSize = kCCBlockSizeAES128;
    //size_t dataOutput;
    //NSMutableData *clearData = [NSMutableData dataWithLength:dataSize];
    //CCCryptorFinal(*ref, clearData.mutableBytes,
    //               kCCBlockSizeAES128, &dataOutput);
    //CCCryptorRelease(*ref);
    //  *ref = nil;
    //}
}


+ (NSData *)hmacForKey:(NSData *)key data:(NSData *)data;
{
    if(key==nil)
        return [@"-" dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    bzero(cHMAC, CC_SHA256_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, data.bytes, data.length, cHMAC);
    NSData *hmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return hmac;
}


- (void)cleanEncrypSession
{
    //clear current session
    _keyId1 = [NSNumber numberWithInt:-1];
    _appSignKey = nil;
    _devSignKey = nil;
    [self clean];
}

- (void)dealloc
{
    CCCryptorRelease(eCipher);
    CCCryptorRelease(dCipher);
}

//-----------TokenGeneration-----------------------------
+ (NSString*)randomToken:(int)len
{
    static NSString *list = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    int list_len =62;
    NSMutableString *s = [NSMutableString stringWithCapacity:len];
    for (NSUInteger i = 0U; i < len; i++) {
        u_int32_t r = arc4random() % list_len;
        unichar c = [list characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

+ (NSData *)base64Decode:(NSString *)string
{
    return [NSData dataFromBase64String:string];
}


+ (NSString*)dataToHexString:(NSData *)data
{
    NSData *ddata = data;
    NSUInteger capacity = [data length] * 2;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = [data bytes];
    NSInteger i;
    for (i=0; i<[ddata length]; ++i) {
        [hexString appendFormat:@"%02lX", (unsigned long)dataBuffer[i]];
    }
    return hexString;
}


+ (NSData *)dataFromHexString:(NSString *)hexString
{
    NSMutableData *stringData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hexString length] / 2; i++) {
        byte_chars[0] = [hexString characterAtIndex:i*2];
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [stringData appendBytes:&whole_byte length:1];
    }
    return stringData;
}

- (NSString *)logTag
{
    return @"Encryption";
}

@end
