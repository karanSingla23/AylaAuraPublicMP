//
//  AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaRegistration+Internal.h"

#import "AylaErrorUtils.h"
#import "AylaHTTPClient.h"
#import "AylaLogManager.h"
#import "AylaRegistrationCandidate.h"
#import "AylaSessionManager+Internal.h"

@interface AylaRegistration (ModuleClient)

/** HTTP Client used to comunicate with the module */
@property (nonatomic, strong, nullable) AylaHTTPClient *moduleClient;
@end

@implementation AylaRegistration (Internal)

- (AylaHTTPClient *)getHttpClient:(NSError *_Nullable __autoreleasing *_Nullable)error
{
    AylaHTTPClient *client = [self.sessionManager getHttpClientWithType:AylaHTTPClientTypeDeviceService];

    if (!client && error) {
        *error = [AylaErrorUtils errorWithDomain:AylaRegistrationErrorDomain
                                            code:AylaRegistrationErrorCodePreconditionFailure
                                        userInfo:@{AylaHTTPClientTag : AylaErrorDescriptionCanNotBeFound}];
    }

    return client;
}

- (AylaHTTPTask *)fetchRegistrationTokenForCandidate:(AylaRegistrationCandidate *)candidate
                                             success:(void (^)(NSString *_Nonnull))successBlock
                                             failure:(void (^)(NSError *_Nonnull))failureBlock
{
    self.moduleClient = [AylaHTTPClient apModeDeviceClientWithLanIp:candidate.lanIp usingHTTPS:NO];
    AylaHTTPTask *task = [self.moduleClient getPath:@"regtoken.json"
        parameters:nil
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable responseObject) {
            NSString *regToken = ([responseObject valueForKeyPath:@"regtoken"] != [NSNull null])
                                     ? [responseObject valueForKeyPath:@"regtoken"]
                                     : @"";
            AylaLogI([self logTag], 0, @"%@:%@, %@", @"regToken", @"retrieved", @"getRegistrationToken.getPath");
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(regToken);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            AylaLogI([self logTag], 0, @"err:%@, %@", error, @"fetchRegistrationTokenForCandidate");
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];

    return task;
}

#pragma mark - Candidates
- (AylaHTTPTask *)fetchCandidatesWithDSN:(NSString *)targetDsn
                        registrationType:(AylaRegistrationType)registrationType
                                 success:(void (^)(NSArray AYLA_GENERIC(AylaRegistrationCandidate *) *
                                                   candidates))successBlock
                                 failure:(void (^)(NSError *error))failureBlock
{
    NSString *path = @"devices/register.json";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (targetDsn) {
        [params setObject:targetDsn forKey:@"dsn"];
    }
    if (registrationType != AylaRegistrationTypeAny) {
        [params setObject:[AylaRegistration registrationNameFromType:registrationType] forKey:@"regtype"];
    }

    NSError *error;
    AylaHTTPClient *httpClient = [self getHttpClient:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        return nil;
    }

    AylaLogI([self logTag], 0, @"%@:%@, %@", @"path", path, NSStringFromSelector(_cmd));

    return [httpClient getPath:path
        parameters:params
        success:^(AylaHTTPTask *_Nonnull task, id _Nullable candidateJSONObject) {
            NSMutableArray AYLA_GENERIC(AylaRegistrationCandidate *) *candidates = [NSMutableArray array];
            if ([candidateJSONObject isKindOfClass:[NSArray class]]) {
                for (NSDictionary *candidateDictionary in candidateJSONObject) {
                    AylaRegistrationCandidate *candidate =
                        [[AylaRegistrationCandidate alloc] initWithDictionary:candidateDictionary];
                    candidate.registrationType = AylaRegistrationTypeNode;
                    AylaLogI([self logTag],
                             0,
                             @"%@:%@, %@",
                             @"model",
                             candidate.model,
                             @"fetchRegistrationCandidates.getPath");
                    [candidates addObject:candidate];
                }
            }
            else {
                AylaRegistrationCandidate *candidate =
                    [[AylaRegistrationCandidate alloc] initWithDictionary:candidateJSONObject];
                candidate.registrationType = registrationType;
                AylaLogI(
                    [self logTag], 0, @"%@:%@, %@", @"model", candidate.model, @"fetchRegistrationCandidates.getPath");
                [candidates addObject:candidate];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(candidates);
            });
        }
        failure:^(AylaHTTPTask *_Nonnull task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }];
}

- (NSString *)logTag
{
    return NSStringFromClass([self class]);
}
@end
