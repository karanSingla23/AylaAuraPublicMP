//
//  AFHTTPSessionManagerProfiler.m
//  iOS_AylaSDK
//
//  Created by Emanuel Peña Aguilar on 10/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import "AFHTTPSessionManagerProfiler.h"
#import "AylaHTTPClient.h"


@interface AFHTTPSessionManager (Ayla_NetworkProfiler)
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;
@end

@implementation AFHTTPSessionManagerProfiler
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                                   URLString:(NSString *)URLString
                                                  parameters:(id)parameters
                                              uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                            downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                                                     success:(void (^)(NSURLSessionDataTask *, id))success
                                                     failure:(void (^)(NSURLSessionDataTask *, NSError *))failure {
    
    CFTimeInterval startTime = CACurrentMediaTime();
    NSURLSessionDataTask *dataTask = [super dataTaskWithHTTPMethod:method URLString:URLString parameters:parameters uploadProgress:uploadProgress downloadProgress:downloadProgress success:^(NSURLSessionDataTask *task, id response) {
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"Success: %@: %@, Total Runtime: %g s", method, URLString, endTime - startTime);
        [[AylaProfiler sharedInstance] didSucceedTask:task duration:endTime - startTime];
        success(task,response);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"Failure: %@: %@, Total Runtime: %g s", method, URLString, endTime - startTime);
        [[AylaProfiler sharedInstance] didFailTask:task duration:endTime - startTime];
        failure(task,error);
    }];
    [[AylaProfiler sharedInstance] didStartTask:dataTask];
    return dataTask;
}

@end
