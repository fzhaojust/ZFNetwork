//
//  ZFBaseRequest+Internal.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/3.
//

#import "ZfBaseRequest.h"


NS_ASSUME_NONNULL_BEGIN

@interface ZFBaseRequest ()

/// 请求方法字符串
- (NSString *)requestMethodString;

/// 请求 URL 字符串
- (NSString *)validRequestURLString;

/// 请求参数字符串
- (id)validRequestParameter;

@end

NS_ASSUME_NONNULL_END
