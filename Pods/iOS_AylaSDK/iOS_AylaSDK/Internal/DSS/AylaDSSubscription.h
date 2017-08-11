//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDefines.h"
#import "AylaObject.h"

NS_ASSUME_NONNULL_BEGIN

/** Default delimiter when passing in multiple dsns as value of property `dsn` */
FOUNDATION_EXPORT NSString * const AylaDSSubscriptionDefaultDelimiter;

@class AylaHTTPClient;
@class AylaHTTPTask;

@interface AylaDSSubscription : AylaObject<NSCopying>

@property (nonatomic, strong, readonly, nullable) NSNumber *id;

@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSString *dsDescription;

@property (nonatomic, strong) NSString *dsn;
@property (nonatomic, strong, nullable) NSString *oem;
@property (nonatomic, strong, nullable) NSString *oemModel;

@property (nonatomic, strong, nullable) NSString *propertyName;
@property (nonatomic, assign) AylaDSSubscriptionType subscriptionTypes;

@property (nonatomic, assign) BOOL isSuspended;

@property (nonatomic, strong, readonly, nullable) NSString *streamKey;
@property (nonatomic, strong, readonly) NSString *clientType;

@property (nonatomic, strong, readonly, nullable) NSDate *dateSuspended;
@property (nonatomic, strong, readonly, nullable) NSDate *createdAt;
@property (nonatomic, strong, readonly, nullable) NSDate *updatedAt;

/**
 * Init method
 *
 * @param name              Name of subscription.
 * @param dsn               Dsn(s) in accepted format.
 * @param subscriptionTypes Enabled subscription types of this new subscription.
 */
- (instancetype)initWithName:(nullable NSString *)name
                         dsn:(NSString *)dsn
           subscriptionTypes:(AylaDSSubscriptionType)subscriptionTypes;

/**
 * Use this method to create a subscription with a passed in http client.
 *
 * @param subscription The subscription which is going to be created.
 * @param httpClient   Http client which is to be used to send request.
 * @param successBlock A block called when the subscription was successfully created.
 * @param failureBlock A block called when the subscription was failed.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
+ (AylaHTTPTask *)createSubscription:(AylaDSSubscription *)subscription
                     usingHttpClient:(AylaHTTPClient *)httpClient
                             success:(void (^)(AylaDSSubscription *createdSubscription))successBlock
                             failure:(void (^)(NSError *_Nonnull))failureBlock;


/**
 * Use this method to update a subscription with a passed in http client.
 *
 * @param subscription The subscription which is going to be updated.
 * @param httpClient   Http client which is to be used to send request.
 * @param successBlock A block called when the subscription was successfully updated.
 * @param failureBlock A block called when the subscription was failed.
 *
 * @return A started `AylaHTTPTask` representing the request.
 */
+ (AylaHTTPTask *)updateSubscription:(AylaDSSubscription *)subscription
                     usingHttpClient:(AylaHTTPClient *)httpClient
                             success:(void (^)(AylaDSSubscription *updatedSubscription))successBlock
                             failure:(void (^)(NSError *_Nonnull))failureBlock;

@end

NS_ASSUME_NONNULL_END
