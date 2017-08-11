//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaUser.h"
#import "NSObject+Ayla.h"

static NSString *const attrNameEmail = @"email";
static NSString *const attrNamePassword = @"password";
static NSString *const attrNameFirstname = @"firstname";
static NSString *const attrNameLastname = @"lastname";
static NSString *const attrNamePhoneCountryCode = @"phone_country_code";
static NSString *const attrNamePhone = @"phone";
static NSString *const attrNameCompany = @"company";
static NSString *const attrNameStreet = @"street";
static NSString *const attrNameCity = @"city";
static NSString *const attrNameState = @"state";
static NSString *const attrNameCountry = @"country";
static NSString *const attrNameDevKitNum = @"ayla_dev_kit_num";
static NSString *const attrNameZip = @"zip";
static NSString *const attrNameTermsAccepted = @"terms_accepted";

@implementation AylaUser
- (instancetype)initWithEmail:(NSString *)email
                     password:(NSString *)password
                    firstName:(NSString *)firstName
                     lastName:(NSString *)lastName
{
    AYLAssert(email.length > 0, @"email is required");
    AYLAssert(firstName.length > 0, @"firstName is required");
    AYLAssert(lastName.length > 0, @"lastName is required");
    if (self = [super init]) {
        _email = email;
        _password = password;
        _firstName = firstName;
        _lastName = lastName;
    }
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;

    _email = [dictionary[attrNameEmail] nilIfNull];
    _firstName = [dictionary[attrNameFirstname] nilIfNull];
    _lastName = [dictionary[attrNameLastname] nilIfNull];
    _phoneCountryCode = [dictionary[attrNamePhoneCountryCode] nilIfNull];
    _phone = [dictionary[attrNamePhone] nilIfNull];
    _company = [dictionary[attrNameCompany] nilIfNull];
    _street = [dictionary[attrNameStreet] nilIfNull];
    _city = [dictionary[attrNameCity] nilIfNull];
    _state = [dictionary[attrNameState] nilIfNull];
    _zip = [dictionary[attrNameZip] nilIfNull];
    _country = [dictionary[attrNameCountry] nilIfNull];
    _devKitNum = [dictionary[attrNameDevKitNum] nilIfNull];
    _termsAccepted = [[dictionary[attrNameTermsAccepted] nilIfNull] boolValue];
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super toJSONDictionary]];

    dictionary[attrNameEmail] = AYLNullIfNil(self.email);
    dictionary[attrNamePassword] = AYLNullIfNil(self.password);
    dictionary[attrNameFirstname] = AYLNullIfNil(self.firstName);
    dictionary[attrNameLastname] = AYLNullIfNil(self.lastName);
    dictionary[attrNamePhoneCountryCode] = AYLNullIfNil(self.phoneCountryCode);
    dictionary[attrNamePhone] = AYLNullIfNil(self.phone);
    dictionary[attrNameCompany] = AYLNullIfNil(self.company);
    dictionary[attrNameStreet] = AYLNullIfNil(self.street);
    dictionary[attrNameCity] = AYLNullIfNil(self.city);
    dictionary[attrNameState] = AYLNullIfNil(self.state);
    dictionary[attrNameZip] = AYLNullIfNil(self.zip);
    dictionary[attrNameCountry] = AYLNullIfNil(self.country);
    dictionary[attrNameDevKitNum] = AYLNullIfNil(self.devKitNum);
    dictionary[attrNameTermsAccepted] = @(self.termsAccepted);

    return dictionary;
}

@end
