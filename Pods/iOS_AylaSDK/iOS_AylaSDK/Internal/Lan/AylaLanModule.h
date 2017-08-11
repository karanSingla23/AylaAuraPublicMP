//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaEncryption.h"
#import "AylaLanSupportDevice.h"
#import "AylaTimer.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaConnectTask;
@class AylaDevice;
@class AylaHTTPClient;
@class AylaHTTPServer;
@class AylaLanConfig;
@class AylaLanMessage;
@class AylaLanModule;
@class AylaLanTask;

typedef NS_ENUM(NSInteger, AylaLanSessionState) {
    /** Session is ready to open. */
    AylaLanSessionStateReadyToOpen,

    /** Session is opening. */
    AylaLanSessionStateOpening,

    /** Session is active. Communication between mobile SDK and device has been eastablished */
    AylaLanSessionStateActive,

    /** Session is closing. */
    AylaLanSessionStateClosing,

    /** An error happens in session. */
    AylaLanSessionStateError,

    /** Session has been disabled. */
    AylaLanSessionStateDisabled
};

typedef NS_ENUM(NSInteger, AylaLanSessionType) {
    /** Session type Normal */
    AylaLanSessionTypeNormal,

    /** Session type Setup which should be set when eastablishing a Secure Setup */
    AylaLanSessionTypeSetup
};

/**
 * Lan module internal delegate proctocol
 */
@protocol AylaLanModuleInternalDelegate<NSObject>

/**
 * Informs delegate a new session has been eastalished.
 *
 * @param lanModule Current lan module.
 * @param lanIp     The lan Ip on which current session is eastablished.
 */
- (void)lanModule:(AylaLanModule *)lanModule didEastablishSessionOnLanIp:(NSString *)lanIp;

/**
 * Informs delegate a new lan message has been received from device.
 *
 * @param lanModule Current lan module.
 * @param lanIp     Received lan mdessage.
 */
- (void)lanModule:(AylaLanModule *)lanModuel didReceiveMessage:(AylaLanMessage *)message;

/**
 * Informs delegate an error has occured in lan communication.
 *
 * @param lanModule Current lan module.
 * @param error     The error from lan module.
 */
- (void)lanModule:(AylaLanModule *)lanModule didFail:(NSError *)error;

/**
 * Informs delegate session has been disabled.
 *
 * @param lanModule Current lan module.
 */
- (void)didDisableSessionOnModule:(AylaLanModule *)module;

@end

/**
 * The AylaLanModule is responsible for LAN communication with an AylaDevice object.
 * The AylaDevice creates an AylaLanModule when it wishes to enter LAN communication with the
 * device. The AylaLanModule is responsible for maintaining the LAN session with the device as well
 * as processing commands to or from the device.
 *
 * Before enabling lan session on a lan module, lan module must be configured with either a lan config or a http client.
 * If config is set, lan module will first use this known config file to eastablish connections to module. If http
 * client is set and config file is invalid or rejected by module, library will attempt to use the given http client to
 * update config file from cloud.
 */
@interface AylaLanModule : NSObject

/** Reference to device */
@property (nonatomic, readonly, weak) id<AylaLanSupportDevice> device;

/** Current in-use lan ip */
@property (nonatomic, strong, readonly, nullable) NSString *lanIp;

/** Current in-use lan config */
@property (nonatomic, nullable) AylaLanConfig *config;

/** Current in-use device service http client */
@property (nonatomic, nullable) AylaHTTPClient *httpClient;

/** Internal delegate of current lan module */
@property (nonatomic, weak) id<AylaLanModuleInternalDelegate> delegate;

/** Session type */
@property (nonatomic, readonly) AylaLanSessionType sessionType;

/** Session state */
@property (nonatomic, readonly) AylaLanSessionState sessionState;

/**
 * Init method
 *
 * @param device a device object which conforms protocol `AylaLanSupportDevice`.
 */
- (instancetype)initWithDevice:(id<AylaLanSupportDevice>)device;

/**
 * A helpful method which returns YES if lan session is active.
 */
- (BOOL)isActive;

/**
 * Use this method to open a new lan session.
 *
 * @param type       Type of new lan session.
 * @param httpServer To be used http server of lan session.
 *
 * @return Returns YES if session is going to be eastablished or it's eatablishing or it's alredy active.
 */
- (BOOL)openSessionWithType:(AylaLanSessionType)type onHTTPServer:(AylaHTTPServer *)httpServer;

/**
 * Close current session.
 */
- (void)closeSession;

/**
 * Let lan module check status of linked lan support device and determine if a session update is required.
 *
 * @note If lan session has been set as disabled, any calls to this method would be skipped. Otherwise, it will detect
 * changes to lan ip of linked lan support device. If lan ip has been updated, lan module would refresh variables and
 * quickly restart a new lan session attempt.
 */
- (void)refreshSessionIfNecessary;

/**
 * Add a task to task list of current lan module. Use this method as the trigger to start a task.
 * @note Once a task is added into module's task list. It's comannds will also be appended to the sending command queue.
 * And all commands will be sent in order when device comes to pick up lan commands.
 *
 * @param task The task which will be processed by lan module.
 */
- (void)addTask:(AylaLanTask *)task;

/**
 * Use this method to fetch lan config from cloud. Once a valid config is fetched, this method will be responsible to
 * update local copy and refresh session timer if necessary.
 *
 * @param successBlock A block which would be called with fetched config when request is succeeded.
 * @param failureBlock A block which would be called an NSError object when request is failed.
 *
 * @return A connect task object.
 */
- (nullable AylaConnectTask *)fetchLanConfig:(void (^)(AylaLanConfig *_Nullable lanConfig))successBlock
                                     failure:(void (^)(NSError *_Nonnull error))failureBlock;

@end

NS_ASSUME_NONNULL_END