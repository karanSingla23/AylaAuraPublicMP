//
//  AylaBaseAuthProvider.h
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaAuthProvider.h"

NS_ASSUME_NONNULL_BEGIN

/** Base class for all providers working with an Ayla Cloud Account (Not SSO) */
@interface AylaBaseAuthProvider : NSObject <AylaAuthProvider>

@end

NS_ASSUME_NONNULL_END
