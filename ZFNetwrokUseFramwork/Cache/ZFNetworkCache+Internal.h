//
//  ZFNetworkCache+Internal.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/3.
//

#import "ZFNetworkCache.h"

//#ifndef ZFNetworkCache_Internal_h
//#define ZFNetworkCache_Internal_h
NS_ASSUME_NONNULL_BEGIN

@interface ZFNetworkCache ()

- (void)setObject:(nullable id<NSCoding>)object forKey:(id)key;

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block;

@end

NS_ASSUME_NONNULL_END

//#endif /* ZFNetworkCache_Internal_h */
