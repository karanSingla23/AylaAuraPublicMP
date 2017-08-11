//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaErrorUtils.h"
#import "AylaLogManager.h"

#define DEFAULT_ORIG_ERROR_KEY @"com.aylanetworks.error.originalErrorKey";
#define DEFAULT_RESP_JSON_KEY @"com.aylanetworks.error.respErrorKey";
#define DEFAULT_STATUS_CODE @"com.aylanetworks.error.statusCode";
#define DEFAULT_COMPLETED_ITEMS_KEY @"com.aylanetworks.error.completedItems";
#define DEFAULT_BATCH_ERRORS_KEY @"com.aylanetworks.error.batchErrors";

@implementation AylaErrorUtils

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo
{
    return [self errorWithDomain:domain code:code userInfo:userInfo shouldLog:NO logTag:nil addOnDescription:nil];
}

+ (NSError *)errorWithDomain:(NSString *)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary *)userInfo
                   shouldLog:(BOOL)shouldLog
                      logTag:(NSString *)tag
            addOnDescription:(NSString *)description
{
    NSError *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    if(shouldLog) {
        AylaLogE(tag, 0, @"%@,%@", error, description);
    }
    return error;
}

@end

/**
 * HTTP error domain constants
 */
// Error domain
NSString *const AylaHTTPErrorDomain = @"com.aylanetworks.error.http";
// User info keys
NSString *const AylaHTTPErrorHTTPResponseKey = @"com.aylanetworks.error.httpResponseKey";
NSString *const AylaHTTPErrorOrignialErrorKey = DEFAULT_ORIG_ERROR_KEY;
NSString *const AylaHTTPErrorResponseJsonKey = DEFAULT_RESP_JSON_KEY;

/**
 * Request error domain
 */
// Error domain
NSString *const AylaRequestErrorDomain = @"com.aylanetworks.error.request";
// User info keys
NSString *const AylaRequestErrorOrignialErrorKey = DEFAULT_ORIG_ERROR_KEY;
NSString *const AylaRequestErrorResponseJsonKey = DEFAULT_RESP_JSON_KEY;
NSString *const AylaRequestErrorCompletedItemsKey = DEFAULT_COMPLETED_ITEMS_KEY;
NSString *const AylaRequestErrorBatchErrorsKey = DEFAULT_BATCH_ERRORS_KEY;

/**
 * JSON error domain
 */
// JSON error domain
NSString *const AylaJsonErrorDomain = @"com.aylanetworks.error.json";
// User info keys
NSString *const AylaJsonErrorOrignialErrorKey = DEFAULT_ORIG_ERROR_KEY;
NSString *const AylaJsonErrorResponseJsonKey = DEFAULT_RESP_JSON_KEY;

/**
 * Lan error domain
 */
// Error domain
NSString *const AylaLanErrorDomain = @"com.aylanetworks.error.lan";
// User info keys
NSString *const AylaLanErrorOrignialErrorKey = DEFAULT_ORIG_ERROR_KEY;
NSString *const AylaLanErrorResponseJsonKey = DEFAULT_RESP_JSON_KEY;
NSString *const AylaLanErrorStatusCode = DEFAULT_STATUS_CODE;  // Key to status code
NSString *const AylaLanErrorFailedCommand = @"com.aylanetworks.error.lan.command";

/**
 * Setup error domain
 */
// Error domain
NSString *const AylaSetupErrorDomain = @"com.aylanetworks.error.setup";
// User info keys
NSString *const AylaSetupErrorOrignialErrorKey = DEFAULT_ORIG_ERROR_KEY;
NSString *const AylaSetupErrorResponseJsonKey = DEFAULT_RESP_JSON_KEY;

/**
 * DS error domain
 */
// Error domain
NSString *const AylaDSErrorDomain = @"com.aylanetworks.error.dss";
// User info keys
NSString *const AylaDSErrorOrignialErrorKey = DEFAULT_ORIG_ERROR_KEY;
NSString *const AylaDSErrorResponseJsonKey = DEFAULT_RESP_JSON_KEY;

NSString *const AylaErrorDescriptionIsInvalid = @"is invalid.";
NSString *const AylaErrorDescriptionCanNotBeBlank = @"can't be blank.";
NSString *const AylaErrorDescriptionCanNotBeFound = @"can't be found.";
NSString *const AylaErrorDescriptionNotReady = @"is not ready.";


