//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaCache+Internal.h"
#import "AylaDefines_Internal.h"
#import "AylaDevice+Internal.h"
#import "AylaDiscovery.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPServer.h"
#import "AylaKeyCrypto.h"
#import "AylaLanCommand.h"
#import "AylaLanConfig.h"
#import "AylaLanMessage.h"
#import "AylaLanMessageCreator.h"
#import "AylaLanModule.h"
#import "AylaLanTask.h"
#import "AylaLogManager.h"
#import "AylaNetworks+Internal.h"
#import "AylaObject+Internal.h"
#import "AylaSessionManager+Internal.h"
#import "AylaSystemUtils.h"
#import "NSData+Base64.h"

/** Default adjustment to lan session poll interval */
static const NSTimeInterval DEFAULT_ADJUST_TO_CONFIG_POLL_INTERVAL_MS =
    4. * 1000;

/** Default lan session poll interval */
static const NSTimeInterval DEFAULT_POLL_INTERVAL_MS = 23. * 1000;

/** Default lan session poll leeway */
static const NSTimeInterval DEFAULT_POLL_LEEWAY_MS = 1. * 1000;

/** Default extension message timeout */
static const NSTimeInterval DEFAULT_EXTENSION_MSG_TIMEOUT = 5.;

/** Default key size of keys used in key negotiation */
static const AylaKeyCryptoRSAKeySize
    DEFAULT_KEY_SIZE_OF_KEYS_IN_KEY_NEGOTIATION = AylaKeyCryptoRSAKeySize1024;

/**
 * A helpful method to compose lan session errors.
 */
static NSError *composeLanSessionError(AylaLanErrorCode code, NSError *origErr,
                                       NSString *decrip, BOOL shouldLog) {
  NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
  if (decrip) {
    userInfoDict[AylaLanErrorResponseJsonKey] = @{ @"state" : decrip };
  }
  if (origErr) {
    userInfoDict[AylaLanErrorOrignialErrorKey] = origErr;
  }

  return [AylaErrorUtils errorWithDomain:AylaLanErrorDomain
                                    code:code
                                userInfo:userInfoDict
                               shouldLog:shouldLog
                                  logTag:@"LanModule"
                        addOnDescription:decrip];
}

@interface AylaLanModule () <AylaHTTPServerResponder>

@property(nonatomic) AylaTimer *sessionTimer;

@property(nonatomic) AylaEncryption *sessionEncryption;

@property(nonatomic) AylaKeyCrypto *keyCrypto;

@property(nonatomic) NSError *lastestError;

@property(nonatomic) AylaHTTPServer *httpServer;

@property(nonatomic) AylaLanSessionType sessionType;
@property(nonatomic) AylaLanSessionState sessionState;

@property(nonatomic) dispatch_queue_t processingQueue;

/**
 * Setter of lan ip is override to adjust http server responder and http client
 * based on updates of lan ip.
 */
@property(nonatomic, setter=setLanIp:) NSString *lanIp;

@property(nonatomic) AylaHTTPClient *deviceHttpClient;

@property(nonatomic) AylaLanMessageCreator *messageCreator;

/** Pending lan tasks */
@property(nonatomic) NSMutableArray AYLA_GENERIC(AylaLanTask *) * pendingTasks;

/** To device commands queue */
@property(nonatomic) NSMutableArray AYLA_GENERIC(AylaLanCommand *) *
    commandQueue;

/** Response waiting dictionary for sent commands */
@property(nonatomic) NSMutableDictionary AYLA_GENERIC(NSString *,
                                                      AylaLanCommand *)
    * responseWaitingCommands;

/** Sequence number */
@property(nonatomic) NSInteger seqNumber;

/** Command queue lock */
@property(nonatomic) NSRecursiveLock *commandQueueLock;

@end

@implementation AylaLanModule

- (instancetype)initWithDevice:(id<AylaLanSupportDevice>)device {
  self = [super init];
  if (!self)
    return nil;

  _device = device;
  _commandQueue = [NSMutableArray array];
  _commandQueueLock = [[NSRecursiveLock alloc] init];

  _messageCreator = [AylaLanMessageCreator defaultCreator];
  _processingQueue = [AylaDevice deviceProcessingQueue];

  __weak __block typeof(self) weakSelf = self;
  _sessionTimer = [[AylaTimer alloc]
      initWithTimeInterval:DEFAULT_POLL_INTERVAL_MS
                    leeway:DEFAULT_POLL_LEEWAY_MS
                     queue:_processingQueue
               handleBlock:^(AylaTimer *timer) {
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 if (strongSelf) {
                   [strongSelf timerFired:timer];
                 } else {
                   [timer stopPolling];
                 }
               }];
  _sessionEncryption = [[AylaEncryption alloc] init];

  // Init key crypto
  _keyCrypto = [[AylaKeyCrypto alloc] init];

  // Set lan ip
  self.lanIp = device.lanIp;

  _pendingTasks = [NSMutableArray array];
  _responseWaitingCommands = [NSMutableDictionary dictionary];

  return self;
}

- (BOOL)openSessionWithType:(AylaLanSessionType)type
               onHTTPServer:(AylaHTTPServer *)httpServer {
  AYLAssert(httpServer, @"Must input a valid http server");

  self.sessionType = type;
  // Hold a strong reference to the http server
  self.httpServer = httpServer;

  AylaLogI([self logTag], 0, @"dsn:%@, %@", self.device.dsn,
           @"openSessionWithType");

  // We only attempt to open a new lan session when session state satifies state
  // check.
  if (self.sessionState == AylaLanSessionStateReadyToOpen ||
      self.sessionState == AylaLanSessionStateError ||
      self.sessionState == AylaLanSessionStateDisabled) {
    [self setSessionState:AylaLanSessionStateOpening object:nil error:nil];
    // Clean all pending task before openning a new session.
    [self cleanPendingTasks];

    // Use device lan ip as default lan ip
    self.lanIp = self.device.lanIp;

    // If lan ip is enabled
    if (self.lanIp) {
      // Add self as a responder of current lan ip.
      [self.httpServer addResponder:self toLanIp:self.lanIp];
    }

    void (^continueBlock)(AylaLanConfig *) = ^(AylaLanConfig *lanConfig) {
      // Api fetch lan config takes the responsibility to update lan config of
      // current
      // device.
      if (lanConfig) {
        // Send extension message immidiately and start timer
        [self.sessionTimer startPollingWithDelay:NO];
      } else {
        NSString *decription =
            self.sessionType == AylaLanSessionTypeNormal
                ? @"Empty config on cloud."
                : @"Must set a config file before eastablishing setup session.";

        // Config is empty on cloud (which indicates module never picked up
        // config file
        // from cloud) or config is not set for secure setup, , Stop lan attempt
        // and send
        // back an error.
        [self
            setSessionState:AylaLanSessionStateError
                     object:nil
                      error:composeLanSessionError(AylaLanErrorCodeEmptyConfig,
                                                   nil, decription, YES)];
      }
    };

    // Fetch lan config will be skipped if lan module is opening a setup sesion
    if (self.sessionType == AylaLanSessionTypeSetup) {
      continueBlock(self.config);
      // Skip fetch lan config
    } else {
      // Attempt to refresh lan config
      [self fetchLanConfig:^(AylaLanConfig *_Nullable lanConfig) {
        continueBlock(lanConfig);
      }
          failure:^(NSError *_Nonnull error) {
            // Failed to update config
            // if we have a buffered config, keep trying to eastablish the lan
            // connection
            if (self.config) {
              continueBlock(self.config);
            } else {
              // Otherwise stop lan attempt and send back an error.
              [self
                  setSessionState:AylaLanSessionStateError
                           object:nil
                            error:composeLanSessionError(
                                      AylaLanErrorCodeRequireCloudReachability,
                                      error, @"", YES)];
            }
          }];
    }
  } else {
    AylaLogI([self logTag], 0, @"%@, already in progress:%ld, %@",
             self.device.dsn, self.sessionState, @"openSessionWithType");
  }

  return YES;
}

- (void)closeSession {
  AylaLogI([self logTag], 0, @"Closed lan session for %@", self.device.dsn);

  // Stop timer
  [self.sessionTimer stopPolling];

  // Set session state as disabled
  [self setSessionState:AylaLanSessionStateDisabled object:nil error:nil];

  // Clean lan ip
  self.lanIp = nil;

  // Clean all pending tasks.
  [self cleanPendingTasks];
}

- (void)refreshSessionIfNecessary {
  if (self.sessionState != AylaLanSessionStateDisabled) {
    NSString *lanIp = self.device.lanIp;
    // If lan ip has been updated for device
    if (![self.lanIp isEqualToString:lanIp]) {
      self.lanIp = lanIp;
      if (lanIp) {
        [self.httpServer addResponder:self toLanIp:lanIp];
      }

      // Clean all pending tasks
      [self cleanPendingTasks];

      // Send a session extension message immidiately
      [self sendExtensionMessageWithCompletionBlock:nil];

      // reset session state as opening
      [self setSessionState:AylaLanSessionStateOpening];
    }
  }
}

/**
 * Add a task to current task queue
 */
- (void)addTask:(AylaLanTask *)task {
  [self.commandQueueLock lock];

  // Move task to pending task queue
  [self.pendingTasks addObject:task];

  BOOL notify = self.commandQueue.count == 0;

  // Move commands into commands queue
  [self.commandQueue addObjectsFromArray:task.commands];

  [self.commandQueueLock unlock];

  // Send a notify message if necessary
  if (notify) {
    [self sendExtensionMessageWithCompletionBlock:nil];
  }
}

/**
 * Use this method to send a extension message
 */
- (BOOL)sendExtensionMessageWithCompletionBlock:
    (void (^)(id _Nullable responseObject,
              NSError *_Nullable error))completionBlock {
  if (self.sessionState == AylaLanSessionStateDisabled) {
    return NO;
  }

  NSDictionary *params = @{
    @"local_reg" : @{
      @"ip" : [AylaSystemUtils getLanIp] ?: @"",
      @"port" : @(self.httpServer.listeningPort),
      @"uri" : @"/local_lan",
      @"notify" : @(self.commandQueue.count > 0)
    }
  };

  NSString *method = self.sessionState == AylaLanSessionStateActive
                         ? AylaHTTPRequestMethodPUT
                         : AylaHTTPRequestMethodPOST;
  NSMutableURLRequest *request =
      [self.deviceHttpClient requestWithMethod:method
                                          path:@"local_reg.json"
                                    parameters:params];
  [request setTimeoutInterval:DEFAULT_EXTENSION_MSG_TIMEOUT];

  AylaHTTPTask *task = [self.deviceHttpClient taskWithRequest:request
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        AylaLogI([self logTag], 0, @"%@, %@", @"success",
                 @"sendExtensionMessage");
        if (completionBlock) {
          completionBlock(responseObject, nil);
        }
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {

        NSHTTPURLResponse *resp =
            (NSHTTPURLResponse *)error.userInfo[AylaHTTPErrorHTTPResponseKey];
        NSInteger httpStatusCode = resp.statusCode;

        AylaLogW([self logTag], 0, @"failed:%ld, %@", httpStatusCode,
                 @"sendExtensionMessage");
        // Get issues from error
        switch (httpStatusCode) {
        case 400: // 400: Forbidden - Bad Request (JSON parse failed)
          [self setSessionState:AylaLanSessionStateError
                         object:nil
                          error:composeLanSessionError(
                                    AylaLanErrorCodeDeviceResponseError, error,
                                    @"", YES)];
          break;
        case 403: // 403: Forbidden - lan_ip on a different network
          [self setSessionState:AylaLanSessionStateError
                         object:nil
                          error:composeLanSessionError(
                                    AylaLanErrorCodeDeviceDifferentLan, error,
                                    @"", YES)];
          break;
        case 404: // 404: Not Found - Lan Mode is not supported by this module
          [self setSessionState:AylaLanSessionStateError
                         object:nil
                          error:composeLanSessionError(
                                    AylaLanErrorCodeDeviceNotSupport, error,
                                    @"", YES)];
          break;
        case 412:
          if (self.sessionType == AylaLanSessionTypeSetup) {
            [self startKeyNegotiation:nil];
          } else {
            [self setSessionState:AylaLanSessionStateError
                           object:nil
                            error:composeLanSessionError(
                                      AylaLanErrorCodeDeviceResponseError,
                                      error, @"", YES)];
          }
          break;
        case 503: // 503: Service Unavailable - Insufficient resources or
                  // maximum number of sessions exceeded
          [self setSessionState:AylaLanSessionStateError
                         object:nil
                          error:composeLanSessionError(
                                    AylaLanErrorCodeDeviceResponseError, error,
                                    @"", YES)];
          break;
        default: {
          [self setSessionState:AylaLanSessionStateError
                         object:nil
                          error:composeLanSessionError(
                                    AylaLanErrorCodeMobileSessionMsgTimeOut,
                                    error, @"", YES)];
          break;
        }
        }
        if (completionBlock) {
          completionBlock(nil, error);
        }
      }];
  [task start];
  return YES;
}

/**
 * Use this method to udpate session state of current module. This method also
 * trigger corresponding delegate callbacks
 * based on different status.
 *
 * @param state  Status of current lan sessin.
 * @param object An object which may be returned to delegate.
 * @param error  Error object which may be returned to delegate.
 */
- (void)setSessionState:(AylaLanSessionState)state
                 object:(id)object
                  error:(NSError *)error {
  if (state == AylaLanSessionStateActive && state != _sessionState) {
    AylaLogD([self logTag], 0, @"session active:%@, %@", self.device.dsn,
             @"setSessionState");
    _sessionState = state;
    [self.delegate lanModule:self didEastablishSessionOnLanIp:self.lanIp];
  } else if (error) {
    _sessionState = state;
    [self.delegate lanModule:self didFail:error];
  } else {
    _sessionState = state;
  }

  if (_sessionState == AylaLanSessionStateDisabled) {
    [self.delegate didDisableSessionOnModule:self];
  }
}

/**
 * Use this method to fetch lan config from cloud. Once a valid config is
 * fetched, this method will be responsible to
 * update local copy and refresh session timer if necessary.
 *
 * @param successBlock A block which would be called with fetched config when
 * request is succeeded.
 * @param failureBlock A block which would be called an NSError object when
 * request is failed.
 *
 * @return A connect task object.
 */
- (nullable AylaConnectTask *)
fetchLanConfig:(void (^)(AylaLanConfig *_Nonnull lanConfig))successBlock
       failure:(void (^)(NSError *_Nonnull error))failureBlock {
  NSString *path = [NSString
      stringWithFormat:@"%@%@%@", @"devices/", self.device.key, @"/lan.json"];

  NSError *error;
  AylaHTTPClient *httpClient = [self getServiceHTTPClient:&error];
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      failureBlock(error);
    });
    return nil;
  }

  return [httpClient getPath:path
      parameters:nil
      success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
        AylaLanConfig *config = nil;
        NSDictionary *lanInfo = [responseObject valueForKeyPath:@"lanip"];
        // Check empty data from server
        if (lanInfo) {
          config =
              [[AylaLanConfig alloc] initWithJSONDictionary:lanInfo error:nil];

          // Check if lan config is different to the one we have
          NSNumber *lanipKeyId = self.config.lanipKeyId;
          if (config &&
              lanipKeyId.integerValue != config.lanipKeyId.integerValue) {
            self.config = config;
            // Get new refresh time and update timer
            // Adjust refresh time interval with a value set in
            // DEFAULT_ADJUST_TO_CONFIG_POLL_INTERVAL
            // TODO: Maybe an adjust to gurantee the interval value will greater
            // than 0
            NSTimeInterval interval = config.keepAlive.doubleValue * 1000 -
                                      DEFAULT_ADJUST_TO_CONFIG_POLL_INTERVAL_MS;

            __weak __block typeof(self) weakSelf = self;
            [self.sessionTimer refreshWithTimeInterval:interval
                                                leeway:DEFAULT_POLL_LEEWAY_MS
                                           handleBlock:^(AylaTimer *timer) {
                                             __strong typeof(weakSelf)
                                                 strongSelf = weakSelf;
                                             if (strongSelf) {
                                               [strongSelf timerFired:timer];
                                             } else {
                                               [timer stopPolling];
                                             }
                                           }];
            [self.device.sessionManager.aylaCache save:AylaCacheTypeLANConfig
                                              uniqueId:self.device.dsn
                                             andObject:config];
            self.device.disableLANUntilNetworkChanges = NO;
          } else if (config) {
            // If config is not changed we do nothing
          } else {
            // If config is gone on cloud
            self.config = nil;
          }
        } else {
          AylaLogW([self logTag], 0, @"%@, %@", @"emptyOnCloud", @"fetch");
        }
        successBlock(config);
      }
      failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
        if ([self.device.sessionManager.aylaCache
                cachingEnabled:AylaCacheTypeLANConfig]) {
          AylaLanConfig *lanConfig = [self.device.sessionManager.aylaCache
               getData:AylaCacheTypeLANConfig
              uniqueId:self.device.dsn];
          self.config = lanConfig;
          successBlock(lanConfig);
          return;
        }
        failureBlock(error);
      }];
}

/**
 * A method which would be called when session timer got fired.
 */
- (void)timerFired:(AylaTimer *)timer {
  if (self.sessionState == AylaLanSessionStateDisabled) {
    // If lan has been disabled for any reason, stop current timer.
    AylaLogI([self logTag], 0, @"cancelled timer for state %ld",
             AylaLanSessionStateDisabled);
    [timer stopPolling];
    return;
  }

  AylaLogV([self logTag], 0, @"timer triggered for %@", self.device.dsn);
  [self sendExtensionMessageWithCompletionBlock:nil];
}

//-----------------------------------------------------------
#pragma mark - HTTP Server Response
//-----------------------------------------------------------

/**
 * Use this method to handle lan messages EXCEPT ones with type
 * AylaLanMessageTypeKeyExchange or
 * AylaLanMessageTypeCommand
 *
 * @param message The received message from HTTP server.
 *
 * @return HTTP server resposne of given message.
 */
- (AylaHTTPServerResponse *)handleLanMessage:(AylaLanMessage *)message {
  // Notify delegate regarding this message
  [self.delegate lanModule:self didReceiveMessage:message];

  if (message.isCallback) {
    // When a update is returned for a callback, we need invoke this pending
    // commands.
    [self handleCallback:message];
  }

  return nil;
}

/**
 * Use this method to handle a message which has callback status.
 *
 * @param message The received message from HTTP server.
 */
- (void)handleCallback:(AylaLanMessage *)message {
  NSString *cmdIdInString = [@(message.cmdId) stringValue];

  AylaLanCommand *pendingCommand = self.responseWaitingCommands[cmdIdInString];
  if (pendingCommand) {
    // Remove this command
    self.responseWaitingCommands[cmdIdInString] = nil;

    if (pendingCommand.callbackBlock) {
      // If we find pending commands for current message, we update that command
      // with data received in lan
      // message.
      pendingCommand.responseObject = message.jsonObject;
      // Check returned status code in message. If a bad status is returned, add
      // an error object inside the
      // command.
      if (message.status >= 400) {
        pendingCommand.error = [AylaErrorUtils
            errorWithDomain:AylaLanErrorDomain
                       code:AylaLanErrorCodeDeviceResponseError
                   userInfo:@{
                     AylaLanErrorStatusCode : @(message.status),
                     AylaLanErrorFailedCommand : pendingCommand,
                     AylaLanErrorResponseJsonKey : message.jsonObject ?: @{}
                   }];
      } else {
        pendingCommand.error = message.error;
      }
      pendingCommand.callbackBlock(
          pendingCommand, pendingCommand.responseObject, pendingCommand.error);
    }
  }
  AylaLogI([self logTag], 0, @"handleCallback");
}

/**
 * Use this method to get next valid command from command queue.
 *
 * @return Next valid lan command. Returns nil if no command left in command
 * queue.
 */
- (AylaLanCommand *)getNextValidCommand {
  AylaLanCommand *command;
  [self.commandQueueLock lock];
  do {
    command = [self.commandQueue firstObject];
    if (command) {
      [self.commandQueue removeObjectAtIndex:0];
    }
  } while (command && [command isCancelled]);
  [self.commandQueueLock unlock];
  return command;
}

/**
 * This method returns a HTTP server response which contains next command to
 * device.
 */
- (AylaHTTPServerResponse *)responseOfNextCommand {
  AylaLanCommand *command = [self getNextValidCommand];
  NSString *commandString = nil;
  if (command) {
    // compose to device command
    commandString = [self commandStringWithCommand:command
                                       sequenceNum:[self nextSequenceNum]];

    if (command.processingBlock) {
      command.processingBlock(command, YES);
    }

    // If command needs response from module
    if (command.needsWaitResponse) {
      self.responseWaitingCommands[[@(command.cmdId) stringValue]] = command;
    } else if (command.callbackBlock) {
      // If no need to wait a response and callback has been set, invoke
      // callback directly.
      command.callbackBlock(command, nil, nil);
    }
  } else {
    // If no command found, set command string with no command
    commandString =
        [self commandStringWithCommand:nil sequenceNum:[self nextSequenceNum]];
  }

  AYLAssert(commandString, @"command string must not be nil.");

  NSString *encrypted = [self.sessionEncryption
      encryptEncapsulateSignWithPlaintext:commandString
                                     sign:self.sessionEncryption.appSignKey];
  int httpStatusCode = self.commandQueue.count > 0 ? 206 : 200;

  AylaLogI([self logTag], 0, @"statusCode:%d, %@", httpStatusCode,
           @"responseOfNextCommand");

  NSData *data = encrypted ? [encrypted dataUsingEncoding:NSUTF8StringEncoding]
                           : [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
  AylaHTTPServerResponse *resp = [[AylaHTTPServerResponse alloc]
      initWithHttpStatusCode:httpStatusCode
                headerFields:[AylaHTTPServerResponse JSONContentHeaderField]
                    bodyData:data];

  return resp;
}

/**
 * A helpful method to compose the to-device message.
 *
 * @param command     The command which is included in this message.
 * @param sequenceNum Next sequence number.
 *
 * @return Composed command string.
 */
- (NSString *)commandStringWithCommand:(AylaLanCommand *)command
                           sequenceNum:(NSInteger)sequenceNum {
  NSDictionary *commandInJson = @{
    @"seq_no" : @(sequenceNum),
    @"data" : command ? command.encapulatedCommandInJson : @{}
  };
  // translate to a json string
  NSError *dataError;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:commandInJson
                                                     options:0
                                                       error:&dataError];
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

//-----------------------------------------------------------
#pragma mark - Key Exchange
//-----------------------------------------------------------
static const int DEFAULT_LAN_TOKEN_LEN = 16;
/**
 * A method which handles key exchanges
 *
 * @param message Recevied key exchange message from device.
 *
 * @return HTTP server resposne of current key exchange request.
 */
- (AylaHTTPServerResponse *)handleKeyExchange:(AylaLanMessage *)message {
  NSDictionary *headerFields = @{ @"Content-Type" : @"application/json" };

  NSError *jerr;
  id responseJSON =
      [NSJSONSerialization JSONObjectWithData:message.data
                                      options:NSJSONReadingMutableContainers
                                        error:&jerr];
  if (!responseJSON) {
    AylaHTTPServerResponse *resp =
        [[AylaHTTPServerResponse alloc] initWithHttpStatusCode:400
                                                  headerFields:headerFields
                                                      bodyData:nil];
    AylaLogE([self logTag], 0, @"httpCode:%ld, jerr:%ld, %@",
             (long)resp.httpStatusCode, (long)jerr.code, @"handleKeyExchange");
    return resp;
  }

  NSDictionary *jsonDict = responseJSON;
  NSDictionary *info = [jsonDict objectForKey:@"key_exchange"];

  NSString *localRnd = [AylaEncryption randomToken:DEFAULT_LAN_TOKEN_LEN];
  NSNumber *curTime = [NSNumber
      numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];

  // Get current config
  AylaLanConfig *lanConfig = self.config;
  AylaEncryption *encryption = self.sessionEncryption;

  // Update encryption data
  NSNumber *ver = encryption.version = info[@"ver"];
  NSNumber *proto = encryption.proto1 = info[@"proto"];
  NSNumber *keyId = encryption.keyId1 = info[@"key_id"];

  AylaLogI([self logTag], 0, @"keyInfo, ver:%@, proto:%@, key_id:%@, %@", ver,
           proto, keyId, @"handleKeyExchange");

  AylaHTTPServerResponse * (^keyExchangeErrorResponseBlock)(NSDictionary *,
                                                            int);
  keyExchangeErrorResponseBlock = ^AylaHTTPServerResponse *(
      NSDictionary *jsonDescrpInError, int httpStatusCode) {
    NSError *error =
        [AylaErrorUtils errorWithDomain:AylaLanErrorDomain
                                   code:AylaLanErrorCodeKeyGenerationFailure
                               userInfo:@{
                                 AylaLanErrorResponseJsonKey : jsonDescrpInError
                               }
                              shouldLog:YES
                                 logTag:[self logTag]
                       addOnDescription:@"handleKeyExchange"];
    [self setSessionState:AylaLanSessionStateError object:nil error:error];

    return [[AylaHTTPServerResponse alloc]
        initWithHttpStatusCode:httpStatusCode
                  headerFields:[AylaHTTPServerResponse JSONContentHeaderField]
                      bodyData:nil];
  };

  if (ver.intValue != 1) {
    return keyExchangeErrorResponseBlock(
        @{
          @"ver" : AylaErrorDescriptionIsInvalid
        },
        426);
  }
  if (proto.intValue != 1) {
    return keyExchangeErrorResponseBlock(
        @{
          @"proto" : AylaErrorDescriptionIsInvalid
        },
        412);
  }

  // Init a new encryp config
  AylaEncryptionConfig *encrypConfig = [[AylaEncryptionConfig alloc] init];

  if (self.sessionType == AylaLanSessionTypeNormal) {
    NSNumber *lanIpKeyId = lanConfig.lanipKeyId;
    if (!lanIpKeyId || ![keyId isEqualToNumber:lanIpKeyId]) {
        self.device.disableLANUntilNetworkChanges = YES;
      // TODO: if cache is enabled, clean cache here
      return keyExchangeErrorResponseBlock(
          @{
            @"lanIpKeyId" : AylaErrorDescriptionIsInvalid
          },
          412);
    }

    encrypConfig.type = AylaEncryptionTypeLAN;
    // Setup encryp config lan ip key as lan config's lan ip key.
    encrypConfig.lanipKey = lanConfig.lanipKey;
  } else if (self.sessionType == AylaLanSessionTypeSetup) {
    // If we are doing a setup session.
    // Check if `sec` key is showing in the message
    NSString *secret = info[@"sec"];
    if (secret) {
      // If secret is ready, use keyCrypto to decrypt and setup encryp config
      NSData *decodedData = [NSData dataFromBase64String:secret];
      NSData *keyInData = [self.keyCrypto decryptAsLanKey:decodedData];

      if (keyInData) {
        encrypConfig.type = AylaEncryptionTypeWifiSetup;
        encrypConfig.data = keyInData;
      } else {
        // an error happened
        return keyExchangeErrorResponseBlock(
            @{
              @"data" : @"can't be decrypted"
            },
            412);
      }
    } else {
      // If secret is not appeared in message, send a request to start key
      // negotiation.
      [self startKeyNegotiation:message];

      // We still return an error to stop current key exchange request.
      AylaHTTPServerResponse *resp =
          [[AylaHTTPServerResponse alloc] initWithHttpStatusCode:412
                                                    headerFields:headerFields
                                                        bodyData:nil];
      return resp;
    }
  } else {
    return keyExchangeErrorResponseBlock(
        @{
          @"type" : @"unknown session type"
        },
        412);
  }

  [encryption generateSessionkeys:encrypConfig
                            sRnd1:info[@"random_1"]
                           nTime1:info[@"time_1"]
                            sRnd2:localRnd
                           nTime2:curTime];

  NSString *respStr =
      [NSString stringWithFormat:@"{\"random_2\":\"%@\",\"time_2\":%@}",
                                 localRnd, curTime];
  NSData *respData = [respStr dataUsingEncoding:NSUTF8StringEncoding];

  AylaHTTPServerResponse *resp =
      [[AylaHTTPServerResponse alloc] initWithHttpStatusCode:200
                                                headerFields:headerFields
                                                    bodyData:respData];

  AylaLogI(@"httpServer", 0, @"httpCode:%d, resp:%@, %@", 200, respStr,
           @"handleKeyExchange");

  // Set session state as alive.
  [self setSessionState:AylaLanSessionStateActive object:nil error:nil];

  return resp;
}

//-----------------------------------------------------------
#pragma mark - HTTP Server Responder
//-----------------------------------------------------------
- (AylaHTTPServerResponse *)httpServer:(AylaHTTPServer *)server
                     didReceiveRequest:(AylaHTTPServerRequest *)request {
  NSError *error;
  AylaLanMessage *message =
      [self.messageCreator messageFromHTTPServerRequest:request
                                             encryption:self.sessionEncryption
                                                  error:&error];
  AylaHTTPServerResponse *resp = nil;

  if (!error) {
    switch (message.type) {
    case AylaLanMessageTypeKeyExchange:
      resp = [self handleKeyExchange:message];
      break;
    case AylaLanMessageTypeCommands:
      resp = [self responseOfNextCommand];
      break;
    default: {
      if (message.type == AylaLanMessageTypeUnknown) {
        AylaLogW([self logTag], 0, @"unknown message, %@",
                 @"didReceiveRequest");
      }
      resp = [self handleLanMessage:message];
    } break;
    }
  } else {
    // If we hit an error, send back a 400 to module.
    resp = [[AylaHTTPServerResponse alloc]
        initWithHttpStatusCode:400
                  headerFields:[AylaHTTPServerResponse JSONContentHeaderField]
                      bodyData:nil];
  }

  return resp ?: [[AylaHTTPServerResponse alloc]
                     initWithHttpStatusCode:200
                               headerFields:[AylaHTTPServerResponse
                                                JSONContentHeaderField]
                                   bodyData:nil];
}

- (void)httpServer:(AylaHTTPServer *)server
    isRemovedAsResponderToLanIp:(NSString *)lanIp {
  AylaLogD([self logTag], 0,
           @"module(%@): be replaced as responder of lan ip:%@",
           self.device.dsn, lanIp);

  NSError *error = [AylaErrorUtils
       errorWithDomain:AylaLanErrorDomain
                  code:AylaLanErrorCodePausedByDuplicateLanIp
              userInfo:@{
                AylaLanErrorResponseJsonKey : @{
                  NSStringFromSelector(@selector(device)) :
                      @"session is paused because of a replacement to the "
                      @"responder of lan ip."
                }
              }
             shouldLog:YES
                logTag:[self logTag]
      addOnDescription:@"startKeyNegotiation"];

  // Set session state with an error
  [self setSessionState:AylaLanSessionStateError object:nil error:error];

  // Clean all pending tasks.
  [self cleanPendingTasks];
}

//-----------------------------------------------------------
#pragma mark - Key Negotiation
//-----------------------------------------------------------
/**
 * Use this method to send key negotiation request to module.
 *
 * @param lanMessage Lan message received from module. This is optional.
 */
- (void)startKeyNegotiation:(AylaLanMessage *)lanMessage {
  NSString *pubKeyTag = self.config.keyPairPublicKeyTag;
  NSString *privKeyTag = self.config.keyPairPrivateKeyTag;
  if (!pubKeyTag || !pubKeyTag) {
    NSError *error = [AylaErrorUtils
         errorWithDomain:AylaLanErrorDomain
                    code:AylaLanErrorCodeKeyGenerationFailure
                userInfo:@{
                  AylaLanErrorResponseJsonKey :
                      @{@"key_neg" : @"Must set key tags in config."}
                }
               shouldLog:YES
                  logTag:[self logTag]
        addOnDescription:@"startKeyNegotiation"];
    [self setSessionState:AylaLanSessionStateError object:nil error:error];
    return;
  }

  // Switch to a different thread to handle the key checks
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
    if (![self.keyCrypto getKeyPairFromKeyChainWithPubKeyTag:pubKeyTag
                                                  privKeyTag:privKeyTag]) {
      // Key Negoitation will take some time if key generation is required.
      self.keyCrypto.pubKeyTag = pubKeyTag;
      self.keyCrypto.privKeyTag = privKeyTag;

      int keySize = self.config.keySizeOfKeysInKeyPair
                        ? [self.config.keySizeOfKeysInKeyPair intValue]
                        : DEFAULT_KEY_SIZE_OF_KEYS_IN_KEY_NEGOTIATION;
      if (![self.keyCrypto updateRSAKeyPairInKeyChain:keySize]) {
        NSError *error = [AylaErrorUtils
             errorWithDomain:AylaLanErrorDomain
                        code:AylaLanErrorCodeKeyGenerationFailure
                    userInfo:@{
                      AylaLanErrorResponseJsonKey :
                          @{@"key_nego" : @"Unable to create a new key pair."}
                    }
                   shouldLog:YES
                      logTag:[self logTag]
            addOnDescription:@"startKeyNegotiation"];
        [self setSessionState:AylaLanSessionStateError object:nil error:error];
        return;
      }
    }

    // Key pair should be ready in keyCrypto
    NSDictionary *params = @{
      @"local_reg" : @{
        @"ip" : [AylaSystemUtils getLanIp] ?: @"",
        @"port" : @(self.httpServer.listeningPort),
        @"uri" : @"/local_lan",
        @"key" : [[self.keyCrypto publicKeyInData] base64EncodedString] ?: @"",
        @"notify" : @(0)
      }
    };

    [self.deviceHttpClient postPath:@"local_reg.json"
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
          AylaLogI([self logTag], 0, @"%@, %@", @"success",
                   @"startKeyNegotiation");
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
          AylaLogE([self logTag], 0, @"errCode:%ld, %@", (long)error.code,
                   @"startKeyNegotiation");
          [self setSessionState:AylaLanSessionStateError
                         object:nil
                          error:error];
        }];
  });
}

//-----------------------------------------------------------
#pragma mark - Helpful
//-----------------------------------------------------------

- (BOOL)isActive {
  return self.sessionState == AylaLanSessionStateActive;
}

- (NSInteger)nextSequenceNum {
  return ++self.seqNumber;
}

- (void)cleanPendingTasks {
  [self.commandQueueLock lock];
  self.seqNumber = 0;
  for (AylaLanTask *task in self.pendingTasks) {
    [task cancel];
  }

  self.pendingTasks = [NSMutableArray array];
  self.commandQueue = [NSMutableArray array];

  [self.commandQueueLock unlock];
}

- (void)setLanIp:(NSString *)lanIp {
  NSString *curLanIp = _lanIp;
  if (lanIp) {
    if (![lanIp isEqualToString:curLanIp]) {
      // Only remove self as responder to current lan ip if new lan ip is set
      // differently.
      if (curLanIp) {
        [self.httpServer removeResponder:self fromLanIp:curLanIp];
      }
      self.deviceHttpClient =
          [AylaHTTPClient apModeDeviceClientWithLanIp:lanIp usingHTTPS:NO];
      _lanIp = lanIp;
    }
  } else {
    // When a nil is passed in
    if (curLanIp) {
      [self.httpServer removeResponder:self fromLanIp:curLanIp];
    }
    _lanIp = lanIp;
  }
}

- (AylaHTTPClient *)getServiceHTTPClient:
    (NSError *_Nullable __autoreleasing *_Nullable)error {
  AylaHTTPClient *client = self.httpClient;
  if (!client && error) {
    *error = [AylaErrorUtils
        errorWithDomain:AylaRequestErrorDomain
                   code:AylaRequestErrorCodePreconditionFailure
               userInfo:@{
                 AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound
               }];
  }
  return client;
}

- (NSString *)logTag {
  return @"LanModule";
}

@end
