//
//  AylaDatum+Internal.h
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDatum.h"

#import "AylaDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class AylaHTTPTask;
@class AylaHTTPClient;

@interface AylaDatum (Internal)

/**
 *  Creates a new datum
 *
 *  @param key          The key used to uniquely identify the datum.
 *  @param value        The initial value for the datum.
 *  @param httpClient   httpClient with which to issue the request.
 *  @param path         Service path to use for the request.
 *  @param successBlock A block which will be called with the created datum when the request is successful.
 *  @param failureBlock A block which will be called with an NSError object if the request fails
 *
 *  @return The service task that was spawned.
 */
+ (nullable AylaHTTPTask *)createDatumWithKey:(NSString *)key
                                        value:(NSString *)value
                                   httpClient:(AylaHTTPClient *)httpClient
                                         path:(NSString *)path
                                      success:(void (^)(AylaDatum *createdDatum))successBlock
                                      failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves an existing datum object based on the input key.
 *
 *  @param key          The key of the datum object to retrieve.
 *  @param httpClient   httpClient with which to issue the request.
 *  @param path         Service path to use for the request.
 *  @param successBlock A block which will be called with the retrieved datum when the request is successful.
 *  @param failureBlock A block which will be called with an NSError object if the request fails.
 *
 *  @return The service task that was spawned.
 */
+ (nullable AylaHTTPTask *)fetchDatumWithKey:(NSString *)key
                                  httpClient:(AylaHTTPClient *)httpClient
                                        path:(NSString *)path
                                     success:(void (^)(AylaDatum *datum))successBlock
                                     failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves existing datum objects based on the input keys.
 *
 *  @param keys         An array of the keys of the datum objects to retrieve. If nil, retrieves all datum objects.
 *  @param httpClient   httpClient with which to issue the request.
 *  @param path         Service path to use for the request.
 *  @param successBlock A block which will be called with the retrieved datum objects when the request is successful.
 *  @param failureBlock A block which will be called with an NSError object if the request fails.
 *
 *  @return The service task that was spawned.
 */
+ (nullable AylaHTTPTask *)fetchDatumsWithKeys:(nullable NSArray AYLA_GENERIC(NSString *) *)keys
                                    httpClient:(AylaHTTPClient *)httpClient
                                          path:(NSString *)path
                                       success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *datums))successBlock
                                       failure:(void (^)(NSError *error))failureBlock;

/**
 *  Retrieves existing datum objects based on a wildcard match.
 *
 *  @param wildcardedString A string where the "%" character defines wild cards before or after the text to match in the datum key
 *  @param httpClient       httpClient with which to issue the request.
 *  @param path             Service path to use for the request.
 *  @param successBlock     A block which will be called with the retrieved datum objects when the request is successful.
 *  @param failureBlock     A block which will be called with an NSError object if the request fails.
 *
 *  @return The service task that was spawned.
 */
+ (nullable AylaHTTPTask *)fetchDatumsMatching:(NSString *)wildcardedString
                                    httpClient:(AylaHTTPClient *)httpClient
                                          path:(NSString *)path
                                       success:(void (^)(NSArray AYLA_GENERIC(AylaDatum *) *datums))successBlock
                                       failure:(void (^)(NSError *error))failureBlock;

/**
 *  Updates an existing datum object.
 *
 *  @param key          The key of the datum to be updated.
 *  @param toValue      The new value to assign to the datum.
 *  @param httpClient   httpClient with which to issue the request.
 *  @param path         Service path to use for the request.
 *  @param successBlock A block which will be called with the retrieved datum when the request is successful.
 *  @param failureBlock A block which will be called with an NSError object if the request fails.
 *
 *  @return The service task that was spawned.
 */
+ (nullable AylaHTTPTask *)updateKey:(NSString *)key
                             toValue:(NSString *)value
                          httpClient:(AylaHTTPClient *)httpClient
                                path:(NSString *)path
                             success:(void (^)(AylaDatum *updatedDatum))successBlock
                             failure:(void (^)(NSError *error))failureBlock;

/**
 *  Removes an existing datum object.
 *
 *  @param key          The key of the datum to be removed.
 *  @param httpClient   httpClient with which to issue the request.
 *  @param path         Service path to use for the request.
 *  @param successBlock A block which will be called with the retrieved datum when the request is successful.
 *  @param failureBlock A block which will be called with an NSError object if the request fails.
 *
 *  @return The service task that was spawned.
 */
+ (nullable AylaHTTPTask *)deleteKey:(NSString *)key
                          httpClient:(AylaHTTPClient *)httpClient
                                path:(NSString *)path
                             success:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END