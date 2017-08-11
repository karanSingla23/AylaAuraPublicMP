//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatapoint.h"
#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN
@class AylaProperty;
@interface AylaDatapoint (Internal)

/**
 * Init method
 *
 * @param dictionary JSON dicitonary which contains datapoint info.
 * @param dataSource Data source of this datapoint
 * @param error      Error description.
 *
 * @return Initialized datapoint instance.
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
                            dataSource:(AylaDataSource)dataSource
                                 error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/**
 *  A weak reference to the parent property to use the HTTP Client
 */
@property (nonatomic, weak) AylaProperty *property ;
@end

NS_ASSUME_NONNULL_END