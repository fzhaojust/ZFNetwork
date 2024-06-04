//
//  ZFNetworkDefine.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import <Foundation/Foundation.h>

#ifndef ZFNetworkDefine_h
#define ZFNetworkDefine_h

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


#define ZFNETWORK_QUEUE_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define ZFNETWORK_MAIN_QUEUE_ASYNC(block) ZFNETWORK_QUEUE_ASYNC(dispatch_get_main_queue(), block)

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RequestMethod) {
    RequestMethodGET,
    RequestMethodPOST,
    RequestMethodDELETE,
    RequestMethodPUT,
    RequestMethodHEAD,
    RequestMethodPATCH,
};
typedef NS_ENUM(NSUInteger, NetworkCacheWriteMode) {
    CacheWriteModeNone = 0,
    CacheWriteModeMemory = 1,
    CacheWriteModeDisk = 2,
    CacheWriteModeMemoryAndDisk = CacheWriteModeMemory || CacheWriteModeDisk,
};

typedef NS_ENUM(NSInteger, NetworkCacheReadMode) {
    CacheReadModeNone,
    CacheReadModeAlsoNetwork,
    CacheReadModeCancelNetwork,
};

typedef NS_ENUM(NSInteger, NetworkReleaseStrategy) {
    ReleaseStrategyHoldRequest,
    ReleaseStrategyWhenRequestDeallck,
    ReleaseStrategyNotCareRequest,
};

typedef NS_ENUM(NSInteger, NetworkRepeatStratety) {
    RepeatStratetyAllAllowed,
    RepeatStratetyCancelOldest,
    RepeatStratetyCancelNewest,
};

typedef NS_ENUM(NSInteger, NetworkRequestRedirection) {
    RequestRedirectionSuccess,
    RequestRedirectionFailure,
    RequestRedirectionStop,
};

@class ZFNetworkReponse;
@class ZFBaseRequest;


typedef void(^ZFRequestProgressBlock)(NSProgress *progress);
typedef void(^ZFRequestCacheBlock)(ZFNetworkReponse *progress);
typedef void(^ZFRequestSuccessBlock)(ZFNetworkReponse *progress);
typedef void(^ZFRequestFailureBlock)(ZFNetworkReponse *progress);

@protocol ZFResponseDelegate <NSObject>

@optional

/// 上传进度
- (void)request:(__kindof ZFBaseRequest *)request uploadProgress:(NSProgress *)progress;

/// 下载进度
- (void)request:(__kindof ZFBaseRequest *)request downloadProgress:(NSProgress *)progress;

/// 缓存命中
- (void)request:(__kindof ZFBaseRequest *)request cacheWithResponse:(ZFNetworkReponse *)response;

/// 请求成功
- (void)request:(__kindof ZFBaseRequest *)request successWithResponse:(ZFNetworkReponse *)response;

/// 请求失败
- (void)request:(__kindof ZFBaseRequest *)request failureWithResponse:(ZFNetworkReponse *)response;

@end


NS_ASSUME_NONNULL_END

#endif /* ZFNetworkDefine_h */
