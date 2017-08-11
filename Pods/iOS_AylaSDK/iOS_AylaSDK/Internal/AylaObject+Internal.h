//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface AylaObject (Internal) <NSCopying>

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error;

- (NSDictionary *)toJSONDictionary;

@end

NS_ASSUME_NONNULL_END
