//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLoginManager.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPClient;
@class AylaNetworks;
@interface AylaLoginManager (Internal)

/**
 * Init method with a AylaNetworks instance. Login manager will keep a weak reference to this input.
 *
 * @param sdkRoot Current AylaNetworks instance.
 */
- (instancetype)initWithSDKRoot:(AylaNetworks *)sdkRoot;

/**
 * Refreshes an authorization with the Ayla cloud service. Authorizations have expirations,
 * and need to be refreshed from time to time. The library generally will take care of
 * updating authorization for you. When authorization is refreshed, if a Session is active,
 * the SessionManager will notify listeners of the refresh.
 *
 * @param authorization Authorization to be refreshed
 * @param successListener Listener to receive the results of a successful call
 * @param errorListener Listener to receive errors in case of failure
 */
- (AylaHTTPTask *)refreshAuthorization:(AylaAuthorization *)authorization
                               success:(void (^)(AylaAuthorization *authorization))successBlock
                               failure:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END
