//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaServiceApp.h"

#import "AylaContact.h"
#import "NSString+AylaNetworks.h"

NSString *const kAylaNotificationTypeEmail       = @"email";
NSString *const kAylaNotificationTypeSMS         = @"sms";
NSString *const kAylaNotificationTypePush        = @"push_ios";
NSString *const kAylaNotificationTypePushAndroid = @"push_android";
NSString *const kAylaNotificationTypePushBaidu   = @"push_baidu";

@implementation AylaServiceApp
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    if (self = [super init]) {
    }
    return self;
}
- (void)setCountryCode:(NSString *)countryCode
{
    _countryCode = [countryCode ayla_stringByStrippingLeadingZeroes];
}

+ (AylaServiceAppType)notificationTypeFromName:(NSString *)notificationName
{
    if ([notificationName isEqualToString:kAylaNotificationTypeEmail]) {
        return AylaServiceAppTypeEmail;
    }
    else if ([notificationName isEqualToString:kAylaNotificationTypePush]) {
        return AylaServiceAppTypePush;
    }
    else if ([notificationName isEqualToString:kAylaNotificationTypeSMS]) {
        return AylaServiceAppTypeSMS;
    }
    else if ([notificationName isEqualToString:kAylaNotificationTypePushAndroid]) {
        return AylaServiceAppTypePushAndroid;
    }
    else if ([notificationName isEqualToString:kAylaNotificationTypePushBaidu]) {
        return AylaServiceAppTypePushBaidu;
    }
    return AylaServiceAppTypeUnknown;
}

+ (NSString *)notificationNameFromType:(AylaServiceAppType)type
{
    switch (type) {
        case AylaServiceAppTypeEmail:
            return kAylaNotificationTypeEmail;
        case AylaServiceAppTypePush:
            return kAylaNotificationTypePush;
        case AylaServiceAppTypeSMS:
            return kAylaNotificationTypeSMS;
        case AylaServiceAppTypePushAndroid:
            return kAylaNotificationTypePushAndroid;
        case AylaServiceAppTypePushBaidu:
            return kAylaNotificationTypePushBaidu;
        default:
            break;
    }
    return nil;
}

- (void)configureAsSMSFor:(AylaContact *)contact message:(NSString *)message
{
    self.type = AylaServiceAppTypeSMS;
    self.contactId = contact.id;
    self.message = message;
}

- (void)configureAsEmailfor:(AylaContact *)contact
                    message:(NSString *)message
                   username:(nullable NSString *)username
                   template:(nullable AylaEmailTemplate *)emailTemplate
{
    self.type = AylaServiceAppTypeEmail;
    self.contactId = contact.id;
    self.emailTemplate = emailTemplate;
    self.message = message;
    self.username = username;
}

- (void)configureAsPushWithMessage:(NSString *)message
                    registrationId:(NSString *)registrationId
                     applicationId:(NSString *)applicationId
                         pushSound:(NSString *)pushSound
                      pushMetaData:(NSString *)pushMetadata
{
    self.type = AylaServiceAppTypePush;
    self.message = message;
    self.registrationId = registrationId;
    self.applicationId = applicationId;
    self.pushSound = pushSound ?: @"normal";
    self.pushMetaData = pushMetadata;
}
@end