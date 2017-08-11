//
//  AylaDeviceConnection.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 5/17/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

@interface AylaDeviceConnection : AylaObject

@property (nonatomic, readonly, strong) NSString *eventTime;
@property (nonatomic, readonly, strong) NSString *userUUID;
@property (nonatomic, readonly, strong) NSString *status;
@end
