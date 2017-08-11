//
//  AylaIDPAuthProvider.h
//  iOS_AylaSDK
//
//  Created by Kavita Khanna on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaSessionManager.h"
#import "AylaPartnerAuthorization.h"
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides partner cloud authentication through Ayla as IDP.
 * This class will host partner authorization objects per parter Id
 * for all partner clouds that app is configured to use.
 */
@interface AylaIDPAuthProvider : AylaObject

/**
 * Initializes partner auth provider.
 *
 * @param sessionManager AylaSessionManager after user has successully signed into the App
 *
 * @return AylaIDPAuthProvider object
 */
- (instancetype)initWithSessionManager:(AylaSessionManager *)sessionManager;

/**
 * Retrieves short-lived partnerTokens from Ayla IDP service for given partnerIds.
 * These partner tokens are used to login to partner cloud.
 *
 * @param partnerIds Array of partner Ids
 * @param successBlock Block executed after successfully fetching partner tokens
 * @param failureBlock Block executed in case of an error.
 */
- (void)getPartnerTokensForPartnerIds:(NSArray<NSString *> * _Nonnull)partnerIds
                              success:(nonnull void(^)(NSDictionary<NSString *, NSString *> *partnerTokensPerId))successBlock
                              failure:(void (^)(NSError *error))failureBlock;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
