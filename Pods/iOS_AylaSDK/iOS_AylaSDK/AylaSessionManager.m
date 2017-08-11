//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaAuthorization.h"
#import "AylaCache+Internal.h"
#import "AylaCache.h"
#import "AylaContact.h"
#import "AylaDSManager.h"
#import "AylaDatum+Internal.h"
#import "AylaDeviceManager+Internal.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPError.h"
#import "AylaListenerArray.h"
#import "AylaLoginManager+Internal.h"
#import "AylaNetworks+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaRequestError.h"
#import "AylaSessionManager.h"
#import "AylaShare.h"
#import "AylaSystemSettings.h"
#import "AylaUser.h"

static const NSUInteger DEFAULT_TOKEN_REFRESH_THRESHOULD_SEC = 1800;

@interface AylaSessionManager ()

@property(nonatomic, readwrite, setter=setAuthorization:)
    AylaAuthorization *authorization;
@property(nonatomic) NSMutableDictionary *httpClients;
@property(nonatomic, readwrite) AylaLoginManager *loginManager;
@property(nonatomic, readwrite) AylaDeviceManager *deviceManager;
@property(nonatomic, readwrite) AylaDSManager *dssManager;
@property(nonatomic) AylaSystemSettings *settings;
@property(nonatomic, assign) BOOL cachedSession;

/** Array of listeners */
@property(nonatomic, strong, readwrite) AylaListenerArray *listeners;

@end

static NSString *const AylaShareResourceName = @"resource_name";
static NSString *const AylaShareResourceId = @"resource_id";
static NSString *const AylaShareExpired = @"expired";
static NSString *const AylaShareAccepted = @"accepted";

@implementation AylaSessionManager

- (instancetype)initWithAuthProvider:(id<AylaAuthProvider>)authProvider
                       authorization:(nullable AylaAuthorization *)authorization
                         sessionName:(NSString *)sessionName
                             sdkRoot:(AylaNetworks *)sdkRoot {
  self = [super init];
  if (!self)
    return nil;

  _authProvider = authProvider;
  _authorization = authorization;
  _sdkRoot = sdkRoot;
  _sessionName = sessionName;
  _settings = sdkRoot.systemSettings;
  _loginManager = sdkRoot.loginManager;
  _listeners = [[AylaListenerArray alloc] init];
  _httpClients = [NSMutableDictionary dictionary];

  [self setupHttpClients];
  _aylaCache = [[AylaCache alloc] initWithSessionName:sessionName];

  _deviceManager = [[AylaDeviceManager alloc] initWithSessionManager:self];

  // Only enable ds manager if allowDSS is set as YES
  if (_settings.allowDSS) {
    _dssManager = [[AylaDSManager alloc]
        initWithSettings:_settings
           deviceManager:_deviceManager
              httpClient:_httpClients[@(AylaHTTPClientTypeStreamService)]];

    // Resume dss manager once session manager has been initialized
    [_dssManager resume];
  }
  if (!_settings.allowOfflineUse) {
    [self.aylaCache disable:AylaCacheTypeProperty | AylaCacheTypeDevice |
                            AylaCacheTypeNode | AylaCacheTypeLANConfig];
  }
  if ([authProvider isKindOfClass:[AylaCachedAuthProvider class]]) {
    _cachedSession = YES;
  }

  [self validateAuthorization];

  return self;
}

/**
 * Use this api to create all http clients. Once a session manager linked http
 * clients. it will also be responsible to
 * update each client header fields (Like access token).
 */
- (void)setupHttpClients {
  self.httpClients[@(AylaHTTPClientTypeDeviceService)] =
      [AylaHTTPClient deviceServiceClientWithSettings:self.settings
                                           usingHTTPS:YES];
  self.httpClients[@(AylaHTTPClientTypeUserService)] =
      [AylaHTTPClient userServiceClientWithSettings:self.settings
                                         usingHTTPS:YES];
  self.httpClients[@(AylaHTTPClientTypeLogService)] =
      [AylaHTTPClient logServiceClientWithSettings:self.settings
                                        usingHTTPS:YES];
  self.httpClients[@(AylaHTTPClientTypeStreamService)] =
      [AylaHTTPClient streamServiceClientWithSettings:self.settings
                                           usingHTTPS:YES];
  self.httpClients[@(AylaHTTPClientTypeMDSSService)] =
      [AylaHTTPClient mdssSubscriptionServiceClientWithSettings:self.settings
                                                     usingHTTPS:YES];

  // Update http clients after setup.
  [self updateHttpClients];
}

/**
 * Update http clients for current session manager.
 */
- (void)updateHttpClients {
  for (AylaHTTPClient *client in self.httpClients.allValues) {
    [client updateRequestHeaderWithAccessToken:self.authorization.accessToken];
  }
}

/**
 * Clean all http clients from current session manager. Access token will be
 * also cleaned from all http clients.
 */
- (void)cleanHttpClients {
  // Clean token for all unlinked Http clients
  for (AylaHTTPClient *client in self.httpClients.allValues) {
    [client updateRequestHeaderWithAccessToken:@""];
  }

  // Clean http clients
  self.httpClients = nil;
}

/**
 *  Cleans all the cookies generated when authenticating with OAuth,
 */
- (void)cleanCookies {
  NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  for (NSHTTPCookie *cookie in storage.cookies) {
    [storage deleteCookie:cookie];
  }

  NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(
      NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *cookiesFolderPath =
      [libraryPath stringByAppendingString:@"/Cookies"];
  NSError *errors;
  [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath
                                             error:&errors];
}

/**
 * Helpful method to get user service http client.
 */
- (AylaHTTPClient *)userServiceHttpClient {
  return self.httpClients[@(AylaHTTPClientTypeUserService)];
}

- (BOOL)isDSActive {
  return self.dssManager.isConnected;
}

//-----------------------------------------------------------
#pragma mark - Authorization
//-----------------------------------------------------------

- (AylaHTTPTask *)refreshAuthorization:
                      (void (^)(AylaAuthorization *authorization))successBlock
                               failure:(void (^)(NSError *error))failureBlock {
  AylaAuthorization *authorization = self.authorization;

  if (!authorization) {
    // No valid authorization found in current session manager.
    NSError *error =
        [NSError errorWithDomain:AylaRequestErrorDomain
                            code:AylaRequestErrorCodeInvalidArguments
                        userInfo:@{
                          NSStringFromSelector(@selector(authorization)) :
                              AylaErrorDescriptionIsInvalid
                        }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  return [self.loginManager refreshAuthorization:authorization
      success:^(AylaAuthorization *authorization) {
        self.authorization = authorization;

        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(authorization);
        });

        // Notify all listeners about this refreshed authorization
        [self.listeners
            iterateListenersRespondingToSelector:@selector(sessionManager:
                                                     didRefreshAuthorization:)
                                    asyncOnQueue:dispatch_get_main_queue()
                                           block:^(id listener) {
                                             [listener sessionManager:self
                                                 didRefreshAuthorization:
                                                     authorization];
                                           }];

      }
      failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

/**
 * A helpful method for perform @selector call
 */
- (void)performValidateAuthorization {
  [self validateAuthorization];
}

/**
 * Overide setter of authorization. Whenever a new authorization is set, session
 * manager must reset
 * its refresh timer to gurantee authorization and update header of all known
 * http clients.
 */
- (void)setAuthorization:(AylaAuthorization *)authorization {
  _authorization = authorization;

  // Use new authorization to refresh access token of all http clients.
  for (AylaHTTPClient *httpClient in self.httpClients.allValues) {
    [httpClient updateRequestHeaderWithAccessToken:authorization.accessToken];
  }

  [self validateAuthorization];
}

/**
 * Validate current authorization and setup a refresh timer
 *
 * If current authorization has expired, a refresh call will be made immidiately
 */
- (void)validateAuthorization {
  AylaAuthorization *authorization = self.authorization;
  NSTimeInterval expireInterval = [authorization secondsToExpiry];

  void (^timerBlock)(AylaSessionManager *, NSTimeInterval tmInterval) = ^(
      AylaSessionManager *sessionManager, NSTimeInterval tmInterval) {
    dispatch_async(dispatch_get_main_queue(), ^{
      // Cancel any existing ones and shcedule a new validatation with a delay.
      [NSObject
          cancelPreviousPerformRequestsWithTarget:sessionManager
                                         selector:
                                             @selector(
                                                 performValidateAuthorization)
                                           object:nil];
      [sessionManager performSelector:@selector(performValidateAuthorization)
                           withObject:nil
                           afterDelay:tmInterval];
    });
  };

  // If left life time of current authorization is shorter then threshould, do a
  // refresh
  // immidiately.
  if (expireInterval < DEFAULT_TOKEN_REFRESH_THRESHOULD_SEC) {
    [self refreshAuthorization:^(AylaAuthorization *authorization) {
      // Once authorization is refreshed successfully
      // -refrshAuthorization:success:failure api will set authorization of
      // current
      // session manager. Setter of authorication will invoke current method
      // (-validateAuthorization:)
      // again to setup the refresh timer. Hence, we do nothing here.
    }
        failure:^(NSError *error) {
          // When refresh timer is not working, do validation again after 3
          // seconds.

          if (error.code == AylaHTTPErrorCodeInvalidResponse &&
              error.userInfo[AylaHTTPErrorHTTPResponseKey]) {
            // If request is rejected by cloud, which means authorization info
            // is no longer avaiable.
            // Inform listeners regarding this issue. Library should stop
            // refresh timer at the same time.

            [self.listeners
                iterateListenersRespondingToSelector:@selector(sessionManager:
                                                              didCloseSession:)
                                        asyncOnQueue:dispatch_get_main_queue()
                                               block:^(id listener) {
                                                 [listener
                                                      sessionManager:self
                                                     didCloseSession:error];
                                               }];
            return;
          }

          // TODO: if validation faliure is because of internet connectivity.
          // Hold retry and wait for
          // Internet reachability notification.
          timerBlock(self, 3);
        }];
  } else {
    // Otherwise, setup refresh timer.
    timerBlock(self, expireInterval);
  }
}

- (AylaHTTPTask *)logoutWithSuccess:(void (^)(void))successBlock
                            failure:(void (^)(NSError *error))failureBlock {
    return [self shutDownWithSuccess:successBlock failure:failureBlock];
}

//-----------------------------------------------------------
#pragma mark - Listeners
//-----------------------------------------------------------

- (void)addListener:(id<AylaDeviceManagerListener>)listener {
  [self.listeners addListener:listener];
}

- (void)removeListener:(id<AylaDeviceManagerListener>)listener {
  [self.listeners removeListener:listener];
}

- (void)setNotificationQueue:(dispatch_queue_t)notificationQueue {
  self.notificationQueue =
      notificationQueue != NULL ? notificationQueue : dispatch_get_main_queue();
}

//-----------------------------------------------------------
#pragma mark - Pause/Resume
//-----------------------------------------------------------
- (void)pause {
  [self.dssManager pause];
  [self.deviceManager pause];
}

- (void)resume {
  [self validateAuthorization];
  [self.deviceManager resume];
  [self.dssManager resume];
}

//-----------------------------------------------------------
#pragma mark - Internal
//-----------------------------------------------------------
- (nullable AylaHTTPTask *)shutDownWithSuccess:(void (^)(void))successBlock
                                       failure:(void (^)(NSError *error))failureBlock {
  void (^shutdown)() = ^{
      AylaLogI([self logTag], 0, @"shut down.");

      // Cancel scheduled validation call
      dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject
            cancelPreviousPerformRequestsWithTarget:self
                                           selector:
                                               @selector(
                                                   performValidateAuthorization)
                                             object:nil];
      });

      // Pause dss manager.
      [self.dssManager pause];

      // Shut down the device manager
      [self.deviceManager shutDown];

      // Notify all session manager listeners
      [self.listeners
        iterateListenersRespondingToSelector:@selector(sessionManager:
            didCloseSession:)
               asyncOnQueue:dispatch_get_main_queue()
                  block:^(id listener) {
                     [listener sessionManager:self didCloseSession:nil];
                  }];

      // Clean all http clients
      [self cleanHttpClients];

      // Clean the HTTP Cookies (OAuth)
      [self cleanCookies];

      // Clear all caches
      [self.aylaCache clearAll];

      // Clean authorization
      self.authorization = nil;
  };
  return [self.authProvider signOutWithSessionManager:self success:^{
      shutdown();
      successBlock();
  } failure:^(NSError * _Nonnull error) {
      shutdown();
      failureBlock(error);
  }];
}

- (AylaHTTPClient *)getHttpClientWithType:(AylaHTTPClientType)type {
  return self.httpClients[@(type)];
}

- (NSString *)logTag {
  return NSStringFromClass([self class]);
}
@end

@implementation AylaSessionManager (User)

/**
 * Use this method to retrieve existing user account information from Ayla Cloud
 * Services. The user must be
 * authenticated, via login, before calling
 * this method.
 *
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when
 * request is failed.
 */
- (nullable AylaHTTPTask *)
fetchUserProfile:(void (^)(AylaUser *user))successBlock
         failure:(void (^)(NSError *err))failureBlock {
  return [self.userServiceHttpClient getPath:@"users/get_user_profile.json"
      parameters:nil
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        // Assume feedback from cloud will alwasy be valid.
        AylaUser *user =
            [[AylaUser alloc] initWithJSONDictionary:responseObject error:nil];
        successBlock(user);
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        failureBlock(error);
      }];
}

/**
 * Use this method to retrieve existing user account information from Ayla Cloud
 * Services. The user must be
 * authenticated, via login, before calling
 * this method.
 *
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when
 * request is failed.
 */
- (nullable AylaHTTPTask *)updateUserProfile:(AylaUser *)user
                                     success:(void (^)(void))successBlock
                                     failure:
                                         (void (^)(NSError *err))failureBlock {
    return [self.authProvider updateUserProfile:user sessionManager:self success:successBlock failure:failureBlock];
}

- (nullable AylaHTTPTask *)updateUserEmailAddress:(NSString *)email
                                          success:(void (^)(void))successBlock
                                          failure:(void (^)(NSError *err))
                                                      failureBlock {
  return [self.userServiceHttpClient putPath:@"users/update_email.json"
      parameters:@{
        @"email" : email
      }
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        successBlock();
      }
      failure:^(AylaHTTPTask *task, NSError *error) {
        failureBlock(error);
      }];
}

- (AylaHTTPTask *)deleteAccountWithSuccess:(void (^)(void))successBlock
                                   failure:(void (^)(NSError *_Nonnull))
                                               failureBlock {
    return [self.authProvider deleteAccountWithSessionManager:self success:successBlock failure:failureBlock];
}

- (AylaHTTPTask *)updatePassword:(NSString *)currentPassword
                     newPassword:(NSString *)newPassword
                         success:(void (^)(void))successBlock
                         failure:(void (^)(NSError *_Nonnull))failureBlock {
  NSDictionary *params = @{
    @"user" : @{
      @"current_password" : AYLNullIfNil(currentPassword),
      @"password" : AYLNullIfNil(newPassword)
    }
  };
  return [self.userServiceHttpClient putPath:@"users.json"
      parameters:params
      success:^(AylaHTTPTask *task, id _Nullable responseObject) {
        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock();
        });
      }
      failure:^(AylaHTTPTask *task, NSError *error) {

        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

@end

#pragma mark -
#pragma mark AylaShare
@implementation AylaSessionManager (AylaShare)

- (nullable AylaHTTPTask *)
createSharesWithParams:(NSDictionary *)params
         emailTemplate:(AylaEmailTemplate *)emailTemplate
               success:(void (^)(NSArray AYLA_GENERIC(AylaShare *) *
                                 createdShares))successBlock
               failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (!params) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                 AylaRequestErrorResponseJsonKey : @{
                                   NSStringFromClass([AylaShare class]) :
                                       AylaErrorDescriptionIsInvalid
                                 }
                               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
    
  if (emailTemplate != nil) {
    NSMutableDictionary *mutableParams = [params mutableCopy];
    mutableParams[@"email_template_id"] = emailTemplate.id;
    params = mutableParams;
  }

  NSString *path = @"api/v1/users/shares.json";
  return [self.userServiceHttpClient postPath:path
      parameters:params
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSArray *sharesDictionaryArray = responseObject;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
          sharesDictionaryArray = @[ responseObject ];
        }

        NSMutableArray *createdShares = [NSMutableArray array];
        for (NSDictionary *shareDictionary in sharesDictionaryArray) {
          NSError *error = nil;
          AylaShare *createdShare =
              [[AylaShare alloc] initWithJSONDictionary:shareDictionary
                                                  error:&error];
          if (error) {
            AylaLogE([self logTag], 0, @"invalidResp:%@, %@", shareDictionary,
                     NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
              failureBlock(error);
            });
            return;
          }
          [createdShares addObject:createdShare];
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(createdShares);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)createShare:(AylaShare *)share
                emailTemplate:(AylaEmailTemplate *)emailTemplate
                      success:(void (^)(AylaShare *_Nonnull))successBlock
                      failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (share.operation != AylaShareOperationNone && share.roleName != nil) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey : @{
                   NSStringFromClass([AylaShare class]) :
                       @"roleName and operation cannot be both specified"
                 }
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }
  return [self createSharesWithParams:[share toJSONDictionary]
                        emailTemplate:emailTemplate
                              success:^(NSArray<AylaShare *> *createdShares) {
                                successBlock(createdShares.firstObject);
                              }
                              failure:failureBlock];
}

- (AylaHTTPTask *)
 createShares:(NSArray<AylaShare *> *)shares
emailTemplate:(nullable AylaEmailTemplate *)emailTemplate
      success:(nonnull void (^)(NSArray<AylaShare *> *_Nonnull))successBlock
      failure:(nonnull void (^)(NSError *))failureBlock {
  void (^fail)(NSString *errorDescription) = ^(NSString *errorDescription) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey :
                     @{NSStringFromClass([AylaShare class]) : errorDescription}
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
  };
  if (!shares) {
    fail(AylaErrorDescriptionIsInvalid);
    return nil;
  }
  for (AylaShare *share in shares) {
    if (share.operation != AylaShareOperationNone && share.roleName != nil) {
      fail(@"roleName and operation cannot be both specified");
      return nil;
    }
  }
  NSMutableArray *sharesJSONArray = [NSMutableArray array];
  for (AylaShare *share in shares) {
    [sharesJSONArray addObject:[share toJSONDictionary][@"share"]];
  }
  return [self createSharesWithParams:@{
    @"shares" : sharesJSONArray
  }
                        emailTemplate:emailTemplate
                              success:successBlock
                              failure:failureBlock];
}

- (AylaHTTPTask *)
fetchSharesWithResourceName:(NSString *)resourceName
                 resourceId:(NSString *)resourceId
                    expired:(BOOL)expired
                   accepted:(BOOL)accepted
                      owned:(BOOL)owned
                    success:
                        (void (^)(NSArray<AylaShare *> *_Nonnull))successBlock
                    failure:(void (^)(NSError *_Nonnull))failureBlock {
  NSDictionary *params = @{
    AylaShareResourceName : resourceName,
    AylaShareResourceId : AYLNullIfNil(resourceId),
    AylaShareExpired : expired ? @"true" : @"false",
    AylaShareAccepted : accepted ? @"true" : @"false"
  };

  if (!resourceName) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey :
                     @{@"resourceName" : AylaErrorDescriptionIsInvalid}
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path = owned ? @"api/v1/users/shares.json"
                         : @"api/v1/users/shares/received.json";
  return [self.userServiceHttpClient getPath:path
      parameters:params
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSMutableArray *shares = [NSMutableArray array];
        for (NSDictionary *shareJSON in responseObject) {
          NSError *error = nil;
          AylaShare *share =
              [[AylaShare alloc] initWithJSONDictionary:shareJSON error:&error];
          if (error) {
            AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                     NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
              failureBlock(error);
            });
            return;
          }
          [shares addObject:share];
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(shares);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)
fetchReceivedSharesWithResourceName:(NSString *)resourceName
                         resourceId:(NSString *)resourceId
                            expired:(BOOL)expired
                           accepted:(BOOL)accepted
                            success:(void (^)(NSArray<AylaShare *> *_Nonnull))
                                        successBlock
                            failure:(void (^)(NSError *_Nonnull))failureBlock {
  return [self fetchSharesWithResourceName:resourceName
                                resourceId:resourceId
                                   expired:expired
                                  accepted:accepted
                                     owned:NO
                                   success:successBlock
                                   failure:failureBlock];
}

- (AylaHTTPTask *)
fetchOwnedSharesWithResourceName:(NSString *)resourceName
                      resourceId:(NSString *)resourceId
                         expired:(BOOL)expired
                        accepted:(BOOL)accepted
                         success:(void (^)(NSArray<AylaShare *> *_Nonnull))
                                     successBlock
                         failure:(void (^)(NSError *_Nonnull))failureBlock {
  return [self fetchSharesWithResourceName:resourceName
                                resourceId:resourceId
                                   expired:expired
                                  accepted:accepted
                                     owned:YES
                                   success:successBlock
                                   failure:failureBlock];
}

- (AylaHTTPTask *)fetchShareWithId:(NSString *)shareId
                           success:(void (^)(AylaShare *_Nonnull))successBlock
                           failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (!shareId) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey :
                     @{@"shareId" : AylaErrorDescriptionIsInvalid}
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/shares/%@.json", shareId];
  return [self.userServiceHttpClient getPath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSError *error = nil;
        AylaShare *share =
            [[AylaShare alloc] initWithJSONDictionary:responseObject
                                                error:&error];
        if (error) {
          AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                   NSStringFromSelector(_cmd));
          dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
          });
          return;
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(share);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)updateShare:(AylaShare *)share
                emailTemplate:(AylaEmailTemplate *)emailTemplate
                      success:(void (^)(AylaShare *updatedShare))successBlock
                      failure:(void (^)(NSError *_Nonnull))failureBlock {
  void (^fail)(NSString *errorDescription) = ^(NSString *errorDescription) {
    NSError *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaRequestErrorResponseJsonKey :
                     @{NSStringFromClass([AylaShare class]) : errorDescription}
               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
  };

  if (!share.id) {
    fail(AylaErrorDescriptionIsInvalid);
    return nil;
  }

  if (share.operation != AylaShareOperationNone && share.roleName != nil) {
    fail(@"roleName and operation cannot be both specified");
    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/shares/%@.json", share.id];
  return [self.userServiceHttpClient putPath:path
      parameters:[share toJSONDictionary]
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSError *error = nil;
        AylaShare *updatedShare =
            [[AylaShare alloc] initWithJSONDictionary:responseObject
                                                error:&error];
        if (error) {
          AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                   NSStringFromSelector(_cmd));
          dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
          });
          return;
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(updatedShare);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)deleteShare:(AylaShare *)share
                      success:(void (^)())successBlock
                      failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (!share.id) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                 AylaRequestErrorResponseJsonKey : @{
                                   NSStringFromClass([AylaShare class]) :
                                       AylaErrorDescriptionIsInvalid
                                 }
                               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/shares/%@.json", share.id];
  return [self.userServiceHttpClient deletePath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock();
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}
@end

#pragma mark -
#pragma mark UserDatum

@implementation AylaSessionManager (UserDatum)

- (nullable AylaHTTPTask *)
createAylaDatumWithKey:(NSString *)key
                 value:(NSString *)value
               success:(void (^)(AylaDatum *createdDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock {
  AylaHTTPClient *httpClient = [self userServiceHttpClient];

  NSString *path = @"api/v1/users/data.json";

  return [AylaDatum createDatumWithKey:key
                                 value:value
                            httpClient:httpClient
                                  path:path
                               success:successBlock
                               failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAylaDatumWithKey:(NSString *)key
              success:(void (^)(AylaDatum *datum))successBlock
              failure:(void (^)(NSError *error))failureBlock {
  AylaHTTPClient *httpClient = [self userServiceHttpClient];

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/data/%@.json", key];

  return [AylaDatum fetchDatumWithKey:key
                           httpClient:httpClient
                                 path:path
                              success:successBlock
                              failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAylaDatumsWithKeys:(nullable NSArray AYLA_GENERIC(NSString *) *)keys
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock {
  AylaHTTPClient *httpClient = [self userServiceHttpClient];

  NSString *path = @"api/v1/users/data.json";

  return [AylaDatum fetchDatumsWithKeys:keys
                             httpClient:httpClient
                                   path:path
                                success:successBlock
                                failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAylaDatumsMatching:(NSString *)wildcardedString
                success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *
                                  datums))successBlock
                failure:(void (^)(NSError *error))failureBlock {
  AylaHTTPClient *httpClient = [self userServiceHttpClient];

  NSString *path = @"api/v1/users/data.json";

  return [AylaDatum fetchDatumsMatching:wildcardedString
                             httpClient:httpClient
                                   path:path
                                success:successBlock
                                failure:failureBlock];
}

- (nullable AylaHTTPTask *)
fetchAllAylaDatumsWithSuccess:
    (void (^)(NSArray AYLA_GENERIC(AylaDatum *) * datums))successBlock
                      failure:(void (^)(NSError *error))failureBlock {
  return [self fetchAylaDatumsWithKeys:nil
                               success:successBlock
                               failure:failureBlock];
}

- (nullable AylaHTTPTask *)
updateAylaDatumWithKey:(NSString *)key
               toValue:(NSString *)value
               success:(void (^)(AylaDatum *updatedDatum))successBlock
               failure:(void (^)(NSError *error))failureBlock {
  AylaHTTPClient *httpClient = [self userServiceHttpClient];

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/data/%@.json", key];

  return [AylaDatum updateKey:key
                      toValue:value
                   httpClient:httpClient
                         path:path
                      success:successBlock
                      failure:failureBlock];
}

- (nullable AylaHTTPTask *)deleteAylaDatumWithKey:(NSString *)key
                                          success:(void (^)())successBlock
                                          failure:(void (^)(NSError *error))
                                                      failureBlock {
  AylaHTTPClient *httpClient = [self userServiceHttpClient];

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/data/%@.json", key];

  return [AylaDatum deleteKey:key
                   httpClient:httpClient
                         path:path
                      success:successBlock
                      failure:failureBlock];
}

@end

@implementation AylaSessionManager (Contact)

- (AylaHTTPTask *)createContact:(AylaContact *)contact
                        success:(void (^)(AylaContact *_Nonnull))successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (!contact) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                 AylaRequestErrorResponseJsonKey : @{
                                   NSStringFromClass([AylaContact class]) :
                                       AylaErrorDescriptionIsInvalid
                                 }
                               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path = @"api/v1/users/contacts.json";
  return [self.userServiceHttpClient postPath:path
      parameters:[contact toJSONDictionary]
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSError *error = nil;
        AylaContact *createdContact =
            [[AylaContact alloc] initWithJSONDictionary:responseObject
                                                  error:&error];
        if (error) {
          AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                   NSStringFromSelector(_cmd));
          dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
          });
          return;
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(createdContact);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)fetchContacts:
                      (void (^)(NSArray<AylaContact *> *_Nonnull))successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock {
  NSString *path = @"api/v1/users/contacts.json";
  return [self.userServiceHttpClient getPath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSMutableArray *contacts = [NSMutableArray array];
        for (NSDictionary *contactJSON in responseObject) {
          NSError *error = nil;
          AylaContact *contact =
              [[AylaContact alloc] initWithJSONDictionary:contactJSON
                                                    error:&error];
          if (error) {
            AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                     NSStringFromSelector(_cmd));
            dispatch_async(dispatch_get_main_queue(), ^{
              failureBlock(error);
            });
            return;
          }
          [contacts addObject:contact];
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(contacts);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)updateContact:(AylaContact *)contact
                        success:(void (^)(AylaContact *_Nonnull))successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock {
  if (!contact) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                 AylaRequestErrorResponseJsonKey : @{
                                   NSStringFromClass([AylaContact class]) :
                                       AylaErrorDescriptionIsInvalid
                                 }
                               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/contacts/%@.json", contact.id];
  return [self.userServiceHttpClient putPath:path
      parameters:[contact toJSONDictionary]
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        NSError *error = nil;
        AylaContact *updatedContact =
            [[AylaContact alloc] initWithJSONDictionary:responseObject
                                                  error:&error];
        if (error) {
          AylaLogE([self logTag], 0, @"invalidResp:%@, %@", responseObject,
                   NSStringFromSelector(_cmd));
          dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
          });
          return;
        }

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock(updatedContact);
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}

- (AylaHTTPTask *)deleteContact:(AylaContact *)contact
                        success:(void (^)())successBlock
                        failure:(void (^)(NSError *_Nonnull))failureBlock {

  if (!contact) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                   code:AylaRequestErrorCodePreconditionFailure
                               userInfo:@{
                                 AylaRequestErrorResponseJsonKey : @{
                                   NSStringFromClass([AylaContact class]) :
                                       AylaErrorDescriptionIsInvalid
                                 }
                               }];
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  NSString *path =
      [NSString stringWithFormat:@"api/v1/users/contacts/%@.json", contact.id];
  return [self.userServiceHttpClient deletePath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {

        AylaLogI([self logTag], 0, @"%@, %@", @"complete",
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          successBlock();
        });

      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        AylaLogE([self logTag], 0, @"err:%@, %@", error,
                 NSStringFromSelector(_cmd));
        dispatch_async(dispatch_get_main_queue(), ^{
          failureBlock(error);
        });
      }];
}
@end
