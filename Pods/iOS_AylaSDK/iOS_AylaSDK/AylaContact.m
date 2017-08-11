//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaContact.h"
#import "AylaDefines_Internal.h"
#import "NSObject+Ayla.h"

static NSString *const attrNameAylaContactId = @"id";
static NSString *const attrNameAylaContactUpdatedAt = @"updated_at";
static NSString *const attrNameAylaContactContact = @"contact";
static NSString *const attrNameAylaContactFirstName = @"firstname";
static NSString *const attrNameAylaContactLastName = @"lastname";
static NSString *const attrNameAylaContactDisplayName = @"display_name";
static NSString *const attrNameAylaContactEmail = @"email";
static NSString *const attrNameAylaContactPhoneCountryCode = @"phone_country_code";
static NSString *const attrNameAylaContactPhoneNumber = @"phone_number";
static NSString *const attrNameAylaContactStreetAddress = @"street_address";
static NSString *const attrNameAylaContactZipCode = @"zip_code";
static NSString *const attrNameAylaContactCountry = @"country";
static NSString *const attrNameAylaContactEmailAccept = @"email_accept";
static NSString *const attrNameAylaContactEmailNotification = @"email_notification";
static NSString *const attrNameAylaContactSmsAccept = @"sms_accept";
static NSString *const attrNameAylaContactSmsNotification = @"sms_notification";

static NSString *const attrNameAylaContactPushNotification = @"push_notification";
static NSString *const attrNameAylaContactMetadata = @"metadata";
static NSString *const attrNameAylaContactNotes = @"notes";
static NSString *const attrNameAylaContactOemModels = @"oem_models";

NSString * const AylaContactAcceptNotReq = @"not_req";
NSString * const AylaContactAcceptReq = @"req";
NSString * const AylaContactAcceptPending = @"pending";
NSString * const AylaContactAcceptAccepted = @"accepted";
NSString * const AylaContactAcceptDenied = @"denied";


@implementation AylaContact
- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    if (self = [super init]) {
        if ([dictionary objectForKey:attrNameAylaContactContact]) {
            dictionary = dictionary[attrNameAylaContactContact];
        };

        _id = [[dictionary objectForKey:attrNameAylaContactId] nilIfNull];
        _firstName = [[dictionary objectForKey:attrNameAylaContactFirstName] nilIfNull];
        _lastName = [[dictionary objectForKey:attrNameAylaContactLastName] nilIfNull];
        _displayName = [[dictionary objectForKey:attrNameAylaContactDisplayName] nilIfNull];
        _email = [[dictionary objectForKey:attrNameAylaContactEmail] nilIfNull];
        _phoneCountryCode = [[dictionary objectForKey:attrNameAylaContactPhoneCountryCode] nilIfNull];
        _phoneNumber = [[dictionary objectForKey:attrNameAylaContactPhoneNumber] nilIfNull];
        _streetAddress = [[dictionary objectForKey:attrNameAylaContactStreetAddress] nilIfNull];
        _zipCode = [[dictionary objectForKey:attrNameAylaContactZipCode] nilIfNull];
        _country = [[dictionary objectForKey:attrNameAylaContactCountry] nilIfNull];
        _emailAccept = [[dictionary objectForKey:attrNameAylaContactEmailAccept] nilIfNull];
        _emailNotification = [[dictionary objectForKey:attrNameAylaContactEmailNotification] boolValue];
        _smsAccept = [[dictionary objectForKey:attrNameAylaContactSmsAccept] nilIfNull];
        _smsNotification = [[dictionary objectForKey:attrNameAylaContactSmsNotification] boolValue];
        _pushNotification = [[dictionary objectForKey:attrNameAylaContactPushNotification] boolValue];
        _notes = [[dictionary objectForKey:attrNameAylaContactNotes] nilIfNull];
        _oemModels = [[dictionary objectForKey:attrNameAylaContactOemModels] nilIfNull];
        _metadata = [[dictionary objectForKey:attrNameAylaContactMetadata] nilIfNull];
        _updatedAt = [[dictionary objectForKey:attrNameAylaContactUpdatedAt] nilIfNull];
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSDictionary *jsonContact = @{
        attrNameAylaContactFirstName : AYLNullIfNil(_firstName),
        attrNameAylaContactLastName : AYLNullIfNil(_lastName),
        attrNameAylaContactDisplayName : AYLNullIfNil(_displayName),
        attrNameAylaContactEmail : AYLNullIfNil(_email),
        attrNameAylaContactPhoneCountryCode : AYLNullIfNil(_phoneCountryCode),
        attrNameAylaContactPhoneNumber : AYLNullIfNil(_phoneNumber),
        attrNameAylaContactStreetAddress : AYLNullIfNil(_streetAddress),
        attrNameAylaContactZipCode : AYLNullIfNil(_zipCode),
        attrNameAylaContactCountry : AYLNullIfNil(_country),

        attrNameAylaContactEmailAccept : _emailAccept ?: AylaContactAcceptNotReq,
        attrNameAylaContactEmailNotification : @(_emailNotification),
        attrNameAylaContactSmsAccept : _smsAccept ?: AylaContactAcceptNotReq,
        attrNameAylaContactSmsNotification : @(_smsNotification),
        attrNameAylaContactPushNotification : @(_pushNotification),

        attrNameAylaContactMetadata : AYLNullIfNil(_metadata),
        attrNameAylaContactNotes : AYLNullIfNil(_notes),
        attrNameAylaContactOemModels : AYLNullIfNil(_oemModels)
    };
    return jsonContact;
}

- (instancetype)init {
    if (self = [super init]) {
        _emailNotification = YES;
        _smsNotification = YES;
        _pushNotification = YES;
    }
    return self;
}
@end
