//
//  AylaLocalRegistrationCandidate.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 1/5/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaLocalRegistrationCandidate.h"

@implementation AylaLocalRegistrationCandidateTemplate

- (NSDictionary *)toJSONDictionary {
    return @{
             @"template_key": self.template_key,
             @"version": self.version
             };
}

@end

@implementation AylaLocalRegistrationCandidateSubdevice

- (NSDictionary *)toJSONDictionary {
    NSMutableArray *templatesJSON = [NSMutableArray array];
    for (AylaLocalRegistrationCandidateTemplate *template in self.templates) {
        [templatesJSON addObject:[template toJSONDictionary]];
    }
    
    return @{ @"subdevice_key": self.subdevice_key,
              @"templates": templatesJSON
              };
}

@end

@implementation AylaLocalRegistrationCandidate
@dynamic deviceType;
@dynamic model;
@dynamic oemModel;
- (NSString *)oem {
    return nil;
}
    
- (NSString *)deviceType {
    return @"Node";
}

- (instancetype)initWithHardwareAddress:(NSString *)hardwareAddress deviceType:(NSString *)deviceType model:(NSString *)model oemModel:(NSString *)oemModel swVersion:(NSString *)swVersion {
    if (self = [super init]) {
        _hardwareAddress = hardwareAddress;
        self.deviceType = deviceType;
        self.model = model;
        self.oemModel = oemModel;
        self.swVersion = swVersion;
    }
    return self;
}

- (NSDictionary *)toJSONDictionary {
    NSMutableArray *subdevicesJSON = [NSMutableArray array];
    
    for (AylaLocalRegistrationCandidateSubdevice *subdevice in self.subdevices) {
        [subdevicesJSON addObject:[subdevice toJSONDictionary]];
    }
    
    NSMutableDictionary *candidateJSON = [NSMutableDictionary dictionaryWithDictionary:@{
                                           @"unique_hardware_id": self.hardwareAddress,
                                           @"oem_model": self.oemModel,
                                           @"model": self.model,
                                           @"sw_version": self.swVersion,
                                           @"device_type": self.deviceType,
                                           @"subdevices": subdevicesJSON
                                           }];
    if ([self oem]) {
        candidateJSON[@"oem"] = [self oem];
    }
    return @{ @"device": candidateJSON };
}
@end
