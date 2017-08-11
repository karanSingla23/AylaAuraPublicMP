//
//  AylaDatum+Internal.m
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatum+Internal.h"

#import "AylaDefines_Internal.h"
#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaHTTPTask.h"
#import "AylaObject+Internal.h"

@implementation AylaDatum (Internal)

+ (nullable AylaHTTPTask *)createDatumWithKey:(NSString *)key
                                        value:(NSString *)value
                                   httpClient:(AylaHTTPClient *)httpClient
                                         path:(NSString *)path
                                      success:(void (^)(AylaDatum *createdDatum))successBlock
                                      failure:(void (^)(NSError *error))failureBlock;
{
    AYLAssert(key, @"key cannot be nil!");
    AYLAssert(value, @"value cannot be nil!");
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");

    NSError *error;
    
    if (![self datumKeyIsValid:key error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }

    if (![self datumValueIsValid:value error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }

    return [httpClient postPath:path
                     parameters:[self serviceParametersForKey:key value:value]
                        success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                            AylaDatum *createdDatum = [[AylaDatum alloc] initWithJSONDictionary:responseObject error:nil];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                successBlock(createdDatum);
                            });
                        }
                        failure:^(AylaHTTPTask *task, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                failureBlock(error);
                            });
                        }];
}

+ (nullable AylaHTTPTask *)fetchDatumWithKey:(NSString *)key
                                  httpClient:(AylaHTTPClient *)httpClient
                                        path:(NSString *)path
                                     success:(void (^)(AylaDatum *datum))successBlock
                                     failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(key, @"key cannot be nil!");
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");
    
    return [httpClient getPath:path
                    parameters:nil
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           AylaDatum *datum = [[AylaDatum alloc] initWithJSONDictionary:responseObject error:nil];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock(datum);
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

+ (nullable AylaHTTPTask *)fetchDatumsWithKeys:(nullable NSArray AYLA_GENERIC(NSString *) *)keys
                                    httpClient:(AylaHTTPClient *)httpClient
                                          path:(NSString *)path
                                       success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *datums))successBlock
                                       failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");
    
    NSDictionary *params = nil;

    if (keys) {
        if ([keys count]) {
            params = @{ @"keys": keys };
        } else {
            AYLAssert(NO, @"must have at least one key");
        }
    }
    
    return [self fetchDatumWithParams:params
                           httpClient:httpClient
                                 path:path
                              success:^(NSArray AYLA_GENERIC(AylaDatum *) *datums) {
                                  successBlock(datums);
                              } failure:^(NSError *error) {
                                  failureBlock(error);
                              }];
}

+ (nullable AylaHTTPTask *)fetchDatumsMatching:(NSString *)wildcardedString
                                    httpClient:(AylaHTTPClient *)httpClient
                                          path:(NSString *)path
                                       success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *datums))successBlock
                                       failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert([wildcardedString length], @"wildcardedString cannot be nil or empty!");
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");
    
    NSDictionary *params = nil;

    if ([wildcardedString length]) {
        if ([wildcardedString rangeOfString:@"%"].location != NSNotFound) {
            params = @{ @"keys": wildcardedString };
        } else {
            AYLAssert(NO, @"wildcardedString must contain a wildcard ('%%') character!");
        }
    }
    
    return [self fetchDatumWithParams:params
                           httpClient:httpClient
                                 path:path
                              success:^(NSArray AYLA_GENERIC(AylaDatum *) *datums) {
                                  successBlock(datums);
                              } failure:^(NSError *error) {
                                  failureBlock(error);
                              }];
}

// Private API
+ (nullable AylaHTTPTask *)fetchDatumWithParams:(nullable NSDictionary *)params
                                     httpClient:(AylaHTTPClient *)httpClient
                                           path:(NSString *)path
                                        success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *datums))successBlock
                                        failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");

    return [httpClient getPath:path
                    parameters:params
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           NSMutableArray *datums = [NSMutableArray new];
                           
                           for (NSDictionary *aDatumInDict in responseObject) {
                               AylaDatum * aDatum = [[AylaDatum alloc] initWithJSONDictionary:aDatumInDict error:nil];
                               [datums addObject:aDatum];
                           }

                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock([NSArray arrayWithArray:datums]);
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

+ (nullable AylaHTTPTask *)updateKey:(NSString *)key
                             toValue:(NSString *)value
                          httpClient:(AylaHTTPClient *)httpClient
                                path:(NSString *)path
                             success:(void (^)(AylaDatum *updatedDatum))successBlock
                             failure:(void (^)(NSError *error))failureBlock
{
    AYLAssert(key, @"key cannot be nil!");
    AYLAssert(value, @"value cannot be nil!");
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");
    
    NSError *error;
    
    if (![self datumKeyIsValid:key error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    if (![self datumValueIsValid:value error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }

    return [httpClient putPath:path
                    parameters:[self serviceParametersForKey:nil value:value]
                       success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                           AylaDatum *datum = [[AylaDatum alloc] initWithJSONDictionary:responseObject error:nil];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               successBlock(datum);
                           });
                       }
                       failure:^(AylaHTTPTask *task, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               failureBlock(error);
                           });
                       }];
}

+ (nullable AylaHTTPTask *)deleteKey:(NSString *)key
                          httpClient:(AylaHTTPClient *)httpClient
                                path:(NSString *)path
                             success:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock;
{
    AYLAssert(key, @"key cannot be nil!");
    AYLAssert(httpClient, @"httpClient cannot be nil!");
    AYLAssert(path, @"path cannot be nil!");
    AYLAssert(successBlock, @"successBlock cannot be NULL!");
    AYLAssert(failureBlock, @"successBlock cannot be NULL!");
    
    NSError *error;
    
    if (![self datumKeyIsValid:key error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
        return nil;
    }
    
    return [httpClient deletePath:path
                       parameters:nil
                          success:^(AylaHTTPTask *task, id _Nullable responseObject) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  successBlock();
                              });
                          }
                          failure:^(AylaHTTPTask *task, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  failureBlock(error);
                              });
                          }];
}

#pragma mark -
#pragma mark Utilities

+ (BOOL)datumKeyIsValid:(NSString *)key error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    NSError *datumKeyError = nil;
    
    NSMutableDictionary *errorResponseInfo = [NSMutableDictionary new];
    
    if (!key || key == (id)[NSNull null] || [key isEqualToString:@""]) {
        errorResponseInfo[@"key"] = AylaErrorDescriptionCanNotBeBlank;
    }
    
    if ([errorResponseInfo count]) {
        datumKeyError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                   code:AylaRequestErrorCodeInvalidArguments
                                               userInfo:@{
                                                          AylaRequestErrorResponseJsonKey : errorResponseInfo
                                                          }
                                              shouldLog:YES
                                                 logTag:[self logTag]
                                       addOnDescription:@"invalidDatumKey"];
    }
    
    if (error) {
        *error = datumKeyError;
    }
    
    return (datumKeyError == nil);
}

+ (BOOL)datumValueIsValid:(NSString *)value error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    NSError *datumValueError = nil;
    
    NSMutableDictionary *errorResponseInfo = [NSMutableDictionary new];
    
    if (!value) {
        errorResponseInfo[@"value"] = AylaErrorDescriptionCanNotBeBlank;
    }
    
    if ([errorResponseInfo count]) {
        datumValueError = [AylaErrorUtils errorWithDomain:AylaRequestErrorDomain
                                                   code:AylaRequestErrorCodeInvalidArguments
                                               userInfo:@{
                                                          AylaRequestErrorResponseJsonKey : errorResponseInfo
                                                          }
                                              shouldLog:YES
                                                 logTag:[self logTag]
                                       addOnDescription:@"invalidDatumValue"];
    }
    
    if (error) {
        *error = datumValueError;
    }
    
    return (datumValueError == nil);
}

+ (NSDictionary *)serviceParametersForKey:(nullable NSString *)key value:(NSString *)value
{
    AYLAssert(value, @"value cannot be nil!");
    
    NSDictionary *datumDict = key ? @{
                                      @"key": key,
                                      @"value": AYLNullIfNil(value)
                                      }
                                  : @{
                                      @"value": AYLNullIfNil(value)
                                      };
    
    return @{ @"datum": datumDict };
}

+ (NSString *)logTag
{
    return @"AylaDatum+Internal";
}

@end
