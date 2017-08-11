//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDSSubscription.h"
#import "AylaDefines_Internal.h"
#import "AylaHTTPClient.h"
#import "AylaObject+Internal.h"
#import "AylaSystemUtils.h"

static NSString *const AylaDSSubscriptionAttrNameClientType = @"client_type";
static NSString *const AylaDSSubscriptionAttrNameCreatedAt = @"created_at";
static NSString *const AylaDSSubscriptionAttrNameDateSuspended = @"date_suspended";
static NSString *const AylaDSSubscriptionAttrNameIsSuspended = @"is_suspended";
static NSString *const AylaDSSubscriptionAttrNameOemModel = @"oem_model";
static NSString *const AylaDSSubscriptionAttrNamePropertyName = @"property_name";
static NSString *const AylaDSSubscriptionAttrNameStreamKey = @"stream_key";
static NSString *const AylaDSSubscriptionAttrNameSubscriptionType = @"subscription_type";
static NSString *const AylaDSSubscriptionAttrNameUpdatedAt = @"updated_at";

static NSString *const AylaDSSubscriptionTypeNameConnectivity = @"connectivity";
static NSString *const AylaDSSubscriptionTypeNameDatapoint = @"datapoint";
static NSString *const AylaDSSubscriptionTypeNameDatapointAck = @"datapointack";
static NSString *const AylaDSSubscriptionTypeNameRegistration = @"registration";

static NSString *const AylaDSSubscriptionClientTypeMobile = @"mobile";
static NSString *const AylaDSSubscriptionAttrWildcard = @"*";

@implementation AylaDSSubscription

- (instancetype)initWithName:(NSString *)name
                         dsn:(NSString *)dsn
           subscriptionTypes:(AylaDSSubscriptionType)subscriptionTypes
{
    NSDictionary *jsonDictionary = @{
        NSStringFromSelector(@selector(name)) : AYLNullIfNil(name),
        NSStringFromSelector(@selector(dsn)) : AYLNullIfNil(dsn),
        AylaDSSubscriptionAttrNameOemModel : AylaDSSubscriptionAttrWildcard,
        AylaDSSubscriptionAttrNameClientType : AylaDSSubscriptionClientTypeMobile,
        AylaDSSubscriptionAttrNameSubscriptionType : [self stringFromSubsriptionTypes:subscriptionTypes]
    };

    return [self initWithJSONDictionary:jsonDictionary error:nil];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return self;

    _clientType = AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameClientType]);
    _dsDescription = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(description))]);
    _dsn = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(dsn))]);
    _id = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(id))]);
    _isSuspended = [AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameIsSuspended]) boolValue];
    _name = AYLNilIfNull(dictionary[NSStringFromSelector(@selector(name))]);
    _oem = AYLNullIfNil(dictionary[NSStringFromSelector(@selector(oem))]);
    _oemModel = AYLNullIfNil(dictionary[AylaDSSubscriptionAttrNameOemModel]);
    _propertyName = AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNamePropertyName]);
    _streamKey = AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameStreamKey]);
    _subscriptionTypes =
        [self subscriptionTypesFromString:AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameSubscriptionType])];

    NSDateFormatter *dateFormatter = [AylaSystemUtils defaultDateFormatter];
    _dateSuspended = [dateFormatter dateFromString:AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameDateSuspended])];
    _createdAt = [dateFormatter dateFromString:AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameCreatedAt])];
    _updatedAt = [dateFormatter dateFromString:AYLNilIfNull(dictionary[AylaDSSubscriptionAttrNameUpdatedAt])];

    return self;
}

+ (AylaHTTPTask *)createSubscription:(AylaDSSubscription *)subscription
                     usingHttpClient:(AylaHTTPClient *)httpClient
                             success:(void (^)(AylaDSSubscription *createdSubscription))successBlock
                             failure:(void (^)(NSError *_Nonnull))failureBlock
{
    AYLAssert(httpClient, @"http client must not be null.");
    NSDictionary *params = [subscription toJSONDictionaryIncludingStreamKey:NO] ?: @{};
    return [httpClient postPath:@"api/v1/subscriptions.json"
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaDSSubscription *subscription =
                [[AylaDSSubscription alloc] initWithJSONDictionary:responseObject[@"subscription"] error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(subscription);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

+ (AylaHTTPTask *)updateSubscription:(AylaDSSubscription *)subscription
                     usingHttpClient:(AylaHTTPClient *)httpClient
                             success:(void (^)(AylaDSSubscription *updatedSubscription))successBlock
                             failure:(void (^)(NSError *_Nonnull error))failureBlock
{
    AYLAssert(httpClient, @"http client must not be null.");
    NSDictionary *params = [subscription toJSONDictionaryIncludingStreamKey:YES] ?: @{};
    return [httpClient putPath:@"api/v1/subscriptions.json"
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            AylaDSSubscription *subscription =
                [[AylaDSSubscription alloc] initWithJSONDictionary:responseObject[@"subscription"] error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(subscription);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (NSDictionary *)toJSONDictionaryIncludingStreamKey:(BOOL)includingStreamKey
{
    NSDictionary *dictionary = @{
        NSStringFromSelector(@selector(id)) : AYLNullIfNil(self.id),
        NSStringFromSelector(@selector(name)) : AYLNullIfNil(self.name),
        NSStringFromSelector(@selector(description)) : AYLNullIfNil(self.dsDescription),
        NSStringFromSelector(@selector(dsn)) : AYLNullIfNil(self.dsn),
        NSStringFromSelector(@selector(oem)) : AYLNullIfNil(self.oem),
        AylaDSSubscriptionAttrNameOemModel : AYLNullIfNil(self.oemModel),
        AylaDSSubscriptionAttrNameClientType : self.clientType,
        AylaDSSubscriptionAttrNamePropertyName : AYLNullIfNil(self.propertyName),
        AylaDSSubscriptionAttrNameSubscriptionType : [self stringFromSubsriptionTypes:self.subscriptionTypes],
    };

    if (includingStreamKey) {
        NSMutableDictionary *copy = [dictionary mutableCopy];
        copy[AylaDSSubscriptionAttrNameStreamKey] = AYLNullIfNil(self.streamKey);
        dictionary = copy;
    }

    return dictionary;
}

- (NSDictionary *)toJSONDictionary
{
    return [self toJSONDictionaryIncludingStreamKey:YES];
}

- (NSString *)stringFromSubsriptionTypes:(AylaDSSubscriptionType)types
{
    NSMutableArray *array = [NSMutableArray new];
    if (AylaDSSubscriptionTypeConnectivity == (types & AylaDSSubscriptionTypeConnectivity)) {
        [array addObject:AylaDSSubscriptionTypeNameConnectivity];
    }
    if (AylaDSSubscriptionTypeDatapoint == (types & AylaDSSubscriptionTypeDatapoint)) {
        [array addObject:AylaDSSubscriptionTypeNameDatapoint];
    }
    if (AylaDSSubscriptionTypeDatapointAck == (types & AylaDSSubscriptionTypeDatapointAck)) {
        [array addObject:AylaDSSubscriptionTypeNameDatapointAck];
    }

    return [array componentsJoinedByString:AylaDSSubscriptionDefaultDelimiter];
}

- (AylaDSSubscriptionType)subscriptionTypesFromString:(NSString *)string
{
    NSArray *typesInString = [string componentsSeparatedByString:AylaDSSubscriptionDefaultDelimiter];
    AylaDSSubscriptionType types = 0;

    if ([typesInString containsObject:AylaDSSubscriptionTypeNameConnectivity]) {
        types |= AylaDSSubscriptionTypeConnectivity;
    }
    if ([typesInString containsObject:AylaDSSubscriptionTypeNameDatapoint]) {
        types |= AylaDSSubscriptionTypeDatapoint;
    }
    if ([typesInString containsObject:AylaDSSubscriptionTypeNameDatapointAck]) {
        types |= AylaDSSubscriptionTypeDatapointAck;
    }
    return types;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[AylaDSSubscription alloc] initWithJSONDictionary:[self toJSONDictionary] error:nil];
}

@end

NSString * const AylaDSSubscriptionDefaultDelimiter = @",";
