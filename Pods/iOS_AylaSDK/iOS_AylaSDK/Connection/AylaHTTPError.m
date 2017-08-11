//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <AFNetworking/AFURLResponseSerialization.h>
#import "AylaErrorUtils.h"
#import "AylaHTTPError.h"

@implementation NSError (AylaHTTPError)
- (BOOL)isAyla_httpErrorResponse
{
    return self.ayla_httpResponse != nil;
}

- (NSHTTPURLResponse *)ayla_httpResponse
{
    return self.userInfo[AylaHTTPErrorHTTPResponseKey];
}

- (NSInteger)ayla_httpStatusCode
{
    return self.ayla_httpResponse.statusCode;
}

- (NSData *)ayla_serverResponseData
{
    NSError *error = self.userInfo[AylaRequestErrorOrignialErrorKey];
    return error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
}

- (NSDictionary *)ayla_httpHeaders
{
    return self.ayla_httpResponse.allHeaderFields;
}

- (NSString *)ayla_httpErrorLocalizedDescription
{
    NSError *error = self.userInfo[AylaRequestErrorOrignialErrorKey];
    return error.localizedDescription;
}

@end
