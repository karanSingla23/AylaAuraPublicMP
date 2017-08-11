//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaDefines_Internal.h"
#import "AylaEmailTemplate.h"
#import "AylaObject+Internal.h"

static NSString *const attrNameEmailTemplateId = @"email_template_id";
static NSString *const attrNameEmailSubject = @"email_subject";
static NSString *const attrNameEmailBodyHTML = @"email_body_html";

@implementation AylaEmailTemplate
- (instancetype)initWithId:(NSString *)id subject:(NSString *)subject bodyHTML:(NSString *)bodyHTML
{
    AYLAssert(id.length > 0, @"id is required");

    if (self = [super init]) {
        _id = id;
        _subject = subject;
        _bodyHTML = bodyHTML;
    }
    return self;
}

- (NSDictionary *)toJSONDictionary
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:self.id forKey:attrNameEmailTemplateId];

    if (self.subject != nil) {
        params[attrNameEmailSubject] = self.subject;
    }

    if (self.bodyHTML != nil) {
        params[attrNameEmailBodyHTML] = self.bodyHTML;
    }
    return params;
}
@end