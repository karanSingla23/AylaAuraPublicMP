//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaTimeZone.h"

#import "AylaDefines_Internal.h"
#import "AylaObject+Internal.h"
#import "AylaSystemUtils.h"

static NSString *const AylaTimeZoneAttrNameTimeZone            = @"time_zone";

static NSString *const AylaTimeZoneAttrNameDST                 = @"dst";
static NSString *const AylaTimeZoneAttrNameDSTActive           = @"dst_active";
static NSString *const AylaTimeZoneAttrNameDSTNextChangeDate   = @"dst_next_change_date";
static NSString *const AylaTimeZoneAttrNameDSTNextChangeTime   = @"dst_next_change_time";
static NSString *const AylaTimeZoneAttrNameUTCOffset           = @"utc_offset";
static NSString *const AylaTimeZoneAttrNameTimeZoneID          = @"tz_id";
static NSString *const AylaTimeZoneAttrNameKey                 = @"key";

@interface AylaTimeZone ()

@property (nonatomic, strong) NSNumber *key;

@property (nonatomic, strong, readwrite, nullable) NSString *dstNextChangeDateString;
@property (nonatomic, strong, readwrite, nullable) NSString *dstNextChangeTimeString;

@end

@implementation AylaTimeZone

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing _Nullable *)error
{
    self = [super initWithJSONDictionary:dictionary error:error];
    
    if (self) {
        NSDictionary *timeZoneDict = dictionary[AylaTimeZoneAttrNameTimeZone];

        if (timeZoneDict) {
            _dst = [(NSNumber *)timeZoneDict[AylaTimeZoneAttrNameDST] boolValue];
            _dstActive = [(NSNumber *)timeZoneDict[AylaTimeZoneAttrNameDSTActive] boolValue];
            _tzID = AYLNilIfNull(timeZoneDict[AylaTimeZoneAttrNameTimeZoneID]);
            _dstNextChangeDateString = AYLNilIfNull(timeZoneDict[AylaTimeZoneAttrNameDSTNextChangeDate]);
            _dstNextChangeTimeString = AYLNilIfNull(timeZoneDict[AylaTimeZoneAttrNameDSTNextChangeTime]);
            _utcOffset = AYLNilIfNull(timeZoneDict[AylaTimeZoneAttrNameUTCOffset]);
            _key = AYLNilIfNull(timeZoneDict[AylaTimeZoneAttrNameKey]);
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (NSDate *)dstNextChangeDate
{
    NSDate *date = nil;
    
    // Only applies when the time zone observes DST
    if (self.dst) {
        if ([self.dstNextChangeDateString length] && [self.utcOffset length]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSString *formattedDateString = nil;
            
            // Setup our date format and concatenated strings based on whether or not we have a time
            if ([self.dstNextChangeTimeString length]) {
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm Z"];
                formattedDateString = [NSString stringWithFormat:@"%@ %@ %@", self.dstNextChangeDateString, self.dstNextChangeTimeString, self.utcOffset];
            } else {
                [dateFormatter setDateFormat:@"yyyy-MM-dd Z"];
                formattedDateString = [NSString stringWithFormat:@"%@ %@", self.dstNextChangeDateString, self.utcOffset];
            }
            
            date = [dateFormatter dateFromString:formattedDateString];
            
            // The service doesn't adjust the utcOffset for DST. So we need adjust for that when DTS in in effect by subtracting an hour.
            if (self.dstActive) {
                NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
                date = [calendar dateByAddingUnit:NSCalendarUnitHour value:-1 toDate:date options:NSCalendarMatchStrictly];
            }
        } else {
            AYLAssert(NO, @"We should have a nextChangeDateString when DST is observed!");
        }
    }
    
    return date;
}

@end
