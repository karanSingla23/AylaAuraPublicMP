//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDSManager.h"
#import "AylaDefines_Internal.h"
#import "AylaSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPClient;
@interface AylaSessionManager (Internal)

// Linked data stream manager.
@property (nonatomic, readonly, nullable) AylaDSManager *dssManager;
@property (nonatomic, assign) BOOL cachedSession;
@property (nonatomic) NSMutableDictionary *httpClients;

/**
 * Init method
 *
 * @param authProvider authProvider used during authentication
 * @param authorization An valid authorization object which should be used in current session.
 * @param sessionName A session name which is assigned the the session of current session manager.
 * @param sdkRoot A AylaNetworks instance who is the owner of current session manager.
 */
- (instancetype)initWithAuthProvider:(id<AylaAuthProvider>)authProvider
                       authorization:(nullable AylaAuthorization *)authorization
                         sessionName:(NSString *)sessionName
                             sdkRoot:(AylaNetworks *)sdkRoot;

/**
 * Get a http client.
 *
 * @param type The type of requested HTTP client.
 */
- (nullable AylaHTTPClient *)getHttpClientWithType:(AylaHTTPClientType)type;

@end

NS_ASSUME_NONNULL_END
