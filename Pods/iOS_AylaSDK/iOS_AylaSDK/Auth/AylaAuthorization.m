//
//  AylaSDK
//
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import "AylaAuthorization.h"
#import "AylaErrorUtils.h"
#import "AylaObject+Internal.h"

@implementation AylaAuthorization

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _accessToken = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(accessToken))];
        _refreshToken = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(refreshToken))];
        _role = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(role))];
        _roleTags = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(roleTags))];
        _expiresIn = [[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(expiresIn))] unsignedIntegerValue];
        _createdAt = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(createdAt))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
    [aCoder encodeObject:self.refreshToken forKey:NSStringFromSelector(@selector(refreshToken))];
    [aCoder encodeObject:self.role forKey:NSStringFromSelector(@selector(role))];
    [aCoder encodeObject:self.roleTags forKey:NSStringFromSelector(@selector(roleTags))];
    [aCoder encodeObject:@(self.expiresIn) forKey:NSStringFromSelector(@selector(expiresIn))];
    [aCoder encodeObject:self.createdAt forKey:NSStringFromSelector(@selector(createdAt))];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *_Nullable __autoreleasing *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    if (!self) return nil;

    _accessToken = [dictionary objectForKey:@"access_token"];
    _refreshToken = [dictionary objectForKey:@"refresh_token"];
    _role = [dictionary objectForKey:@"role"];
    _roleTags = [dictionary objectForKey:@"role_tags"];

    _expiresIn = [[dictionary objectForKey:@"expires_in"] integerValue];  // The cloud returns an expiration time
                                                                          // interval as a string when doing Facebook
                                                                          // OAuth, NSString doesn't implement
                                                                          // unsignedIntegerValue, so use integerValue
                                                                          // which both NSNumber and NSString implement
    _createdAt = [NSDate date];

    if (!_accessToken || !_refreshToken || !_createdAt || _expiresIn == 0) {
        _accessToken = _refreshToken = @"";

        NSMutableDictionary *errDictionary = [NSMutableDictionary dictionary];
        if (!_accessToken) {
            errDictionary[NSStringFromSelector(@selector(accessToken))] = AylaErrorDescriptionCanNotBeBlank;
        }
        if (!_refreshToken) {
            errDictionary[NSStringFromSelector(@selector(refreshToken))] = AylaErrorDescriptionCanNotBeBlank;
        }
        if (_expiresIn == 0) {
            errDictionary[NSStringFromSelector(@selector(expiresIn))] = AylaErrorDescriptionIsInvalid;
        }

        NSError *createdError = [NSError errorWithDomain:AylaJsonErrorDomain
                                                    code:AylaJsonErrorCodeInvalidJson
                                                userInfo:@{AylaRequestErrorResponseJsonKey : errDictionary}];
        if (error != NULL) {
            *error = createdError;
        }
    }
    return self;
}

- (NSTimeInterval)secondsToExpiry
{
    NSTimeInterval interval =
        [[self.createdAt dateByAddingTimeInterval:self.expiresIn] timeIntervalSinceDate:[NSDate date]];
    return interval > 0 ? interval : 0;
}

@end
