//
//  AylaLocalRegistrationCandidate.h
//  Ayla_LocalDevice_SDK
//
//  Created by Emanuel Peña Aguilar on 1/5/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

#import "AylaRegistrationCandidate.h"

NS_ASSUME_NONNULL_BEGIN


/**
 Represents a Candidate for Local Registration
 */
@interface AylaLocalRegistrationCandidateTemplate : NSObject

/** Template Key */
@property (nonatomic, strong) NSString *template_key;
/** Template version */
@property (nonatomic, strong) NSString *version;
@end


/** Represents a subdevice in candidate */
@interface AylaLocalRegistrationCandidateSubdevice : NSObject

/** Subdevice key */
@property (nonatomic, strong) NSString *subdevice_key;

/** Array of templates */
@property (nonatomic, strong, nullable) NSArray <AylaLocalRegistrationCandidateTemplate *> *templates;
@end


/**
 Represents a local candidate.
 */
@interface AylaLocalRegistrationCandidate : AylaRegistrationCandidate

/**
 Initializes the candidate with the specified parameters

 @param hardwareAddress Hardware address of the device
 @param deviceType Device type
 @param model Device model
 @param oemModel OEM Model
 @param swVersion Version
 @return A candidate for local registration
 */
- (instancetype)initWithHardwareAddress:(NSString *)hardwareAddress deviceType:(NSString *)deviceType model:(NSString *)model oemModel:(NSString *)oemModel swVersion:(NSString *)swVersion;

/** @return Returns a JSON representation of the candidate */
- (NSDictionary *)toJSONDictionary;

/** swVersion */
@property (nonatomic, strong, nullable) NSString *swVersion;
/** Hardware address of the candidate */
@property (nonatomic, strong, nullable) NSString *hardwareAddress;
/** Candidate device type */
@property (nonatomic, strong, nullable) NSString *deviceType;
/** Model */
@property (nonatomic, strong, nullable) NSString *model;
/** OEM Model */
@property (nonatomic, strong, nullable) NSString *oemModel;
/** Array of subdevices */
@property (nonatomic, strong, nullable) NSArray<AylaLocalRegistrationCandidateSubdevice *> *subdevices;
@end
NS_ASSUME_NONNULL_END
