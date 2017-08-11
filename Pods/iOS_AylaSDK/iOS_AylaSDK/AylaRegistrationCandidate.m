//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaRegistrationCandidate.h"

#import "AylaDevice.h"
#import "NSObject+Ayla.h"
@interface AylaRegistrationCandidate ()
@property (nonatomic, strong, nullable) NSString *deviceType;
@property (nonatomic, strong, nullable) NSString *model;
@property (nonatomic, strong, nullable) NSString *oemModel;
@end

@implementation AylaRegistrationCandidate
static NSString *const kAylaRegistrationConnectedAt = @"connected_at";
static NSString *const kAylaRegistrationDeviceType = @"device_type";
static NSString *const kAylaRegistrationDsn = @"dsn";
static NSString *const kAylaRegistrationLanIp = @"lan_ip";
static NSString *const kAylaRegistrationLatitude = @"lat";
static NSString *const kAylaRegistrationLongitude = @"lng";
static NSString *const kAylaRegistrationModel = @"model";
static NSString *const kAylaRegistrationOemModel = @"oem_model";
static NSString *const kAylaRegistrationProductClass = @"product_class";
static NSString *const kAylaRegistrationProductName = @"product_name";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        NSDictionary *device = [dictionary objectForKey:@"device"];
        _connectedAt = [device[kAylaRegistrationConnectedAt] nilIfNull];
        _deviceType = [device[kAylaRegistrationDeviceType] nilIfNull];
        _dsn = [device[kAylaRegistrationDsn] nilIfNull];
        _lanIp = [device[kAylaRegistrationLanIp] nilIfNull];
        _lat = [device[kAylaRegistrationLatitude] nilIfNull];
        _lng = [device[kAylaRegistrationLongitude] nilIfNull];
        _model = [device[kAylaRegistrationModel] nilIfNull];
        _oemModel = [device[kAylaRegistrationOemModel] nilIfNull];
        _productClass = [device[kAylaRegistrationProductClass] nilIfNull];
        _productName = [device[kAylaRegistrationProductName] nilIfNull];
    }
    return self;
}

- (NSString *)description
{
    return [NSString
        stringWithFormat:@"Candidate DSN: %@\nProduct Name: %@\nLAN IP:%@", self.dsn, self.productName, self.lanIp];
}

@end
