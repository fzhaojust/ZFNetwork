//
//  ZFBaseRequest.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/5/30.
//

#import "ZFBaseRequest.h"
#import "ZFBaseRequest+Internal.h"
#import "ZFNetworkCache+Internal.h"

#import <pthread/pthread.h>
#import "ZFNetworkManager.h"


#define ZFN_IDECORD_LOCK(...) \
pthread_mutex_lock(&self->_lock); \
__VA_ARGS__ \
pthread_mutex_unlock(&self->_lock); \

@class ZFNetworkCache;

@interface ZFBaseRequest ()

@property (nonatomic, copy, nullable) ZFRequestProgressBlock uploadProgress;
@property (nonatomic, copy, nullable) ZFRequestProgressBlock downloadProgress;
@property (nonatomic, copy, nullable) ZFRequestCacheBlock cacheBlock;
@property (nonatomic, copy, nullable) ZFRequestSuccessBlock successBlock;
@property (nonatomic, copy, nullable) ZFRequestFailureBlock failureBlock;
@property (nonatomic, strong) ZFNetworkCache *cacheHandler;
/// 记录网络任务标识容器
@property (nonatomic, strong) NSMutableSet<NSNumber *> *taskIDRecord;

@end


@implementation ZFBaseRequest {
    pthread_mutex_t _lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        self.releaseStrategy = ReleaseStrategyHoldRequest;
        self.repeatStrategy = RepeatStratetyAllAllowed;
        self.taskIDRecord = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc
{
    if (self.releaseStrategy == ReleaseStrategyWhenRequestDeallck) {
        [self cancel];
    }
    pthread_mutex_destroy(&_lock);
    
}

#pragma mark - public
- (void)startWithsuccess:(ZFRequestSuccessBlock)success failure:(ZFRequestFailureBlock)failure
{
    [self startWithUploadProgress:nil downloadProgress:nil cache:nil success:success failure:failure];
}

- (void)startWithCache:(ZFRequestCacheBlock)cache success:(ZFRequestSuccessBlock)success failure:(ZFRequestFailureBlock)failure
{
    [self startWithUploadProgress:nil downloadProgress:nil cache:cache success:success failure:failure];
}

- (void)startWithUploadProgress:(ZFRequestProgressBlock)uploadProgress downloadProgress:(ZFRequestProgressBlock)downloadProgress cache:(ZFRequestCacheBlock)cache success:(ZFRequestSuccessBlock)success failure:(ZFRequestFailureBlock)failure
{
    self.uploadProgress = uploadProgress;
    self.downloadProgress = downloadProgress;
    self.cacheBlock = cache;
    self.successBlock = success;
    self.failureBlock = failure;
    [self start];
}

- (void)start
{
    if (self.isExecuting) {
        switch (self.repeatStrategy) {
            case RepeatStratetyCancelNewest:
                return;
                break;
            case RepeatStratetyCancelOldest:
                [self cancelNetworking];
                break;
            default:
                break;
        }
    }
    NSString *cacheKey = [self requestCacheKey];
    if (self.cacheHandler.readMode == CacheReadModeNone) {
        [self startWithCache:cacheKey];
        return;
    }
    [self.cacheHandler objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
            if (object) {
                ZFNetworkReponse *response = [ZFNetworkReponse responseWithSessionTask:nil responseObject:object error:nil];
                [self successWithResponse:response cacheKey:cacheKey fromCache:YES taskID:nil];
            }
        BOOL needRequestNetwork = !object || self.cacheHandler.readMode == CacheReadModeAlsoNetwork;
        if (needRequestNetwork) {
            [self startWithCache:cacheKey];
        } else {
            [self clearRequestBlocks];
        }
        
    }];

}

- (void)cancel
{
    self.delegate = nil;
    [self cancelNetworking];
    [self clearRequestBlocks];
}

#pragma mark - request
- (void)startWithCache:(NSString *)cacheKey
{
    __weak typeof(self) weakSelf = self;
    BOOL(^cancelled)(NSNumber *) = ^BOOL(NSNumber *taskID) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return YES;
        ZFN_IDECORD_LOCK(BOOL contains = [self.taskIDRecord containsObject:taskID];)
        return !contains;
    };
    __block NSNumber *taskID = nil;
    if (self.releaseStrategy == ReleaseStrategyHoldRequest) {
        taskID = [[ZFNetworkManager sharedManager] startNetworkingWithRequest:self uploadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            [self requestUploadProgress:progress];
        } downloadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            [self requestDownloadProgress:progress];
        } completion:^(ZFNetworkReponse * _Nonnull response) {
            if (cancelled(taskID)) return;
            [self requestCompletionWithresponse:response cacheKey:cacheKey fromCache:NO taskID:taskID];
        }];
    } else {
        __weak typeof(self) weakSelf = self;
        taskID = [[ZFNetworkManager sharedManager] startNetworkingWithRequest:weakSelf uploadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            __strong typeof(weakSelf) self = weakSelf;
            [self requestUploadProgress:progress];
        } downloadProgress:^(NSProgress * _Nonnull progress) {
            if (cancelled(taskID)) return;
            __strong typeof(weakSelf) self = weakSelf;
            [self requestDownloadProgress:progress];
        } completion:^(ZFNetworkReponse * _Nonnull response) {
            if (cancelled(taskID)) return;
            __strong typeof(weakSelf) self = weakSelf;
            [self requestCompletionWithresponse:response cacheKey:cacheKey fromCache:NO taskID:taskID];
        }];
    }
    if (nil != taskID) {
        ZFN_IDECORD_LOCK([self.taskIDRecord addObject:taskID];)
    }
    
}

#pragma mark - request
- (void)requestUploadProgress:(NSProgress *)progress
{
    ZFNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self.delegate respondsToSelector:@selector(request:uploadProgress:)]) {
            [self.delegate request:self uploadProgress:progress];
        }
        if (self.uploadProgress) {
            self.uploadProgress(progress);
        }
    })
    
}

- (void)requestDownloadProgress:(NSProgress *)progress
{
    ZFNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self.delegate respondsToSelector:@selector(request:downloadProgress:)]) {
            [self.delegate request:self downloadProgress:progress];
        }
        if (self.downloadProgress) {
            self.downloadProgress(progress);
        }
    })
}

- (void)requestCompletionWithresponse:(ZFNetworkReponse *)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache taskID:(NSNumber *)taskID
{
    void(^process)(NetworkRequestRedirection) = ^(NetworkRequestRedirection redirection) {
        switch (redirection) {
            case RequestRedirectionSuccess: {
                [self successWithResponse:response cacheKey:cacheKey fromCache:NO taskID:taskID];
            }
                break;
            case RequestRedirectionFailure: {
                [self failureWithResponse:response taskID:taskID];
            }
                break;
            case RequestRedirectionStop:
            default: {
                ZFN_IDECORD_LOCK([self.taskIDRecord removeObject:taskID];)
            }
                break;
        }
    };
    if ([self respondsToSelector:@selector(zf_redirection:response:)]) {
        [self zf_redirection:process response:response];
    } else {
        NetworkRequestRedirection redirection = response.error ? RequestRedirectionFailure : RequestRedirectionSuccess;
        process(redirection);
    }
}

- (void)successWithResponse:(ZFNetworkReponse *)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache taskID:(NSNumber *)taskID
{
    if ([self respondsToSelector:@selector(zf_preprocessSuccessInChildThreadWithResponse:)]) {
        [self zf_preprocessSuccessInChildThreadWithResponse:response];
    }
    ZFNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self respondsToSelector:@selector(zf_preprocessSuccessInMainThreadWithResponse:)]) {
            [self zf_preprocessSuccessInMainThreadWithResponse:response];
        }
        if (fromCache) {
            if ([self.delegate respondsToSelector:@selector(request:cacheWithResponse:)]) {
                [self.delegate request:self cacheWithResponse:response];
            }
            if (self.cacheBlock) {
                self.cacheBlock(response);
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(request:successWithResponse:)]) {
                [self.delegate request:self successWithResponse:response];
            }
            if (self.successBlock) {
                self.successBlock(response);
            }
            [self clearRequestBlocks];
            // 在网络响应数据被业务处理完成后进行缓存，可避免将异常数据写入缓存（比如数据导致 Crash 的情况）
            BOOL shouldCache = !self.cacheHandler.shouldCacheBlock || self.cacheHandler.shouldCacheBlock(response);
            BOOL isSendFile = self.requestConstructingBody || self.downloadPath.length > 0;
            if (!isSendFile && shouldCache) {
                [self.cacheHandler setObject:response.responseObject forKey:cacheKey];
            }
        }
        if (taskID) {
            [self.taskIDRecord removeObject:taskID];
        }
    })
}

- (void)failureWithResponse:(ZFNetworkReponse *)response taskID:(NSNumber *)taskID
{
    if ([self respondsToSelector:@selector(zf_preprocessFailureInChildThreadWithResponse:)]) {
        [self zf_preprocessFailureInChildThreadWithResponse:response];
    }
    ZFNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self respondsToSelector:@selector(zf_preprocessFailureInMainThreadWithResponse:)]) {
            [self zf_preprocessFailureInMainThreadWithResponse:response];
        }
        if ([self.delegate respondsToSelector:@selector(request:failureWithResponse:)]) {
            [self.delegate request:self failureWithResponse:response];
        }
        if (self.failureBlock) {
            self.failureBlock(response);
        }
        [self clearRequestBlocks];
        if (taskID) [self.taskIDRecord removeObject:taskID];
    })
    
}
#pragma mark - private

- (void)cancelNetworking
{
    ZFN_IDECORD_LOCK(
                      NSSet *removeSet = self.taskIDRecord.mutableCopy;
                      [self.taskIDRecord removeAllObjects];
                      )
    [[ZFNetworkManager sharedManager] cancelNetworkingWithSet:removeSet];
}

- (void)clearRequestBlocks
{
    self.uploadProgress = nil;
    self.downloadProgress = nil;
    self.cacheBlock = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
}

- (BOOL)isExecuting
{
    ZFN_IDECORD_LOCK(BOOL isExecuting = self.taskIDRecord.count > 0;)
    return isExecuting;
}
- (NSString *)requestIdentifier
{
    NSString *identifier = [NSString stringWithFormat:@"%@-%@%@", [self requestMethodString], [self validRequestURLString], [self stringFromParameter:[self validRequestParameter]]];
    return identifier;
}
- (NSString *)requestCacheKey
{
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", self.cacheHandler.extraCacheKey, [self requestIdentifier]];
    if (self.cacheHandler.customCacheKeyBlock) {
        cacheKey = self.cacheHandler.customCacheKeyBlock(cacheKey);
    }
    return cacheKey;
}
- (NSString *)stringFromParameter:(NSDictionary *)parameter
{
    NSMutableString *string = [NSMutableString string];
    NSArray *allKeys = [parameter.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[NSString stringWithFormat:@"%@", obj1] compare:[NSString stringWithFormat:@"%@", obj2] options:NSLiteralSearch];
    }];
    for (id key in allKeys) {
        [string appendString:[NSString stringWithFormat:@"%@%@=%@", string.length > 0 ? @"&" : @"?", key, parameter[key]]];
    }
    return string;
}


- (NSString *)requestMethodString
{
    switch (self.requestMethod) {
        case RequestMethodGET: return @"GET";
        case RequestMethodPOST: return @"POST";
        case RequestMethodPUT: return @"PUT";
        case RequestMethodDELETE: return @"DELETE";
        case RequestMethodHEAD: return @"HEAD";
        case RequestMethodPATCH: return @"PATCH";
    }
}

- (NSString *)validRequestURLString
{
    NSURL *baseURL = [NSURL URLWithString:self.baseURI];
    NSString *URLString = [NSURL URLWithString:self.requestURL relativeToURL:baseURL].absoluteString;
    if ([self respondsToSelector:@selector(zf_preprocessURLString:)]) {
        URLString = [self zf_preprocessURLString:URLString];
    }
    return URLString;
}

- (id)validRequestParameter
{
    id parameter = self.requestParameter;
    if ([self respondsToSelector:@selector(zf_preprocessParameter:)]) {
        parameter = [self zf_preprocessParameter:parameter];
    }
}

#pragma mark - getter
- (ZFNetworkCache *)cacheHandler
{
    if (!_cacheHandler) {
        _cacheHandler = [ZFNetworkCache new];
    }
    return _cacheHandler;
}

@end
