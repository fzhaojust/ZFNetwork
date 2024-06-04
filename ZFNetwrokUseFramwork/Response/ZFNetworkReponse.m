//
//  ZFNetworkReponse.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import "ZFNetworkReponse.h"


@implementation ZFNetworkReponse

+ (instancetype)responseWithSessionTask:(nullable NSURLSessionTask *)sessionTask
                         responseObject:(nullable id)responseObject
                                  error:(nullable NSError *)error
{
    ZFNetworkReponse *response = [[ZFNetworkReponse alloc] init];
    response->_sessionTask = sessionTask;
    response->_responseObject = responseObject;
    response->_error = error;
    return response;
}


- (NSHTTPURLResponse *)URLResponse
{
    if (!self.sessionTask || [self.sessionTask.response isKindOfClass:NSHTTPURLResponse.class]) {
        return nil;
    }
    return (NSHTTPURLResponse *)self.sessionTask.response;
}

@end
