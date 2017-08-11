//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaConnectivity.h"

@class AylaSystemSettings;

@interface AylaConnectivity (Internal)

/**
 * Init method with settings.
 *
 * @param settings The settings which will be used in this connectivity.
 */
- (instancetype)initWithSettings:(AylaSystemSettings *)settings;

@end
