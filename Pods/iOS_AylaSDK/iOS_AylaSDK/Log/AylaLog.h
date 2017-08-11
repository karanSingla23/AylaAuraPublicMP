//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Available levels at which to log `AylaLogMessages`.
 */
typedef NS_ENUM(uint16_t, AylaLogMessageLevel) {
    /**
     * Log message level Error.
     */
    AylaLogMessageLevelError = 1 << 0,
    /**
     * Log message level Warning.
     */
    AylaLogMessageLevelWarning = 1 << 1,
    /**
     * Log message level Info.
     */
    AylaLogMessageLevelInfo = 1 << 2,
    /**
     * Log message level Debug.
     */
    AylaLogMessageLevelDebug = 1 << 3,
    /**
     * Log Message level Verbose.
     */
    AylaLogMessageLevelVerbose = 1 << 4
};

NS_ASSUME_NONNULL_BEGIN

@class AylaLogMessage;

/**
 * The `AylaLoggerProtocol` protocol is to be adopted by an object intended as a custom 
 * application-level logger in `AylaLogManager`.
 */
@protocol AylaLoggerProtocol<NSObject>

/**
 * This method will be called whenever a new log message arrives.
 * @param message The `AylaLogMessage` instance to be logged.
 */
- (void)logMessage:(AylaLogMessage *)message;

@end

/**
 * An `AylaLogMessage` object is a representation of a log message.
 */
@interface AylaLogMessage : NSObject

/** @name Log Message Properties */

/** Log message tag */
@property (nonatomic, readonly) NSString *tag;

/** Log message flag */
@property (nonatomic, readonly, assign) NSInteger flag;

/** Log message logging level */
@property (nonatomic, readonly, assign) AylaLogMessageLevel level;

/** Log message timestamp */
@property (nonatomic, readonly) NSDate *time;

/** Log message content */
@property (nonatomic, readonly) NSString *message;

/** @name Initializer Methods */

/**
 * Init method with Tag, Level, Flag, TimeStamp, Message format, Message args as inputs.
 *
 * @param tag Tag of log message, targeting a specific logger instance.
 * @param level Log Level at which to log the log message.
 * @param flag Flag for log message.
 * @param time Timestamp of the log message. If this param is set to be nil, the SDK will use `[NSDate data]` to create a
 * timestamp for this messsage.
 * @param fmt Format string for the message contents.
 * @param args Other arguments required for the log message (`va_list`)
 *
 * @return An initialized `AylaLogMessage` instance
 */
- (instancetype)initWithTag:(NSString *)tag
                      level:(AylaLogMessageLevel)level
                       flag:(NSInteger)flag
                       time:(NSDate *__nullable)time
                        fmt:(NSString *)fmt
                       args:(va_list)args;

/**
 * Init method with Tag, Level, Flag, TimeStamp, Message string as inputs.
 * @param tag Tag of log message, targeting a specific logger instance.
 * @param level Logging level of the log message.
 * @param flag Flag of log message.
 * @param time Timestamp of log message. If this param is set to be nil, the SDK will use `[NSDate data]` to create a
 * timestamp for this messsage.
 * @param message An NSString containing the log message contents.
 *
 * @return An initialized `AylaLogMessage` instance
 */
- (instancetype)initWithTag:(NSString *)tag
                      level:(AylaLogMessageLevel)level
                       flag:(NSInteger)flag
                       time:(NSDate *__nullable)time
                    message:(NSString *)message;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END