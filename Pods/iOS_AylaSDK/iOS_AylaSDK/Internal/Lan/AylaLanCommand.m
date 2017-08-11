//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLanCommand.h"
#import "AylaProperty+Internal.h"

@interface AylaLanCommand ()

@property (nonatomic, readwrite) BOOL cancelled;

@end

@implementation AylaLanCommand

static long __nextLanCommandId = 1;

- (instancetype)initWithType:(AylaLanCommandType)type commandInJson:(id)jsonObject
{
    self = [super init];
    if (!self) return nil;

    _type = type;
    _commandInJson = jsonObject;
    _cmdId = __nextLanCommandId++;

    return self;
}

+ (instancetype)GETDeviceDetailsCommand
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    command.commandInJson = @{
                              @"cmd" : @{
                                      @"cmd_id" : @(command.cmdId),
                                      @"method" : @"GET",
                                      @"resource" : [NSString stringWithFormat:@"status.json"],
                                      @"data" : [NSNull null],
                                      @"uri" : @"/local_lan/status.json"
                                      }
                              };
    command.needsWaitResponse = YES;
    command.identifier = [NSUUID UUID].UUIDString;
    return command;
}

+ (instancetype)PUTNewDeviceTimeCommand:(NSNumber *)time
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    
    
    command.commandInJson =  @{
                               @"cmd" : @{
                                       @"cmd_id" : @(command.cmdId),
                                       @"method" : @"PUT",
                                       @"resource" : [NSString stringWithFormat:@"time.json?time=%@", time],
                                       @"data" : [NSNull null],
                                       @"uri" : @"/local_lan/time.json"
                                       }
                               };
    command.needsWaitResponse = YES;
    command.identifier = [NSUUID UUID].UUIDString;
    return command;
}

+ (instancetype)POSTStartScanCommand
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    command.commandInJson = @{
                              @"cmd" : @{
                                      @"cmd_id" : @(command.cmdId),
                                      @"method" : @"POST",
                                      @"resource" : [NSString stringWithFormat:@"wifi_scan.json"],
                                      @"data" : [NSNull null],
                                      @"uri" : @"/local_lan/wifi_scan.json"
                                      }
                              };
    command.needsWaitResponse = YES;
    command.identifier = [NSUUID UUID].UUIDString;
    return command;
}

+ (instancetype)GETWiFiScanResults
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    command.commandInJson = @{
                              @"cmd" : @{
                                      @"cmd_id" : @(command.cmdId),
                                      @"method" : @"GET",
                                      @"resource" : [NSString stringWithFormat:@"wifi_scan_results.json"],
                                      @"data" : [NSNull null],
                                      @"uri" : @"/local_lan/wifi_scan_results.json"
                                      }
                              };
    command.needsWaitResponse = YES;
    command.identifier = [NSUUID UUID].UUIDString;
    return command;
}

+ (instancetype)PUTStopAPCommand
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    
    
    command.commandInJson =  @{
                               @"cmd" : @{
                                       @"cmd_id" : @(command.cmdId),
                                       @"method" : @"PUT",
                                       @"resource" : [NSString stringWithFormat:@"wifi_stop_ap.json"],
                                       @"data" : [NSNull null],
                                       @"uri" : @"/local_lan/wifi_stop_ap.json"
                                       }
                               };
    command.needsWaitResponse = YES;
    command.identifier = [NSUUID UUID].UUIDString;
    return command;
}

+ (instancetype)GETWiFiStatusCommand
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    command.commandInJson = @{
                              @"cmd" : @{
                                      @"cmd_id" : @(command.cmdId),
                                      @"method" : @"GET",
                                      @"resource" : [NSString stringWithFormat:@"wifi_status.json"],
                                      @"data" : [NSNull null],
                                      @"uri" : @"/local_lan/wifi_status.json"
                                      }
                              };
    command.needsWaitResponse = YES;
    command.identifier = [NSUUID UUID].UUIDString;
    return command;
}

+ (instancetype)GETPropertyCommandWithPropertyName:(NSString *)propertyName data:(id)data
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    command.commandInJson = @{
        @"cmd" : @{
            @"cmd_id" : @(command.cmdId),
            @"method" : @"GET",
            @"resource" : [NSString stringWithFormat:@"property.json?name=%@", propertyName],
            @"data" : data ?: [NSNull null],
            @"uri" : @"/local_lan/property/datapoint.json"
        }
    };
    command.needsWaitResponse = YES;
    command.identifier = propertyName;
    return command;
}

+ (instancetype)GETNodePropertyCommandWithNodeDsn:(NSString *)dsn propertyName:(NSString *)propertyName data:(id)data
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    command.commandInJson = @{
        @"cmd" : @{
            @"cmd_id" : @(command.cmdId),
            @"method" : @"GET",
            @"resource" : [NSString stringWithFormat:@"node_property.json?name=%@", propertyName],
            @"data" : [NSString stringWithFormat:@"{\"dsn\":\"%@\"}", dsn],
            @"uri" : @"/local_lan/node/property/datapoint.json"
        }
    };
    command.needsWaitResponse = YES;
    command.identifier = [NSString stringWithFormat:@"%@/%@", dsn, propertyName];
    return command;
}

+ (instancetype)POSTDatapointCommandWithProperty:(AylaProperty *)property datapointParams:(AylaDatapointParams *)params
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeProperty commandInJson:nil];

    NSMutableDictionary *propertyParams = [@{
        @"name" : property.name,
        @"value" : params.value ?: [NSNull null],
        @"base_type" : property.baseType,
        @"metadata" : params.metadata ?: [NSNull null]
    } mutableCopy];
    if (property.ackEnabled) {
        propertyParams[@"id"] = [NSString stringWithFormat:@"%ld", command.cmdId];
    }

    command.commandInJson = @{ @"property" : propertyParams };
    command.needsWaitResponse = property.ackEnabled;
    command.identifier = property.name;
    return command;
}

+ (instancetype)POSTNodeDatapointCommandWithNodeDsn:(NSString *)dsn
                                       nodeProperty:(AylaProperty *)property
                                    datapointParams:(AylaDatapointParams *)params
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeNodeProperty commandInJson:nil];

    NSMutableDictionary *propertyParams = [@{
        @"name" : property.name,
        @"dsn" : dsn,
        @"value" : params.value ?: [NSNull null],
        @"base_type" : property.baseType,
        @"metadata" : params.metadata ?: [NSNull null]
    } mutableCopy];
    if (property.ackEnabled) {
        propertyParams[@"id"] = [NSString stringWithFormat:@"%ld", command.cmdId];
    }

    command.commandInJson = @{ @"property" : propertyParams };
    command.needsWaitResponse = property.ackEnabled;
    command.identifier = property.name;
    return command;
}

+ (instancetype)ConnectCommandWithSSID:(NSString *)SSID
                              password:(NSString *)password
                            setupToken:(NSString *)setupToken
                              latitude:(double)latitude
                            longitude:(double)longitude
{
    AylaLanCommand *command = [[[self class] alloc] initWithType:AylaLanCommandTypeCommand commandInJson:nil];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:@"wifi_connect.json"];
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[NSURLQueryItem queryItemWithName:@"ssid" value:SSID]];
    if (password) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"key" value:password]];
    }
    if (setupToken) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"setup_token" value:setupToken]];
    }
    if (latitude != 0. && longitude != 0.) {
        [items
            addObject:[NSURLQueryItem queryItemWithName:@"location"
                                                  value:[NSString stringWithFormat:@"%f, %f", latitude, longitude]]];
    }

    urlComponents.queryItems = items;
    NSString *path = urlComponents.string;

    command.commandInJson = @{
        @"cmd" : @{
            @"cmd_id" : @(command.cmdId),
            @"method" : @"POST",
            @"resource" : path,
            @"data" : [NSNull null],
            @"uri" : @"/local_lan/connect_status.json"
        }
    };
    command.needsWaitResponse = YES;
    command.identifier = SSID;
    return command;
}

- (BOOL)isCancelled
{
    return _cancelled;
}

- (void)cancel
{
    self.cancelled = YES;
}

- (NSDictionary *)encapulatedCommandInJson
{
    NSDictionary *jsonDictionary = @{};
    switch (self.type) {
        case AylaLanCommandTypeCommand:
            jsonDictionary = @{ @"cmds" : @[ self.commandInJson ] };
            break;
        case AylaLanCommandTypeProperty:
            jsonDictionary = @{ @"properties" : @[ self.commandInJson ] };
            break;
        case AylaLanCommandTypeNodeProperty:
            jsonDictionary = @{ @"node_properties" : @[ self.commandInJson ] };
            break;
        default:
            jsonDictionary = self.commandInJson;
            break;
    }
    return jsonDictionary;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"LanCmd: [%@]", self.identifier];
}

@end
