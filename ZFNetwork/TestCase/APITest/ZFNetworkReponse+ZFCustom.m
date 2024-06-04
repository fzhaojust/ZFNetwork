//
//  ZFNetworkReponse+ZFCustom.m
//  ZFNetworkDemo
//
//  Created by ZhaoFei on 2024/6/4.
//

#import "ZFNetworkReponse+ZFCustom.h"
#import <objc/runtime.h>

@implementation ZFNetworkReponse (ZFCustom)

static void const *ZFResponseErrorTypeKey = &ZFResponseErrorTypeKey;
- (void)setErrorType:(ZFResponseErrorType)errorType
{
    objc_setAssociatedObject(self, ZFResponseErrorTypeKey, @(errorType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (ZFResponseErrorType)errorType
{
    NSNumber *tmp = objc_getAssociatedObject(self, ZFResponseErrorTypeKey);
    return tmp.integerValue;
}
@end
