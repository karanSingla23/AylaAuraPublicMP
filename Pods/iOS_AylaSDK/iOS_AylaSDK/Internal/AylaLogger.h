//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLog.h"

@class AylaLogMessage;
@class AylaLogFormatter;

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^AylaLoggerFilterBlock)(AylaLogMessage *message);

@interface AylaLogger : NSObject

/** Logger's filter block */
@property (nonatomic, readonly, copy) AylaLoggerFilterBlock filterBlock;

/**
 * Create a new logger with pass-in filter block and formatter.
 *
 * @param filterBlock A filterBlock which will be used to determine if a log message should be processed by this logger.
 * Can be nil.
 * @param formatter A formatter which will be used to format a log to a string. If it's nil, library will assign the
 * default formatter to this logger.
 *
 * @return The created logger.
 */
+ (instancetype)loggerWithFilterBlock:(AylaLoggerFilterBlock __nullable)filterBlock
                            formatter:(AylaLogFormatter *__nullable)formatter;

/**
 * Get a new logger.
 *
 * @return The created logger.
 */
+ (instancetype)logger;

/**
 * init logger with pass-in filter block and formatter.
 *
 * @param filterBlock A filterBlock which will be used to determine if a log message should be processed by this logger.
 * Can be nil.
 * @param formatter A formatter which will be used to format a log to a string. If nil, library will assign the default
 * formatter to this logger.
 *
 * @return The initialized logger.
 */
- (instancetype)initWithFilterBlock:(AylaLoggerFilterBlock __nullable)filterBlock
                          formatter:(AylaLogFormatter *__nullable)formatter;

@end

/**
 * Library's File Logger
 */
@interface AylaFileLogger : AylaLogger<AylaLoggerProtocol>

- (void)logMessage:(AylaLogMessage *)message;

/**
 * Get log file path
 */
+ (NSString *)getLogFilePath;


/**
 * @return Returns the log header.
 */
+ (NSString *)logHeader;
@end

/**
 * Library's console Logger
 */
@interface AylaConsoleLogger : AylaLogger<AylaLoggerProtocol>

- (void)logMessage:(AylaLogMessage *)message;

@end

/**
 * Library's log formatter
 */
@interface AylaLogFormatter : NSObject

/** time formatter */
@property (nonatomic, readonly) NSDateFormatter *timeFormatter;

/**
 * Default log formatter
 */
+ (instancetype)defaultLogFormatter;

/**
 * Use this method to format a log message
 *
 * @param message The log message to be formatted.
 *
 * @return Formated text string of log message.
 */
- (NSString *)formattedLogMessage:(AylaLogMessage *)message;

/**
 * A helpful method to get logging level letter (in NSString) from logging level.
 *
 * @return Return one of @"E", @"I", @"D", @"W", @"V", @"U". Note @"U" will be returned if input logging level is
 * invalid.
 */
+ (NSString *)stringFromLoggingLevel:(AylaLogMessageLevel)level;

@end

NS_ASSUME_NONNULL_END
