//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * `AylaChange` objects are provided to the application whenever the SDK has detected changes to
 * objects, and the application has requested to listen for changes. The base class defines the
 * various ChangeTypes, which represent the type of Change subclass that the object implements.
 *
 * Each type of `AylaChange` object contains information specific to what has changed.
 */
@interface AylaChange : NSObject

@end

NS_ASSUME_NONNULL_END