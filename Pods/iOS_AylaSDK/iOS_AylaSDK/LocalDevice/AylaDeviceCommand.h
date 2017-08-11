//
//  AylaDeviceCommand.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

extern NSString * const CMD_OTA;

/**
 <#Description#>
 */
@interface AylaDeviceCommand : AylaObject
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic) NSInteger deviceId;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *resource;
@property (nonatomic) BOOL ack;
@property (nonatomic, strong) NSString *ackedAt;
@property (nonatomic, strong) NSString *createdAt;
@property (nonatomic, strong) NSString *updatedAt;

- (id)getCommand;
@end
