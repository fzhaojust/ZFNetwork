//
//  ZFNetworkCache.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/3.
//

#import <Foundation/Foundation.h>
#import "ZFNetworkDefine.h"
#import <YYCache/YYCache.h>


@class ZFNetworkReponse;

NS_ASSUME_NONNULL_BEGIN

@interface ZFNetworkCache : NSObject

@property (nonatomic, assign) NetworkCacheWriteMode writeMode;

@property (nonatomic, assign) NetworkCacheReadMode readMode;

@property (nonatomic, assign) NSTimeInterval ageSeconds;

@property (nonatomic, copy) NSString *extraCacheKey;

@property (nonatomic, copy, nullable) BOOL(^shouldCacheBlock)(ZFNetworkReponse *response);

@property (nonatomic, copy, nullable) NSString *(^customCacheKeyBlock)(NSString *defaultCacheKey);


//获取磁盘大小
+ (NSInteger)getDiskCacheSize;

+ (void)removeDiskCache;

+ (void)removeMemoryCache;

@property (nonatomic, class, readonly) YYDiskCache *diskCache;

@property (nonatomic, class, readonly) YYMemoryCache *memoryCache;

@end

NS_ASSUME_NONNULL_END
