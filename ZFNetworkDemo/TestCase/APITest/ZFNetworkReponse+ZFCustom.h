//
//  ZFNetworkReponse+ZFCustom.h
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/4.
//

#import "ZFNetworkReponse.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ZFResponseErrorType) {
    ZFResponseErrorTypeUnKnown,
    ZFResponseErrorTypeTimeOut,
    ZFResponseErrorTypeCancelled,
    ZFResponseErrorTypeNoNetwork,
    ZFResponseErrorTypeServerError,
    ZFResponseErrorTypeLoginExpired
};

@interface ZFNetworkReponse (ZFCustom)

// 请求失败类型
@property (nonatomic, assign) ZFResponseErrorType errorType;
@end

NS_ASSUME_NONNULL_END
