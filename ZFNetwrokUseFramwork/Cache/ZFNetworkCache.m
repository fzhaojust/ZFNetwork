//
//  ZFNetworkCache.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/3.
//

#import "ZFNetworkCache.h"
#import "ZFNetworkCache+Internal.h"

@interface ZFNetWorkCachePackage : NSObject <NSCoding>
@property (nonatomic, strong) id<NSCoding> object;
@property (nonatomic, strong) NSDate *updateDate;
@end

@implementation ZFNetWorkCachePackage

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.object = [coder decodeObjectForKey:NSStringFromSelector(@selector(object))];
        self.updateDate = [coder decodeObjectForKey:NSStringFromSelector(@selector(updateDate))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.object forKey:NSStringFromSelector(@selector(object))];
    [coder encodeObject:self.updateDate forKey:NSStringFromSelector(@selector(updateDate))];
}

@end

static NSString *const ZFNetworkCacheName = @"ZFNetworkCacheName";
static YYDiskCache *_diskCache = nil;
static YYMemoryCache *_memoryCache = nil;

@implementation ZFNetworkCache
#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.writeMode = CacheWriteModeNone;
        self.readMode = CacheReadModeNone;
        self.ageSeconds = 0;
        self.extraCacheKey = [@"v" stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    }
    return self;
}
#pragma mark - public
+ (NSInteger)getDiskCacheSize
{
    return [ZFNetworkCache.diskCache totalCost] / 1024.0 / 1024.0;
}
+ (void)removeDiskCache
{
    [ZFNetworkCache.diskCache removeAllObjects];
}
+ (void)removeMemoryCache
{
    [ZFNetworkCache.memoryCache removeAllObjects];
}

#pragma mark - internal
- (void)setObject:(id<NSCoding>)object forKey:(id)key
{
    if (self.writeMode == CacheWriteModeNone) return;
    ZFNetWorkCachePackage *package = [ZFNetWorkCachePackage new];
    package.object = object;
    package.updateDate = [NSDate date];
    if (self.writeMode & CacheWriteModeMemory) {
        [ZFNetworkCache.memoryCache setObject:package forKey:key];
    }
    if (self.writeMode & CacheWriteModeDisk) {
        [ZFNetworkCache.diskCache setObject:package forKey:key withBlock:^{
            
        }];
    }
}
- (void)objectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block
{
    if (!block)return;
    void(^callBack)(id<NSCoding>) = ^(id<NSCoding> obj) {
        ZFNETWORK_MAIN_QUEUE_ASYNC(^{
            if (obj && [((NSObject *)obj) isKindOfClass:ZFNetWorkCachePackage.class]) {
                ZFNetWorkCachePackage *package = (ZFNetWorkCachePackage *)obj;
                if (self.ageSeconds != 0 && -[package.updateDate timeIntervalSinceNow] > self.ageSeconds) {
                    block(key, nil);
                } else {
                    block(key, package.object);
                }
            } else {
                block(key, nil);
            }
        })
    };
    id<NSCoding> object = [ZFNetworkCache.memoryCache objectForKey:key];
    if (object) {
        callBack(object);
    } else {
        [ZFNetworkCache.diskCache objectForKey:key withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
                    if (object && ![ZFNetworkCache.memoryCache objectForKey:key]) {
                        [ZFNetworkCache.memoryCache setObject:object forKey:key];
                    }
                    callBack(object);
        }];
    }
}

#pragma mark - getter
+ (YYDiskCache *)diskCache
{
    if (!_diskCache) {
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:ZFNetworkCacheName];
        _diskCache = [[YYDiskCache alloc] initWithPath:path];
    }
    return _diskCache;
}
+ (void)setDiskCache:(YYDiskCache *)diskCache
{
    _diskCache = diskCache;
}

+ (YYMemoryCache *)memoryCache
{
    if (!_memoryCache) {
        _memoryCache = [YYMemoryCache new];
        _memoryCache.name = ZFNetworkCacheName;
    }
    return _memoryCache;
}

+ (void)setMemoryCache:(YYMemoryCache *)memoryCache
{
    _memoryCache = memoryCache;
}
@end
