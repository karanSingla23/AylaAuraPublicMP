//
//  AylaLocalOTACommand.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 4/27/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaObject.h"

@interface AylaLocalOTACommand : AylaObject
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *ver;
@property (nonatomic) NSInteger size;
@property (nonatomic, strong) NSString *checksum;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *apiUrl;
@property (nonatomic) NSInteger commandId;
@end
