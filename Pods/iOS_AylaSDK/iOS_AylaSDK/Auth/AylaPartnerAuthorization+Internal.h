//
//  AylaPartnerAuthorization+Internal.h
//  iOS_AylaSDK
//
//  Created by Kavita Khanna on 5/22/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaPartnerAuthorization.h"

NS_ASSUME_NONNULL_BEGIN

@interface AylaPartnerAuthorization (Internal)

// Test/Demo Method
/**
 * This is a test method to test login to partner cloud using short-lived partner token retrieved from AylaIDP.
 * This is a test method using Ayla implemeted partner cloud test API.
 *
 * @param partnerToken Short-lived partner token to login to patner cloud
 * @param settings AylaSystemSettings object
 * @param successBlock Success block called after successful auth to partner cloud. Passes in the created AylaPartnerAuthorization object
 * @param failureBlock Failure block called if auth fails to partner cloud
 */
- (void)testLoginToPartnerCloudWithToken:(NSString *)partnerToken
                          systemSettings:(AylaSystemSettings *)settings
                                 success:(void(^)(AylaPartnerAuthorization *partnerAuth))successBlock
                                 failure:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END
