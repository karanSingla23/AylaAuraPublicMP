//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

@class AylaHTTPTask;
@class AylaLoginManager;

#import <WebKit/WebKit.h>
#import "AylaAuthProvider.h"
#import "AylaBaseAuthProvider.h"

/**
 *  Enumerates the supported OAuth types
 */
typedef NS_ENUM(NSInteger, AylaOAuthType) {
    
    /** Type used for Facebook authentication */
    AylaOAuthTypeFacebook,
    
    /** Type used for Google authentication */
    AylaOAuthTypeGoogle,
    
    /** Type used for Wechat authentication */
    AylaOAuthTypeWechat,
};

NS_ASSUME_NONNULL_BEGIN
/**
 *  Login provider for OAuth 2.0. When the `[AylaAuthProvider authenticateWithLoginManager:success:failure:]` method from superclass is
 * called, the `webView` passed when creating the instance will display the autherntication page for the specified OAuth
 * `type`
 */
@interface AylaOAuthProvider : AylaBaseAuthProvider


/** @name OAuth Provider Properties */

/**
 *  The `UIWebView` that will display the authentication page.
 */
@property (nonatomic, strong, readonly) WKWebView *webView;

/**
 *  The `AylaOAuthType` of authentication to use.
 */
@property (nonatomic, assign, readonly) AylaOAuthType type;

/** @name Initializer Methods */

/**
 *  Creates an instance with the specified `webView` and `type`
 *  Since Google block OAuth requests from web-views, for Google OAuth you should integrate Google SDK and pass the authCode to Ayla using `[AylaOAuthProvider providerWithAuthCode:type:]`
 *
 *  @param webView The `UIWebView` that will display the authentication page
 *  @param type    The `AylaOAuthType` of authentication to use.
 *
 *
 *  @return An `AylaOAuthProvider` instance, initialized with the specified `webView` and `type`
 */
+ (instancetype)providerWithWebView:(WKWebView *)webView type:(AylaOAuthType)type;

/** Method Unavailable. Do not use. (Marked NS_UNAVAILABLE) */
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
