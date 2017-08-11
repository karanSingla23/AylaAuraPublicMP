//
//  iOS_SDK
//
//  Copyright © 2016 AylaNetworks. All rights reserved.
//

#import "HTTPServer.h"

FOUNDATION_EXPORT NSInteger const AylaLANOTAHTTPDefaultServerPort;

/**
 * Delegate for image pushing status
 */
@protocol AylaLANOTAHTTPServerDelegate<NSObject>

/**
 * Method to be called when image push status updated.
 *
 * @param status image push status
 */
- (void)didReceiveImagePushStatus:(NSInteger)status;

@end

/**
 * HTTP Server for LAN OTA
 */
@interface AylaLANOTAHTTPServer : HTTPServer

/**
 * Delegate for image pushing status
 */
@property (nonatomic, weak) id<AylaLANOTAHTTPServerDelegate> delegate;

/**
 * Initial a HTTP Server with given port number
 *
 * @param portNum HTTP Server port
 *
 */
- (instancetype)initWithPort:(int)portNum;

/**
 * Get cureent image pushing status
 *
 * @return Image push status
 */
- (NSNumber *)imagePushStatus;

@end
