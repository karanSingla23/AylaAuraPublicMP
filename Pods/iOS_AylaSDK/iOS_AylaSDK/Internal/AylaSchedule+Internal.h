//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaSchedule.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaDevice;

@interface AylaSchedule (Internal)

@property (nonatomic, strong, nullable) NSNumber *key;

@property (nonatomic, weak, nullable) AylaDevice *device;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary device:(AylaDevice *)device error:(NSError *__autoreleasing _Nullable *)error;

- (BOOL)isValid:(NSError *_Nullable __autoreleasing *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
