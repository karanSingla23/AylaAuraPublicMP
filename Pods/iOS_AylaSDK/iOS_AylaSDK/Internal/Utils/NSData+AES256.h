//
//  NSData+Crypto.h
//  iOS_AylaSDK
//
//  Created by Brian King on 6/21/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (AES256)
- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;

@end
