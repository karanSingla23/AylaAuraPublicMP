//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaScheduleAction.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaSchedule;

@interface AylaScheduleAction (Internal)

@property (nonatomic, strong, nullable) NSNumber *key;

@property (nonatomic, weak) AylaSchedule *_Nullable schedule;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary schedule:(AylaSchedule *)schedule error:(NSError *__autoreleasing _Nullable *)error;

- (BOOL)isValid:(NSError *_Nullable __autoreleasing *_Nullable)error;

- (BOOL)hasKey:(NSError *_Nullable __autoreleasing *_Nullable)error;

/**
 * Update this schedule action
 *
 * @param successBlock A block which will be called with the created AylaScheduleAction object when the request is successful.
 * @param failureBlock A block which will be called with an NSError object if the request fails.
 *
 * @return The service task that was spawned.
 */
- (nullable AylaHTTPTask *)updateWithSuccess:(void (^)(AylaScheduleAction *updatedScheduleAction))successBlock
                                     failure:(void (^)(NSError *error))failureBlock;

/**
 * Remove this schedule action
 *
 * @param successBlock A block which will be called when the request is successful.
 * @param failureBlock A block which will be called with an NSError object if the request fails.
 *
 * @return The service task that was spawned.
 */
- (nullable AylaHTTPTask *)deleteWithSuccess:(void (^)())successBlock
                                     failure:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END
