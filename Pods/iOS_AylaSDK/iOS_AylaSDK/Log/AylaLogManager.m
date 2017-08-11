//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaLogManager.h"
#import "AylaLogger.h"
#import "NSObject+Ayla.h"

@interface AylaLogManager () {
    int _curOutputs;
    dispatch_queue_t _queue;
}

@property (nonatomic, readwrite) NSMutableDictionary *mutableLoggers;
@property (nonatomic, readwrite) NSMutableDictionary *mutableSysLoggers;

@end

@implementation AylaLogManager

static NSString *const DefaultFileLoggerKey = @"com.aylanetworks.fileLogger";
static NSString *const DefaultConsoleLoggerKey = @"com.aylanetworks.consoleLogger";
static NSString *const DefaultCloudLoggerKey = @"com.aylanetworks.cloudLogger";

+ (instancetype)sharedManager
{
    static AylaLogManager *logManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logManager = [[AylaLogManager alloc] init];
    });

    return logManager;
}

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    const char *queue_label = "com.aylanetworks.logManagerQueue";
    _queue = dispatch_queue_create(queue_label, DISPATCH_QUEUE_SERIAL);

    // Set default loggingLevel and loggingOutputs.
    _loggingLevel = AylaSystemLoggingError;
    _loggingOutputs = AylaSystemLoggingOutputConsole | AylaSystemLoggingOutputLogFile;

    // Init two logger lists: One for system loggers, one for application loggers.
    _mutableLoggers = [NSMutableDictionary dictionary];
    _mutableSysLoggers = [NSMutableDictionary dictionary];

    return self;
}

/**
 * This method will be triggered through -log:level:flag:time:fmt... method. If loggingOutputs
 * is different to current in-use one, this method will update loggers based on new value of
 * loggingOuputs.
 *
 * @attention This method is not thread safe. It must be called through log manager serial queue.
 */
- (void)updateSysLoggers
{
    if (_curOutputs == self.loggingOutputs) return;
    AylaSystemLoggingOutput outputs = self.loggingOutputs;
    void (^handleBlock)(AylaSystemLoggingOutput option, NSString *key, Class LoggerClass) =
        ^(AylaSystemLoggingOutput loggerOption, NSString *key, Class LoggerClass) {
            if ((outputs & loggerOption) > 0) {
                if (![_mutableSysLoggers objectForKey:key]) {
                    AylaLogger *logger = [[LoggerClass alloc] initWithFilterBlock:nil formatter:nil];
                    [_mutableSysLoggers setObject:logger forKey:key];
                }
            }
            else {
                [_mutableSysLoggers removeObjectForKey:key];
            }
        };
    handleBlock(AylaSystemLoggingOutputConsole, DefaultConsoleLoggerKey, [AylaConsoleLogger class]);
    handleBlock(AylaSystemLoggingOutputLogFile, DefaultFileLoggerKey, [AylaFileLogger class]);
    _curOutputs = outputs;
}

/**
 * Add a new logger into current log manager
 */
- (void)addLogger:(id<AylaLoggerProtocol>)logger withKey:(NSString *)key
{
    if (![key nilIfNull] || !logger) return;
    dispatch_async(_queue, ^{
        [_mutableLoggers setObject:logger forKey:key];
    });
}

/**
 * Remove a logger from current log manager
 */
- (void)removeLoggerWithKey:(NSString *)key
{
    if (![key nilIfNull]) return;
    dispatch_async(_queue, ^{
        [_mutableLoggers removeObjectForKey:key];
    });
}

- (NSArray *)loggers
{
    return _mutableLoggers.allValues;
}

- (void)log:(NSString *)tag
      level:(AylaLogMessageLevel)level
       flag:(NSInteger)flag
       time:(NSDate *)time
        fmt:(NSString *)fmt, ...
{
    // Skip messages based on logging level
    if ((level & [self loggingLevel]) <= 0) return;

    va_list args;
    va_start(args, fmt);
    AylaLogMessage *message =
        [[AylaLogMessage alloc] initWithTag:tag level:level flag:flag time:time fmt:fmt args:args];
    va_end(args);

    dispatch_async(_queue, ^{
        @autoreleasepool {
            // Update system logger
            [self updateSysLoggers];
            for (id<AylaLoggerProtocol> logger in _mutableSysLoggers.allValues) {
                [logger logMessage:message];
            }
            if ((_curOutputs & AylaSystemLoggingOutputAppLoggers) > 0) {
                for (id<AylaLoggerProtocol> logger in _mutableLoggers.allValues) {
                    [logger logMessage:message];
                }
            }
        }
    });
}

- (void)log:(NSString *)tag level:(AylaLogMessageLevel)level flag:(NSInteger)flag time:(NSDate *)time message:(NSString *)message {
    [self log:tag level:level flag:flag time:time fmt:@"%@", message];
}

- (nullable NSString *)getLogFilePath
{
    NSString *logFilePath = [AylaFileLogger getLogFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:logFilePath]) {
        // If file can't be found from the given file path, return nil.
        return nil;
    }
    
    return logFilePath;
}

@end
