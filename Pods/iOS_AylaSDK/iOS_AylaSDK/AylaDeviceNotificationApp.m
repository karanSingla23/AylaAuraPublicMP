//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDeviceNotificationApp.h"

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "NSObject+Ayla.h"

NSString *const attrDeviceNotificationAppNameId = @"id";
NSString *const attrDeviceNotificationAppNameNotificationId = @"notification_id";
NSString *const attrDeviceNotificationAppNameAppType = @"app_type";
NSString *const attrDeviceNotificationAppNameNickname = @"nickname";

NSString *const attrDeviceNotificationAppNameContactId = @"contact_id";

NSString *const attrDeviceNotificationAppNameUserName = @"username";
NSString *const attrDeviceNotificationAppNameMessage = @"message";

NSString *const attrDeviceNotificationAppNameEmailAddr = @"email";
NSString *const attrDeviceNotificationAppNameEmailTemplateId = @"email_template_id";
NSString *const attrDeviceNotificationAppNameEmailSubject = @"email_subject";
NSString *const attrDeviceNotificationAppNameEmailBodyHtml = @"email_body_html";

NSString *const attrDeviceNotificationAppNameAppId = @"application_id";
NSString *const attrDeviceNotificationAppNameRegistrationId = @"registration_id";
NSString *const attrDeviceNotificationAppNamePushData = @"push_mdata";
NSString *const attrDeviceNotificationAppNamePushSound = @"push_sound";

NSString *const attrDeviceNotificationAppNameCountryCode = @"country_code";
NSString *const attrDeviceNotificationAppNamePhoneNumber = @"phone_number";

@interface AylaDeviceNotificationApp ()
@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSString *notificationId;
@end

@implementation AylaDeviceNotificationApp
@synthesize type = _type;
@synthesize contactId = _contactId;
@synthesize username = _username;
@synthesize message = _message;
@synthesize nickname = _nickname;

@synthesize email = _email;
@synthesize emailTemplate = _emailTemplate;

@synthesize countryCode = _countryCode;
@synthesize phoneNumber = _phoneNumber;

@synthesize registrationId = _registrationId;
@synthesize applicationId = _applicationId;
@synthesize pushSound = _pushSound;
@synthesize pushMetaData = _pushMetaData;
@synthesize retrievedAt = _retrievedAt;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    if (self = [super initWithJSONDictionary:dictionary error:error]) {
        NSDictionary *notificationDictionary = [dictionary objectForKey:@"notification_app"];
        _id = [notificationDictionary objectForKey:attrDeviceNotificationAppNameId];
        _notificationId = [notificationDictionary objectForKey:attrDeviceNotificationAppNameNotificationId];
        NSString *notificationType = [notificationDictionary objectForKey:attrDeviceNotificationAppNameAppType];

        _type = [AylaDeviceNotificationApp notificationTypeFromName:notificationType];

        _nickname = [notificationDictionary objectForKey:attrDeviceNotificationAppNameNickname] != [NSNull null]
                        ? [notificationDictionary objectForKey:attrDeviceNotificationAppNameNickname]
                        : nil;

        NSDictionary *appParams = [notificationDictionary objectForKey:@"notification_app_parameters"];

        _contactId = [[appParams objectForKey:attrDeviceNotificationAppNameContactId] nilIfNull];
        _username = [[appParams objectForKey:attrDeviceNotificationAppNameUserName] nilIfNull];
        _message = [[appParams objectForKey:attrDeviceNotificationAppNameMessage] nilIfNull];

        _email = [[appParams objectForKey:attrDeviceNotificationAppNameEmailAddr] nilIfNull];
        NSString *templateId = [[appParams objectForKey:attrDeviceNotificationAppNameEmailTemplateId] nilIfNull];
        if (templateId) {
            _emailTemplate = [[AylaEmailTemplate alloc]
                initWithId:templateId
                   subject:[[appParams objectForKey:attrDeviceNotificationAppNameEmailSubject] nilIfNull]
                  bodyHTML:[[appParams objectForKey:attrDeviceNotificationAppNameEmailBodyHtml] nilIfNull]];
        }

        _countryCode = [[appParams objectForKey:attrDeviceNotificationAppNameCountryCode] nilIfNull];
        _phoneNumber = [[appParams objectForKey:attrDeviceNotificationAppNamePhoneNumber] nilIfNull];

        _applicationId = [[appParams objectForKey:attrDeviceNotificationAppNameAppId] nilIfNull];
        _registrationId = [[appParams objectForKey:attrDeviceNotificationAppNameRegistrationId] nilIfNull];
        _pushMetaData = [[appParams objectForKey:attrDeviceNotificationAppNamePushData] nilIfNull];
        _pushSound = [[appParams objectForKey:attrDeviceNotificationAppNamePushSound] nilIfNull];
        _retrievedAt = [NSDate date];
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *toServiceDictionary = [NSMutableDictionary new];
    [toServiceDictionary setObject:[AylaDeviceNotificationApp notificationNameFromType:self.type]
                            forKey:attrDeviceNotificationAppNameAppType];
    [toServiceDictionary setObject:AYLNullIfNil(self.nickname) forKey:attrDeviceNotificationAppNameNickname];

    [toServiceDictionary setObject:[self toParamsServiceDictionary] forKey:@"notification_app_parameters"];
    return @{ @"notification_app" : toServiceDictionary };
}

- (NSDictionary *)toParamsServiceDictionary
{
    NSMutableDictionary *appParams = [NSMutableDictionary new];
    if (self.contactId) {
        [appParams setObject:AYLNullIfNil(self.contactId) forKey:attrDeviceNotificationAppNameContactId];
    }
    if (self.username) {
        [appParams setObject:AYLNullIfNil(self.username) forKey:attrDeviceNotificationAppNameUserName];
    }
    [appParams setObject:AYLNullIfNil(self.message) forKey:attrDeviceNotificationAppNameMessage];
    switch (self.type) {
        case AylaServiceAppTypeEmail:
            if (self.email) {  // this condition is required because the cloud requires it to be nonnull or not present
                               // in the dictionary at all
                [appParams setObject:self.email forKey:attrDeviceNotificationAppNameEmailAddr];
            }
            if (self.emailTemplate != nil) {
                [appParams setObject:AYLNullIfNil(self.emailTemplate.subject)
                              forKey:attrDeviceNotificationAppNameEmailSubject];
                [appParams setObject:AYLNullIfNil(self.emailTemplate.id)
                              forKey:attrDeviceNotificationAppNameEmailTemplateId];
                [appParams setObject:AYLNullIfNil(self.emailTemplate.bodyHTML)
                              forKey:attrDeviceNotificationAppNameEmailBodyHtml];
            }
            break;
        case AylaServiceAppTypeSMS:
            if (self.countryCode) {
                [appParams setObject:AYLNullIfNil(self.countryCode) forKey:attrDeviceNotificationAppNameCountryCode];
            }
            if (self.phoneNumber) {
                [appParams setObject:AYLNullIfNil(self.phoneNumber) forKey:attrDeviceNotificationAppNamePhoneNumber];
            }
            break;
        case AylaServiceAppTypePush:
            [appParams setObject:AYLNullIfNil(self.applicationId) forKey:attrDeviceNotificationAppNameAppId];
            [appParams setObject:AYLNullIfNil(self.registrationId) forKey:attrDeviceNotificationAppNameRegistrationId];
            if (self.pushMetaData) {
                [appParams setObject:AYLNullIfNil(self.pushMetaData) forKey:attrDeviceNotificationAppNamePushData];
            }
            [appParams setObject:AYLNullIfNil(self.pushSound) forKey:attrDeviceNotificationAppNamePushSound];
            [appParams setObject:AYLNullIfNil(self.message) forKey:attrDeviceNotificationAppNameMessage];
            break;
        case AylaServiceAppTypePushAndroid:
            [appParams setObject:AYLNullIfNil(self.applicationId) forKey:attrDeviceNotificationAppNameAppId];
            [appParams setObject:AYLNullIfNil(self.registrationId) forKey:attrDeviceNotificationAppNameRegistrationId];
            [appParams setObject:AYLNullIfNil(self.message) forKey:attrDeviceNotificationAppNameMessage];
            break;
        case AylaServiceAppTypePushBaidu:
            [appParams setObject:AYLNullIfNil(self.registrationId) forKey:attrDeviceNotificationAppNameRegistrationId];
            [appParams setObject:AYLNullIfNil(self.message) forKey:attrDeviceNotificationAppNameMessage];
            break;
        default:
            break;
    }
    return appParams;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"DeviceNotificationApp: %@", [self toJSONDictionary]];
}
@end
