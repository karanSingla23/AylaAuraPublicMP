//
//  AylaLocalProperty.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/9/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaProperty.h"
@class AylaLocalDevice;
NS_ASSUME_NONNULL_BEGIN

/**
 Describes a property representation from a local device
 */
@interface AylaLocalProperty : AylaProperty

/**
 Initializes the instance with the specified params.

 @param device Device holding the property
 @param property Property from cloud
 @param name Name of the property
 @param displayName Display name of the property
 @param readOnly Indicates if property is readonly
 @param baseType base type od the property
 @return An initialized local property
 */
- (instancetype)initWithDevice:(AylaLocalDevice *)device originalProperty:(AylaProperty *)property name:(NSString *)name displayName:(NSString *)displayName readOnly:(BOOL)readOnly baseType:(NSString *)baseType;

/**
 Pushes the changes in the properties received from device to cloud

 @param success A block called when the change has succeeded
 @param failure A block called when the push fails
 @return An `AylaConnectTask` for the push
 */
- (nullable AylaConnectTask *)pushUpdateToCloudWithSuccess:(nullable void (^)())success failure:(nullable void (^)())failure;

/**
 Indicates whether the property is readonly
 */
@property (nonatomic, readwrite, getter=isReadOnly) BOOL readOnly;

/**
 Original property received from cloud
 */
@property (nonatomic, strong) AylaProperty *originalProperty;
@end
NS_ASSUME_NONNULL_END
