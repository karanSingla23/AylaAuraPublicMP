//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaCachedAuthProvider.h"
#import "AylaHTTPError.h"
#import "AylaLoginManager+Internal.h"
#import "AylaNetworks.h"
#import "AylaRequestError.h"

@implementation AylaCachedAuthProvider

- (instancetype)initWithAuthorization:(AylaAuthorization *)authorization
{
    self = [super init];
    if (!self) return nil;

    _cachedAuthorization = authorization;

    return self;
}

+ (instancetype)providerWithAuthorization:(AylaAuthorization *)authorization
{
    return [[self alloc] initWithAuthorization:authorization];
}

- (AylaHTTPTask *)authenticateWithLoginManager:(AylaLoginManager *)loginManager
                                       success:(void (^)(AylaAuthorization *authorization))successBlock
                                       failure:(void (^)(NSError *error))failureBlock;
{
    return [loginManager refreshAuthorization:self.cachedAuthorization
        success:^(AylaAuthorization *_Nonnull authorization) {
            successBlock(authorization);
        }
        failure:^(NSError *_Nonnull error) {
            if (error.code == AylaHTTPErrorCodeLostConnectivity && [AylaNetworks shared].systemSettings.allowOfflineUse) {
                // Request failed due to cloud reachablity.
                // If offline login is allowed. call successBlock directly.
                successBlock(self.cachedAuthorization);
            }
            else {
                failureBlock(error);
            }
        }];
}


+ (NSString *)logTag
{
    return @"CachedAuthProvider";
}

@end
