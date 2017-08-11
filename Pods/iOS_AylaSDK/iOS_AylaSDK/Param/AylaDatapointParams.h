//
//  AylaDatapointParams.h
//  iOS_AylaSDK
//
//  Created by Yipei Wang on 1/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * AylaDatapointParams is a class to help fulfill datapoint related requests.
 */
@interface AylaDatapointParams : NSObject

/** @name Datapoint Parameter Properties */

/** Value of datapoint */
@property (nonatomic, strong) id value;

/** Metadata of datapoint */
@property (nonatomic, strong) NSDictionary *metadata;

/**
 * The path of the file to upload, used to initialize the params
 */
@property (nonatomic, strong, readonly, nullable) NSURL *filePath;

/**
 * The data to upload
 */
@property (nonatomic, strong, readonly, nullable) NSData *data;

/**
 * A helpful method to create a dictionary which contains all datapoint params.
 */
- (NSDictionary *)toCloudJSONDictionary;

/**
 * Initializes the params with a path to a file in the disk.
 *
 * @param filePath The path to the file to upload
 */
- (instancetype)initWithFilePath:(NSURL *)filePath;

/**
 * Initializes the params with the specified data
 *
 * @param data The data to upload
 */
- (instancetype)initWithData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END