//
//  AylaLocalProperty.m
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 12/9/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaLocalProperty.h"
#import "AylaLocalDevice.h"
#import "AylaDevice+Extensible.h"

@interface AylaLocalProperty ()
@property(readonly) AylaLocalDevice *localDevice;
@end

@implementation AylaLocalProperty
- (instancetype)initWithDevice:(AylaLocalDevice *)device originalProperty:(nonnull AylaProperty *)property name:(NSString *)name displayName:(NSString *)displayName readOnly:(BOOL)readOnly baseType:(NSString *)baseType {
    if (self = [super init]) {
        _originalProperty = property;
        self.datapoint = property.datapoint;
        self.device = device;
        self.name = name;
        self.displayName = displayName;
        self.readOnly = readOnly;
        self.baseType = baseType;
    }
    return self;
}
- (AylaLocalDevice *)localDevice {
    return (AylaLocalDevice *)self.device;
}
- (AylaConnectTask *)createDatapoint:(AylaDatapointParams *)datapointParams success:(void (^)(AylaDatapoint * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self.localDevice setValue:datapointParams.value forProperty:self success:^{
        AylaDatapoint *datapoint = [[AylaDatapoint alloc] initWithValue:datapointParams.value];
        // update cloud when API is available
        successBlock(datapoint);
    } failure:failureBlock];
}

- (AylaConnectTask *)createDatapointLAN:(AylaDatapointParams *)datapointParams success:(void (^)(AylaDatapoint * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self createDatapoint:datapointParams success:successBlock failure:failureBlock];
}

- (AylaConnectTask *)createDatapointCloud:(AylaDatapointParams *)datapointParams success:(void (^)(AylaDatapoint * _Nonnull))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    return [self createDatapoint:datapointParams success:successBlock failure:failureBlock];
}

- (id)value {
    return [self.localDevice valueForProperty:self];
}

- (AylaPropertyChange *)updateFromDatapoint:(AylaDatapoint *)datapoint {
    self.originalProperty.datapoint = datapoint;
    return [super updateFromDatapoint:datapoint];
}

- (AylaConnectTask *)pushUpdateToCloudWithSuccess:(void (^)())success failure:(void (^)())failure {
    AylaDatapointParams *datapointParams = [[AylaDatapointParams alloc] init];
    datapointParams.value = self.value;
    AylaLogI([self logTag], 0, @"Pushing local property update to cloud: %@ = %@", self.originalProperty.name, self.value);
    return [self.originalProperty createDatapointCloud:datapointParams success:^(AylaDatapoint * _Nonnull createdDatapoint) {
        
        AylaLogI([self logTag], 0, @"Pushed local property update to cloud Successfully!: %@, %@", self.originalProperty.name, self.value);
        if (success != nil) {
            success();
        }
    } failure:^(NSError * _Nonnull error) {
        AylaLogI([self logTag], 0, @"Failed to push local property update to cloud: %@, %@", self.originalProperty.name, error);
        if (failure != nil) {
            failure();
        }
    }];
}

- (NSString *)logTag {
    return NSStringFromClass([self class]);
}
@end
