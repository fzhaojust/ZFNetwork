//
//  DefaultServerRequest.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/4.
//

#import "DefaultServerRequest.h"

@implementation DefaultServerRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baseURI = @"http://japi.juhe.cn";
        [self.cacheHandler setShouldCacheBlock:^BOOL(ZFNetworkReponse * _Nonnull response) {
            return YES;
        }];
    }
    return self;
}

#pragma mark - override
- (AFHTTPRequestSerializer *)requestSerializer
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer new];
    serializer.timeoutInterval = 25;
    return serializer;
}

- (AFHTTPResponseSerializer *)responseSerializer
{
    AFHTTPResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSMutableSet *types = [NSMutableSet set];
    [types addObject:@"text/html"];
    [types addObject:@"text/plain"];
    [types addObject:@"application/json"];
    [types addObject:@"text/json"];
    [types addObject:@"text/javascript"];
    serializer.acceptableContentTypes = types;
    return serializer;
}

- (void)start {
    NSLog(@"发起请求：%@", self.requestIdentifier);
    [super start];
}

- (void)zf_redirection:(void (^)(NetworkRequestRedirection))redirection response:(ZFNetworkReponse *)response
{
    //处理错误状态
    if (response.error) {
        ZFResponseErrorType errorType;
        switch (response.error.code) {
            case NSURLErrorTimedOut:
                errorType = ZFResponseErrorTypeTimeOut;
                break;
            case NSURLErrorCancelled:
                errorType = ZFResponseErrorTypeCancelled;
                break;
            default:
                errorType = ZFResponseErrorTypeNoNetwork;
                break;
        }
        response.errorType = errorType;
    }
    // 自定义重定向
    NSDictionary *responseDic = response.responseObject;
    if ([[NSString stringWithFormat:@"%@", responseDic[@"error_code"]] isEqualToString:@"2"]) {
        redirection(RequestRedirectionFailure);
        response.errorType = ZFResponseErrorTypeServerError;
        return;
    }
    redirection(RequestRedirectionSuccess);
}

- (NSDictionary *)zf_preprocessParameter:(NSDictionary *)parameter
{
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:parameter ?: @{}];
    tmp[@"test_deviceID"] = @"test250";
    return tmp;
}

- (NSString *)zf_preprocessURLString:(NSString *)URLString
{
    return URLString;
}

- (void)zf_preprocessSuccessInChildThreadWithResponse:(ZFNetworkReponse *)response
{
    NSMutableDictionary *res = [NSMutableDictionary dictionaryWithDictionary:response.responseObject];
    res[@"test_user"] = @"indulge_in";
    response.responseObject = res;
}


@end
