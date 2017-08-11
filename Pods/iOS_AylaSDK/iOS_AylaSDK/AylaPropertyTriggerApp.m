//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaPropertyTriggerApp.h"

#import "AylaContact.h"
#import "AylaDefines_Internal.h"
#import "AylaLogManager.h"
#import "AylaServiceApp+Internal.h"
#import "NSObject+Ayla.h"
#import "NSString+AylaNetworks.h"

@interface AylaPropertyTriggerApp ()

@property (nonatomic, copy) NSNumber *key;
@end

@implementation AylaPropertyTriggerApp
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

@synthesize key = _key;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    if (self = [super init]) {
        NSArray *triggerApp = [dictionary objectForKey:@"trigger_app"];

        if (triggerApp) {
            NSString *appName = [[triggerApp valueForKeyPath:@"name"] nilIfNull];
            _type = [AylaPropertyTriggerApp notificationTypeFromName:appName];

            _nickname = [[triggerApp valueForKeyPath:@"nickname"] nilIfNull];
            _username = [[triggerApp valueForKeyPath:@"username"] nilIfNull];
            id param1 = [[triggerApp valueForKeyPath:@"param1"] nilIfNull];
            id param2 = [[triggerApp valueForKeyPath:@"param2"] nilIfNull];
            id param3 = [[triggerApp valueForKeyPath:@"param3"] nilIfNull];
            _key = [triggerApp valueForKeyPath:@"key"];
            _retrievedAt = [NSDate date];
            _contactId = [[triggerApp valueForKeyPath:@"contact_id"] nilIfNull];

            if ([appName isEqualToString:kAylaNotificationTypeSMS]) {
                // {"trigger_app": {"name":"sms", "param1":"1", "param2":"4085551111", "param3":"Hi. Pushbutton event"}}
                _countryCode = [param1 ayla_stringByStrippingLeadingZeroes];
                _phoneNumber = param2;
                _message = param3;
            }
            else if ([appName isEqualToString:kAylaNotificationTypeEmail]) {
                // {"trigger_app":{"name":"email","username":"Dave","param1":"emailAddress", "param3":"Hi. Pushbutton
                // event"}}
                _email = param1;
                _message = param3;
                
                NSString *emailTemplateID = [[triggerApp valueForKeyPath:@"email_template_id"] nilIfNull];
                _emailTemplate = (emailTemplateID) ? [[AylaEmailTemplate alloc] initWithId:emailTemplateID
                                                                                   subject:[[triggerApp valueForKeyPath:@"email_subject"] nilIfNull]
                                                                                  bodyHTML:[[triggerApp valueForKeyPath:@"email_body_html"] nilIfNull]]
                                                   : nil;
            }
            else if ([appName isEqualToString:kAylaNotificationTypePush]) {
                _applicationId = param2;
                _registrationId = param1;
                _message = param3;
                _pushSound = [[triggerApp valueForKeyPath:@"push_sound"] nilIfNull];
                _pushMetaData = [[triggerApp valueForKeyPath:@"push_mdata"] nilIfNull];
            }
            else if ([appName isEqualToString:kAylaNotificationTypePushAndroid]) {
                _registrationId = param1;
                _message = param3;
            }
            else if ([appName isEqualToString:kAylaNotificationTypePushBaidu]) {
                _applicationId = param1;
                _registrationId = param2;
                _message = param3;
            }
            else {
                AylaLogE([self logTag],
                         0,
                         @"%@, %@, %@:%@",
                         NSStringFromSelector(_cmd),
                         @"appName",
                         appName,
                         @"Unknown application");
            }
        }
        else {
            AylaLogE([self logTag],
                     0,
                     @"%@, %@, %@:%@",
                     NSStringFromSelector(_cmd),
                     @"PropertyTriggers",
                     @"applicationTrigger",
                     @"nil");
        }
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSDictionary *parameters;
    NSDictionary *paramsDictionary;
    switch (self.type) {
        case AylaServiceAppTypeSMS:
            // {"trigger_app": {"name":"sms", "param1":"1", "param2":"4085551111", "param3":"Hi. Pushbutton event"}}
            parameters = @{
                @"name" : kAylaNotificationTypeSMS,
                @"nickname" : AYLNullIfNil(self.nickname),
                @"contact_id" : AYLNullIfNil(self.contactId),
                @"param1" : AYLNullIfNil(self.countryCode),
                @"param2" : AYLNullIfNil(self.phoneNumber),
                @"param3" : AYLNullIfNil(self.message)
            };
            break;
        case AylaServiceAppTypeEmail:
            // {"trigger_app":{"name":"email","username":"Dave","param1":"emailAddress"}}
            parameters = @{
                @"name" : kAylaNotificationTypeEmail,
                @"nickname" : AYLNullIfNil(self.nickname),
                @"contact_id" : AYLNullIfNil(self.contactId),
                @"username" : AYLNullIfNil(self.username),
                @"param1" : AYLNullIfNil(self.email),
                @"param3" : AYLNullIfNil(self.message),
                @"email_template_id" : AYLNullIfNil(self.emailTemplate.id),
                @"email_subject" : AYLNullIfNil(self.emailTemplate.subject),
                @"email_body_html" : AYLNullIfNil(self.emailTemplate.bodyHTML)
            };
            break;
        case AylaServiceAppTypePush:
            parameters = @{
                @"name" : kAylaNotificationTypePush,
                @"nickname" : AYLNullIfNil(self.nickname),
                @"contact_id" : AYLNullIfNil(self.contactId),
                @"param1" : AYLNullIfNil(self.registrationId),
                @"param2" : AYLNullIfNil(self.applicationId),
                @"param3" : AYLNullIfNil(self.message),
                @"push_sound" : AYLNullIfNil(self.pushSound),
                @"push_mdata" : AYLNullIfNil(self.pushMetaData)
            };
            break;
        case AylaServiceAppTypePushAndroid:
            parameters = @{
                @"name" : kAylaNotificationTypePushAndroid,
                @"nickname" : AYLNullIfNil(self.nickname),
                @"contact_id" : AYLNullIfNil(self.contactId),
                @"param1" : AYLNullIfNil(self.registrationId),
                @"param3" : AYLNullIfNil(self.message)
            };
            break;
        case AylaServiceAppTypePushBaidu:
            parameters = @{
                @"name" : kAylaNotificationTypePushBaidu,
                @"nickname" : AYLNullIfNil(self.nickname),
                @"contact_id" : AYLNullIfNil(self.contactId),
                @"param1" : AYLNullIfNil(self.applicationId),
                @"param2" : AYLNullIfNil(self.registrationId),
                @"param3" : AYLNullIfNil(self.message)
            };
            break;
        default:
            break;
    }
    
    paramsDictionary = @{ @"trigger_app" : parameters };
    return paramsDictionary;
}

- (NSString *)logTag
{
    return NSStringFromClass([self class]);
}
@end
