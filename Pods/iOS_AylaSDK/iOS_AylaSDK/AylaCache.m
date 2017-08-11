//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AylaCache.h"
#import "AylaLanConfig.h"
#import "AylaLogManager.h"
#import "AylaNetworks.h"
#import "AylaObject+Internal.h"
#import "AylaSessionManager.h"
#import "AylaSystemUtils.h"
#import "NSData+AES256.h"
#import <CommonCrypto/CommonDigest.h>
#import <zlib.h>

@interface AylaCache () {
  int caches;
}

@property(nonatomic) NSString *sessionName;
@property (strong, nonatomic) NSString *_testSessionAccessToken;
@end

@implementation AylaCache

NSString *const kAylaCacheParamDeviceDsn = @"dsn";

NSString *const AylaCacheTypeLANConfigPrefix = @"lanConfig_";
NSString *const AylaCacheTypeDevicePrefix = @"allDevices";
NSString *const AylaCacheTypePropertyPrefix = @"properties_";
NSString *const AylaCacheTypeNodePrefix = @"nodes_";
NSString *const AylaCacheTypeSetupPrefix = @"newDeviceConnected";
NSString *const AylaCacheTypeGroupPrefix = @"group";

static NSString *const AylaCacheDeviceFile = @"AylaDevicesArchiver.arch";
static NSString *const AylaCacheSetupFile = @"newDeviceConnected.arch";
static NSString *const AylaCacheGroupFile = @"group.arch";

- (instancetype)initWithSessionName:(NSString *)sessionName {
  if (self = [super init]) {
    caches = 0xFF;
    self.sessionName = sessionName;
  }
  return self;
}

- (BOOL)cachingEnabled {
  return (caches != 0x00);
}

- (BOOL)cachingEnabled:(NSInteger)selection {
  return (caches & selection) == selection;
}

- (void)enable:(NSInteger)cachesToSet {
  caches |= cachesToSet;
}

- (void)disable:(NSInteger)cachesToDisable {
  caches &= ~cachesToDisable;
}

- (void)clearAll {
  [self clear:AylaCacheTypeAll];
}

- (NSInteger)caches {
  return caches;
}

- (void)clear:(NSInteger)cachesToClear {
  NSFileManager *manager = [[NSFileManager alloc] init];
  NSDirectoryEnumerator *en =
      [manager enumeratorAtPath:[AylaSystemUtils
                                    deviceArchivesPathForSession:_sessionName]];
  NSString *fileObj;

  AylaLogI([AylaCache logTag], 0, @"%@ mask: %ld", NSStringFromSelector(_cmd),
           cachesToClear);
  while (fileObj = [en nextObject]) {
    BOOL shouldClearLANCache =
        ([fileObj rangeOfString:AylaCacheTypeLANConfigPrefix].location !=
             NSNotFound &&
         ((cachesToClear & AylaCacheTypeLANConfig) != 0x00));
    BOOL shouldClearPropertyCache =
        ([fileObj rangeOfString:AylaCacheTypePropertyPrefix].location !=
             NSNotFound &&
         ((cachesToClear & AylaCacheTypeProperty) != 0x00));
    BOOL shouldClearNodeCache =
        ([fileObj rangeOfString:AylaCacheTypeNodePrefix].location !=
             NSNotFound &&
         ((cachesToClear & AylaCacheTypeNode) != 0x00));
    BOOL shouldClearDeviceCache =
        ([fileObj isEqualToString:AylaCacheDeviceFile] &&
         ((cachesToClear & AylaCacheTypeDevice) != 0x00));
    BOOL shouldClearSetupCache =
        ([fileObj isEqualToString:AylaCacheSetupFile] &&
         ((cachesToClear & AylaCacheTypeSetup) != 0x00));
    BOOL shouldClearGroupCache =
        ([fileObj isEqualToString:AylaCacheGroupFile] &&
         ((cachesToClear & AylaCacheTypeGroup) != 0x00));

    if (shouldClearLANCache || shouldClearPropertyCache ||
        shouldClearNodeCache || shouldClearDeviceCache ||
        shouldClearSetupCache || shouldClearGroupCache) {
      NSError *error;
      [[NSFileManager defaultManager]
          removeItemAtPath:[[AylaSystemUtils
                               deviceArchivesPathForSession:_sessionName]
                               stringByAppendingPathComponent:fileObj]
                     error:&error];
      if (error) {
        AylaLogE([AylaCache logTag], 0, @"%@. Error: %@",
                 NSStringFromSelector(_cmd), error);
      }
    }
  }
}

- (void)clear:(NSInteger)cachesToClear withParams:(NSDictionary *)params {
  NSFileManager *manager = [[NSFileManager alloc] init];
  NSDirectoryEnumerator *en =
      [manager enumeratorAtPath:[AylaSystemUtils
                                    deviceArchivesPathForSession:_sessionName]];
  NSString *fileObj;
  NSString *fileName = nil;

  if ((cachesToClear & AylaCacheTypeProperty) != 0) {
    fileName = AylaCacheTypePropertyPrefix;
    if (params && params[kAylaCacheParamDeviceDsn]) {
      NSString *dsn = params[kAylaCacheParamDeviceDsn];
      fileName =
          [NSString stringWithFormat:@"%@%@", AylaCacheTypePropertyPrefix, dsn];
    }
  }

  AylaLogI([AylaCache logTag], 0, @"%@ mask: %ld", NSStringFromSelector(_cmd),
           cachesToClear);
  if (fileName) {
    while (fileObj = [en nextObject]) {
      if ([fileObj rangeOfString:fileName].location != NSNotFound) {
        NSError *error;
        [[NSFileManager defaultManager]
            removeItemAtPath:[[AylaSystemUtils
                                 deviceArchivesPathForSession:_sessionName]
                                 stringByAppendingPathComponent:fileObj]
                       error:&error];
        if (error) {
          AylaLogE([AylaCache logTag], 0, @"%@. Error: %@",
                   NSStringFromSelector(_cmd), error);
        }
      }
    }
  }
}

- (id)getData:(NSString *)key {
  if (key) {
    return [self loadCache:key];
  }
  return nil;
}

- (id)getData:(AylaCacheType)cacheType uniqueId:(NSString *)uniqueId {
  NSString *id = [self getKey:cacheType uniqueId:uniqueId];

  if (id) {
    return [self loadCache:id];
  }
  return nil;
}

- (BOOL)save:(AylaCacheType)cacheType
    uniqueId:(NSString *)uniqueId
   andObject:(id)valueToCache {
  if (![self cachingEnabled:cacheType]) {
    return NO;
  }

  NSString *id = [self getKey:cacheType uniqueId:uniqueId];

  if (id) {
    return [self save:id object:valueToCache];
  }
  return NO;
}

- (id)loadCache:(NSString *)name {
  if ([name containsString:AylaCacheTypeLANConfigPrefix]) {
    return [self loadLanConfig:name];
  }

  if ([name isEqualToString:AylaCacheTypeDevicePrefix]) {
    if ((caches & AylaCacheTypeDevice) == 0x00) {
      return nil;
    }
    id root = [NSKeyedUnarchiver
        unarchiveObjectWithFile:
            [AylaSystemUtils devicesArchiveFilePathForSession:_sessionName]];
    if (root == NULL)
      return nil;
    NSMutableDictionary *devices = root;
    return devices;
  } else if (([name rangeOfString:AylaCacheTypePropertyPrefix].location !=
                  NSNotFound &&
              ((caches & AylaCacheTypeProperty) != 0x00)) ||
             ([name rangeOfString:AylaCacheTypeNodePrefix].location !=
                  NSNotFound &&
              ((caches & AylaCacheTypeNode) != 0x00)) ||
             ([name isEqualToString:AylaCacheTypeSetupPrefix] &&
              ((caches & AylaCacheTypeSetup) != 0x00)) ||
             ([name isEqualToString:AylaCacheTypeGroupPrefix] &&
              ((caches & AylaCacheTypeGroup) != 0x00))) {
    id root = [NSKeyedUnarchiver
        unarchiveObjectWithFile:
            [NSString
                stringWithFormat:@"%@/%@%@",
                                 [AylaSystemUtils
                                     deviceArchivesPathForSession:_sessionName],
                                 name, @".arch"]];
    return root == NULL ? nil : root;
  }
  return nil;
}

- (id)getKey:(AylaCacheType)type uniqueId:(NSString *)uniqueId {
  NSString *key = nil;
  switch (type) {
  case AylaCacheTypeDevice:
    key = AylaCacheTypeDevicePrefix;
    break;
  case AylaCacheTypeSetup:
    key = AylaCacheTypeSetupPrefix;
    break;
  case AylaCacheTypeProperty:
    key = [NSString
        stringWithFormat:@"%@%@", AylaCacheTypePropertyPrefix, uniqueId];
    break;
  case AylaCacheTypeLANConfig:
    key = [NSString
        stringWithFormat:@"%@%@", AylaCacheTypeLANConfigPrefix, uniqueId];
    break;
  case AylaCacheTypeNode:
    key =
        [NSString stringWithFormat:@"%@%@", AylaCacheTypeNodePrefix, uniqueId];
    break;
  case AylaCacheTypeGroup:
    key = AylaCacheTypeGroupPrefix;
    break;
  default:
    break;
  }
  return key;
}

- (BOOL)save:(NSString *)name object:(id)value {
  if (value == nil) { // Delete cache
    if ([name isEqualToString:AylaCacheDeviceFile]) {
      NSError *error;
      [[NSFileManager defaultManager]
          removeItemAtPath:[AylaSystemUtils
                               devicesArchiveFilePathForSession:_sessionName]
                     error:&error];
      if (error && error.code != 4) {
        AylaLogE([AylaCache logTag], 0, @"%@. Error: %@",
                 NSStringFromSelector(_cmd), error);
        return NO;
      }
    } else if ([name rangeOfString:AylaCacheTypeLANConfigPrefix].location !=
                   NSNotFound ||
               [name rangeOfString:AylaCacheTypePropertyPrefix].location !=
                   NSNotFound ||
               [name rangeOfString:AylaCacheTypeNodePrefix].location !=
                   NSNotFound ||
               [name isEqualToString:AylaCacheTypeSetupPrefix] ||
               [name isEqualToString:AylaCacheTypeGroupPrefix]) {
      NSError *error;
      [[NSFileManager defaultManager]
          removeItemAtPath:
              [NSString stringWithFormat:
                            @"%@/%@%@",
                            [AylaSystemUtils
                                deviceArchivesPathForSession:_sessionName],
                            name, @".arch"]
                     error:&error];
      if (error && error.code != 4) {
        AylaLogE([AylaCache logTag], 0, @"%@. Error: %@",
                 NSStringFromSelector(_cmd), error);
        return NO;
      }
    }
    return YES;
  } else {
    if ([name rangeOfString:AylaCacheTypeLANConfigPrefix].location !=
        NSNotFound) {
      // LAN config is special in that it is encrypted. We need to provide the
      // session name to the
      // object before archiving so that it knows which session it belongs to.
      if ([value isKindOfClass:[AylaLanConfig class]]) {
        AylaLanConfig *lanConfig = (AylaLanConfig *)value;
        return [self saveLanConfig:lanConfig withName:name];
      } else {
        AylaLogE(
            [AylaCache logTag], 0,
            @"Cache request for LAN config that is not a LAN config object");
        return NO;
      }
    }

    if ([name rangeOfString:AylaCacheTypeDevicePrefix].location != NSNotFound) {
      [NSKeyedArchiver
          archiveRootObject:value
                     toFile:[AylaSystemUtils
                                devicesArchiveFilePathForSession:_sessionName]];
      return YES;
    } else if ([name rangeOfString:AylaCacheTypeLANConfigPrefix].location !=
                   NSNotFound ||
               [name rangeOfString:AylaCacheTypePropertyPrefix].location !=
                   NSNotFound ||
               [name rangeOfString:AylaCacheTypeNodePrefix].location !=
                   NSNotFound ||
               [name isEqualToString:AylaCacheTypeSetupPrefix] ||
               [name isEqualToString:AylaCacheTypeGroupPrefix]) {
      [NSKeyedArchiver
          archiveRootObject:value
                     toFile:[NSString stringWithFormat:
                                          @"%@/%@%@",
                                          [AylaSystemUtils
                                              deviceArchivesPathForSession:
                                                  _sessionName],
                                          name, @".arch"]];
      return YES;
    }
  }
  return NO;
}

- (BOOL)saveLanConfig:(AylaLanConfig *)lanConfig withName:(NSString *)name {
  NSDictionary *jsonDictionary = [lanConfig toJSONDictionary];
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                     options:0
                                                       error:nil];
  if ([jsonData length] == 0) {
    AylaLogE([AylaCache logTag], 0, @"No LAN config data to save");
    return NO;
  }

  NSString *key = [self lanConfigKey];
  if (key == nil) {
    return NO;
  }

  NSData *encryptedData = [jsonData AES256EncryptWithKey:key];

  NSString *filename =
      [NSString stringWithFormat:@"%@/%@%@",
                                 [AylaSystemUtils
                                     deviceArchivesPathForSession:_sessionName],
                                 name, @".arch"];

  return [encryptedData writeToFile:filename atomically:NO];
}

- (AylaLanConfig *)loadLanConfig:(NSString *)name {
  NSString *filename =
      [NSString stringWithFormat:@"%@/%@%@",
                                 [AylaSystemUtils
                                     deviceArchivesPathForSession:_sessionName],
                                 name, @".arch"];

  NSData *encryptedData = [NSData dataWithContentsOfFile:filename];
  if (encryptedData == nil) {
    return nil;
  }

  NSString *key = [self lanConfigKey];
  if (key == nil) {
    return nil;
  }

  NSData *decryptedData = [encryptedData AES256DecryptWithKey:key];
  NSDictionary *jsonDictionary =
      [NSJSONSerialization JSONObjectWithData:decryptedData
                                      options:0
                                        error:nil];
  if (jsonDictionary == nil) {
    return nil;
  }

  return
      [[AylaLanConfig alloc] initWithJSONDictionary:jsonDictionary error:nil];
}

- (NSString *)lanConfigKey {
  // Get the session manager
  AylaSessionManager *sessionManager =
      [[AylaNetworks shared] getSessionManagerWithName:_sessionName];
    NSString *authString = sessionManager.authorization.accessToken;
  if (authString == nil) {
#ifdef DEBUG
      authString = self._testSessionAccessToken;
#else
      return nil;
#endif
  }

  // Create pointer to the string as UTF8
  const char *ptr = [authString UTF8String];

  // Create byte array of unsigned chars
  unsigned char shaBuffer[CC_SHA256_DIGEST_LENGTH];

  // Create 16 byte SHA256 hash value, store in buffer
  CC_SHA256(ptr, (CC_LONG)strlen(ptr), shaBuffer);

  // Convert SHA256 value in the buffer to NSString of hex values
  NSMutableString *output =
      [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x", shaBuffer[i]];

  return output;
}

+ (NSString *)logTag {
  return NSStringFromClass([self class]);
}
@end