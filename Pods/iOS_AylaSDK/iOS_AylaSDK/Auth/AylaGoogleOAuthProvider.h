//
//  AylaGoogleOAuthProvider.h
//  iOS_AylaSDK
//
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaBaseAuthProvider.h"

NS_ASSUME_NONNULL_BEGIN


/**
 This class is used to authenticate login credentials via Google OAuth provider.
 It passes authCode received from Google to Ayla User Service for login account validation.
 The response received from Ayla User Service is converted to AylaAuthorization object
 */
@interface AylaGoogleOAuthProvider : AylaBaseAuthProvider

/**
 Creates an instance with the specified `authCode`.
 
 You should first integrate provider's officail SDK and do authentication on App layer. Once authenticate success `authCode` will be returned from provider. Then call this API to pass the authCode to Ayla cloud.
 
 @param authCode  The `authCode` get from provider's official SDK.
 
 @return An `AylaGoogleOAuthProvider` instance, initialized with the specified `authCode`
 */
+ (instancetype)providerWithAuthCode:(NSString *)authCode;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
