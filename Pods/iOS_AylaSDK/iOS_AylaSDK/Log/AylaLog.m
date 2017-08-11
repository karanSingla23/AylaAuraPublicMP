//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaLog.h"

@interface AylaLogMessage ()

@property (nonatomic, readwrite) NSString *tag;
@property (nonatomic, readwrite, assign) NSInteger flag;
@property (nonatomic, readwrite, assign) AylaLogMessageLevel level;
@property (nonatomic, readwrite) NSDate *time;
@property (nonatomic, readwrite) NSString *message;
@property (nonatomic, readwrite, assign) BOOL oldFormat;

@end

@implementation AylaLogMessage

- (instancetype)initWithTag:(NSString *)tag
                      level:(AylaLogMessageLevel)level
                       flag:(NSInteger)flag
                        fmt:(NSString *)fmt
                       args:(va_list)args
{
    NSString *message;
    if (fmt) {
        message = [[NSString alloc] initWithFormat:fmt arguments:args];
    }
    return [self initWithTag:tag level:level flag:flag time:nil message:message];
}

- (instancetype)initWithTag:(NSString *)tag
                      level:(AylaLogMessageLevel)level
                       flag:(NSInteger)flag
                       time:(NSDate *__nullable)time
                        fmt:(NSString *)fmt
                       args:(va_list)args
{
    NSString *message;
    if (fmt) {
        message = [[NSString alloc] initWithFormat:fmt arguments:args];
    }
    return [self initWithTag:tag level:level flag:flag time:time message:message];
}

static NSString *const DefaultLogTag = @"AylaSDK";
- (instancetype)initWithTag:(NSString *)tag
                      level:(AylaLogMessageLevel)level
                       flag:(NSInteger)flag
                       time:(NSDate *)time
                    message:(NSString *)message
{
    self = [super init];
    if (!self) return nil;

    self.tag = tag;
    self.flag = flag;
    self.level = level;
    self.time = time ?: [NSDate date];
    self.message = message;

    return self;
}

@end
