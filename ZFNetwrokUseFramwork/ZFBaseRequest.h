//
//  ZFBaseRequest.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import <Foundation/Foundation.h>
#import "ZFNetworkReponse.h"
#import "ZFNetworkCache.h"


NS_ASSUME_NONNULL_BEGIN

@interface ZFBaseRequest : NSObject

#pragma - 网络请求数据
@property (nonatomic, assign) RequestMethod requestMethod;

@property (nonatomic, copy)NSString *requestURL;

@property (nonatomic, copy, nullable) NSDictionary *requestParameter;

@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

@property (nonatomic, copy, nullable) void(^requestConstructingBody)(id<AFMultipartFormData> formData);

@property (nonatomic, copy) NSString *downloadPath;

#pragma - 发起网络请求
- (void)start;

- (void)startWithsuccess:(nullable ZFRequestSuccessBlock)success
                 failure:(nullable ZFRequestFailureBlock)failure;

- (void)startWithCache:(nullable ZFRequestCacheBlock)cache
               success:(nullable ZFRequestSuccessBlock)success
               failure:(nullable ZFRequestFailureBlock)failure;

- (void)startWithUploadProgress:(nullable ZFRequestProgressBlock)uploadProgress
               downloadProgress:(nullable ZFRequestProgressBlock)downloadProgress
                          cache:(nullable ZFRequestCacheBlock)cache
                        success:(nullable ZFRequestSuccessBlock)success
                        failure:(nullable ZFRequestFailureBlock)failure;

- (void)cancel;

#pragma - 回调代理
@property (nonatomic, weak) id<ZFResponseDelegate> delegate;


#pragma - 其他
@property (nonatomic, assign) NetworkReleaseStrategy releaseStrategy;

@property (nonatomic, assign) NetworkRepeatStratety repeatStrategy;

@property (nonatomic, assign) BOOL isExecuting;

- (NSString *)requestIdentifier;

- (void)clearRequestBlocks;

#pragma - 网络请求公共配置 (以子类化方式实现: 针对不同的接口团队设计不同的公共配置)

/**
 事务管理器 (通常情况下不需设置) 。注意：
 1、其 requestSerializer 和 responseSerializer 属性会被下面两个同名属性覆盖。
 */

@property (nonatomic, strong, nullable) AFHTTPSessionManager *sessionManager;

/** 请求序列化器 */
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;

/** 响应序列化器 */
@property (nonatomic, strong) AFHTTPResponseSerializer *responseSerializer;

/** 服务器地址及公共路径 (例如：https://www.baidu.com) */
@property (nonatomic, copy) NSString *baseURI;

@end

@interface ZFBaseRequest (PreprocessRequest)

- (nullable NSDictionary *)zf_preprocessParameter:(nullable NSDictionary *)parameter;

- (NSString *)zf_preprocessURLString:(nullable NSString *)URLString;

@end

@interface ZFBaseRequest (PreprocessResponse)
/**
 网络请求回调重定向，方法在子线程回调，并会再下面几个预处理方法之前调用。
 需要特别注意 YBRequestRedirectionStop 会停止后续操作，如果业务使用闭包回调，这个闭包不会被清空，可能会造成循环引用，所以这种场景务必保证回调被正确处理，一般有以下两种方式：
 1、Stop 过后执行特定逻辑，然后重新 start 发起网络请求，之前的回调闭包就能继续正常处理了。
 2、直接调用 clearRequestBlocks 清空回调闭包。
 */

- (void)zf_redirection:(void(^)(NetworkRedirection))redirection response:(ZFNetworkReponse *)response;

/** 预处理请求成功数据 (子线程执行, 若数据来自缓存在主线程执行) */
- (void)zf_preprocessSuccessInChildThreadWithResponse:(ZFNetworkReponse *)response;

/** 预处理请求成功数据 */
- (void)zf_preprocessSuccessInMainThreadWithResponse:(ZFNetworkReponse *)response;

/** 预处理请求失败数据 (子线程执行) */
- (void)zf_preprocessFailureInChildThreadWithResponse:(ZFNetworkReponse *)response;

/** 预处理请求失败数据 */
- (void)zf_preprocessFailureInMainThreadWithResponse:(ZFNetworkReponse *)response;

@end
NS_ASSUME_NONNULL_END
