//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface AylaLanConfig : AylaObject

@property(nonatomic, nullable) NSNumber *lanipKeyId;
@property(nonatomic, nullable) NSString *lanipKey;
@property(nonatomic, nullable) NSNumber *keepAlive;
@property(nonatomic, nullable) NSString *status;

// Key pair which will be used in key negotiation.
@property(nonatomic, nullable) NSNumber *keySizeOfKeysInKeyPair;
@property(nonatomic, nullable) NSString *keyPairPublicKeyTag;
@property(nonatomic, nullable) NSString *keyPairPrivateKeyTag;

@end

NS_ASSUME_NONNULL_END